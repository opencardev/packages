#!/usr/bin/env python3
from pathlib import Path
import glob

for path in glob.glob('.github/workflows/*.yml'):
    p = Path(path)
    text = p.read_text()
    lines = text.splitlines()
    changed = False
    i = 0
    while i < len(lines):
        if lines[i].strip() == 'steps:':
            indent = len(lines[i]) - len(lines[i].lstrip(' '))
            j = i + 1
            while j < len(lines):
                if lines[j].strip() == '':
                    j += 1
                    continue
                curr_indent = len(lines[j]) - len(lines[j].lstrip(' '))
                stripped = lines[j].lstrip(' ')
                if curr_indent == indent and stripped.startswith('- '):
                    lines[j] = ' ' * (indent + 2) + stripped
                    changed = True
                    j += 1
                    continue
                if curr_indent <= indent:
                    break
                j += 1
        i += 1
    if changed:
        p.write_text('\n'.join(lines) + '\n')
        print('Fixed steps indentation in', path)
