from PIL import Image, ImageDraw, ImageFont
import os

def create_icon():
    # Colors
    bg_color = "#1A1A1D"  # Deep Matte Charcoal
    accent_color = "#FF8A73"  # Salmon Orange
    
    # Size
    size = 1024
    img = Image.new('RGB', (size, size), color=bg_color)
    draw = ImageDraw.Draw(img)
    
    # Draw a geometric journal/book icon
    # Center coordinates
    cx, cy = size // 2, size // 2
    
    # Book dimensions
    w = 500
    h = 600
    
    # Draw book cover (rounded rect simulation)
    x1 = cx - w // 2
    y1 = cy - h // 2
    x2 = cx + w // 2
    y2 = cy + h // 2
    
    # Main book shape
    draw.rounded_rectangle([x1, y1, x2, y2], radius=60, fill=accent_color)
    
    # Spine detail (darker strip on left)
    spine_width = 60
    draw.rounded_rectangle([x1, y1, x1 + spine_width, y2], radius=60, fill="#E67A64") # Slightly darker orange
    
    # Page lines (minimalist)
    line_color = "#1A1A1D"
    line_x1 = x1 + spine_width + 40
    line_x2 = x2 - 40
    
    start_y = y1 + 100
    gap = 80
    
    for i in range(4):
        y = start_y + i * gap
        draw.line([line_x1, y, line_x2, y], fill=line_color, width=20)
        
    # Save
    img.save('app_icon.png')
    print("Icon created: app_icon.png")

if __name__ == "__main__":
    create_icon()
