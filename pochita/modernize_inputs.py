import glob
import re

old_input_class = r'w-full px-4 py-3.5 rounded-xl text-sm.*?outline-none border border-\[var\(--pochita-border\)\] bg-\[var\(--pochita-card\)\].*?transition-colors'
new_input_class = 'w-full px-5 py-4 rounded-2xl text-[15px] font-medium text-[var(--pochita-text)] placeholder-gray-400 outline-none bg-[#F2F4F6] focus:bg-white focus:ring-2 focus:ring-[var(--pochita-orange)] focus:border-transparent transition-all'

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    new_content = re.sub(old_input_class, new_input_class, content)
    
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print("Updated inputs in " + filepath)

for f in glob.glob('/Users/minjooncho/SandBox/pochita/src/**/*.tsx', recursive=True):
    process_file(f)
