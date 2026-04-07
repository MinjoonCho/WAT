import sys
from PIL import Image

def remove_bg(img_path, out_path):
    img = Image.open(img_path).convert("RGBA")
    data = img.getdata()
    bg_color = img.getpixel((0,0))
    new_data = []
    for item in data:
        if abs(item[0]-bg_color[0])<20 and abs(item[1]-bg_color[1])<20 and abs(item[2]-bg_color[2])<20:
            new_data.append((255,255,255,0))
        else:
            new_data.append(item)
    img.putdata(new_data)
    bbox = img.getbbox()
    if bbox: img = img.crop(bbox)
    img.save(out_path, "PNG")

remove_bg("/Users/minjooncho/SandBox/열품타/KakaoTalk_Photo_2026-04-07-16-28-14 006.png", "/Users/minjooncho/SandBox/pochita/public/pochita-logo.png")
