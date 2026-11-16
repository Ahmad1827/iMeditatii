// Șablonul culegerii LFA · Testul 1 (limbaje regulate): aceleași chenare și automate ca ghidul.
#import "@preview/finite:0.5.0": automaton

#let albastru = rgb("#1f5fa8")
#let mov = rgb("#6a3fa0")
#let rosu = rgb("#b03a2e")
#let verde = rgb("#1e7a46")
#let gri = rgb("#5d6d7e")

#let cutie(titlu, culoare, corp) = block(
  width: 100%,
  inset: (x: 10pt, y: 8pt),
  radius: 3pt,
  stroke: (left: 3pt + culoare),
  fill: culoare.lighten(93%),
  breakable: true,
)[#if titlu != none [#text(weight: "bold", fill: culoare.darken(15%))[#titlu] #h(2pt)]#corp]

#let defn(t: "Definiție", corp) = cutie(t, albastru, corp)
#let teorema(t: "Teoremă", corp) = cutie(t, mov, corp)
#let capcana(corp) = cutie("Capcană.", rosu, corp)
#let petest(corp) = cutie("Pe test.", verde, corp)
#let idee(corp) = cutie("Idee.", gri, corp)

#let barem(corp) = cutie("Barem.", verde, corp)
#let metoda(corp) = cutie("Metoda.", albastru, corp)

#let nrprob = counter("problema")
// sursa: de unde vine enunțul (test, examen, seminar), scris discret lângă titlu.
#let problema(titlu, enunt, solutie, sursa: none) = {
  nrprob.step()
  block(width: 100%, breakable: true, above: 1.3em)[
    #block(width: 100%, inset: (x: 10pt, y: 7pt), fill: albastru.lighten(88%), radius: (top: 3pt), below: 0pt, sticky: true)[
      #text(weight: "bold", fill: albastru.darken(25%))[Exercițiul #context nrprob.display()#if titlu != none [ · #titlu]]#if sursa != none [#h(1fr)#text(8.5pt, fill: gri)[#sursa]]
    ]
    #block(width: 100%, inset: (x: 10pt, y: 8pt), stroke: (left: 0.6pt + albastru.lighten(60%), right: 0.6pt + albastru.lighten(60%)), below: 0pt, sticky: true)[#enunt]
    #block(width: 100%, inset: (x: 10pt, y: 8pt), stroke: 0.6pt + albastru.lighten(60%), radius: (bottom: 3pt), breakable: true)[
      #text(weight: "bold", fill: verde)[Rezolvare.] #solutie
    ]
  ]
}

// Un automat desenat: spec = tranzițiile, poz = coordonatele stărilor,
// st = stiluri pe tranziții ("q0-q1": (curve: .6)), fara-start ascunde săgeata „Start”.
#let aut(spec, poz, final: auto, initial: auto, st: (:), etichete: (:), lungime: 0.95cm, raza: .42) = align(center, automaton(
  spec,
  labels: etichete,
  layout: poz,
  final: final,
  initial: initial,
  length: lungime,
  style: (
    state: (radius: raza, extrude: .85, label: (size: 0.9em), initial: (label: (text: ""))),
    transition: (curve: 0, label: (dist: .22, size: 0.85em, angle: 0deg)),
  ) + st,
))

#let tabel(..args) = align(center, table(
  stroke: 0.5pt + gri.lighten(40%),
  inset: (x: 7pt, y: 4pt),
  align: left + horizon,
  fill: (x, y) => if y == 0 { albastru.lighten(88%) },
  ..args,
))

#let ghid(corp) = {
  set document(title: "LFA · Testul 1 · Culegere de exerciții rezolvate", author: "iMeditații")
  set page(
    paper: "a4",
    margin: (x: 2cm, top: 2cm, bottom: 2cm),
    header: context if counter(page).get().first() > 1 [
      #set text(8.5pt, fill: gri)
      LFA · Testul 1 (limbaje regulate) #h(1fr) culegere de exerciții rezolvate
      #v(-4pt) #line(length: 100%, stroke: 0.4pt + gri.lighten(50%))
    ],
    footer: context [#set text(8.5pt, fill: gri); #h(1fr) #counter(page).display() #h(1fr)],
  )
  set text(lang: "ro", size: 10.5pt, font: "Libertinus Serif")
  set par(justify: true, leading: 0.62em, spacing: 0.9em)
  // capitolele încep de la 0
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
  set list(indent: 0.6em)
  set enum(indent: 0.6em)
  show math.equation: set text(font: "New Computer Modern Math")
  corp
}
