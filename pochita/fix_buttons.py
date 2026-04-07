import glob

def process_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    changed = False
    for i in range(len(lines)):
        # If line has linear-gradient or var(--pochita-orange-dark) and previous line has text-[var(--pochita-text)]
        if "linear-gradient(135deg" in lines[i] or "background: `linear-gradient" in lines[i] or "linear-gradient(135deg,#FF6B00" in lines[i]:
            if i > 0 and "text-[var(--pochita-text)]" in lines[i-1]:
                lines[i-1] = lines[i-1].replace("text-[var(--pochita-text)]", "text-white")
                changed = True
            elif "text-[var(--pochita-text)]" in lines[i]:
                lines[i] = lines[i].replace("text-[var(--pochita-text)]", "text-white")
                changed = True

    if changed:
        with open(filepath, 'w') as f:
            f.writelines(lines)
        print("Fixed buttons in " + filepath)

for f in glob.glob('/Users/minjooncho/SandBox/pochita/src/**/*.tsx', recursive=True):
    process_file(f)
