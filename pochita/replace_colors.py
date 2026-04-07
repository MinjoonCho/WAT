import os
import glob

replacements = {
    'bg-[#0A0A0A]': 'bg-[var(--pochita-bg)]',
    'bg-[#111111]': 'bg-[var(--pochita-card)]',
    'bg-[#1A1A1A]': 'bg-[var(--pochita-card)]',
    'bg-[#161616]': 'bg-[var(--pochita-card)]',
    'bg-[#222222]': 'bg-[var(--pochita-border)]',
    'bg-[#2A2A2A]': 'bg-[var(--pochita-border)]',
    'text-white': 'text-[var(--pochita-text)]',
    'text-[#ffffff]': 'text-[var(--pochita-text)]',
    'text-gray-400': 'text-[var(--pochita-text-secondary)]',
    'text-gray-500': 'text-[var(--pochita-text-secondary)]',
    'border-[#333333]': 'border-[var(--pochita-border)]',
    'border-[#2A2A2A]': 'border-[var(--pochita-border)]',
    'border-[#1F1F1F]': 'border-[var(--pochita-border)]',
    'bg-[#FF6B00]': 'bg-[var(--pochita-orange)]',
    'text-[#FF6B00]': 'text-[var(--pochita-orange)]',
    'border-[#FF6B00]': 'border-[var(--pochita-orange)]',
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
    if 'timer/page.tsx' not in f:
        process_file(f)
