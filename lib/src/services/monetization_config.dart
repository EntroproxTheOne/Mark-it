/// Replace with your production AdMob App ID in AndroidManifest and these unit IDs
/// in the AdMob console before release.
abstract final class MonetizationConfig {
  /// Google test application ID (Android). Replace for production.
  static const String androidAdMobAppId =
      'ca-app-pub-3940256099942544~3347511713';

  /// Google test rewarded ad units.
  static const String androidRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String iosRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  /// Play Console subscription or in-app product ID (must match exactly).
  static const String premiumProductId = 'mark_it_plus';

  static const Set<String> premiumProductIds = {premiumProductId};
}
