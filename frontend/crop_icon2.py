from PIL import Image

def get_crop_box(image_path):
    img = Image.open(image_path).convert("RGB")
    width, height = img.size
    
    threshold = 245
    
    min_x, min_y = width, height
    max_x, max_y = 0, 0
    
    pixels = img.load()
    
    for y in range(height):
        for x in range(width):
            r, g, b = pixels[x, y]
            if r < threshold and g < threshold and b < threshold:
                if x < min_x: min_x = x
                if y < min_y: min_y = y
                if x > max_x: max_x = x
                if y > max_y: max_y = y
                
    if min_x < max_x and min_y < max_y:
        print(f"Found box: {min_x}, {min_y}, {max_x}, {max_y}")
        cropped = img.crop((min_x, min_y, max_x, max_y))
        cropped.save("assets/app_icon_cropped.jpg")
    else:
        print("Could not find box")

get_crop_box("assets/app_icon.jpg")
