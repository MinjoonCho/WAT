import glob
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # We don't touch timer/page.tsx
    if 'timer/page.tsx' in filepath:
        return

    new_content = content
    # Replace overly bold fonts
    new_content = new_content.replace('font-black', 'font-bold')
    new_content = new_content.replace('linear-gradient(135deg,#FF6B00,#CC4400)', 'var(--pochita-orange)')
    new_content = new_content.replace('rgba(255,107,0,0.4)', 'none')
    new_content = new_content.replace('rgba(255,107,0,0.5)', 'none')
    
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print("Cleaned " + filepath)

for f in glob.glob('/Users/minjooncho/SandBox/pochita/src/**/*.tsx', recursive=True):
    process_file(f)
