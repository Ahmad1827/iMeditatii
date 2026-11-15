"""LFA multiple-choice questions from Moodle attempt reviews whose formulas came out as TeX.

Reads the review PDFs already turned into text (pymupdf), keeps the questions whose text,
options and answer line are whole (formulas as \\( \\), no MathJax debris), matches the answer
to an option and drops duplicates. Usage:

    python3 -I tool/acs/moodle_tex.py <folder of .txt> out.json

The result was curated into tool/acs/data/lfa_grile.json (single-answer items, duplicates and
garbled ones out, \\( \\) written as $ $). Blocks it drops (about 350) have their formulas
scattered after the options and need a person (or the PDF page images) to rebuild.
"""
import re, glob, json, sys, unicodedata
txt = sys.argv[1]
out = sys.argv[2]
files = sorted(glob.glob(txt + '/*Attempt*')) + sorted(glob.glob(txt + '/driveCA__Examen__Grile__*.txt')) + [txt + '/driveCA__Teste__Grile__LFA_Teste_Grile.pdf.txt', txt + '/driveCA__Grile-TURBO__LFA_All_Grile_TURBO.pdf.txt']
HDR = re.compile(r'^(\d{1,2}[/.]\d{1,2}[/.]\d{2,4}|https?://|\d+ of \d+$|\d+/\d+$|Dashboard|.*Attempt review|Question \d+$|Correct$|Incorrect$|Partially correct$|Not answered$|Mark |Marked out|Started on|State$|Finished$|Completed on|Time taken|Marks$|Grade$|\d+ mins|\w+day, \d+|[\d.]+/[\d.]+$|[\d.]+ out of|/ Seria|Comment:|Flag question|Grila|Test grila)')
def key(s):
    s = unicodedata.normalize('NFKD', s.lower()); s = ''.join(c for c in s if not unicodedata.combining(c))
    return re.sub(r'\s+|\\[,;! ]', '', s)
items, seen, bad = [], set(), 0
for f in files:
    raw = open(f).read()
    for b in re.split(r'Atentie!! Nu se poate reveni la aceasta intrebare!\n', raw)[1:]:
        if '\\(' not in b and '\\[' not in b:
            continue
        lines = [re.sub('[\ue000-\uf8ff]', '', l).rstrip() for l in b.split('\n')]
        # cut at the answer line
        try:
            ai = next(i for i, l in enumerate(lines) if l.startswith('The correct answer'))
        except StopIteration:
            bad += 1; continue
        ans = lines[ai].split(':', 1)[1].strip()
        # the answer may go on to the next lines (until an empty or header line)
        j = ai + 1
        while j < len(lines) and lines[j].strip() and not HDR.match(lines[j].strip()) and not lines[j].startswith('Atentie'):
            ans += ' ' + lines[j].strip(); j += 1
        body = [l for l in lines[:ai] if not HDR.match(l.strip())]
        try:
            si = next(i for i, l in enumerate(body) if l.startswith('Select one'))
        except StopIteration:
            bad += 1; continue
        qlines = [l for l in body[:si] if l.strip()]
        if any(l.startswith(' ') for l in qlines[1:]) or any(re.search(r'(^|\s)(Fie|si|cu|pentru)\s*$', l) for l in qlines[:-1] if '\\(' not in l):
            bad += 1; continue
        if re.match(r'^(Alegeti|Stabiliti|Care sunt) valo', qlines[0]) and len(qlines) > 1:
            parts = [qlines[0].strip()] + ['- ' + l.strip().lstrip('•').strip() for l in qlines[1:]]
            q = '\n'.join(parts)
        else:
            q = ' '.join(l.strip() for l in qlines)
        q = re.sub(r'\s*•\s*', '\n- ', q)
        rest = [l for l in body[si + 1:]]
        opts, cur = [], None
        ok = True
        for l in rest:
            m = re.match(r'^([a-h])\.\s*(.*)$', l)
            if m and ord(m[1]) == ord('a') + len(opts) + (0 if cur is None else 1):
                if cur is not None: opts.append(cur)
                cur = m[2].strip()
                continue
            if cur is None:
                if l.strip(): ok = False
                continue
            if not l.strip():
                continue
            if cur == '':
                cur = l.strip()
            else:
                # a second line after the option: stray text (displaced math) unless the option is long
                cur += '\n' + l.strip()
        if cur is not None: opts.append(cur)
        if not ok or len(opts) < 2 or any(not o or '\n' in o or o.startswith(' ') for o in opts):
            bad += 1; continue
        if re.search(r'figur|imagin|diagram', q, re.I):
            bad += 1; continue
        # match the answer
        ka = key(ans)
        right = [i for i, o in enumerate(opts) if key(o) and key(o) == ka]
        if not right:
            right = [i for i, o in enumerate(opts) if key(o) and key(o) in ka]
            if len(right) < 2 and not (len(right) == 1 and key(opts[right[0]]) == ka):
                # one option inside the answer text: only fine if the rest of the answer is not another option
                if len(right) != 1 or len(ka) > len(key(opts[right[0]])) + 3:
                    bad += 1; continue
        k = key(q) + '|' + '|'.join(sorted(key(opts[r]) for r in right))
        if k in seen:
            continue
        seen.add(k)
        fn = f.split('/')[-1]
        src = 'Test grilă LFA (Moodle)' if 'Teste' in fn else ('Grile LFA (Moodle, culegere)' if 'TURBO' in fn else 'Grilă de examen LFA (Moodle)')
        items.append({'q': q, 'options': opts, 'right': right, 'source': src})
print(len(items), 'kept', bad, 'dropped', file=sys.stderr)
json.dump(items, open(out, 'w'), ensure_ascii=False, indent=1)
