"""Questions from Moodle "Attempt review" pages (curs.upb.ro), saved as PDF and turned into text.

Reads the question, its options and the line "The correct answer(s) is/are:" (or the
Romanian "Răspunsul corect este:" / "Răspunsurile corecte sunt:"), matches the answer
text against the options (several, in any order, for "select one or more") and keeps
the test's name from the page header. True/False questions are kept as such.

    python3 -I tool/acs/moodle_review.py out.json review1.txt review2.txt ...

The output is the raw material for tool/acs/data/<course>_grile.json: drop questions
that point at a figure or a matrix not in the text, duplicates and page junk, then keep
{q, options, right} or {q, tf}, with source and test (see common.add_grile).
"""
import sys, re, json, unicodedata

DROP = re.compile(r'^(Question \d+|\d+ întrebare|Întrebarea \d+|Correct|Corect|Incorrect|Incorect|Partially correct|Parțial corect|Parţial corect|Not answered|Fără răspuns|Not yet answered|Complete|Mark [\d.,]+ out of [\d.,]+|Marcat [\d.,]+ din [\d.,]+|Marked out of [\d.,]+|Flag question|Select one( or more)?:|Selectați unul( sau mai multe)?:|Selectaţi unul( sau mai multe)?:|Your answer is (in)?correct\.?|Your answer is partially correct\.?|Răspunsul dumneavoastră este (in)?corect\.?|Răspunsul dumneavoastră este parțial corect\.?|You have correctly selected \d+\.?|Ați selectat în mod corect \d+\.?|Question text|Sari la\.\.\.|Jump to\.\.\.)\s*$', re.I)
HDR = re.compile(r'^\d{1,2}[/.]\d{1,2}[/.]\d{2,4},? \d|^https?://|Attempt review|Revizuirea încercării|^Dashboard /|^Started on|^State |^Completed on|^Time taken|^Grade |^Marks |^Feedback|^Finish review|^◄|►\s*$|^\d+ din \d+$|^Început|^Stare |^Finalizat|^Timp |^Notă |^Calificativ')
OPT = re.compile(r'^([a-hA-H])[.)]\s+(.*)$')
MARK = re.compile(r"^(The correct answers? (?:is|are)|Răspunsul corect este|Răspunsurile corecte sunt)\s*:?\s*(.*)$")

def fix(s):
    return s.replace('ṭ', 'ț').replace('Ṭ', 'Ț').replace('ţ', 'ț').replace('Ţ', 'Ț').replace('ş', 'ș').replace('Ş', 'Ș').replace(' ', ' ')

def key(s):
    s = unicodedata.normalize('NFKD', s.lower())
    s = ''.join(c for c in s if not unicodedata.combining(c))
    return re.sub(r'[^a-z0-9]+', '', s)

TITLE = re.compile(r'^\d{1,2}[/.]\d{1,2}[/.](\d{2,4}),?(?: [\d:]+(?:\s*[AP]M)?)?\s+(.*?):\s*(Attempt review|Revizuirea încercării)')
def clean(lines):
    out = []
    title = ''
    for l in lines:
        l = fix(l).strip()
        t = TITLE.match(l)
        if t:
            y = t.group(1); y = y if len(y) == 4 else '20' + y
            title = f'{t.group(2).strip()}|{y}'
        if not l or DROP.match(l) or HDR.search(l):
            continue
        out.append((l, title))
    return out

def parse_set(ka, ok, used=()):
    """ka as a sequence of distinct options (any order): (indices, complete) or None."""
    if ka == '':
        return (list(used), True)
    best = None
    for i, k in enumerate(ok):
        if i in used or not k:
            continue
        if ka.startswith(k):
            r = parse_set(ka[len(k):], ok, used + (i,))
            if r and r[1]:
                return r
            best = best or r
        elif k.startswith(ka):
            best = best or (list(used) + [i], False)
    return best

def parse(text):
    pairs = clean(text.split('\n'))
    lines = [a for a, _ in pairs]
    titles = [b for _, b in pairs]
    idx = [k for k, l in enumerate(lines) if MARK.match(l)]
    qs = []
    prev_end = 0
    for m in idx:
        body = lines[prev_end:m]
        multi = bool(re.match(r'^(The correct answers are|Răspunsurile corecte)', lines[m]))
        after = MARK.match(lines[m]).group(2)
        q, opts = [], []
        for l in body:
            mo = OPT.match(l)
            if mo and ((not opts and mo.group(1).lower() == 'a') or (opts and ord(mo.group(1).lower()) == ord(opts[-1][0]) + 1)):
                if not opts and q == []:
                    pass
                opts.append([mo.group(1).lower(), mo.group(2)])
            elif opts:
                opts[-1][1] += ' ' + l
            else:
                q.append(l)
        tf = False
        while q and q[-1] in ('True', 'False', 'Adevărat', 'Fals'):
            q.pop(); tf = True
        nxt = lines[m + 1:]
        used = 0
        ans = after
        right = None
        if tf or re.match(r"^['„\"”]?(True|False|Adevărat|Fals)['”\"]?\.?$", after):
            ans = after.strip("'.„”\" "); tf = True
            right = ans in ('True', 'Adevărat')
        elif opts:
            ok = [key(o[1]) for o in opts]
            def state(a):
                return parse_set(key(a), ok)
            st = state(ans)
            while used < len(nxt) and not (st and st[1] and (multi or len(st[0]) == 1) and not (state(ans + ' ' + nxt[used]) or (None, False))[1:] == (True,) and False):
                cand = (ans + ' ' + nxt[used]).strip()
                cs = state(cand)
                if cs is None:
                    break
                if st and st[1] and not cs[1] and not multi:
                    break
                if st and st[1] and cs and not cs[1]:
                    # may continue into another option of a multi answer
                    pass
                ans, st, used = cand, cs, used + 1
            if st and st[1]:
                right = sorted(st[0])
        prev_end = m + 1 + used
        qs.append({'q': ' '.join(q).strip(), 'options': [o[1].strip() for o in opts], 'answer': ans.strip(), 'tf': tf, 'right': right, 'multi': multi, 'test': titles[m]})
    return qs

out = sys.argv[1]
allq = []
for f in sys.argv[2:]:
    for q in parse(open(f).read()):
        q['file'] = f.split('/')[-1]
        allq.append(q)
good, seen = [], set()
for q in allq:
    if q['right'] is None or not q['q'] or (not q['tf'] and len(q['options']) < 2):
        continue
    k = key(q['q'])[-160:] + '|' + key(' '.join(q['options']))[:80]
    if k in seen:
        continue
    seen.add(k)
    good.append(q)
json.dump(good, open(out, 'w'), ensure_ascii=False, indent=1)
print(f"{len(allq)} parsed, {len(good)} usable, {sum(1 for q in good if q['tf'])} true/false, {sum(1 for q in good if not q['tf'] and len(q['right'])>1)} multi", file=sys.stderr)
