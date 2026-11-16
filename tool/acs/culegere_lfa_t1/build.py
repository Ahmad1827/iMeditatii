"""Builds the LFA test 1 exercise book: web/materiale/lfa-testul-1-culegere.pdf.

Needs the Typst compiler for Python (`pip install typst`); the automata are drawn with
the Typst package @preview/finite, downloaded on the first build. check.py verifies
every automaton and regular expression the book gives as an answer.
"""
import pathlib

import typst

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parents[2] / 'web' / 'materiale' / 'lfa-testul-1-culegere.pdf'

OUT.parent.mkdir(parents=True, exist_ok=True)
typst.compile(str(HERE / 'main.typ'), output=str(OUT), root=str(HERE))
print(OUT)
