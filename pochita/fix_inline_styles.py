import re
import glob

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Replace inline hex styles manually
    new_content = content
    new_content = new_content.replace('"#1A1A1A"', '"var(--pochita-card)"')
    new_content = new_content.replace('"#222"', '"var(--pochita-border)"')
    new_content = new_content.replace('color: "#888"', 'color: "var(--pochita-text-secondary)"')
    new_content = new_content.replace('"#2A2A2A"', '"var(--pochita-border)"')
    new_content = new_content.replace('"#1F1F1F"', '"var(--pochita-border)"')
    new_content = new_content.replace('"#111"', '"var(--pochita-card)"')
    new_content = new_content.replace('"#22C55E"', '"#4ade80"') # bright green
    
    # Also fix buttons text
    new_content = re.sub(r'text-\[var\(--pochita-text\)\](.*?linear-gradient)', r'text-white\1', new_content, flags=re.DOTALL)
    
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print("Updated " + filepath)

for f in glob.glob('/Users/minjooncho/SandBox/pochita/src/**/*.tsx', recursive=True):
    if 'timer/page.tsx' not in f:
        process_file(f)
