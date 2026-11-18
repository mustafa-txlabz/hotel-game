import os
import sys
from PIL import Image

def generate_icons(source_path):
    if not os.path.exists(source_path):
        print(f"Error: Source image not found at {source_path}")
        sys.exit(1)

    img = Image.open(source_path).convert("RGBA")
    print(f"Loaded master icon: {img.size} from {source_path}")

    # Android mipmap targets
    android_res = os.path.abspath("android/app/src/main/res")
    mipmap_sizes = {
        "mipmap-mdpi": (48, 48),
        "mipmap-hdpi": (72, 72),
        "mipmap-xhdpi": (96, 96),
        "mipmap-xxhdpi": (144, 144),
        "mipmap-xxxhdpi": (192, 192),
    }

    for folder, size in mipmap_sizes.items():
        folder_path = os.path.join(android_res, folder)
        os.makedirs(folder_path, exist_ok=True)
        dest_path = os.path.join(folder_path, "ic_launcher.png")
        resized = img.resize(size, Image.Resampling.LANCZOS)
        resized.save(dest_path, "PNG")
        print(f"Generated {folder}/ic_launcher.png ({size[0]}x{size[1]})")

    # Assets folder for Store listings
    assets_icon_dir = os.path.abspath("assets/icon")
    os.makedirs(assets_icon_dir, exist_ok=True)

    # 512x512 Google Play Store Icon
    play_store_path = os.path.join(assets_icon_dir, "app_icon_512.png")
    img.resize((512, 512), Image.Resampling.LANCZOS).save(play_store_path, "PNG")
    print(f"Generated Play Store icon: {play_store_path} (512x512)")

    # 1024x1024 Master copy
    master_path = os.path.join(assets_icon_dir, "app_icon_1024.png")
    img.resize((1024, 1024), Image.Resampling.LANCZOS).save(master_path, "PNG")
    print(f"Saved master copy: {master_path} (1024x1024)")

    print("All app launcher icons successfully generated!")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python scripts/generate_icons.py <source_image_path>")
        sys.exit(1)
    generate_icons(sys.argv[1])
