import os
import glob

def replace_in_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 0xFFE05A47 (Action) -> 0xFF4693D4 (Bleu)
    content = content.replace('0xFFE05A47', '0xFF4693D4')
    # 0xFFFAF7F2 (Sand bg) -> 0xFFFFFFFF (Blanc)
    content = content.replace('0xFFFAF7F2', '0xFFFFFFFF')
    # 0xFFFED7AA (Light orange selected) -> 0xFFE1F0FA (Light blue)
    content = content.replace('0xFFFED7AA', '0xFFE1F0FA')
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, dirs, files in os.walk('d:/neurocare-track-mobile/lib'):
    for file in files:
        if file.endswith('.dart'):
            replace_in_file(os.path.join(root, file))

print("Colors updated successfully.")
