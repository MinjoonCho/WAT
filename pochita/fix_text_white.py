import re
import glob

def process_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    changed = False
    for i, line in enumerate(lines):
        if 'text-white' in line:
            # If it's not a timer file, and not a button line (e.g. linear-gradient usually follows, or has specific button classes)
            if 'timer/page.tsx' in filepath:
                continue
            
            # The big orange buttons usually have "transition-all active:scale-95" somewhere nearby, or the next line has linear-gradient.
            is_button = "active:scale-95" in line or "linear-gradient" in line
            next_is_gradient = i+1 < len(lines) and "linear-gradient" in lines[i+1]
            next_next_is_gradient = i+2 < len(lines) and "linear-gradient" in lines[i+2]
            
            if not (is_button or next_is_gradient or next_next_is_gradient):
                lines[i] = lines[i].replace('text-white', 'text-[var(--pochita-text)]')
                changed = True

    if changed:
        with open(filepath, 'w') as f:
            f.writelines(lines)
        print("Fixed text-white in " + filepath)

for f in glob.glob('/Users/minjooncho/SandBox/pochita/src/**/*.tsx', recursive=True):
    process_file(f)
