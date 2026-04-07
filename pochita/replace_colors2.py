import os
import glob

replacements = {
    'bg-[#111]': 'bg-[var(--pochita-card)]',
    'border-[#222]': 'border-[var(--pochita-border)]',
    'bg-[#222]': 'bg-[var(--pochita-bg)]',
    'bg-[#333]': 'bg-[var(--pochita-border)]',
}

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    new_content = content
    for old, new in replacements.items():
        new_content = new_content.replace(old, new)
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print("Updated " + filepath)

for f in glob.glob('/Users/minjooncho/SandBox/pochita/src/**/*.tsx', recursive=True):
    # Only skip timer since it contains intentional dark mode colors
    if 'timer/page.tsx' not in f:
        process_file(f)
