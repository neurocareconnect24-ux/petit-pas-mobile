from PIL import Image
import os

# 1. Générer l'icône 512x512 à partir de logo_icon.jpg (qui contient juste le dessin)
print("Génération de l'icône (512x512)...")
icon_src = Image.open('assets/logo_icon.jpg')
# Resize to 512x512
icon_512 = icon_src.resize((512, 512), Image.Resampling.LANCZOS)
icon_512.save('playstore_icon_512.png', 'PNG')

# 2. Générer l'image de présentation 1024x500 à partir de logo.jpg (1024x558)
print("Génération de l'image de présentation (1024x500)...")
feature_src = Image.open('assets/logo.jpg')
# Crop the middle to get 500px height. 558 - 500 = 58. Crop 29px from top and bottom.
left = 0
top = 29
right = 1024
bottom = 529
feature_1024 = feature_src.crop((left, top, right, bottom))
feature_1024.save('playstore_feature_1024x500.png', 'PNG')

print("Fichiers générés avec succès :")
print("- playstore_icon_512.png")
print("- playstore_feature_1024x500.png")
