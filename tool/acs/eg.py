"""EG — Economie Generală: the market on a graph, and the seminar's computations.

Topics from the Economie generală seminar (Automatică): demand and supply,
equilibrium, price controls and taxes, elasticity, costs, productivity and
profit, interest, money, and the macroeconomic indicators.
Every answer is computed here from the numbers in the statement.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, quiz, write_course, load_grile, add_grile, fold

C1 = '1. Cerere, ofertă, echilibru'
C2 = '2. Elasticitate'
C3 = '3. Costuri, productivitate, profit'
C4 = '4. Bani, dobândă, indicatori macroeconomici'
C5 = '5. Noțiuni'
C6 = '6. Grile: principii, alegere'
C7 = '7. Grile: cerere și ofertă'
C8 = '8. Grile: elasticitate'
C9 = '9. Grile: taxe, prețuri impuse, bunăstare'
C10 = '10. Grile: costuri și concurență'
CHAPTERS = [C1, C2, C3, C4, C5, C6, C7, C8, C9, C10]
SEM = 'Seminar Economie generală'
P = []


def num(id, label, value, hint='un număr', tol=0.01):
    v = round(float(value), 4)
    return {'id': id, 'label': label, 'answer': repr(v if v != int(v) else int(v)), 'number': True, 'tol': tol, 'hint': hint}


def txt(id, label, answer, hint=''):
    return {'id': id, 'label': label, 'answer': answer, 'hint': hint}


def eg(id, title, ch, diff, statement, fields, hint, solution, curves=None, price=0, source=SEM):
    spec = {'fields': fields}
    if curves:
        spec['curves'] = list(curves)
        spec['price'] = price
    P.append(problem(id, title, ch, diff, statement, 'market', spec, hint, solution, source))


def n(v):
    v = round(float(v), 2)
    return str(int(v)) if v == int(v) else f'{v:.2f}'.rstrip('0').replace('.', ',')


def equilibrium(a, b, c, d):
    p = (a - c) / (b + d)
    return p, a - b * p


def fn(a, b, c, d):
    return f'`Qc = {a} - {b}P`, `Qo = {c} + {d}P`'.replace('+ -', '- ')


def echilibru(id, title, diff, a, b, c, d):
    p, q = equilibrium(a, b, c, d)
    eg(id, title, C1, diff, f'Cererea și oferta pe o piață sunt {fn(a, b, c, d)} (`P` prețul, `Q` cantitatea). Află prețul și cantitatea de echilibru.',
       [num('p', 'prețul de echilibru', p), num('q', 'cantitatea de echilibru', q)],
       'La echilibru cantitatea cerută e egală cu cea oferită: `Qc = Qo`. Pe grafic, mută prețul până când cele două puncte se întâlnesc.',
       f'`{a} - {b}P = {c} + {d}P` ⇒ `P = {n(p)}`, apoi `Q = {a} - {b}·{n(p)} = {n(q)}`.'.replace('+ -', '- '), curves=(a, b, c, d), price=round(p * 0.5, 1))


echilibru(1, 'Echilibrul pieței', 'ușoară', 100, 2, 20, 2)
echilibru(2, 'Echilibru, ofertă care pornește mai târziu', 'ușoară', 120, 3, -30, 2)
echilibru(3, 'Echilibru cu preț fracționar', 'medie', 90, 4, 10, 1)

a, b, c, d = 100, 2, 20, 2
eg(4, 'Preț maxim impus', C1, 'medie', f'Pe piața cu {fn(a, b, c, d)}, statul impune un preț maxim (plafon) de 15. Ce se întâmplă?',
   [num('qd', 'cantitatea cerută la prețul 15', a - b * 15), num('qs', 'cantitatea oferită la prețul 15', c + d * 15), num('gap', 'penuria (cererea neacoperită)', (a - b * 15) - (c + d * 15))],
   'Un plafon sub prețul de echilibru: se cere mai mult decât se oferă.', '`Qc = 100 - 30 = 70`, `Qo = 20 + 30 = 50`: lipsesc 20 de unități. Prețul de echilibru ar fi fost 20.', curves=(a, b, c, d), price=15)
eg(5, 'Preț minim impus', C1, 'medie', f'Pe aceeași piață, {fn(a, b, c, d)}, statul impune un preț minim de 25.',
   [num('qd', 'cantitatea cerută la prețul 25', a - b * 25), num('qs', 'cantitatea oferită la prețul 25', c + d * 25), num('gap', 'surplusul (oferta nevândută)', (c + d * 25) - (a - b * 25))],
   'Un preț minim peste cel de echilibru: se oferă mai mult decât se cere.', '`Qc = 50`, `Qo = 70`: rămân nevândute 20 de unități.', curves=(a, b, c, d), price=25)
p0, q0 = equilibrium(a, b, c, d)
p1, q1 = equilibrium(140, b, c, d)
eg(6, 'Cererea crește', C1, 'medie', f'Inițial {fn(a, b, c, d)}. Veniturile cresc și cererea devine `Qc = 140 - 2P`; oferta nu se schimbă. Graficul arată piața nouă.',
   [num('p', 'noul preț de echilibru', p1), num('q', 'noua cantitate de echilibru', q1), num('dp', 'cu cât a crescut prețul', p1 - p0)],
   'Curba cererii se mută spre dreapta: cresc și prețul, și cantitatea.', f'Înainte: `P = {n(p0)}`, `Q = {n(q0)}`. După: `140 - 2P = 20 + 2P` ⇒ `P = {n(p1)}`, `Q = {n(q1)}`.', curves=(140, b, c, d), price=p0)
pt, qt = equilibrium(a, b, c - d * 5, d)
eg(7, 'Taxă pe unitatea vândută', C1, 'grea', f'Pe piața cu {fn(a, b, c, d)}, producătorii plătesc statului o taxă de 5 pe fiecare unitate vândută. Oferta devine `Qo = 20 + 2(P - 5)`; graficul arată piața cu taxă.',
   [num('p', 'prețul plătit de cumpărători', pt), num('pn', 'prețul care le rămâne producătorilor', pt - 5), num('q', 'cantitatea vândută', qt), num('tax', 'încasările statului din taxă', 5 * qt)],
   'Producătorul primește `P - 5`, deci oferta se scrie în funcție de `P - 5`.', f'`100 - 2P = 10 + 2P` ⇒ `P = {n(pt)}`, `Q = {n(qt)}`. Producătorilor le rămâne `{n(pt - 5)}`; statul încasează `5 · {n(qt)} = {n(5 * qt)}`. Taxa e împărțită: cumpărătorii plătesc cu 2,5 mai mult, producătorii primesc cu 2,5 mai puțin.',
   curves=(a, b, c - d * 5, d), price=p0)
eg(8, 'Încasările la echilibru', C1, 'ușoară', f'Pe piața cu {fn(a, b, c, d)}, cât încasează vânzătorii la echilibru?',
   [num('v', 'încasările totale (preț × cantitate)', p0 * q0)], 'Găsește întâi echilibrul.', f'`P = {n(p0)}`, `Q = {n(q0)}`: încasări `{n(p0 * q0)}`.', curves=(a, b, c, d), price=10)


def elast(id, title, diff, what, pa, pb, qa, qb, kinds=True):
    dp, dq = (pb - pa) / pa * 100, (qb - qa) / qa * 100
    e = abs(dq / dp)
    fields = [num('dp', 'variația prețului, în %', dp, '%'), num('dq', 'variația cantității, în %', dq, '%'), num('e', 'coeficientul de elasticitate (în modul)', e)]
    if kinds:
        fields.append(txt('k', 'cererea este: elastică / inelastică / unitară', 'elastică|elastica' if e > 1 else ('inelastică|inelastica' if e < 1 else 'unitară|unitara'), 'un cuvânt'))
    eg(id, title, C2, diff, f'Prețul unui bun {"crește" if pb > pa else "scade"} de la {pa} la {pb}, iar cantitatea {what} {"crește" if qb > qa else "scade"} de la {qa} la {qb}. Calculează elasticitatea în funcție de preț (față de valorile inițiale).',
       fields, 'Coeficientul = variația procentuală a cantității împărțită la variația procentuală a prețului.',
       f'`ΔP% = {n(dp)}%`, `ΔQ% = {n(dq)}%`, deci `E = {n(abs(dq))} / {n(abs(dp))} = {n(e)}`.' + (f' {"Peste" if e > 1 else "Sub"} 1: cerere {"elastică" if e > 1 else "inelastică"}.' if kinds and e != 1 else ''))


elast(9, 'Cerere inelastică', 'ușoară', 'cerută', 10, 12, 100, 90)
elast(10, 'Cerere elastică', 'ușoară', 'cerută', 20, 18, 50, 60)
elast(11, 'Elasticitatea ofertei', 'medie', 'oferită', 10, 11, 200, 230, kinds=False)
elast(12, 'Elasticitate unitară', 'medie', 'cerută', 40, 50, 80, 60)
eg(13, 'Elasticitatea într-un punct al curbei', C2, 'grea', 'Cererea este `Qc = 100 - 2P`. Calculează elasticitatea cererii în funcție de preț în punctul `P = 20`.',
   [num('q', 'cantitatea cerută la P = 20', 60), num('e', 'coeficientul de elasticitate (în modul)', 2 * 20 / 60)],
   '`E = |dQ/dP| · P / Q`. Panta curbei e constantă, dar elasticitatea se schimbă de-a lungul ei.', '`Q = 60`, `dQ/dP = -2`: `E = 2 · 20 / 60 ≈ 0,67`, cerere inelastică în acest punct.', curves=(100, 2, 20, 2), price=20)
eg(14, 'Elasticitatea în funcție de venit', C2, 'ușoară', 'Venitul consumatorilor crește cu 10%, iar cantitatea cerută dintr-un bun crește cu 15%.',
   [num('e', 'coeficientul de elasticitate în funcție de venit', 1.5), txt('k', 'bunul este: normal / inferior', 'normal', 'un cuvânt')],
   'Coeficient pozitiv: bun normal; negativ: bun inferior.', '`E = 15% / 10% = 1,5 > 0`: bun normal (peste 1: cererea crește mai repede decât venitul).')

eg(15, 'Costuri totale și medii', C3, 'ușoară', 'O firmă produce 200 de bucăți, cu costuri fixe de 1000 și costuri variabile de 3000.',
   [num('ct', 'costul total', 4000), num('ctm', 'costul total mediu (pe bucată)', 20), num('cvm', 'costul variabil mediu', 15), num('cfm', 'costul fix mediu', 5)],
   '`CT = CF + CV`; mediile se obțin împărțind la producție.', '`CT = 4000`, `CTM = 4000 / 200 = 20`, `CVM = 15`, `CFM = 5` (și `CTM = CVM + CFM`).')
eg(16, 'Costul marginal', C3, 'ușoară', 'Producția crește de la 100 la 120 de bucăți, iar costul total de la 5000 la 5600.',
   [num('cmg', 'costul marginal', 30), num('a', 'costul total mediu inițial', 50), num('b', 'costul total mediu final', 5600 / 120)],
   'Costul marginal = sporul costului total împărțit la sporul producției.', '`Cmg = 600 / 20 = 30`. E sub costul mediu (50), de aceea costul mediu scade la `≈ 46,67`.')
eg(17, 'Productivitatea muncii', C3, 'medie', '20 de lucrători produc 400 de bucăți. După angajarea a încă 5 lucrători, producția ajunge la 475.',
   [num('w0', 'productivitatea medie inițială', 20), num('w1', 'productivitatea medie finală', 19), num('wmg', 'productivitatea marginală a muncii', 15)],
   'Medie: producția pe lucrător. Marginală: sporul producției pe lucrător în plus.', '`WM₀ = 400 / 20 = 20`, `WM₁ = 475 / 25 = 19`, `Wmg = 75 / 5 = 15`. Marginala e sub medie, deci media scade.')
eg(18, 'Profit și rate ale profitului', C3, 'medie', 'O firmă vinde 200 de bucăți la prețul de 50, cu un cost total de 8000.',
   [num('ca', 'cifra de afaceri', 10000), num('pr', 'profitul', 2000), num('rc', 'rata profitului la cost, în %', 25, '%'), num('rca', 'rata profitului la cifra de afaceri, în %', 20, '%')],
   'Rata la cost = profit / cost; rata la cifra de afaceri = profit / încasări.', '`CA = 10000`, `Pr = 2000`, `2000 / 8000 = 25%`, `2000 / 10000 = 20%`.')
eg(19, 'Pragul de rentabilitate', C3, 'medie', 'Costurile fixe sunt 6000, costul variabil pe bucată este 30, iar prețul de vânzare este 50.',
   [num('q', 'producția la care profitul este zero', 300), num('ca', 'cifra de afaceri la prag', 15000)],
   'La prag, încasările acoperă exact costurile: `P·Q = CF + CVM·Q`.', '`Q = CF / (P - CVM) = 6000 / 20 = 300` bucăți, adică încasări de `15000`.')
eg(20, 'Profit maxim', C3, 'grea', 'Pe o piață cu concurență perfectă prețul este 40. Costul total al firmei este `CT = 100 + 10Q + 0,5Q²`, deci costul marginal este `Cmg = 10 + Q`.',
   [num('q', 'producția care maximizează profitul', 30), num('pr', 'profitul maxim', 40 * 30 - (100 + 300 + 450))],
   'Profitul e maxim când costul marginal ajunge la preț.', '`10 + Q = 40` ⇒ `Q = 30`. `CA = 1200`, `CT = 100 + 300 + 450 = 850`, profit `350`.')

eg(21, 'Dobânda simplă', C4, 'ușoară', 'Un depozit de 10 000 de lei, cu rata anuală a dobânzii de 8%, este ținut 2 ani, cu dobândă simplă.',
   [num('d', 'dobânda totală', 1600), num('s', 'suma finală', 11600)], '`D = S · r · n`.', '`10 000 · 0,08 · 2 = 1600`; suma finală `11 600`.')
eg(22, 'Dobânda compusă', C4, 'medie', 'Un depozit de 10 000 de lei, cu rata anuală de 10%, este ținut 3 ani, cu capitalizarea anuală a dobânzii.',
   [num('s', 'suma finală', 13310), num('d', 'dobânda totală', 3310)], '`Sn = S · (1 + r)ⁿ`.', '`10 000 · 1,1³ = 13 310`, din care dobândă `3310` (față de 3000 cu dobândă simplă).')
eg(23, 'Ecuația schimbului', C4, 'ușoară', 'Masa monetară este 200, viteza de rotație a banilor este 5, iar volumul tranzacțiilor este de 500 de unități.',
   [num('p', 'nivelul mediu al prețurilor', 2), num('m', 'masa monetară necesară dacă volumul crește la 600, la aceleași prețuri și viteză', 240)],
   '`M · V = P · Q`.', '`P = 200 · 5 / 500 = 2`. Pentru `Q = 600`: `M = 2 · 600 / 5 = 240`.')
eg(24, 'Salariul real', C4, 'medie', 'Salariul nominal crește cu 20%, iar prețurile bunurilor de consum cresc cu 25%.',
   [num('i', 'indicele salariului real, în %', 96, '%'), num('v', 'variația salariului real, în % (cu semn)', -4, '%')],
   'Indicele salariului real = indicele salariului nominal / indicele prețurilor.', '`120 / 125 = 0,96`: salariul real scade cu 4%, deși cel nominal a crescut.')
eg(25, 'Inflație și puterea de cumpărare', C4, 'medie', 'Indicele prețurilor de consum crește într-un an de la 100 la 108.',
   [num('r', 'rata inflației, în %', 8, '%'), num('p', 'indicele puterii de cumpărare a banilor, în %', 100 / 1.08, '%', tol=0.05)],
   'Puterea de cumpărare e inversul indicelui prețurilor.', '`Ri = 8%`; `1 / 1,08 ≈ 92,59%`: cu aceiași bani se cumpără cu 7,41% mai puțin.')
eg(26, 'PIB prin metoda cheltuielilor', C4, 'ușoară', 'Consumul privat este 600, investițiile 200, cheltuielile guvernamentale 150, exportul 120 și importul 70.',
   [num('en', 'exportul net', 50), num('pib', 'PIB', 1000)], '`PIB = C + I + G + (E - M)`.', '`600 + 200 + 150 + (120 - 70) = 1000`.')
eg(27, 'Rata șomajului', C4, 'ușoară', 'Populația activă este de 10 000 de persoane, dintre care 9500 sunt ocupate.',
   [num('s', 'numărul șomerilor', 500), num('r', 'rata șomajului, în %', 5, '%')], 'Rata șomajului se raportează la populația activă.', '`500 / 10 000 = 5%`.')
eg(28, 'Multiplicatorul investițiilor', C4, 'medie', 'Înclinația marginală spre consum este 0,8. Investițiile cresc cu 100.',
   [num('k', 'multiplicatorul investițiilor', 5), num('dy', 'creșterea venitului național', 500)], '`k = 1 / (1 - c\')`.', '`k = 1 / 0,2 = 5`, deci `ΔY = 5 · 100 = 500`.')


def q(id, title, diff, st, right, wrong, hint, sol):
    P.append(quiz(id, title, C5, diff, st, right, wrong, hint, sol, SEM))


q(29, 'Legea cererii', 'ușoară', 'Ce spune legea generală a cererii?', 'când prețul unui bun crește, cantitatea cerută scade, celelalte condiții rămânând neschimbate',
  ['când prețul crește, cantitatea cerută crește', 'cererea nu depinde de preț', 'când venitul crește, prețul scade'], 'Relație inversă între preț și cantitatea cerută.', 'De aceea curba cererii coboară. Legea ofertei e relația directă dintre preț și cantitatea oferită.')
q(30, 'Costul de oportunitate', 'ușoară', 'Ce este costul de oportunitate al unei alegeri?', 'valoarea celei mai bune alternative la care renunți',
  ['suma tuturor alternativelor la care renunți', 'prețul plătit în bani', 'costul fix al producției'], 'Resursele sunt limitate: a alege înseamnă a renunța.', 'Nu se adună toate alternativele, ci doar cea mai bună dintre cele sacrificate.')
q(31, 'Bunuri substituibile', 'medie', 'Prețul untului crește. Ce se întâmplă, de regulă, cu cererea de margarină?', 'crește, pentru că sunt bunuri substituibile',
  ['scade, pentru că sunt bunuri complementare', 'nu se schimbă', 'scade, pentru că legea cererii se aplică și ei'], 'Elasticitatea încrucișată e pozitivă pentru bunuri care se pot înlocui.', 'La bunurile complementare (mașini și benzină) cererea celuilalt scade.')
q(32, 'Costul fix', 'ușoară', 'Care dintre următoarele este, pe termen scurt, un cost fix?', 'chiria halei de producție',
  ['materiile prime', 'salariile plătite la bucată', 'energia consumată de utilaje în producție'], 'Costul fix nu se schimbă când se schimbă producția.', 'Chiria se plătește și dacă nu se produce nimic; pe termen lung toate costurile sunt variabile.')
q(33, 'Monopol', 'ușoară', 'Ce caracterizează piața de monopol?', 'un singur vânzător, care poate influența prețul',
  ['mulți vânzători și mulți cumpărători, cu bunuri identice', 'câțiva vânzători mari', 'un singur cumpărător'], 'Mono = unul.', 'Câțiva vânzători: oligopol. Un singur cumpărător: monopson. Concurența perfectă: mulți vânzători, preț dat.')
q(34, 'Inflația și dobânda reală', 'medie', 'Rata nominală a dobânzii este 6%, iar rata inflației este 8%. Cum este rata reală a dobânzii?', 'negativă: deponentul pierde putere de cumpărare',
  ['pozitivă, de 6%', 'pozitivă, de 14%', 'egală cu zero'], 'Rata reală ≈ rata nominală - rata inflației.', '`6% - 8% = -2%`: banii din depozit cumpără la sfârșit mai puțin decât la început.')

# ------------------------------------------------- the tests' questions (curs.upb.ro)
import re


def eg_chapter(it):
    t = fold(it['q'] + ' ' + ' '.join(it.get('options', [])))
    if re.search(r'tax|impozit|pret(ul)? (maxim|minim)|plafon|surplus|bunastar|pierderea de', t):
        return C9
    if 'elastic' in t:
        return C8
    if re.search(r'cost(ul)? (marginal|total|variabil|fix|mediu)|concurent|monopol|oligopol', t):
        return C10
    if re.search(r'oportunitat|frontiera|normativ|pozitiv|raritat|pranz|invizibil|flux(ului)? circular|analiza marginal|marginala|compromis|stiinta economica|economia studiaza|economistii|rationa', t):
        return C6
    return C7


def eg_difficulty(it):
    if 'tf' in it:
        return 'ușoară'
    return 'grea' if re.search(r'[CO]\(p\)|p ?= ?\d', it['q']) else 'medie'


add_grile(P, load_grile('eg_grile'), 101, eg_chapter, eg_difficulty)

write_course('eg', CHAPTERS, P)
