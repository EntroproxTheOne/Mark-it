import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mark_it/src/services/monetization_config.dart';

const _kPremiumKey = 'monetization_is_premium';
const _kDebugSkipGateKey = 'debug_skip_export_gate';

/// Handles rewarded ads, Play Billing subscription state, and export gating.
class MonetizationService {
  MonetizationService._();
  static final MonetizationService instance = MonetizationService._();

  bool _initialized = false;
  bool _purchaseListenerAttached = false;
  SharedPreferences? _prefs;
  Completer<bool>? _pendingPurchaseCompleter;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    if (Platform.isAndroid || Platform.isIOS) {
      await MobileAds.instance.initialize();
    }

    if (Platform.isAndroid || Platform.isIOS) {
      final iap = InAppPurchase.instance;
      final ok = await iap.isAvailable();
      if (ok && !_purchaseListenerAttached) {
        _purchaseListenerAttached = true;
        iap.purchaseStream.listen(
          _onPurchaseUpdate,
          onError: (Object e, _) => debugPrint('IAP stream error: $e'),
        );
        unawaited(iap.restorePurchases());
      }
    }

    _initialized = true;
  }

  Future<bool> isPremium() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getBool(_kPremiumKey) ?? false;
  }

  Future<void> _setPremium(bool value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_kPremiumKey, value);
  }

  Future<bool> debugSkipGateEnabled() async {
    if (!kDebugMode) return false;
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getBool(_kDebugSkipGateKey) ?? false;
  }

  Future<void> setDebugSkipGate(bool value) async {
    if (!kDebugMode) return;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_kDebugSkipGateKey, value);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    final iap = InAppPurchase.instance;
    for (final p in purchases) {
      if (!MonetizationConfig.premiumProductIds.contains(p.productID)) {
        if (p.pendingCompletePurchase) {
          unawaited(iap.completePurchase(p));
        }
        continue;
      }

      final status = p.status;
      if (status == PurchaseStatus.purchased ||
          status == PurchaseStatus.restored) {
        unawaited(_setPremium(true));
        final c = _pendingPurchaseCompleter;
        if (c != null && !c.isCompleted) {
          c.complete(true);
        }
      } else if (status == PurchaseStatus.error ||
          status == PurchaseStatus.canceled) {
        final c = _pendingPurchaseCompleter;
        if (c != null && !c.isCompleted) {
          c.complete(false);
        }
      }

      if (p.pendingCompletePurchase) {
        unawaited(iap.completePurchase(p));
      }
    }
  }

  /// Shows UI to subscribe or watch a rewarded ad. Returns true if export may proceed.
  Future<bool> requestExportPermission(
    BuildContext context, {
    required bool bulk,
  }) async {
    await ensureInitialized();

    if (await isPremium()) return true;
    if (kDebugMode && await debugSkipGateEnabled()) return true;
    if (!context.mounted) return false;

    final allowed = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _ExportGateSheet(bulk: bulk),
        ) ??
        false;
    return allowed;
  }

  Future<void> restorePurchases() async {
    await ensureInitialized();
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final iap = InAppPurchase.instance;
    if (await iap.isAvailable()) {
      await iap.restorePurchases();
    }
  }

  Future<String?> buyPremiumSubscription() async {
    await ensureInitialized();
    if (!Platform.isAndroid && !Platform.isIOS) {
      return 'In-app purchases are only available on Android and iOS.';
    }
    final iap = InAppPurchase.instance;
    if (!await iap.isAvailable()) {
      return 'Billing is not available on this device.';
    }

    final response = await iap.queryProductDetails(
      {MonetizationConfig.premiumProductId},
    );

    if (response.productDetails.isEmpty) {
      return 'Product "${MonetizationConfig.premiumProductId}" is not configured '
          'in the store yet. Use "Watch ad" to export, or add the product in '
          'Play Console.';
    }

    final product = response.productDetails.first;
    _pendingPurchaseCompleter = Completer<bool>();

    try {
      await iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      _pendingPurchaseCompleter = null;
      return 'Purchase could not start: $e';
    }

    final completer = _pendingPurchaseCompleter;
    if (completer == null) {
      return 'Purchase could not start.';
    }

    final result = await completer.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () => false,
    );

    if (result) return null;
    return 'Purchase did not complete. Try again or use Restore purchases.';
  }

  Future<String?> loadAndShowRewardedAd(VoidCallback onReward) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return 'Ads are only supported on mobile.';
    }
    await ensureInitialized();

    final completer = Completer<String?>();

    final adUnit = Platform.isIOS
        ? MonetizationConfig.iosRewardedAdUnitId
        : MonetizationConfig.androidRewardedAdUnitId;

    await RewardedAd.load(
      adUnitId: adUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          var rewarded = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!rewarded && !completer.isCompleted) {
                completer.complete('Ad closed before reward.');
              }
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete('Could not show ad: $err');
              }
            },
          );
          ad.show(
            onUserEarnedReward: (AdWithoutView reward, RewardItem item) {
              rewarded = true;
              onReward();
              if (!completer.isCompleted) completer.complete(null);
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (!completer.isCompleted) {
            completer.complete('Ad failed to load: ${error.message}');
          }
        },
      ),
    );

    return completer.future;
  }
}

class _ExportGateSheet extends StatefulWidget {
  const _ExportGateSheet({required this.bulk});
  final bool bulk;

  @override
  State<_ExportGateSheet> createState() => _ExportGateSheetState();
}

class _ExportGateSheetState extends State<_ExportGateSheet> {
  bool _busy = false;
  String? _message;

  Future<void> _subscribe() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final err = await MonetizationService.instance.buyPremiumSubscription();
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null && await MonetizationService.instance.isPremium()) {
      if (mounted) Navigator.of(context).pop(true);
    } else if (err != null) {
      setState(() => _message = err);
    }
  }

  Future<void> _watchAd() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final err = await MonetizationService.instance.loadAndShowRewardedAd(() {});
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() => _message = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mark-it Plus',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.bulk
                ? 'Bulk export requires an active subscription, or watch one ad to run this batch.'
                : 'Subscribe for unlimited exports, or watch a short ad to save this image.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _subscribe,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Subscribe'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _busy ? null : _watchAd,
            child: const Text('Watch ad to export'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
