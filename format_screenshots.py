import glob
from PIL import Image, ImageDraw

files = glob.glob('C:/Users/adebo/.gemini/antigravity/brain/66275baf-6f5f-4ecf-9820-36afd4503345/.user_uploaded/media_17907369920*.jpg')

# Background color for the padding (Light blue from the app theme)
bg_color = (240, 247, 252) # hex #F0F7FC

count = 1
for file in files:
    img = Image.open(file)
    
    # 1. Crop status bar (top 40px) and nav bar (bottom 48px)
    # Original size: 640x1024
    cropped = img.crop((0, 40, 640, 1024 - 48))
    
    # 2. Calculate scaling to fit width 1080
    new_width = 1080
    new_height = int(cropped.height * (1080 / 640))
    resized = cropped.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    # 3. Create 1080x1920 canvas (9:16 ratio required by Google)
    canvas = Image.new('RGB', (1080, 1920), bg_color)
    
    # 4. Paste the resized screenshot in the center vertically
    y_offset = (1920 - new_height) // 2
    canvas.paste(resized, (0, y_offset))
    
    # Save
    out_name = f'd:/neurocare-track-mobile/playstore_screenshot_{count}.png'
    canvas.save(out_name, 'PNG')
    print(f'Saved {out_name}')
    count += 1
