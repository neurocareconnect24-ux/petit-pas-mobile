from PIL import Image
img = Image.open('assets/logo.jpg')
# Crop: (left, upper, right, lower)
# Image is 1024x558. The text is at the bottom, roughly from y=350 downwards.
# Let's crop x: 300 to 724, y: 50 to 350 to get the icon.
cropped = img.crop((300, 50, 724, 350))
# Let's make it square by padding or just ensure it's roughly square. (424x300)
# To make it square, let's take a 424x424 square centered on the icon.
# Let's just crop 300, 0, 724, 424
cropped = img.crop((300, 0, 724, 424))
cropped.save('assets/logo_icon.jpg')
print("Cropped successfully")
