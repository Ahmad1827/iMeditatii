// Șablonul ghidului APM · Lucrarea 2 (RISC-V: IF + ID).
#import "@preview/cetz:0.3.4"

#let albastru = rgb("#1f5fa8")
#let mov = rgb("#6a3fa0")
#let rosu = rgb("#b03a2e")
#let verde = rgb("#1e7a46")
#let gri = rgb("#5d6d7e")
#let portocaliu = rgb("#b9770e")

// culorile câmpurilor unei instrucțiuni (aceleași în tot ghidul)
#let c-op = rgb("#d6eaf8")
#let c-rd = rgb("#d5f5e3")
#let c-f3 = rgb("#fcf3cf")
#let c-rs1 = rgb("#fadbd8")
#let c-rs2 = rgb("#e8daef")
#let c-f7 = rgb("#f6ddcc")
#let c-imm = rgb("#eaeded")

#let cutie(titlu, culoare, corp) = block(
  width: 100%,
  inset: (x: 10pt, y: 8pt),
  radius: 3pt,
  stroke: (left: 3pt + culoare),
  fill: culoare.lighten(93%),
  breakable: true,
)[#if titlu != none [#text(weight: "bold", fill: culoare.darken(15%))[#titlu] #h(2pt)]#corp]

#let defn(t: "Definiție.", corp) = cutie(t, albastru, corp)
#let regula(t: "Regulă.", corp) = cutie(t, mov, corp)
#let capcana(corp) = cutie("Capcană.", rosu, corp)
#let prof(corp) = cutie("La prezentare.", verde, corp)
#let idee(corp) = cutie("Idee.", gri, corp)
#let vivado(corp) = cutie("În Vivado.", portocaliu, corp)

#let nrprob = counter("problema")
#let problema(titlu, enunt, solutie) = {
  nrprob.step()
  block(width: 100%, breakable: true, above: 1.3em)[
    #block(width: 100%, inset: (x: 10pt, y: 7pt), fill: albastru.lighten(88%), radius: (top: 3pt), below: 0pt, sticky: true)[
      #text(weight: "bold", fill: albastru.darken(25%))[Exercițiul #context nrprob.display()#if titlu != none [ · #titlu]]
    ]
    #block(width: 100%, inset: (x: 10pt, y: 8pt), stroke: (left: 0.6pt + albastru.lighten(60%), right: 0.6pt + albastru.lighten(60%)), below: 0pt, sticky: true)[#enunt]
    #block(width: 100%, inset: (x: 10pt, y: 8pt), stroke: 0.6pt + albastru.lighten(60%), radius: (bottom: 3pt), breakable: true)[
      #text(weight: "bold", fill: verde)[Rezolvare.] #solutie
    ]
  ]
}

#let tabel(..args) = align(center, table(
  stroke: 0.5pt + gri.lighten(40%),
  inset: (x: 6pt, y: 4pt),
  align: left + horizon,
  fill: (x, y) => if y == 0 { albastru.lighten(88%) },
  ..args,
))

// Un fișier sursă, cu numele lui deasupra și liniile numerotate.
#let sursa(nume, cod) = block(width: 100%, breakable: true, above: 0.9em, below: 0.9em)[
  #block(width: 100%, fill: gri.lighten(80%), inset: (x: 8pt, y: 4pt), radius: (top: 3pt), below: 0pt, sticky: true)[
    #text(8.5pt, weight: "bold", font: "DejaVu Sans Mono")[#nume]
  ]
  #block(width: 100%, fill: rgb("#f8f9f9"), stroke: 0.5pt + gri.lighten(60%), inset: (x: 8pt, y: 6pt), radius: (bottom: 3pt), breakable: true)[
    #set text(8.4pt)
    #show raw.line: it => [#box(width: 1.8em)[#align(right)[#text(fill: gri.lighten(20%))[#it.number]]]#h(0.8em)#it.body]
    #raw(cod, lang: "verilog", block: true)
  ]
]

// O instrucțiune desenată pe câmpuri: (eticheta, biții, culoarea, lățimea în biți)
#let campuri(..f) = {
  let cs = f.pos()
  align(center, box(table(
    columns: cs.map(c => c.at(3) * 1fr),
    stroke: 0.6pt + gri,
    inset: (x: 2pt, y: 4pt),
    align: center + horizon,
    ..cs.map(c => table.cell(fill: c.at(2))[#text(7.5pt, fill: gri.darken(30%))[#c.at(0)]]),
    ..cs.map(c => table.cell(fill: c.at(2))[#text(8.5pt, font: "DejaVu Sans Mono")[#c.at(1)]]),
  ), width: 100%))
}

#let mono(t) = text(font: "DejaVu Sans Mono", size: 0.92em, t)

#let g = json("gen.json")
#let culori = (op: c-op, rd: c-rd, f3: c-f3, rs1: c-rs1, rs2: c-rs2, f7: c-f7, imm: c-imm)

// o instrucțiune din gen.json desenată pe câmpuri, cu binarul și hexa
#let instr(d, titlu: auto) = block(breakable: false, above: 0.8em, below: 0.9em)[
  #text(weight: "bold")[#mono(if titlu == auto { d.text } else { titlu })] #h(1fr) #text(fill: gri)[format #d.fmt]
  #campuri(..d.cells.map(c => (c.at(0), c.at(1), culori.at(c.at(2)), c.at(3))))
  #align(center)[#mono(d.nibbles) #h(6pt) → #h(6pt) #text(weight: "bold", fill: albastru)[#mono("0x" + d.hex)]]
]


#let ghid(corp) = {
  set document(title: "APM · Lucrarea 2 · Front-end-ul RISC-V (IF + ID)", author: "iMeditații")
  set page(
    paper: "a4",
    margin: (x: 1.9cm, top: 2cm, bottom: 2cm),
    header: context if counter(page).get().first() > 1 [
      #set text(8.5pt, fill: gri)
      APM · Lucrarea 2 · RISC-V IF + ID #h(1fr) ghid complet
      #v(-4pt) #line(length: 100%, stroke: 0.4pt + gri.lighten(50%))
    ],
    footer: context [#set text(8.5pt, fill: gri); #h(1fr) #counter(page).display() #h(1fr)],
  )
  set text(lang: "ro", size: 10.5pt, font: "Libertinus Serif")
  set par(justify: true, leading: 0.62em, spacing: 0.9em)
  set heading(numbering: (..n) => numbering("1.1", ..n.pos().enumerate().map(((i, x)) => if i == 0 { x - 1 } else { x })))
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    block(below: 1em)[
      #text(size: 20pt, fill: albastru, weight: "bold")[#if it.numbering != none [#counter(heading).display() · ]#it.body]
      #v(-6pt) #line(length: 100%, stroke: 1pt + albastru)
    ]
  }
  show heading.where(level: 2): set text(size: 13pt, fill: albastru.darken(20%))
  show heading.where(level: 3): set text(size: 11pt)
  show raw.where(block: false): set text(font: "DejaVu Sans Mono", size: 0.9em)
  show raw.where(block: true): set text(font: "DejaVu Sans Mono")
  set list(indent: 0.6em)
  set enum(indent: 0.6em)
  corp
}
