"""Builds the LFA test 1 study guide: web/materiale/lfa-testul-1-lr.pdf.

Needs the Typst compiler for Python (`pip install typst`); the automata are drawn with
the Typst package @preview/finite, downloaded on the first build.
"""
import pathlib

import typst

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parents[2] / 'web' / 'materiale' / 'lfa-testul-1-lr.pdf'

OUT.parent.mkdir(parents=True, exist_ok=True)
typst.compile(str(HERE / 'main.typ'), output=str(OUT), root=str(HERE))
print(OUT)
