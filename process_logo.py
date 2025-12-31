from PIL import Image

def process_logo():
    input_path = "docs/images/hg-logo.png"
    output_path = "docs/images/hg-logo-cropped.png"

    img = Image.open(input_path).convert("RGBA")
    
    # 1. Get the bounding box of non-zero alpha content
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        print(f"Cropped to content: {img.size}")
    else:
        print("Image is fully transparent!")
        return

    # 2. Create a square background
    w, h = img.size
    max_dim = max(w, h)
    
    # Create white background square
    new_img = Image.new("RGBA", (max_dim, max_dim), (255, 255, 255, 255))
    
    # Center the logo
    offset_x = (max_dim - w) // 2
    offset_y = (max_dim - h) // 2
    
    # Paste the logo (using alpha channel as mask)
    new_img.paste(img, (offset_x, offset_y), img)
    
    # Remove alpha channel entirely since iOS icons prefer no transparency? 
    # Actually, saving as PNG is fine, but iOS ignores alpha. 
    # Let's flatten it to RGB to be sure it's opaque white background.
    final_img = new_img.convert("RGB")
    
    final_img.save(output_path)
    print(f"Saved square logo to {output_path}")

if __name__ == "__main__":
    process_logo()
