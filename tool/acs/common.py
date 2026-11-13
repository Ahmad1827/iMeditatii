"""Shared helpers for the ACS course files (assets/data/acs/<code>.json).

Each course module builds PROBLEMS with problem(...) and calls write_course().
Run from the repo root:  python3 -I tool/acs/<course>.py
"""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DIFFS = ('ușoară', 'medie', 'grea')


def problem(id, title, chapter, difficulty, statement, kind, spec, hint='', solution='', source=''):
    assert difficulty in DIFFS, (id, difficulty)
    return {
        'id': str(id), 'title': title, 'chapter': chapter, 'difficulty': difficulty,
        'source': source, 'statement': statement.strip(), 'hint': hint.strip(),
        'solution': solution.strip(), 'kind': kind, 'spec': spec,
    }


def write_course(code, chapters, problems):
    ids = [p['id'] for p in problems]
    assert len(ids) == len(set(ids)), 'duplicate ids'
    for p in problems:
        assert p['chapter'] in chapters, (p['id'], p['chapter'])
    # chapter order, then the order written
    problems = sorted(problems, key=lambda p: (chapters.index(p['chapter']), problems.index(p)))
    out = os.path.join(ROOT, 'assets', 'data', 'acs', f'{code}.json')
    text = json.dumps({'code': code, 'chapters': chapters, 'problems': problems}, ensure_ascii=False, indent=1)
    # the app's font (a subset of Iosevka) has no U+2212: a plain minus reads the same
    text = text.replace('\u2212', '-')
    with open(out, 'w', encoding='utf-8') as f:
        f.write(text + '\n')
    print(f'{code}: {len(problems)} probleme -> {os.path.relpath(out, ROOT)}', file=sys.stderr)


def quiz(id, title, chapter, difficulty, statement, right, wrong, hint='', solution='', source=''):
    """A multiple-choice question: [right] and the [wrong] answers, placed in an order fixed by the id."""
    assert right not in wrong and len(set(wrong)) == len(wrong), (id, 'options repeat')
    at = (int(''.join(ch for ch in str(id) if ch.isdigit()) or 0) * 7 + len(title)) % (len(wrong) + 1)
    options = wrong[:at] + [right] + wrong[at:]
    return problem(id, title, chapter, difficulty, statement, 'grila', {'options': options, 'answer': at}, hint, solution, source)


def quiz_multi(id, title, chapter, difficulty, statement, options, answers, hint='', solution='', source=''):
    """A question with one or more correct answers ("select one or more"), the options in the order given."""
    answers = sorted(set(answers))
    assert answers and all(0 <= a < len(options) for a in answers), (id, answers)
    assert len(set(options)) == len(options), (id, 'options repeat')
    if len(answers) == 1:
        return problem(id, title, chapter, difficulty, statement, 'grila', {'options': options, 'answer': answers[0]}, hint, solution, source)
    return problem(id, title, chapter, difficulty, statement, 'grila', {'options': options, 'answers': answers}, hint, solution, source)


def true_false(id, title, chapter, difficulty, statement, truth, hint='', solution='', source=''):
    """A statement to judge: a) Adevărat, b) Fals."""
    return problem(id, title, chapter, difficulty, statement, 'grila', {'options': ['Adevărat', 'Fals'], 'answer': 0 if truth else 1}, hint, solution, source)


def title_of(text, n=52):
    """A list title from a question: its first words, cut at a word."""
    import re as _re
    t = _re.sub(r'\s+', ' ', text).strip()
    # "Care dintre următoarele afirmații sunt corecte referitor la X?" says nothing in a list: name X
    m = _re.match(r'^Care dintre (?:următoarele|urmatoarele) (?:afirmații|afirmatii|afirmații|propoziții|propozitii)(?: despre (.+?))? (?:sunt|este) (?:corecte|corectă|corecta|adevărate|adevărată|adevarate)\s*(?:(?:referitor la|privind|dacă se aplică|daca se aplica)\s+(.*))?$', t)
    if m and (m[1] or m[2]):
        t = 'Afirmații: ' + (m[1] or m[2]).rstrip(' :?.')
    elif len(t) > n:
        t = _re.split(r'(?<=[?:.])\s', t)[0]
    t = t.rstrip(' :?.,;')
    if len(t) > n:
        t = t[:n].rsplit(' ', 1)[0].rstrip(' ,;:(') + '…'
    return t[0].upper() + t[1:] if t else t


def load_grile(name):
    """Questions taken from the course's tests: tool/acs/data/<name>.json, made from the Moodle reviews."""
    with open(os.path.join(ROOT, 'tool', 'acs', 'data', f'{name}.json'), encoding='utf-8') as f:
        return json.load(f)


def fold(s):
    """Lower case, without diacritics: for matching keywords in a question."""
    import unicodedata
    s = unicodedata.normalize('NFKD', s.lower())
    return ''.join(c for c in s if not unicodedata.combining(c))


def add_grile(P, items, first_id, chapter_of, difficulty_of=None, source_of=None):
    """Append the questions of a course's tests (load_grile) to P, numbered from first_id.

    Each item: {q, source, options + right (a list: one or more correct)} or {q, source, tf}.
    The answer is the one the test's review marks as correct."""
    id = first_id
    for it in items:
        q = it['q']
        ch = chapter_of(it)
        diff = difficulty_of(it) if difficulty_of else ('ușoară' if 'tf' in it else 'medie')
        src = source_of(it) if source_of else it['source']
        if 'tf' in it:
            P.append(true_false(id, title_of(q), ch, diff, f'Adevărat sau fals?\n\n{q}', it['tf'],
                                solution=f'Afirmația este **{"adevărată" if it["tf"] else "falsă"}**.', source=src))
        else:
            right = it['right']
            sol = ('Răspunsul corect: ' + '; '.join(f'„{it["options"][r]}”' for r in right) + '.') if len(right) == 1 else \
                ('Răspunsurile corecte:\n' + '\n'.join(f'• {it["options"][r]}' for r in right))
            P.append(quiz_multi(id, title_of(q), ch, diff, q, it['options'], right, solution=sol, source=src))
        id += 1
    return id
