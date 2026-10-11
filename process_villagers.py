import os
from PIL import Image

artifacts_dir = r"C:\Users\danir\.gemini\antigravity-ide\brain\f8edb84c-166e-4659-b5f9-0e3659471ee6"
output_dir = r"d:\Mobile Apps\Word Puzzul Game\assets\images\village\villagers"

files = [
    ("bunny_villager_fixed_1791281837987.jpg", "bunny.webp")
]

for in_name, out_name in files:
    in_path = os.path.join(artifacts_dir, in_name)
    out_path = os.path.join(output_dir, out_name)
    
    print(f"Processing {in_name}...")
    img = Image.open(in_path).convert("RGBA")
    
    datas = img.getdata()
    newData = []
    # Fuzziness for white background
    for item in datas:
        if item[0] > 240 and item[1] > 240 and item[2] > 240:
            newData.append((255, 255, 255, 0))
        else:
            newData.append(item)
            
    img.putdata(newData)
    
    # Scale down
    img.thumbnail((128, 128), Image.Resampling.LANCZOS)
    
    img.save(out_path, format="WEBP")
    print(f"Saved {out_name}")

print("Done!")
