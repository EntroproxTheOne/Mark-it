"""
Decode compiled Android Binary XML (AXML) VectorDrawable files from Beauty Frame APK
and convert them to SVG files for use in Flutter.
"""
import os
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

try:
    from androguard.core.axml import AXMLPrinter
except ImportError:
    print("androguard not found, install with: pip install androguard")
    sys.exit(1)

TEMP = os.environ.get("TEMP", "/tmp")
APK_EXTRACT = os.path.join(TEMP, "beauty_frame_apk")
DRAWABLE_DIR = os.path.join(APK_EXTRACT, "res", "drawable")
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "logos", "svg")

ANDROID_NS = "http://schemas.android.com/apk/res/android"
AAPT_NS = "http://schemas.android.com/aapt"

BRANDS = {
    "ic_apple_logo_default": "apple",
    "ic_canon_logo_default": "canon",
    "ic_dji_logo_default": "dji",
    "ic_fujifilm_logo_default": "fujifilm",
    "ic_google_logo_default": "google",
    "ic_hasselblad_logo_default": "hasselblad",
    "ic_huawei_logo_default": "huawei",
    "ic_iqoo_logo_default": "iqoo",
    "ic_leica_camera_logo_default": "leica",
    "ic_lumix_logo_default": "lumix",
    "ic_motorola_logo_default": "motorola",
    "ic_nikon_logo_default": "nikon",
    "ic_nubia_logo_default": "nubia",
    "ic_olympus_corporation_logo_default": "olympus",
    "ic_oneplus_logo_default": "oneplus",
    "ic_oppo_logo_default": "oppo",
    "ic_panasonic_logo_default": "panasonic",
    "ic_pentax_logo_default": "pentax",
    "ic_realme_logo_default": "realme",
    "ic_ricoh_logo_default": "ricoh",
    "ic_samsung_logo_default": "samsung",
    "ic_sigma_logo_default": "sigma",
    "ic_sony_logo_default": "sony_camera",
    "ic_vivo_logo_default": "vivo",
    "ic_xiaomi_logo_default": "xiaomi",
    "ic_zeiss_logo_default": "zeiss",
    "ic_logo_honor_default": "honor",
    "ic_hasselblad_h_logo_default": "hasselblad_h",
}

# Also get white variants for logos that look better in white
WHITE_BRANDS = {
    "ic_apple_logo_white": "apple_white",
    "ic_canon_logo_white": "canon_white",
    "ic_samsung_logo_white": "samsung_white",
    "ic_sony_logo_white": "sony_camera_white",
    "ic_xiaomi_logo_white": "xiaomi_white",
    "ic_nikon_logo_blue": "nikon_blue",
}


def decode_axml(filepath):
    """Decode an AXML binary file to XML string."""
    with open(filepath, "rb") as f:
        data = f.read()
    try:
        ap = AXMLPrinter(data)
        return ap.get_xml()
    except Exception as e:
        print(f"  Failed to decode {filepath}: {e}")
        return None


def android_color_to_svg(color_str):
    """Convert Android color (#AARRGGBB or #RRGGBB) to SVG fill + opacity."""
    if not color_str or not color_str.startswith("#"):
        return "#000000", "1"
    color_str = color_str.lstrip("#")
    if len(color_str) == 8:
        alpha = int(color_str[:2], 16) / 255.0
        rgb = "#" + color_str[2:]
        return rgb, f"{alpha:.2f}"
    return "#" + color_str, "1"


def vector_drawable_to_svg(xml_str):
    """Convert Android VectorDrawable XML to SVG."""
    if isinstance(xml_str, bytes):
        xml_str = xml_str.decode("utf-8", errors="replace")

    xml_str = re.sub(r'xmlns:android="[^"]*"', '', xml_str)
    xml_str = re.sub(r'xmlns:aapt="[^"]*"', '', xml_str)
    xml_str = re.sub(r'android:(\w+)', r'\1', xml_str)

    try:
        root = ET.fromstring(xml_str)
    except ET.ParseError as e:
        print(f"  XML parse error: {e}")
        return None

    vw = root.get("viewportWidth", "24")
    vh = root.get("viewportHeight", "24")
    w = root.get("width", vw)
    h = root.get("height", vh)

    w = re.sub(r'[^\d.]', '', str(w))
    h = re.sub(r'[^\d.]', '', str(h))

    svg_parts = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {vw} {vh}" width="{w}" height="{h}">']

    def process_group(elem, indent=1):
        pad = "  " * indent
        for child in elem:
            tag = child.tag.split("}")[-1] if "}" in child.tag else child.tag
            if tag == "path":
                path_data = child.get("pathData", "")
                fill_color = child.get("fillColor", "#000000")
                fill_alpha = child.get("fillAlpha", "1")
                stroke_color = child.get("strokeColor")
                stroke_width = child.get("strokeWidth")

                if not path_data:
                    continue

                rgb, alpha = android_color_to_svg(fill_color)
                try:
                    total_alpha = float(alpha) * float(fill_alpha)
                except (ValueError, TypeError):
                    total_alpha = 1.0

                attrs = f'd="{path_data}" fill="{rgb}"'
                if total_alpha < 0.99:
                    attrs += f' fill-opacity="{total_alpha:.2f}"'
                if stroke_color and stroke_color != "#0":
                    s_rgb, s_alpha = android_color_to_svg(stroke_color)
                    attrs += f' stroke="{s_rgb}"'
                    if stroke_width:
                        attrs += f' stroke-width="{stroke_width}"'

                svg_parts.append(f"{pad}<path {attrs}/>")

            elif tag == "group":
                tx = child.get("translateX", "0")
                ty = child.get("translateY", "0")
                sx = child.get("scaleX", "1")
                sy = child.get("scaleY", "1")
                rotation = child.get("rotation", "0")
                px = child.get("pivotX", "0")
                py = child.get("pivotY", "0")

                transforms = []
                if float(tx) != 0 or float(ty) != 0:
                    transforms.append(f"translate({tx},{ty})")
                if float(rotation) != 0:
                    transforms.append(f"rotate({rotation},{px},{py})")
                if float(sx) != 1 or float(sy) != 1:
                    transforms.append(f"scale({sx},{sy})")

                if transforms:
                    svg_parts.append(f'{pad}<g transform="{" ".join(transforms)}">')
                else:
                    svg_parts.append(f"{pad}<g>")
                process_group(child, indent + 1)
                svg_parts.append(f"{pad}</g>")

    process_group(root)
    svg_parts.append("</svg>")
    return "\n".join(svg_parts)


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    all_brands = {**BRANDS}
    
    success = 0
    failed = 0

    for xml_name, svg_name in all_brands.items():
        xml_path = os.path.join(DRAWABLE_DIR, f"{xml_name}.xml")
        svg_path = os.path.join(OUTPUT_DIR, f"{svg_name}.svg")

        if not os.path.exists(xml_path):
            print(f"  SKIP {xml_name}.xml (not found)")
            failed += 1
            continue

        print(f"  Converting {xml_name}.xml -> {svg_name}.svg ... ", end="")
        xml_str = decode_axml(xml_path)
        if xml_str is None:
            failed += 1
            continue

        svg_str = vector_drawable_to_svg(xml_str)
        if svg_str is None:
            failed += 1
            continue

        with open(svg_path, "w", encoding="utf-8") as f:
            f.write(svg_str)

        size_kb = os.path.getsize(svg_path) / 1024
        print(f"OK ({size_kb:.1f} KB)")
        success += 1

    print(f"\nDone: {success} converted, {failed} failed")


if __name__ == "__main__":
    main()
