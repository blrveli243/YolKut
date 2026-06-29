from PIL import Image
from PIL import ImageChops

def crop_white_borders(image_path, output_path):
    img = Image.open(image_path).convert("RGB")
    # The background is white (255, 255, 255)
    bg = Image.new("RGB", img.size, (255, 255, 255))
    diff = ImageChops.difference(img, bg)
    bbox = diff.getbbox()
    if bbox:
        # bbox is (left, upper, right, lower)
        cropped = img.crop(bbox)
        cropped.save(output_path)
        print(f"Cropped from {img.size} to {cropped.size}")
    else:
        print("Could not find bounding box")

crop_white_borders("assets/app_icon.jpg", "assets/app_icon_cropped.jpg")
