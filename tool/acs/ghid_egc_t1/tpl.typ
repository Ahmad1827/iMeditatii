// Șablonul ghidului EGC · Tema 1 (Card Games: Hearthstone).
#import "@preview/cetz:0.3.4"

#let albastru = rgb("#1f5fa8")
#let mov = rgb("#6a3fa0")
#let rosu = rgb("#b03a2e")
#let verde = rgb("#1e7a46")
#let gri = rgb("#5d6d7e")
#let portocaliu = rgb("#b9770e")

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
#let barem(corp) = cutie("Barem.", portocaliu, corp)

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

// O întrebare de la prezentare, cu răspunsul.
#let nrint = counter("intrebare")
#let intrebare(q, a) = {
  nrint.step()
  block(width: 100%, breakable: true, above: 1em, below: 0.6em)[
    #text(weight: "bold", fill: verde.darken(10%))[Î#context nrint.display(). #q]
    #block(inset: (left: 12pt, top: 2pt))[#a]
  ]
}

#let tabel(..args) = align(center, table(
  stroke: 0.5pt + gri.lighten(40%),
  inset: (x: 6pt, y: 4pt),
  align: left + horizon,
  fill: (x, y) => if y == 0 { albastru.lighten(88%) },
  ..args,
))

#let mono(t) = text(font: "DejaVu Sans Mono", size: 0.92em, t)

// Liniile [de]..[pana] (numerotate ca în fișier) din src/[fisier].
#let cod(fisier, de, pana) = {
  let linii = read("src/" + fisier).split("\n")
  let bucata = linii.slice(de - 1, calc.min(pana, linii.len())).join("\n")
  block(width: 100%, breakable: true, above: 0.9em, below: 0.9em)[
    #block(width: 100%, fill: gri.lighten(80%), inset: (x: 8pt, y: 4pt), radius: (top: 3pt), below: 0pt, sticky: true)[
      #text(8.5pt, weight: "bold", font: "DejaVu Sans Mono")[#fisier] #h(1fr) #text(8pt, fill: gri)[liniile #de–#pana]
    ]
    #block(width: 100%, fill: rgb("#f8f9f9"), stroke: 0.5pt + gri.lighten(60%), inset: (x: 8pt, y: 6pt), radius: (bottom: 3pt), breakable: true)[
      #set text(8.2pt)
      #show raw.line: it => [#box(width: 2.2em)[#align(right)[#text(fill: gri.lighten(20%))[#(it.number + de - 1)]]]#h(0.8em)#it.body]
      #raw(bucata, lang: "cpp", block: true)
    ]
  ]
}

// Un fișier întreg.
#let fisier(nume) = {
  let n = read("src/" + nume).split("\n").len()
  cod(nume, 1, n)
}

#let g = json("gen.json")
#let L = g.L
#let f2(x) = str(calc.round(x, digits: 2))

// Un mesh din gen.json desenat: triunghiurile (din indici) colorate, vârfurile numerotate.
#let deseneaza-mesh(nume, size: 3.2, numere: true, triunghiuri: true, vs: none) = {
  let m = g.meshes.at(nume)
  let v = if vs == none { m.v } else { vs }
  cetz.canvas(length: size * 1cm, {
    import cetz.draw: *
    // grila unității
    rect((-0.5, -0.5), (0.5, 0.5), stroke: (paint: gri.lighten(50%), dash: "dashed", thickness: 0.4pt))
    line((-0.6, 0), (0.6, 0), stroke: 0.3pt + gri.lighten(40%))
    line((0, -0.6), (0, 0.6), stroke: 0.3pt + gri.lighten(40%))
    if triunghiuri and "i" in m and vs == none {
      let idx = m.i
      let k = 0
      while k + 2 < idx.len() {
        let t = (idx.at(k), idx.at(k + 1), idx.at(k + 2))
        let fill = if calc.rem(calc.quo(k, 3), 2) == 0 { albastru.lighten(70%) } else { albastru.lighten(82%) }
        line(v.at(t.at(0)), v.at(t.at(1)), v.at(t.at(2)), close: true, fill: fill, stroke: 0.4pt + albastru)
        k += 3
      }
    } else {
      // evantai din vârful 0 (pentru variantele cu mai puține segmente)
      let n = v.len() - 1
      for i in range(n) {
        let fill = if calc.rem(i, 2) == 0 { albastru.lighten(70%) } else { albastru.lighten(82%) }
        line(v.at(0), v.at(i + 1), v.at(calc.rem(i + 1, n) + 1), close: true, fill: fill, stroke: 0.4pt + albastru)
      }
    }
    if numere {
      for (i, p) in v.enumerate() {
        circle(p, radius: 0.012, fill: rosu, stroke: none)
        content((p.at(0) + 0.045, p.at(1) + 0.04), text(6pt, fill: rosu)[#i])
      }
    }
  })
}

#let ghid(corp) = {
  set document(title: "EGC · Tema 1 · Card Games (Hearthstone)", author: "iMeditații")
  set page(
    paper: "a4",
    margin: (x: 1.9cm, top: 2cm, bottom: 2cm),
    header: context if counter(page).get().first() > 1 [
      #set text(8.5pt, fill: gri)
      EGC · Tema 1 · Hearthstone în OpenGL #h(1fr) ghid pentru prezentare
      #v(-4pt) #line(length: 100%, stroke: 0.4pt + gri.lighten(50%))
    ],
    footer: context [#set text(8.5pt, fill: gri); #h(1fr) #counter(page).display() #h(1fr)],
  )
  set text(lang: "ro", size: 10.5pt, font: "Libertinus Serif")
  set par(justify: true, leading: 0.62em, spacing: 0.9em)
  set heading(numbering: "1.1")
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
