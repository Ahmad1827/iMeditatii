#!/usr/bin/env python3
"""The problem details live in assets/data/details/, one file per subject and grade
(split further when a grade passes LIMIT bytes), listed in index.json.

  python3 tool/details.py merge OUT.json   # every part -> one file, to edit
  python3 tool/details.py split IN.json    # one file -> the parts (rewrites the folder)
"""
import json, os, sys, unicodedata

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'data', 'details')
LIMIT = 40_000_000  # GitHub warns at 50 MB and refuses 100 MB


def slug(s):
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode().lower()
    return ''.join(c if c.isalnum() else '_' for c in s)


def dump(o):
    return json.dumps(o, ensure_ascii=False, indent=2)


def merge():
    index = json.load(open(os.path.join(ROOT, 'index.json'), encoding='utf-8'))
    out = {}
    for subject, grades in index.items():
        for grade, files in grades.items():
            g = out.setdefault(subject, {}).setdefault(grade, {})
            for f in files:
                g.update(json.load(open(os.path.join(ROOT, f), encoding='utf-8')))
    return out


def split(data):
    os.makedirs(ROOT, exist_ok=True)
    for f in os.listdir(ROOT):
        if f.endswith('.json'):
            os.remove(os.path.join(ROOT, f))
    index = {}
    for subject, grades in data.items():
        for grade, items in grades.items():
            base = f'{slug(subject)}_{slug(grade)}'
            chunks, cur, size = [], {}, 0
            for k, v in items.items():
                n = len(dump({k: v}).encode())
                if cur and size + n > LIMIT:
                    chunks.append(cur); cur, size = {}, 0
                cur[k] = v; size += n
            chunks.append(cur)
            names = []
            for i, c in enumerate(chunks):
                name = f'{base}.json' if len(chunks) == 1 else f'{base}_{i + 1}.json'
                with open(os.path.join(ROOT, name), 'w', encoding='utf-8') as fh:
                    fh.write(dump(c))
                names.append(name)
            index.setdefault(subject, {})[grade] = names
    with open(os.path.join(ROOT, 'index.json'), 'w', encoding='utf-8') as fh:
        fh.write(dump(index))
    return index


if __name__ == '__main__':
    cmd, path = sys.argv[1], sys.argv[2]
    if cmd == 'merge':
        with open(path, 'w', encoding='utf-8') as fh:
            fh.write(dump(merge()))
    elif cmd == 'split':
        print(dump(split(json.load(open(path, encoding='utf-8')))))
