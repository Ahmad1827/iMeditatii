import 'package:flutter/material.dart';
import 'app_colors.dart';

class ResourcesData {
  static const String defaultAuthor = "Ahmad Arnaoute";
  static const String defaultRole = "FOUNDER & ADMIN";
  static const String defaultDate = "18.09.2026";

  static final List<Map<String, dynamic>> allArticles = [
    // =========================================================================
    // CLASA A 9-A (15 ARTICOLE)
    // =========================================================================
    {
      "id": "py-9-intro",
      "subject": "PYTHON",
      "grade": "9",
      "module": "1. BAZE PYTHON",
      "title": "Introducere în Python & Scurt Istoric",
      "desc": "Arhitectura interpretorului, compilare vs. interpretare, tipare dinamică și funcția print().",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "6 MIN",
      "color": AppColors.forest,
      "tag": "INTRO",
    },
    {
      "id": "py-9-vars",
      "subject": "PYTHON",
      "grade": "9",
      "module": "1. BAZE PYTHON",
      "title": "Variabile, Tipuri Primitive & input()",
      "desc": "Tipuri fundamentale (int, float, str, bool), conversii de tip (type casting) și citirea cu input().",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "7 MIN",
      "color": AppColors.sky,
      "tag": "SINTAXĂ",
    },
    {
      "id": "py-9-operators",
      "subject": "PYTHON",
      "grade": "9",
      "module": "1. BAZE PYTHON",
      "title": "Operatori Aritmetici & Logici în Python",
      "desc": "Împărțirea întreagă (//), modulo (%), exponențierea (**) și operatorii logici and, or, not.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "4 MIN",
      "color": AppColors.mustard,
      "tag": "OPERATORI",
    },
    {
      "id": "py-9-if",
      "subject": "PYTHON",
      "grade": "9",
      "module": "2. STRUCTURI DE CONTROL (PYTHON)",
      "title": "Instrucțiunea Decizională: if, elif, else",
      "desc": "Ramificări condiționale, operatori de comparare și indentarea obligatorie conform PEP 8.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "4 MIN",
      "color": AppColors.sunset,
      "tag": "CONTROL",
    },
    {
      "id": "py-9-loops",
      "subject": "PYTHON",
      "grade": "9",
      "module": "2. STRUCTURI DE CONTROL (PYTHON)",
      "title": "Structuri Repetitive: while & for range()",
      "desc": "Bucle cu număr cunoscut sau necunoscut de pași. Utilizarea funcției range(), break și continue.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "8 MIN",
      "color": AppColors.forest,
      "tag": "BUCLE",
    },
    {
      "id": "cpp-9-intro",
      "subject": "C++",
      "grade": "9",
      "module": "3. BAZE C++",
      "title": "Directiva #include, iostream & cin/cout",
      "desc": "Structura unui program C++, spațiul de nume std și fluxurile de intrare/ieșire din bibliotecă.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "3 MIN",
      "color": AppColors.sky,
      "tag": "C++ I/O",
    },
    {
      "id": "cpp-9-types",
      "subject": "C++",
      "grade": "9",
      "module": "3. BAZE C++",
      "title": "Tipuri de Date, Operatori & Codul ASCII",
      "desc": "Tipul char, conversii implicite/explicite, împărțirea întreagă și operatorul modulo (%).",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "5 MIN",
      "color": AppColors.mustard,
      "tag": "SINTAXĂ",
    },
    {
      "id": "cpp-9-if-switch",
      "subject": "C++",
      "grade": "9",
      "module": "4. STRUCTURI DE CONTROL (C++)",
      "title": "Instrucțiunile if-else și switch",
      "desc": "Evaluarea condițiilor compuse, acoladele ca delimitator de bloc și instrucțiunea switch-case.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "6 MIN",
      "color": AppColors.sunset,
      "tag": "CONTROL",
    },
    {
      "id": "cpp-9-loops",
      "subject": "C++",
      "grade": "9",
      "module": "4. STRUCTURI DE CONTROL (C++)",
      "title": "Buclele while, do-while și for în C++",
      "desc": "Structuri cu test inițial vs test final. Cum prevenim buclele infinite și când folosim break/continue.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "7 MIN",
      "color": AppColors.forest,
      "tag": "BUCLE",
    },
    {
      "id": "alg-9-digits",
      "subject": "C++",
      "grade": "9",
      "module": "5. ALGORITMI ELEMENTARI",
      "title": "Prelucrarea Cifrelor unui Număr",
      "desc": "Descompunerea cifrelor cu % 10 și / 10, construirea oglinditului și verificarea palindroamelor.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "8 MIN",
      "color": AppColors.sky,
      "tag": "ALGORITMI",
    },
    {
      "id": "alg-9-divisors",
      "subject": "C++",
      "grade": "9",
      "module": "5. ALGORITMI ELEMENTARI",
      "title": "Divizibilitate, Numere Prime & Descompunere",
      "desc": "Determinarea divizorilor în O(sqrt(N)), testul de primalitate și descompunerea în factori primi.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "8 MIN",
      "color": AppColors.mustard,
      "tag": "ALGORITMI",
    },
    {
      "id": "alg-9-gcd",
      "subject": "C++",
      "grade": "9",
      "module": "5. ALGORITMI ELEMENTARI",
      "title": "CMMDC & Algoritmul lui Euclid",
      "desc": "Algoritmul prin scăderi repetate vs algoritmul rapid prin împărțiri, calculul CMMMC.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "5 MIN",
      "color": AppColors.sunset,
      "tag": "ALGORITMI",
    },
    {
      "id": "cpp-9-vectors-basic",
      "subject": "C++",
      "grade": "9",
      "module": "6. VECTORI (TABLOURI UNIDIMENSIONALE)",
      "title": "Vectori în C++: Declarare, Citire & Parcurgere",
      "desc": "Indexare de la 0 la n-1, determinarea maximului/minimului și inversarea elementelor.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "6 MIN",
      "color": AppColors.forest,
      "tag": "VECTORI",
    },
    {
      "id": "cpp-9-vectors-sort",
      "subject": "C++",
      "grade": "9",
      "module": "6. VECTORI (TABLOURI UNIDIMENSIONALE)",
      "title": "Sortarea Vectorilor: BubbleSort & Selecție",
      "desc": "Metode clasice de sortare în O(N^2), interschimbarea valorilor și căutarea binară pe vector sortat.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "8 MIN",
      "color": AppColors.sky,
      "tag": "SORTARE",
    },
    {
      "id": "mat-9-quad",
      "subject": "MATEMATICĂ",
      "grade": "9",
      "module": "7. MATEMATICĂ (ALGEBRĂ CLASA A 9-A)",
      "title": "Funcția de Gradul II, Delta & Relațiile lui Viète",
      "desc": "Calculul discriminantului (Δ), semnele rădăcinilor, formarea ecuației și studiul monotoniei parabolei.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "8 MIN",
      "color": AppColors.mustard,
      "tag": "ALGEBRĂ",
    },

    // =========================================================================
    // CLASA A 10-A (15 ARTICOLE)
    // =========================================================================
    {
      "id": "cpp-10-matrix-basics",
      "subject": "C++",
      "grade": "10",
      "module": "1. TABLOURI BIDIMENSIONALE (MATRICE)",
      "title": "Matrice în C++: Declarare & Parcurgere",
      "desc": "Indexare cu linii (i) și coloane (j), citirea tablourilor bidimensionale și parcurgerea pe contur.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "7 MIN",
      "color": AppColors.forest,
      "tag": "MATRICE",
    },
    {
      "id": "cpp-10-matrix-diagonals",
      "subject": "C++",
      "grade": "10",
      "module": "1. TABLOURI BIDIMENSIONALE (MATRICE)",
      "title": "Diagonala Principală, Secundară & Zone Speciale",
      "desc": "Zone delimitate de diagonale (Nord, Sud, Est, Vest), simetria față de axele principale.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "7 MIN",
      "color": AppColors.sky,
      "tag": "MATRICE",
    },
    {
      "id": "cpp-10-strings-cstring",
      "subject": "C++",
      "grade": "10",
      "module": "2. ȘIRURI DE CARACTERE",
      "title": "Șiruri în stil C: char[] & Biblioteca cstring",
      "desc": "Caractere terminale '\\0', funcții esențiale: strlen, strcpy, strcat, strcmp, strstr și strtok.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "7 MIN",
      "color": AppColors.mustard,
      "tag": "ȘIRURI",
    },
    {
      "id": "cpp-10-strings-class",
      "subject": "C++",
      "grade": "10",
      "module": "2. ȘIRURI DE CARACTERE",
      "title": "Clasa std::string în C++ Modern",
      "desc": "Operații native cu operatorul +, metodele length(), find(), substr(), erase() și getline().",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "5 MIN",
      "color": AppColors.sunset,
      "tag": "ȘIRURI",
    },
    {
      "id": "cpp-10-subprog-basics",
      "subject": "C++",
      "grade": "10",
      "module": "3. SUBPROGRAME (FUNCȚII)",
      "title": "Subprograme: Antet, Prototip & Apel",
      "desc": "Modularizarea codului, tipul returnat de funcție, instrucțiunea return și variabile locale vs globale.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "7 MIN",
      "color": AppColors.forest,
      "tag": "FUNCȚII",
    },
    {
      "id": "cpp-10-subprog-params",
      "subject": "C++",
      "grade": "10",
      "module": "3. SUBPROGRAME (FUNCȚII)",
      "title": "Parametri prin Valoare vs. Referință (&)",
      "desc": "Cum modificăm variabilele din apelant, transmiterea vectorilor ca parametri în funcții.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "7 MIN",
      "color": AppColors.sky,
      "tag": "FUNCȚII",
    },
    {
      "id": "cpp-10-recursion-intro",
      "subject": "C++",
      "grade": "10",
      "module": "4. RECURSIVITATE",
      "title": "Noțiuni de Bază: Ce este Recursivitatea?",
      "desc": "Stiva de apeluri (Call Stack), condiția de oprire (cazul de bază) și riscul de Stack Overflow.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "4 MIN",
      "color": AppColors.mustard,
      "tag": "RECURSIVITATE",
    },
    {
      "id": "cpp-10-recursion-classic",
      "subject": "C++",
      "grade": "10",
      "module": "4. RECURSIVITATE",
      "title": "Algoritmi Clasici Recursivi: Factorial, CMMDC, Fibonacci",
      "desc": "Transformarea algoritmilor iterativi în funcții recursive directe și analiza eficienței.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "6 MIN",
      "color": AppColors.sunset,
      "tag": "RECURSIVITATE",
    },
    {
      "id": "cpp-10-d&i-intro",
      "subject": "C++",
      "grade": "10",
      "module": "5. DIVIDE ET IMPERA",
      "title": "Tehnica Divide et Impera & Căutarea Binară",
      "desc": "Descompunerea problemei în subprobleme similare, căutarea binară recursivă în O(log N).",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "5 MIN",
      "color": AppColors.forest,
      "tag": "D&I",
    },
    {
      "id": "cpp-10-d&i-mergesort",
      "subject": "C++",
      "grade": "10",
      "module": "5. DIVIDE ET IMPERA",
      "title": "Sortarea prin Interclasare: MergeSort",
      "desc": "Divizarea tabloului, interclasarea a doi vectori ordonați și complexitatea stabilă O(N log N).",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "6 MIN",
      "color": AppColors.sky,
      "tag": "SORTARE",
    },
    {
      "id": "cpp-10-d&i-quicksort",
      "subject": "C++",
      "grade": "10",
      "module": "5. DIVIDE ET IMPERA",
      "title": "Sortarea Rapidă: QuickSort",
      "desc": "Alegerea pivotului, partiționarea vectorului și analiza cazului favorabil vs nefavorabil.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "5 MIN",
      "color": AppColors.mustard,
      "tag": "SORTARE",
    },
    {
      "id": "cpp-10-struct",
      "subject": "C++",
      "grade": "10",
      "module": "6. TIPURI STRUCTURATE (STRUCT)",
      "title": "Structuri Eterogene în C++: Tipul struct",
      "desc": "Definirea tipurilor de date proprii, vectori de structuri și accesarea câmpurilor cu operatorul punct (.).",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "8 MIN",
      "color": AppColors.sunset,
      "tag": "STRUCT",
    },
    {
      "id": "mat-10-powers",
      "subject": "MATEMATICĂ",
      "grade": "10",
      "module": "7. MATEMATICĂ (CLASA A 10-A)",
      "title": "Puteri, Radicali & Logaritmi",
      "desc": "Proprietățile logaritmilor, schimbarea de bază, ecuații exponențiale și logaritmice pentru bac.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "8 MIN",
      "color": AppColors.forest,
      "tag": "ALGEBRĂ",
    },
    {
      "id": "mat-10-complex",
      "subject": "MATEMATICĂ",
      "grade": "10",
      "module": "7. MATEMATICĂ (CLASA A 10-A)",
      "title": "Numere Complexe: Forma Algebrică & Modul",
      "desc": "Unitatea imaginară i (i^2 = -1), conjugatul unui număr complex, modulul |z| și ecuații în C.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "3 MIN",
      "color": AppColors.sky,
      "tag": "ALGEBRĂ",
    },
    {
      "id": "mat-10-combinatorics",
      "subject": "MATEMATICĂ",
      "grade": "10",
      "module": "7. MATEMATICĂ (CLASA A 10-A)",
      "title": "Permutări, Aranjamente & Combinări",
      "desc": "Formule de calcul factorial, binomul lui Newton și calculul probabilităților clasice (fav/pos).",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "3 MIN",
      "color": AppColors.mustard,
      "tag": "COMBINATORICĂ",
    },

    // =========================================================================
    // CLASA A 11-A (15 ARTICOLE)
    // =========================================================================
    {
      "id": "cpp-11-backtracking-intro",
      "subject": "C++",
      "grade": "11",
      "module": "1. TEHNICA BACKTRACKING",
      "title": "Backtracking: Mecanismul de Căutare cu Revenire",
      "desc": "Reprezentarea soluțiilor sub formă de vector stivă, condiții de validare și condiții de final.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "4 MIN",
      "color": AppColors.forest,
      "tag": "BACKTRACKING",
    },
    {
      "id": "cpp-11-backtracking-perm",
      "subject": "C++",
      "grade": "11",
      "module": "1. TEHNICA BACKTRACKING",
      "title": "Generarea Permutărilor cu Backtracking",
      "desc": "Algoritmul clasic de generare a tuturor permutărilor mulțimii {1, 2, ..., n}.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "8 MIN",
      "color": AppColors.sky,
      "tag": "BACKTRACKING",
    },
    {
      "id": "cpp-11-backtracking-comb",
      "subject": "C++",
      "grade": "11",
      "module": "1. TEHNICA BACKTRACKING",
      "title": "Generarea Combinărilor & Aranjamentelor",
      "desc": "Optimizarea condițiilor de validare pentru a evita soluțiile duplicate și a genera aranjamente.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "7 MIN",
      "color": AppColors.mustard,
      "tag": "BACKTRACKING",
    },
    {
      "id": "cpp-11-graphs-matrix",
      "subject": "C++",
      "grade": "11",
      "module": "2. GRAFURI NEORIENTATE",
      "title": "Grafuri Neorientate: Matricea de Adiacență & Grad",
      "desc": "Reprezentarea prin matrice binară simetrică, gradul unui vârf, numărul de muchii și lema strângerilor de mână.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "5 MIN",
      "color": AppColors.sunset,
      "tag": "GRAFURI",
    },
    {
      "id": "cpp-11-graphs-bfs",
      "subject": "C++",
      "grade": "11",
      "module": "2. GRAFURI NEORIENTATE",
      "title": "Parcurgerea în Lățime a Grafurilor (BFS)",
      "desc": "Determinarea celor mai scurte drumuri în graf neponderat folosind o coadă (queue).",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "7 MIN",
      "color": AppColors.forest,
      "tag": "PARCURGERE",
    },
    {
      "id": "cpp-11-graphs-dfs",
      "subject": "C++",
      "grade": "11",
      "module": "2. GRAFURI NEORIENTATE",
      "title": "Parcurgerea în Adâncime a Grafurilor (DFS)",
      "desc": "Parcurgerea recursivă a vârfurilor nevizitate și detecția ciclurilor în graf.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "6 MIN",
      "color": AppColors.sky,
      "tag": "PARCURGERE",
    },
    {
      "id": "cpp-11-graphs-connected",
      "subject": "C++",
      "grade": "11",
      "module": "2. GRAFURI NEORIENTATE",
      "title": "Conexitate & Componente Conexe",
      "desc": "Algoritm de numărare a componentelor conexe și adăugarea numărului minim de muchii pentru conexitate.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "5 MIN",
      "color": AppColors.mustard,
      "tag": "GRAFURI",
    },
    {
      "id": "cpp-11-digraphs-intro",
      "subject": "C++",
      "grade": "11",
      "module": "3. GRAFURI ORIENTATE",
      "title": "Grafuri Orientate: Arcuri & Matrice de Adiacență",
      "desc": "Grad interior vs. grad exterior, circuite, drumuri orientate și reprezentare în memorie.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "6 MIN",
      "color": AppColors.sunset,
      "tag": "GRAFURI",
    },
    {
      "id": "cpp-11-trees-rooted",
      "subject": "C++",
      "grade": "11",
      "module": "4. ARBORI",
      "title": "Arbori cu Rădăcină: Vectorul de Tați & Frunze",
      "desc": "Proprietățile arborelui (N noduri, N-1 muchii, aciclic și conex), determinarea rădăcinii și a frunzelor.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "6 MIN",
      "color": AppColors.forest,
      "tag": "ARBORI",
    },
    {
      "id": "cpp-11-dp-intro",
      "subject": "C++",
      "grade": "11",
      "module": "5. PROGRAMARE DINAMICĂ",
      "title": "Programare Dinamică: Memoizare & Recurență",
      "desc": "Diferența față de divide et impera: memorarea stărilor calculate pentru a evita recalculările inutile.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "6 MIN",
      "color": AppColors.sky,
      "tag": "DINAMICĂ",
    },
    {
      "id": "cpp-11-dp-subseq",
      "subject": "C++",
      "grade": "11",
      "module": "5. PROGRAMARE DINAMICĂ",
      "title": "Subșirul Crescător Maximal (LIS)",
      "desc": "Construirea relației de recurență dp[i] și reconstituirea soluției optime în O(N^2).",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "6 MIN",
      "color": AppColors.mustard,
      "tag": "DINAMICĂ",
    },
    {
      "id": "cpp-11-dp-knapsack",
      "subject": "C++",
      "grade": "11",
      "module": "5. PROGRAMARE DINAMICĂ",
      "title": "Problema Rucsacului Discret (0-1 Knapsack)",
      "desc": "Maximizarea valorii fără a depăși greutatea maximă folosind o matrice de stări dp[i][w].",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "5 MIN",
      "color": AppColors.sunset,
      "tag": "DINAMICĂ",
    },
    {
      "id": "mat-11-matrices",
      "subject": "MATEMATICĂ",
      "grade": "11",
      "module": "6. MATEMATICĂ (CLASA A 11-A)",
      "title": "Algebră Liniară: Operații cu Matrice",
      "desc": "Adunarea matricelor, înmulțirea cu scalar și produsul matricial linie pe coloană.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "3 MIN",
      "color": AppColors.forest,
      "tag": "ALGEBRĂ",
    },
    {
      "id": "mat-11-determinants",
      "subject": "MATEMATICĂ",
      "grade": "11",
      "module": "6. MATEMATICĂ (CLASA A 11-A)",
      "title": "Determinanți de Ordin 2 & 3: Regula lui Sarrus",
      "desc": "Calculul determinanților, proprietăți esențiale (linii nule, comutativitate) și dezvoltarea după o linie.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "8 MIN",
      "color": AppColors.sky,
      "tag": "ALGEBRĂ",
    },
    {
      "id": "mat-11-limits",
      "subject": "MATEMATICĂ",
      "grade": "11",
      "module": "6. MATEMATICĂ (CLASA A 11-A)",
      "title": "Analiză: Limite de Funcții & Cazuri de Nedeterminare",
      "desc": "Eliminarea cazurilor 0/0, infinit/infinit, limite fundamentale și regula lui l'Hospital.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "3 MIN",
      "color": AppColors.mustard,
      "tag": "ANALIZĂ",
    },

    // =========================================================================
    // CLASA A 12-A (15 ARTICOLE)
    // =========================================================================
    {
      "id": "cpp-12-oop-classes",
      "subject": "C++",
      "grade": "12",
      "module": "1. PROGRAMARE ORIENTATĂ PE OBIECTE (OOP)",
      "title": "OOP în C++: Clase, Obiecte & Modificatori de Acces",
      "desc": "Diferența dintre clasă și instanță, specificatorii public, private și protected, metode membre.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "10 MIN",
      "color": AppColors.forest,
      "tag": "OOP",
    },
    {
      "id": "cpp-12-oop-constructors",
      "subject": "C++",
      "grade": "12",
      "module": "1. PROGRAMARE ORIENTATĂ PE OBIECTE (OOP)",
      "title": "Constructori, Destructori & Încapsulare",
      "desc": "Constructorul implicit, constructorul de copiere, lista de inițializare și eliberarea resurselor.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "12 MIN",
      "color": AppColors.sky,
      "tag": "OOP",
    },
    {
      "id": "cpp-12-oop-inheritance",
      "subject": "C++",
      "grade": "12",
      "module": "1. PROGRAMARE ORIENTATĂ PE OBIECTE (OOP)",
      "title": "Moștenirea în C++ (Inheritance)",
      "desc": "Clasa de bază și clasa derivată, reutilizarea codului și accesul la membrii protejați.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "10 MIN",
      "color": AppColors.mustard,
      "tag": "OOP",
    },
    {
      "id": "cpp-12-oop-polymorphism",
      "subject": "C++",
      "grade": "12",
      "module": "1. PROGRAMARE ORIENTATĂ PE OBIECTE (OOP)",
      "title": "Polimorfism & Funcții Virtuale (virtual)",
      "desc": "Legarea dinamică la execuție, clase abstracte și suprascrierea metodelor (override).",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "8 MIN",
      "color": AppColors.sunset,
      "tag": "OOP",
    },
    {
      "id": "db-12-sql-intro",
      "subject": "C++",
      "grade": "12",
      "module": "2. BAZE DE DATE RELAȚIONALE (SQL)",
      "title": "Baze de Date: Modelul Relațional & Tabele",
      "desc": "Concepte de cheie primară (PRIMARY KEY), cheie străină (FOREIGN KEY) și tipuri de date SQL.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "3 MIN",
      "color": AppColors.forest,
      "tag": "SQL",
    },
    {
      "id": "db-12-sql-select",
      "subject": "C++",
      "grade": "12",
      "module": "2. BAZE DE DATE RELAȚIONALE (SQL)",
      "title": "Interogarea Datelor: Instrucțiunea SELECT",
      "desc": "Filtrarea cu WHERE, clauzele LIKE, BETWEEN, ordonarea cu ORDER BY și eliminarea duplicatelor (DISTINCT).",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "4 MIN",
      "color": AppColors.sky,
      "tag": "SQL",
    },
    {
      "id": "db-12-sql-crud",
      "subject": "C++",
      "grade": "12",
      "module": "2. BAZE DE DATE RELAȚIONALE (SQL)",
      "title": "Comenzile INSERT, UPDATE & DELETE",
      "desc": "Manipularea înregistrărilor din tabele, importanța condiției WHERE la actualizare și ștergere.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "3 MIN",
      "color": AppColors.mustard,
      "tag": "SQL",
    },
    {
      "id": "bac-12-info-sub1",
      "subject": "C++",
      "grade": "12",
      "module": "3. PREGĂTIRE BACALAUREAT (INFORMATICĂ)",
      "title": "Bacalaureat: Strategii pentru Subiectul I (Grile & Expresii)",
      "desc": "Evaluarea expresiilor logice C++, operatori pe biți, matrice și recurențe fără greșeală.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "5 MIN",
      "color": AppColors.sunset,
      "tag": "BAC",
    },
    {
      "id": "bac-12-info-sub2",
      "subject": "C++",
      "grade": "12",
      "module": "3. PREGĂTIRE BACALAUREAT (INFORMATICĂ)",
      "title": "Bacalaureat: Rezolvarea Eficientă a Subiectului II",
      "desc": "Manipularea șirurilor de caractere, declararea structurilor struct și algoritmi pe grafuri/arbori.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "7 MIN",
      "color": AppColors.forest,
      "tag": "BAC",
    },
    {
      "id": "bac-12-info-sub3",
      "subject": "C++",
      "grade": "12",
      "module": "3. PREGĂTIRE BACALAUREAT (INFORMATICĂ)",
      "title": "Bacalaureat: Algoritmi Eficienți la Subiectul III (Problema 3)",
      "desc": "Scrierea algoritmilor eficienți ca memorie și timp de execuție: complexitate O(N) și memorie O(1).",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "5 MIN",
      "color": AppColors.sky,
      "tag": "BAC",
    },
    {
      "id": "mat-12-laws",
      "subject": "MATEMATICĂ",
      "grade": "12",
      "module": "4. MATEMATICĂ (STRUCTURI ALGEBRICE)",
      "title": "Legi de Compoziție & Proprietăți Fundamentale",
      "desc": "Parte stabilă, comutativitate, asociativitate, element neutru și elemente simetrizabile.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "3 MIN",
      "color": AppColors.mustard,
      "tag": "ALGEBRĂ",
    },
    {
      "id": "mat-12-groups",
      "subject": "MATEMATICĂ",
      "grade": "12",
      "module": "4. MATEMATICĂ (STRUCTURI ALGEBRICE)",
      "title": "Grupuri Comutative (Abeliene) & Morfisme",
      "desc": "Axiomele de grup, ecuații într-un grup, noțiunea de izomorfism de grupuri.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "4 MIN",
      "color": AppColors.sunset,
      "tag": "ALGEBRĂ",
    },
    {
      "id": "mat-12-polynomials",
      "subject": "MATEMATICĂ",
      "grade": "12",
      "module": "4. MATEMATICĂ (STRUCTURI ALGEBRICE)",
      "title": "Inele de Polinoame & Relațiile lui Viète",
      "desc": "Împărțirea polinoamelor, schema lui Horner, rădăcini multiple și descompunerea în factori ireductibili.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "4 MIN",
      "color": AppColors.forest,
      "tag": "ALGEBRĂ",
    },
    {
      "id": "mat-12-primitives",
      "subject": "MATEMATICĂ",
      "grade": "12",
      "module": "5. MATEMATICĂ (CALCUL INTEGRAL)",
      "title": "Primitive & Integrale Nedefinite",
      "desc": "Tabelul integralelor imediate, proprietatea de liniaritate a integralei nedefinite.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "4 MIN",
      "color": AppColors.sky,
      "tag": "INTEGRALE",
    },
    {
      "id": "mat-12-definite",
      "subject": "MATEMATICĂ",
      "grade": "12",
      "module": "5. MATEMATICĂ (CALCUL INTEGRAL)",
      "title": "Integrala Definită: Formula Leibniz-Newton & Părți",
      "desc": "Calculul integralelor definite, metoda schimbării de variabilă și calculul ariilor suprafețelor plane.",
      "author": defaultAuthor,
      "date": defaultDate,
      "readTime": "9 MIN",
      "color": AppColors.mustard,
      "tag": "INTEGRALE",
    },
  ];

  // Specific high-depth lecture dictionary
  static final Map<String, Map<String, dynamic>> curatedLectures = {
    // ---------------- PYTHON 9 ----------------
    "py-9-intro": {
      "tag": "INFORMATICĂ // CLASA A 9-A // PYTHON",
      "title": "Introducere în limbajul Python",
      "subtitle": "Ghid complet de start conform noii programe de liceu pentru clasa a 9-a.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. De ce Python în programa de liceu?",
          "text": "Spre deosebire de C++, care impune de la primul program noțiuni de compilare, directiva preprocesor #include, spații de nume și acolade rigide, Python a fost conceput pe principiul lizibilității ('Readability Counts'). În clasa a 9-a, elevii învață mai întâi logica algoritmilor (pașii decizionali, repetitivi și manipularea datelor) fără a fi blocați de erori de sintaxă sau punct și virgulă uitat la sfârșitul fiecărei linii.",
        },
        {
          "heading": "2. Arhitectura de execuție: Compilat vs. Interpretat",
          "text": "C++ este un limbaj compilat: codul tău sursă (.cpp) este transformat de către compilator (ex: g++) direct în limbaj mașină (fișier binar executabil .exe sau ELF) specific procesorului tău. Execuția este ultrarapidă, dar necesită o etapă separată de compilare.\n\nPython este un limbaj interpretat: codul sursă (.py) este compilat 'la cald' într-un format intermediar numit Bytecode (.pyc), care este apoi executat linie cu linie de către o mașină virtuală (Python Virtual Machine - PVM). Avantajul major este testarea imediată și portabilitatea totală între sisteme de operare.",
          "code": "# Primul tău program în Python:\nprint(\"Nivelul 1 în breaslă a început!\")\n\n# Citire de date de la consolă:\nnume = input(\"Introdu numele tău de ucenic: \")\nprint(f\"Bine ai venit în arenă, {nume}!\")\n\n# Afișare cu separatori personalizați:\nprint(\"Python\", \"este\", \"ușor\", sep=\" -> \", end=\" [SFÂRȘIT]\\n\")",
          "lang": "python"
        },
        {
          "heading": "3. Regula de Aur: Indentarea PEP 8",
          "text": "În Python NU există acolade { } pentru a delimita blocurile de instrucțiuni (cum ar fi corpul unui if sau al unui for)! Structura ierarhică este dată exclusiv de nivelul de indentare (aliniere la dreapta). Conform standardului oficial PEP 8, un nivel de indentare este egal cu exact 4 spații albe.",
          "callout": "EROARE CRITICĂ (IndentationError):\nDacă aliniezi o linie cu 3 spații și următoarea cu 4 spații, sau amesteci tasta TAB cu tasta SPACE, Python va refuza să execute codul și va afișa 'IndentationError: unexpected indent'."
        },
      ]
    },

    "py-9-vars": {
      "tag": "INFORMATICĂ // CLASA A 9-A // PYTHON",
      "title": "Variabile, Tipuri Primitive & input()",
      "subtitle": "Cum stocăm, convertim și manipulăm datele în memoria RAM a calculatorului.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Ce este o variabilă în Python? (Tipare Dinamică)",
          "text": "În C++, o variabilă este o zonă fixă de memorie cu un tip strict definit la compilare (int x = 5;). În Python, variabilele sunt doar etichete (referințe) atașate obiectelor din memorie. Tipul variabilei este determinat automat la atribuire și se poate schimba oricând (tipare dinamică).",
          "code": "x = 42             # x referă un întreg (int)\nprint(type(x))     # <class 'int'>\n\nx = \"Salutare\"     # acum x referă un text (str)\nprint(type(x))     # <class 'str'>",
          "lang": "python"
        },
        {
          "heading": "2. Tipuri fundamentale de date în clasa a 9-a",
          "text": "• int: Numere întregi de dimensiune nelimitată (nu dau overflow la 2 miliarde ca în C++!).\n• float: Numere reale cu virgulă mobilă (reprezentate conform IEEE 754 pe 64 de biți).\n• str: Șiruri de caractere imutabile, delimitate prin ghilimele simple sau duble.\n• bool: Valori logice booleene: True sau False (Atenție: cu majusculă!).",
        },
        {
          "heading": "3. Citirea cu input() și conversia de tip (Type Casting)",
          "text": "Funcția input() citește o linie de la consolă și returnează întotdeauna un șir de caractere (str). Dacă vrem să facem operații matematice, trebuie să convertim explicit valoarea folosind int() sau float().",
          "code": "# Program care calculează perimetrul și aria unui dreptunghi:\nlungime = float(input(\"Introdu lungimea: \"))\nlatime = float(input(\"Introdu lățimea: \"))\n\nperimetru = 2 * (lungime + latime)\naria = lungime * latime\n\nprint(f\"Perimetrul dreptunghiului: {perimetru}\")\nprint(f\"Aria dreptunghiului: {aria}\")",
          "lang": "python",
          "callout": "CAPCANĂ CLASICĂ LA EXAMEN:\nDacă scrii `a = input()` și `b = input()` introducând numerele 7 și 3, expresia `a + b` va fi '73' (concatenare de caractere) și NU 10!"
        }
      ]
    },

    "py-9-loops": {
      "tag": "INFORMATICĂ // CLASA A 9-A // PYTHON",
      "title": "Structuri Repetitive: while & for range()",
      "subtitle": "Cum automatizăm execuția calculelor repetitive și a algoritmilor cu pași multipli.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Bucla for cu generatorul range()",
          "text": "Bucla for în Python iterează peste o secvență de valori. Funcția range() generează secvențe numerice sub trei forme:\n• range(stop): numere de la 0 la stop - 1\n• range(start, stop): numere de la start la stop - 1\n• range(start, stop, step): numere din pas în pas",
          "code": "# Afișarea primelor 5 numere pare pozitive:\nfor i in range(2, 12, 2):\n    print(i, end=' ')  # Afișează: 2 4 6 8 10\nprint()\n\n# Numărare descrescătoare (de la 5 la 1):\nfor i in range(5, 0, -1):\n    print(i, end=' ')  # Afișează: 5 4 3 2 1",
          "lang": "python"
        },
        {
          "heading": "2. Bucla while (cu test inițial)",
          "text": "Instrucțiunea while se execută repetat atâta timp cât o condiție rămâne True. Este folosită când numărul de pași nu este cunoscut dinainte (de exemplu, la descompunerea cifrelor unui număr).",
          "code": "# Calculul sumei cifrelor unui număr natural n:\nn = int(input(\"Introdu numărul: \"))\nsuma_cifre = 0\n\nwhile n > 0:\n    cifra = n % 10          # extragem ultima cifră\n    suma_cifre += cifra     # o adunăm la sumă\n    n = n // 10             # tăiem ultima cifră (împărțire întreagă)\n\nprint(f\"Suma cifrelor este: {suma_cifre}\")",
          "lang": "python"
        },
        {
          "heading": "3. Instrucțiunile break și continue",
          "text": "• `break`: Întrerupe imediat execuția buclei curente și sare la prima instrucțiune de după ea.\n• `continue`: Oprește iterația curentă și trece direct la verificarea condiției pentru pasul următor.",
          "code": "# Căutarea primului număr divizibil cu 7 din interval:\nfor x in range(20, 50):\n    if x % 7 == 0:\n        print(f\"Găsit: {x}\")\n        break  # Oprește căutarea imediat",
          "lang": "python"
        }
      ]
    },

    // ---------------- C++ 9 ----------------
    "alg-9-digits": {
      "tag": "INFORMATICĂ // CLASA A 9-A // C++",
      "title": "Prelucrarea Cifrelor unui Număr",
      "subtitle": "Algoritmul fundamental de izolare, numărare, inversare și verificare de palindrom.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Mecanismul de bază: % 10 și / 10",
          "text": "În baza 10, orice număr întreg pozitiv poate fi descompus de la dreapta la stânga folosind doi operatori fundamentali:\n• `n % 10` : Extrage ultima cifră (cifra unităților)\n• `n / 10` : Elimină ultima cifră prin trunchiere întreagă",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n;\n    cout << \"Introdu numărul: \";\n    cin >> n;\n    \n    int suma = 0, nr_cifre = 0;\n    int copie = n;\n    \n    if (n == 0) {\n        nr_cifre = 1;\n    } else {\n        while (n > 0) {\n            int c = n % 10;\n            suma += c;\n            nr_cifre++;\n            n /= 10;\n        }\n    }\n    \n    cout << \"Numărul de cifre: \" << nr_cifre << \"\\n\";\n    cout << \"Suma cifrelor: \" << suma << \"\\n\";\n    return 0;\n}",
          "lang": "cpp"
        },
        {
          "heading": "2. Construirea Oglinditului (Inversului unui Număr)",
          "text": "Pentru a inversa un număr, inițializăm oglinditul cu 0. La fiecare pas înmulțim oglinditul anterior cu 10 (pentru a deplasa cifrele spre stânga) și adăugăm noua cifră extrasă.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n;\n    cin >> n;\n    \n    int copie = n;\n    int oglindit = 0;\n    \n    while (n > 0) {\n        oglindit = oglindit * 10 + (n % 10);\n        n /= 10;\n    }\n    \n    cout << \"Oglindit: \" << oglindit << \"\\n\";\n    if (copie == oglindit)\n        cout << \"Numărul este PALINDROM!\\n\";\n    else\n        cout << \"Numărul NU este palindrom.\\n\";\n        \n    return 0;\n}",
          "lang": "cpp",
          "callout": "CAPCANĂ FRECVENTĂ:\nCând procesezi un număr prin `while (n > 0)`, valoarea lui `n` devine 0 la finalul buclei! Dacă mai ai nevoie de valoarea originală (ex: pentru a o compara cu oglinditul), salveaz-o înainte într-o copie: `int copie = n;`."
        }
      ]
    },

    "alg-9-divisors": {
      "tag": "INFORMATICĂ // CLASA A 9-A // C++",
      "title": "Divizibilitate, Numere Prime & Descompunere",
      "subtitle": "Optimizarea de la algoritmul naiv O(N) la O(sqrt(N)) și ciurul lui Eratostene.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Testul optimizat de primalitate în O(√N)",
          "text": "Un număr întreg n > 1 este prim dacă nu are alți divizori în afară de 1 și el însuși. Verificarea naivă până la n este ineficientă pentru numere mari (ex: n = 10^9). Dacă un număr are un divizor d > √n, atunci are în mod obligatoriu și un divizor pereche n / d < √n. Prin urmare, este suficient să căutăm divizori până la d * d <= n.",
          "code": "#include <iostream>\nusing namespace std;\n\nbool estePrim(int n) {\n    if (n < 2) return false;\n    if (n == 2) return true;\n    if (n % 2 == 0) return false;\n    \n    for (int d = 3; d * d <= n; d += 2) {\n        if (n % d == 0) return false;\n    }\n    return true;\n}\n\nint main() {\n    int x;\n    cin >> x;\n    if (estePrim(x))\n        cout << x << \" este NUMĂR PRIM!\\n\";\n    else\n        cout << x << \" este NUMĂR COMPUS.\\n\";\n    return 0;\n}",
          "lang": "cpp"
        },
        {
          "heading": "2. Descompunerea în factori primi",
          "text": "Orice număr natural compus poate fi scris unic ca produs de puteri de numere prime. Împărțim numărul la fiecare factor prim posibil atâta timp cât se divide.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n;\n    cin >> n;\n    \n    int d = 2;\n    while (n > 1) {\n        int p = 0;\n        while (n % d == 0) {\n            p++;\n            n /= d;\n        }\n        if (p > 0) {\n            cout << d << \"^\" << p << \" \";\n        }\n        d++;\n        if (d * d > n && n > 1) {\n            // Cazul în care ce a rămas din n este prim\n            cout << n << \"^1 \";\n            break;\n        }\n    }\n    return 0;\n}",
          "lang": "cpp"
        }
      ]
    },

    // ---------------- MATEMATICĂ 9 ----------------
    "mat-9-quad": {
      "tag": "MATEMATICĂ // CLASA A 9-A // ALGEBRĂ",
      "title": "Funcția de Gradul al II-lea, Delta & Viète",
      "subtitle": "Studiul ecuației ax² + bx + c = 0, parabolei și relațiilor dintre rădăcini.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Definiție și Discriminantul Delta (Δ)",
          "text": "Fie funcția f : ℝ → ℝ, f(x) = ax² + bx + c, cu a, b, c ∈ ℝ și a ≠ 0.\n\nRezolvarea ecuației f(x) = 0 depinde exclusiv de valoarea discriminantului Δ = b² - 4ac:\n\n• Cazul 1: Dacă Δ > 0, ecuația are două rădăcini reale distincte:\n  x₁,₂ = (-b ± √Δ) / (2a)\n  Graficul funcției intersectează axa Ox în două puncte distincte.\n\n• Cazul 2: Dacă Δ = 0, ecuația are două rădăcini reale egale (rădăcină dublă):\n  x₁ = x₂ = -b / (2a)\n  Graficul funcției este tangent axei Ox.\n\n• Cazul 3: Dacă Δ < 0, ecuația nu are rădăcini reale (rădăcinile sunt complexe conjugate din ℂ \\ ℝ).\n  Graficul funcției nu atinge axa Ox (se află în întregime strict deasupra sau strict dedesubtul axei Ox).",
        },
        {
          "heading": "2. Relațiile lui Viète",
          "text": "Dacă x₁ și x₂ sunt rădăcinile ecuației ax² + bx + c = 0, atunci fără a calcula efectiv valorile rădăcinilor, avem relațiile fundamentale:\n\n• Suma rădăcinilor: S = x₁ + x₂ = -b / a\n• Produsul rădăcinilor: P = x₁ · x₂ = c / a\n\nFormarea ecuației de gradul II cunoscând suma S și produsul P:\nx² - S·x + P = 0\n\nFormule utile deduse frecvent cerute la Bacalaureat:\n• x₁² + x₂² = (x₁ + x₂)² - 2x₁x₂ = S² - 2P\n• 1/x₁ + 1/x₂ = (x₁ + x₂) / (x₁ · x₂) = S / P",
        },
        {
          "heading": "3. Coordonatele Vârfului Parabolei & Semnul Funcției",
          "text": "Graficul funcției de gradul II este o parabolă cu vârful în punctul V:\nV( -b / (2a) , -Δ / (4a) )\n\n• Dacă a > 0: ramurile parabolei sunt orientate în sus (parabolă convexă). Funcția admite un punct de MINIM în V, cu valoarea minimă y_min = -Δ / (4a).\n• Dacă a < 0: ramurile sunt orientate în jos (parabolă concavă). Funcția admite un punct de MAXIM în V, cu valoarea maximă y_max = -Δ / (4a).\n\nRegula semnelor pentru f(x):\n• În afara rădăcinilor: semnul lui a\n• Între rădăcini: semnul contrar lui a\n• Dacă Δ < 0: funcția păstrează semnul lui a pe tot domeniul ℝ.",
          "callout": "PROBLEMĂ TIPICĂ DE BACALAUREAT:\nSă se determine m ∈ ℝ astfel încât f(x) = x² - 2mx + m + 2 să fie strict pozitivă pentru orice x ∈ ℝ.\nRezolvare:\nCondiția ca f(x) > 0 ∀x ∈ ℝ impune două cerințe:\n1) a > 0 (aici a = 1 > 0, verificat)\n2) Δ < 0\nCalculăm Δ = (-2m)² - 4(1)(m + 2) = 4m² - 4m - 8 < 0.\nÎmpărțim la 4: m² - m - 2 < 0. Rădăcinile sunt m₁ = -1, m₂ = 2.\nSemnul contrar lui a impune m ∈ (-1, 2)."
        }
      ]
    },

    // ---------------- MATEMATICĂ 10 ----------------
    "mat-10-powers": {
      "tag": "MATEMATICĂ // CLASA A 10-A // ALGEBRĂ",
      "title": "Logaritmi: Definiție, Proprietăți & Ecuații",
      "subtitle": "Studiul funcției logaritmice, domeniul de existență și rezolvarea ecuațiilor pentru Bac.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Definiția Logaritmului și Condiții de Existență",
          "text": "Fie a > 0, a ≠ 1 și x > 0. Numim logaritm al numărului pozitiv x în baza a exponentul la care trebuie ridicată baza a pentru a obține x:\nlog_a(x) = y  ⟺  a^y = x\n\nCondiții de existență obligatorii la orice ecuație cu logaritmi:\n1) Baza: a > 0 și a ≠ 1\n2) Argumentul: x > 0",
        },
        {
          "heading": "2. Proprietățile Fundamentale ale Logaritmilor",
          "text": "• log_a(1) = 0 și log_a(a) = 1\n• log_a(x · y) = log_a(x) + log_a(y) (Logaritmul produsului este suma logaritmilor)\n• log_a(x / y) = log_a(x) - log_a(y) (Logaritmul raportului este diferența logaritmilor)\n• log_a(x^k) = k · log_a(x)\n• Formula de schimbare a bazei: log_a(x) = log_b(x) / log_b(a)\n• Logaritmi speciali:\n  - ln(x) reprezintă logaritmul natural (în baza e ≈ 2.718)\n  - lg(x) reprezintă logaritmul zecimal (în baza 10)",
        },
        {
          "heading": "3. Rezolvarea Ecuațiilor Logaritmice (Model de Bac)",
          "text": "Exemplu: Să se rezolve în ℝ ecuația log₂(x + 3) + log₂(x - 1) = 5.\n\nPasul 1: Condiții de existență (D.E.):\n• x + 3 > 0 ⟹ x > -3\n• x - 1 > 0 ⟹ x > 1\nIntersectând: x ∈ (1, ∞).\n\nPasul 2: Aplicăm proprietatea de adunare a logaritmilor:\nlog₂((x + 3)(x - 1)) = 5\n\nPasul 3: Trecem la forma exponențială:\n(x + 3)(x - 1) = 2^5\nx² + 2x - 3 = 32\nx² + 2x - 35 = 0\n\nPasul 4: Calculăm rădăcinile ecuației de gradul II:\nΔ = 2² - 4(1)(-35) = 4 + 140 = 144 = 12²\nx₁ = (-2 + 12) / 2 = 5\nx₂ = (-2 - 12) / 2 = -7\n\nPasul 5: Verificarea cu domeniul de existență:\n• x₁ = 5 ∈ (1, ∞) ⟹ SOLUȚIE VALIDĂ\n• x₂ = -7 ∉ (1, ∞) ⟹ SOLUȚIE REPRINSĂ\nSoluția ecuației: S = {5}.",
          "callout": "ATENȚIE MAXIMĂ LA EXAMEN:\nOmiterea stabilirii domeniului de existență (D.E.) este sancționată automat la corectură cu pierderea a 2 puncte din cele 5 alocate exercițiului!"
        }
      ]
    },

    // ---------------- MATEMATICĂ 11 ----------------
    "mat-11-determinants": {
      "tag": "MATEMATICĂ // CLASA A 11-A // ALGEBRĂ",
      "title": "Determinanți de Ordin 2 & 3: Regula lui Sarrus",
      "subtitle": "Calculul matricial, proprietățile determinanților și matrice inversabile.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Determinantul de Ordinul 2",
          "text": "Fie matricea A = [ [a, b], [c, d] ] ∈ M₂(ℝ).\nDeterminantul său este calculat prin produsul elementelor de pe diagonala principală minus produsul elementelor de pe diagonala secundară:\ndet(A) = a·d - b·c",
        },
        {
          "heading": "2. Determinantul de Ordinul 3 și Regula lui Sarrus",
          "text": "Fie matricea A ∈ M₃(ℝ). Pentru a calcula determinantul prin Regula lui Sarrus:\n1. Copiem primele două linii sub determinant.\n2. Adunăm produsele elementelor de pe cele 3 diagonale paralele cu diagonala principală.\n3. Scădem produsele elementelor de pe cele 3 diagonale paralele cu diagonala secundară.\n\ndet(A) = a₁₁a₂₂a₃₃ + a₂₁a₃₂a₁₃ + a₃₁a₁₂a₂₃ - (a₁₃a₂₂a₃₁ + a₂₃a₃₂a₁₁ + a₃₃a₁₂a₂₁)",
        },
        {
          "heading": "3. Matrice Inversabilă și Formula Inversei",
          "text": "O matrice pătratică A ∈ M_n(ℝ) este inversabilă dacă și numai dacă det(A) ≠ 0 (matrice nesingulară).\n\nFormula de calcul a inversei A⁻¹:\nA⁻¹ = (1 / det(A)) · A*\n\nUnde A* este matricea adjunctă, obținută prin transpunerea lui A (A^t) și înlocuirea fiecărui element cu complementul său algebric:\nδ_ij = (-1)^(i+j) · d_ij",
          "callout": "PROPRIETĂȚI UTILE LA CALCUL:\n• det(A · B) = det(A) · det(B)\n• det(A^t) = det(A)\n• Dacă o matrice are o linie (sau coloană) de zerouri, determinantul este 0.\n• Dacă două linii sunt egale sau proporționale, determinantul este 0."
        }
      ]
    },

    // ---------------- MATEMATICĂ 12 ----------------
    "mat-12-definite": {
      "tag": "MATEMATICĂ // CLASA A 12-A // CALCUL INTEGRAL",
      "title": "Integrala Definită: Leibniz-Newton & Integrarea prin Părți",
      "subtitle": "Calculul ariei de sub curbe, formula fundamentală și tehnici de integrare.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Formula Fundamentală Leibniz - Newton",
          "text": "Dacă f : [a, b] → ℝ este o funcție continuă și F este o primitivă a sa pe [a, b] (adică F'(x) = f(x)), atunci:\n\n∫_a^b f(x) dx = F(x) |_a^b = F(b) - F(a)\n\nInterpretare geometrică: Dacă f(x) ≥ 0 pe [a, b], valoarea integralei definite reprezintă exact aria suprafeței plane cuprinse între graficul funcției f, axa Ox și dreptele verticale x = a și x = b.",
        },
        {
          "heading": "2. Formula Integrării prin Părți",
          "text": "Dacă u, v : [a, b] → ℝ sunt funcții derivabile cu derivate continue pe [a, b], atunci:\n\n∫_a^b u(x) · v'(x) dx = (u(x) · v(x)) |_a^b - ∫_a^b u'(x) · v(x) dx\n\nStrategia de alegere a funcției u(x) conform regulii LIATE:\n1. L - Logaritmice (ln x)\n2. I - Inverse trigonometrice (arctg x, arcsin x)\n3. A - Algebrice / Polinoame (x, x² + 1)\n4. T - Trigonometrice (sin x, cos x)\n5. E - Exponențiale (e^x)",
        },
        {
          "heading": "3. Aplicație practică pas cu pas (Model Bac Subiectul III.2)",
          "text": "Să se calculeze integrala I = ∫_1^e x · ln(x) dx.\n\nAlegem funcțiile conform regulii LIATE:\n• u(x) = ln(x) ⟹ u'(x) = 1/x\n• v'(x) = x    ⟹ v(x) = x² / 2\n\nAplicăm formula integrării prin părți:\nI = (ln(x) · x² / 2) |_1^e - ∫_1^e (1/x · x² / 2) dx\nI = (ln(e) · e² / 2 - ln(1) · 1² / 2) - 1/2 · ∫_1^e x dx\n\nȘtiind că ln(e) = 1 și ln(1) = 0:\nI = e² / 2 - 1/2 · (x² / 2) |_1^e\nI = e² / 2 - 1/4 · (e² - 1)\nI = 2e² / 4 - (e² - 1) / 4\nI = (e² + 1) / 4.",
          "callout": "PRO-TIP BACALAUREAT:\nVerifică întotdeauna dacă integrala din dreapta este mai simplă decât cea inițială! Dacă devine mai complicată, înseamnă că ai ales greșit funcția u(x)."
        }
      ]
    },

    // =========================================================================
    // LECȚII COMPLETATE (toate clasele)
    // =========================================================================
    "py-9-operators": {
      "tag": "INFORMATICĂ // CLASA A 9-A // PYTHON",
      "title": "Operatori Aritmetici & Logici în Python",
      "subtitle": "Împărțirea întreagă, restul, puterea și cum se evaluează o expresie cu and, or, not.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Operatorii aritmetici",
          "text": "Python are șapte operatori aritmetici. Primii trei (`+`, `-`, `*`) se comportă ca la matematică. Ceilalți patru trebuie înțeleși bine, pentru că apar în aproape orice problemă:\n\n• `/` : împărțire reală. Rezultatul este întotdeauna de tip float, chiar dacă împărțirea este exactă: `8 / 2` dă `4.0`.\n• `//` : împărțire întreagă (câtul). `17 // 5` dă `3`.\n• `%` : restul împărțirii. `17 % 5` dă `2`.\n• `**` : ridicare la putere. `2 ** 10` dă `1024`.\n\nCâtul și restul sunt legate prin teorema împărțirii cu rest: `a == (a // b) * b + a % b`.",
          "code": "a = 17\nb = 5\n\nprint(a / b)    # 3.4\nprint(a // b)   # 3\nprint(a % b)    # 2\nprint(a ** 2)   # 289\n\n# Ultima cifră și numărul fără ultima cifră:\nn = 2749\nprint(n % 10)   # 9\nprint(n // 10)  # 274",
          "lang": "python",
        },
        {
          "heading": "2. Operatorii de comparare și cei logici",
          "text": "Operatorii de comparare (`==`, `!=`, `<`, `<=`, `>`, `>=`) produc o valoare de tip bool: `True` sau `False`.\n\nCondițiile simple se leagă între ele cu operatorii logici:\n• `and` : adevărat doar dacă ambele condiții sunt adevărate.\n• `or` : adevărat dacă cel puțin una dintre condiții este adevărată.\n• `not` : inversează valoarea de adevăr.\n\nPython permite și comparații înlănțuite, exact ca la matematică: `1 <= x <= 10` înseamnă `1 <= x and x <= 10`.",
          "code": "an = 2024\n\n# Un an este bisect dacă se împarte la 4 dar nu la 100,\n# sau dacă se împarte la 400.\nbisect = (an % 4 == 0 and an % 100 != 0) or (an % 400 == 0)\nprint(bisect)           # True\n\nx = 7\nprint(1 <= x <= 10)     # True\nprint(not (x % 2 == 0)) # True, pentru că 7 este impar",
          "lang": "python",
        },
        {
          "heading": "3. Ordinea operațiilor",
          "text": "Când o expresie conține mai mulți operatori, Python îi aplică în această ordine (de la cel mai puternic la cel mai slab):\n\n1. Parantezele `( )`\n2. Puterea `**`\n3. Înmulțirea și împărțirile `*`, `/`, `//`, `%`\n4. Adunarea și scăderea `+`, `-`\n5. Comparațiile `==`, `!=`, `<`, `>`, `<=`, `>=`\n6. `not`\n7. `and`\n8. `or`\n\nOperatorii de pe același nivel se aplică de la stânga la dreapta. Excepție face puterea, care se aplică de la dreapta la stânga: `2 ** 3 ** 2` înseamnă `2 ** 9`, adică `512`.",
          "code": "print(2 + 3 * 4)        # 14\nprint((2 + 3) * 4)      # 20\nprint(10 - 4 - 3)       # 3, de la stânga la dreapta\nprint(2 ** 3 ** 2)      # 512\nprint(7 // 2 * 2)       # 6, nu 7\nprint(True or False and False)  # True: and se evaluează înaintea lui or",
          "lang": "python",
          "callout": "CAPCANĂ CU NUMERE NEGATIVE:\nÎn Python, `//` rotunjește în jos, spre minus infinit, nu spre zero. De aceea `-7 // 2` este `-4` (nu `-3`), iar `-7 % 2` este `1`. În C++, aceleași operații dau `-3` și `-1`. Dacă treci o soluție dintr-un limbaj în altul, verifică ce se întâmplă cu valorile negative.",
        },
      ]
    },

    "py-9-if": {
      "tag": "INFORMATICĂ // CLASA A 9-A // PYTHON",
      "title": "Instrucțiunea Decizională: if, elif, else",
      "subtitle": "Cum alege programul ce are de făcut în funcție de o condiție.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Forma generală",
          "text": "Instrucțiunea `if` execută un bloc de cod doar dacă o condiție este adevărată. Ramura `else` este opțională și se execută când condiția este falsă.\n\nDouă reguli de sintaxă:\n• După condiție și după `else` se pune două puncte `:`.\n• Instrucțiunile care țin de o ramură se scriu indentat, cu 4 spații. Indentarea este cea care îi spune lui Python unde începe și unde se termină blocul.",
          "code": "n = int(input())\n\nif n % 2 == 0:\n    print(\"PAR\")\nelse:\n    print(\"IMPAR\")\n\nprint(\"Gata\")   # nu e indentat, deci se execută oricum",
          "lang": "python",
        },
        {
          "heading": "2. Mai multe cazuri: elif",
          "text": "Când sunt mai mult de două cazuri, se folosește `elif` (prescurtare de la „else if”). Python verifică pe rând condițiile, de sus în jos, și execută doar prima ramură a cărei condiție este adevărată. Restul sunt sărite.\n\nDin acest motiv ordinea condițiilor contează. În exemplul de mai jos, când se ajunge la `elif nota >= 7` știm deja că nota este mai mică decât 9, deci nu mai trebuie scris `7 <= nota < 9`.",
          "code": "nota = float(input())\n\nif nota >= 9:\n    calificativ = \"Foarte bine\"\nelif nota >= 7:\n    calificativ = \"Bine\"\nelif nota >= 5:\n    calificativ = \"Suficient\"\nelse:\n    calificativ = \"Insuficient\"\n\nprint(calificativ)",
          "lang": "python",
        },
        {
          "heading": "3. Condiții compuse și if-uri imbricate",
          "text": "O ramură poate conține la rândul ei alt `if`. De multe ori însă, două if-uri imbricate se pot scrie mai clar ca o singură condiție compusă cu `and`.\n\nExemplul verifică dacă trei numere pot fi laturile unui triunghi: fiecare trebuie să fie strict mai mică decât suma celorlalte două.",
          "code": "a = float(input())\nb = float(input())\nc = float(input())\n\nif a < b + c and b < a + c and c < a + b:\n    if a == b and b == c:\n        print(\"Triunghi echilateral\")\n    elif a == b or b == c or a == c:\n        print(\"Triunghi isoscel\")\n    else:\n        print(\"Triunghi oarecare\")\nelse:\n    print(\"Nu este triunghi\")",
          "lang": "python",
          "callout": "EROARE FRECVENTĂ:\n`=` este atribuire, `==` este comparare. Dacă scrii `if x = 5:` Python se oprește cu SyntaxError. A doua greșeală des întâlnită este uitarea celor două puncte de la sfârșitul liniei cu `if`, `elif` sau `else`.",
        },
      ]
    },

    "cpp-9-intro": {
      "tag": "INFORMATICĂ // CLASA A 9-A // C++",
      "title": "Directiva #include, iostream & cin/cout",
      "subtitle": "Din ce este alcătuit un program C++ și cum citește și afișează date.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Structura unui program",
          "text": "Orice program C++ are aceleași piese de bază:\n\n• `#include <iostream>` : directivă de preprocesare. Aduce în program biblioteca de citire și afișare.\n• `using namespace std;` : ne lasă să scriem `cout` în loc de `std::cout`.\n• `int main()` : funcția principală. De aici începe execuția.\n• `{ }` : acoladele delimitează un bloc de instrucțiuni.\n• `return 0;` : programul anunță sistemul de operare că s-a încheiat fără erori.\n\nFiecare instrucțiune se termină cu punct și virgulă. Spre deosebire de Python, indentarea nu are efect asupra programului, dar o păstrăm pentru că face codul ușor de citit.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    cout << \"Salut, lume!\";\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Afișarea cu cout",
          "text": "`cout` trimite date către ecran prin operatorul `<<`. Într-o singură instrucțiune se pot înlănțui mai multe valori: texte, numere, variabile.\n\nPentru a trece pe rând nou se folosește caracterul `'\\n'` sau `endl`. `'\\n'` este mai rapid, de aceea îl vei vedea în soluțiile de la concursuri.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int varsta = 15;\n    cout << \"Am \" << varsta << \" ani.\" << '\\n';\n    cout << \"Peste 3 ani voi avea \" << varsta + 3 << \" ani.\\n\";\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Citirea cu cin",
          "text": "`cin` citește de la tastatură prin operatorul `>>`. Valorile pot fi separate prin spații sau prin Enter, `cin` le sare automat.\n\nÎnainte să citim o valoare trebuie să declarăm variabila în care o păstrăm, împreună cu tipul ei.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int a, b;\n    cin >> a >> b;\n\n    cout << \"Suma: \" << a + b << '\\n';\n    cout << \"Produsul: \" << a * b << '\\n';\n    return 0;\n}",
          "lang": "cpp",
          "callout": "EROARE FRECVENTĂ:\nSăgețile arată încotro merg datele. La `cout << x` valoarea pleacă din x către ecran. La `cin >> x` valoarea vine de la tastatură către x. Dacă le inversezi (`cin << x`), programul nu se compilează.",
        },
      ]
    },

    "cpp-9-types": {
      "tag": "INFORMATICĂ // CLASA A 9-A // C++",
      "title": "Tipuri de Date, Operatori & Codul ASCII",
      "subtitle": "Ce valori încap în fiecare tip, cum se face împărțirea și ce legătură au literele cu numerele.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Tipurile de bază",
          "text": "În C++ fiecare variabilă are un tip, stabilit la declarare, care nu se mai schimbă:\n\n• `int` : numere întregi, aproximativ între -2 miliarde și 2 miliarde (-2³¹ ... 2³¹ - 1).\n• `long long` : numere întregi mari, până la aproximativ 9 · 10¹⁸.\n• `double` : numere reale, cu aproximativ 15 cifre semnificative.\n• `char` : un singur caracter, scris între apostrofuri: `'a'`.\n• `bool` : `true` sau `false`.\n\nDacă un calcul depășește limita tipului, rezultatul este greșit, fără niciun mesaj de eroare. Fenomenul se numește overflow (depășire).",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int a = 100000, b = 100000;\n\n    long long gresit = a * b;             // înmulțirea se face pe int: depășire\n    long long corect = 1LL * a * b;       // 1LL forțează calculul pe long long\n\n    cout << corect << '\\n';               // 10000000000\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Împărțirea întreagă și restul",
          "text": "Operatorul `/` se comportă diferit în funcție de tipul operanzilor:\n• dacă ambii sunt întregi, rezultatul este câtul întreg: `7 / 2` este `3`;\n• dacă măcar unul este real, rezultatul este real: `7 / 2.0` este `3.5`.\n\nOperatorul `%` dă restul împărțirii și funcționează doar pe numere întregi.\n\nPentru a obține un rezultat real din două variabile întregi, una dintre ele se convertește explicit: `(double)a / b`.",
          "code": "#include <iostream>\n#include <iomanip>\nusing namespace std;\n\nint main() {\n    int a = 7, b = 2;\n\n    cout << a / b << '\\n';             // 3\n    cout << a % b << '\\n';             // 1\n    cout << (double)a / b << '\\n';     // 3.5\n\n    // Afișare cu exact două zecimale:\n    cout << fixed << setprecision(2) << 10 / 3.0 << '\\n';   // 3.33\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Tipul char și codul ASCII",
          "text": "În memorie, un caracter este de fapt un număr: codul său ASCII. Câteva valori merită reținute:\n\n• `'0'` are codul 48, iar cifrele sunt consecutive până la `'9'` (57).\n• `'A'` are codul 65, literele mari sunt consecutive până la `'Z'` (90).\n• `'a'` are codul 97, literele mici sunt consecutive până la `'z'` (122).\n\nPentru că sunt numere, cu caracterele se pot face calcule. Diferența dintre o literă mică și litera mare corespunzătoare este mereu 32.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    char c = 'd';\n\n    cout << (int)c << '\\n';            // 100, codul ASCII al lui 'd'\n    cout << (char)(c - 32) << '\\n';    // D, litera mare\n    cout << c - 'a' << '\\n';           // 3, poziția în alfabet (a = 0)\n\n    char cifra = '7';\n    int valoare = cifra - '0';         // 7, valoarea numerică a cifrei\n    cout << valoare * 2 << '\\n';       // 14\n    return 0;\n}",
          "lang": "cpp",
          "callout": "CAPCANĂ LA MEDII:\n`int a = 7, b = 8; double m = (a + b) / 2;` pune în m valoarea 7, nu 7.5. Împărțirea se face între două numere întregi, iar zecimalele se pierd înainte ca rezultatul să ajungă în variabila reală. Scrie `(a + b) / 2.0`.",
        },
      ]
    },

    "cpp-9-if-switch": {
      "tag": "INFORMATICĂ // CLASA A 9-A // C++",
      "title": "Instrucțiunile if-else și switch",
      "subtitle": "Decizia în C++: condiții, blocuri cu acolade și alegerea dintr-o listă de cazuri.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Instrucțiunea if-else",
          "text": "Forma generală este `if (conditie) instructiune1; else instructiune2;`. Condiția se scrie obligatoriu între paranteze rotunde.\n\nDacă pe o ramură trebuie executate mai multe instrucțiuni, ele se grupează între acolade. Fără acolade, de ramură ține doar prima instrucțiune.\n\nOperatorii logici se scriu altfel decât în Python:\n• `&&` : și\n• `||` : sau\n• `!` : negație",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int a, b;\n    cin >> a >> b;\n\n    if (a > b) {\n        cout << \"Maximul este \" << a << '\\n';\n    } else if (a < b) {\n        cout << \"Maximul este \" << b << '\\n';\n    } else {\n        cout << \"Numerele sunt egale\\n\";\n    }\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Condiții compuse",
          "text": "Mai multe condiții simple se combină cu `&&` și `||`. Operatorul `&&` are prioritate față de `||`, așa că este bine să pui paranteze ori de câte ori apar amândoi în aceeași expresie.\n\nC++ evaluează condițiile compuse „prin scurtcircuit”: la `A && B`, dacă A este fals, B nu mai este evaluat deloc. Asta permite scrieri de forma `if (b != 0 && a % b == 0)`, în care împărțirea nu se mai face atunci când b este zero.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int an;\n    cin >> an;\n\n    if ((an % 4 == 0 && an % 100 != 0) || an % 400 == 0)\n        cout << \"An bisect\";\n    else\n        cout << \"An obisnuit\";\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Instrucțiunea switch",
          "text": "Când o variabilă întreagă sau de tip char trebuie comparată cu o listă de valori fixe, `switch` este mai clar decât un lanț de if-uri.\n\nExecuția sare la eticheta `case` care se potrivește și continuă de acolo în jos până la primul `break`. Ramura `default` se execută când nu se potrivește niciun caz.\n\nMai multe etichete pot fi puse una sub alta pentru a trata la fel mai multe valori.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int luna;\n    cin >> luna;\n\n    switch (luna) {\n        case 2:\n            cout << \"28 sau 29 de zile\";\n            break;\n        case 4:\n        case 6:\n        case 9:\n        case 11:\n            cout << \"30 de zile\";\n            break;\n        default:\n            cout << \"31 de zile\";\n    }\n    return 0;\n}",
          "lang": "cpp",
          "callout": "CAPCANE CLASICE:\n1) `if (x = 5)` nu compară, ci îi atribuie lui x valoarea 5, iar condiția devine mereu adevărată. Compararea se scrie `x == 5`.\n2) Dacă uiți `break` la sfârșitul unui `case`, execuția „cade” în cazul următor și se execută și instrucțiunile lui.",
        },
      ]
    },

    "cpp-9-loops": {
      "tag": "INFORMATICĂ // CLASA A 9-A // C++",
      "title": "Buclele while, do-while și for în C++",
      "subtitle": "Cele trei instrucțiuni repetitive, când o alegi pe fiecare și cum ieși dintr-o buclă.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. while: test la început",
          "text": "`while (conditie) { ... }` verifică întâi condiția. Dacă este adevărată, execută blocul și apoi verifică din nou. Dacă este falsă de la început, blocul nu se execută niciodată.\n\nSe folosește când nu știm dinainte câți pași vor fi. Exemplul clasic este prelucrarea cifrelor unui număr: repetăm cât timp numărul mai are cifre.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n;\n    cin >> n;\n\n    int nrCifre = 0;\n    while (n > 0) {\n        nrCifre++;\n        n /= 10;\n    }\n    cout << nrCifre;\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. do-while: test la sfârșit",
          "text": "`do { ... } while (conditie);` execută întâi blocul și abia apoi verifică condiția. Blocul se execută deci cel puțin o dată.\n\nProgramul de mai sus afișează 0 pentru n = 0, deși numărul 0 are o cifră. Varianta cu `do-while` rezolvă cazul fără niciun if în plus.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n;\n    cin >> n;\n\n    int nrCifre = 0;\n    do {\n        nrCifre++;\n        n /= 10;\n    } while (n > 0);\n\n    cout << nrCifre;      // pentru n = 0 afișează 1\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. for: număr cunoscut de pași",
          "text": "`for (initializare; conditie; pas)` adună într-o singură linie cele trei lucruri de care are nevoie un contor: valoarea de pornire, condiția de continuare și modificarea de la sfârșitul fiecărui pas.\n\nOrdinea de execuție este: inițializarea (o singură dată), apoi condiția, blocul, pasul, din nou condiția și tot așa.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n;\n    cin >> n;\n\n    long long suma = 0;\n    for (int i = 1; i <= n; i++) {\n        suma += i;\n    }\n    cout << suma << '\\n';\n\n    // Numărătoare inversă, din 2 în 2:\n    for (int i = 10; i >= 0; i -= 2)\n        cout << i << ' ';\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "4. break și continue",
          "text": "• `break` oprește bucla pe loc. Execuția continuă cu prima instrucțiune de după buclă.\n• `continue` sare peste restul pasului curent și trece direct la pasul următor.\n\nExemplul caută cel mai mic divizor mai mare decât 1 al unui număr. După ce l-a găsit, nu mai are rost să continue căutarea.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n;\n    cin >> n;\n\n    int divizor = n;\n    for (int d = 2; d * d <= n; d++) {\n        if (n % d == 0) {\n            divizor = d;\n            break;\n        }\n    }\n    cout << divizor;\n    return 0;\n}",
          "lang": "cpp",
          "callout": "ATENȚIE LA BUCLELE INFINITE:\nO buclă se termină doar dacă ceva din interiorul ei schimbă condiția. Dacă într-un `while (n > 0)` uiți instrucțiunea `n /= 10;`, programul nu se mai oprește. Aceeași problemă apare când pui din greșeală punct și virgulă imediat după paranteză: `while (n > 0);`.",
        },
      ]
    },

    "alg-9-gcd": {
      "tag": "INFORMATICĂ // CLASA A 9-A // C++",
      "title": "CMMDC & Algoritmul lui Euclid",
      "subtitle": "Cel mai mare divizor comun prin scăderi și prin împărțiri, plus calculul CMMMC.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Algoritmul prin scăderi repetate",
          "text": "Cel mai mare divizor comun (CMMDC) al numerelor a și b este cel mai mare număr care le divide pe amândouă.\n\nVarianta prin scăderi se bazează pe observația că orice divizor comun al lui a și b îl divide și pe a - b. Cât timp numerele sunt diferite, îl scădem pe cel mic din cel mare. Când devin egale, acea valoare este CMMDC.\n\nExemplu pentru 24 și 18: (24, 18) → (6, 18) → (6, 12) → (6, 6). CMMDC este 6.\n\nAlgoritmul cere ca ambele numere să fie nenule și devine foarte lent când unul este mult mai mare decât celălalt.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int a, b;\n    cin >> a >> b;\n\n    while (a != b) {\n        if (a > b) a -= b;\n        else b -= a;\n    }\n    cout << a;\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Algoritmul lui Euclid prin împărțiri",
          "text": "Mai multe scăderi consecutive ale aceluiași număr înseamnă de fapt un rest. De aici vine varianta rapidă:\n\nCMMDC(a, b) = CMMDC(b, a % b), iar CMMDC(a, 0) = a.\n\nLa fiecare pas, perechea (a, b) devine (b, a % b). Ne oprim când b ajunge 0, iar răspunsul este a.\n\nExemplu pentru 1071 și 462: (1071, 462) → (462, 147) → (147, 21) → (21, 0). CMMDC este 21.\n\nNumărul de pași este proporțional cu numărul de cifre, deci algoritmul merge instantaneu și pentru valori de ordinul 10¹⁸.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    long long a, b;\n    cin >> a >> b;\n\n    while (b != 0) {\n        long long r = a % b;\n        a = b;\n        b = r;\n    }\n    cout << a;\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Cel mai mic multiplu comun",
          "text": "Între CMMDC și CMMMC există relația:\n\nCMMDC(a, b) · CMMMC(a, b) = a · b\n\nPrin urmare CMMMC(a, b) = a · b / CMMDC(a, b). Cum algoritmul lui Euclid modifică variabilele a și b, valorile inițiale trebuie păstrate în copii.\n\nDouă numere al căror CMMDC este 1 se numesc prime între ele (de exemplu 8 și 15).",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    long long a, b;\n    cin >> a >> b;\n\n    long long x = a, y = b;\n    while (y != 0) {\n        long long r = x % y;\n        x = y;\n        y = r;\n    }\n    // x este acum CMMDC(a, b)\n    cout << a / x * b;\n    return 0;\n}",
          "lang": "cpp",
          "callout": "SFAT PENTRU CMMMC:\nScrie `a / cmmdc * b`, nu `a * b / cmmdc`. Rezultatul este același, dar în prima variantă împărțirea se face înaintea înmulțirii, iar valorile intermediare rămân mici. În a doua, produsul `a * b` poate depăși limita tipului chiar dacă răspunsul final ar fi încăput.",
        },
      ]
    },

    "cpp-9-vectors-basic": {
      "tag": "INFORMATICĂ // CLASA A 9-A // C++",
      "title": "Vectori în C++: Declarare, Citire & Parcurgere",
      "subtitle": "Cum păstrăm mai multe valori de același tip și cum le prelucrăm una câte una.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Declarare, citire și afișare",
          "text": "Un vector (tablou unidimensional) păstrează mai multe valori de același tip sub un singur nume. Fiecare element se accesează prin poziția sa, numită indice: `v[i]`.\n\nLa declararea `int v[100];` se rezervă 100 de elemente, cu indici de la 0 la 99. Dimensiunea se alege după valoarea maximă a lui n din enunț, la care se adaugă câteva poziții de rezervă.\n\nUn vector se citește și se afișează element cu element, cu o buclă `for`.",
          "code": "#include <iostream>\nusing namespace std;\n\nint v[1005];\n\nint main() {\n    int n;\n    cin >> n;\n    for (int i = 0; i < n; i++)\n        cin >> v[i];\n\n    for (int i = 0; i < n; i++)\n        cout << v[i] << ' ';\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Sumă, minim și maxim",
          "text": "Majoritatea prelucrărilor urmează același tipar: o variabilă care ține rezultatul și o parcurgere care o actualizează la fiecare element.\n\n• Pentru sumă, variabila pornește de la 0.\n• Pentru minim și maxim, variabilele pornesc de la primul element, `v[0]`. Dacă le-am inițializa cu 0, rezultatul ar fi greșit pentru un vector care conține doar numere negative.",
          "code": "#include <iostream>\nusing namespace std;\n\nint v[1005];\n\nint main() {\n    int n;\n    cin >> n;\n    for (int i = 0; i < n; i++) cin >> v[i];\n\n    long long suma = 0;\n    int minim = v[0], maxim = v[0];\n    for (int i = 0; i < n; i++) {\n        suma += v[i];\n        if (v[i] < minim) minim = v[i];\n        if (v[i] > maxim) maxim = v[i];\n    }\n\n    cout << suma << ' ' << minim << ' ' << maxim;\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Inversarea elementelor",
          "text": "Pentru a inversa ordinea elementelor fără un al doilea vector, interschimbăm primul element cu ultimul, al doilea cu penultimul și așa mai departe.\n\nFolosim doi indici: `i` pornește de la început, `j` de la sfârșit, și se apropie unul de celălalt. Ne oprim când se întâlnesc. Dacă am merge până la capăt, fiecare pereche ar fi interschimbată de două ori și vectorul ar reveni la forma inițială.",
          "code": "#include <iostream>\nusing namespace std;\n\nint v[1005];\n\nint main() {\n    int n;\n    cin >> n;\n    for (int i = 0; i < n; i++) cin >> v[i];\n\n    int i = 0, j = n - 1;\n    while (i < j) {\n        int aux = v[i];\n        v[i] = v[j];\n        v[j] = aux;\n        i++;\n        j--;\n    }\n\n    for (int k = 0; k < n; k++) cout << v[k] << ' ';\n    return 0;\n}",
          "lang": "cpp",
          "callout": "ATENȚIE LA INDICI:\nÎntr-un vector declarat cu n elemente, ultimul indice valid este n - 1. C++ nu verifică indicii: dacă scrii `v[n]` sau `v[-1]`, programul citește sau modifică o altă zonă de memorie, fără niciun mesaj de eroare. De cele mai multe ori greșeala vine dintr-un `<=` pus în loc de `<` în condiția buclei.",
        },
      ]
    },

    "cpp-9-vectors-sort": {
      "tag": "INFORMATICĂ // CLASA A 9-A // C++",
      "title": "Sortarea Vectorilor: BubbleSort & Selecție",
      "subtitle": "Două metode de sortare în O(n²) și căutarea binară, care profită de un vector deja ordonat.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Sortarea prin selecție",
          "text": "Ideea: pe prima poziție trebuie să ajungă cel mai mic element, pe a doua următorul ca mărime și tot așa.\n\nPentru fiecare poziție `i`, căutăm poziția minimului dintre elementele rămase (de la `i` la `n - 1`) și îl interschimbăm cu `v[i]`.\n\nAlgoritmul face aproximativ n² / 2 comparații, indiferent de cum arată vectorul la început. Spunem că are complexitatea O(n²).",
          "code": "#include <iostream>\nusing namespace std;\n\nint v[1005];\n\nint main() {\n    int n;\n    cin >> n;\n    for (int i = 0; i < n; i++) cin >> v[i];\n\n    for (int i = 0; i < n - 1; i++) {\n        int pmin = i;\n        for (int j = i + 1; j < n; j++)\n            if (v[j] < v[pmin]) pmin = j;\n\n        int aux = v[i];\n        v[i] = v[pmin];\n        v[pmin] = aux;\n    }\n\n    for (int i = 0; i < n; i++) cout << v[i] << ' ';\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Sortarea prin metoda bulelor (BubbleSort)",
          "text": "Ideea: parcurgem vectorul și comparăm fiecare element cu vecinul său din dreapta. Dacă sunt în ordine greșită, le interschimbăm. După o parcurgere, cel mai mare element a ajuns pe ultima poziție.\n\nRepetăm parcurgerile cât timp s-a făcut cel puțin o interschimbare. Când o parcurgere întreagă trece fără nicio interschimbare, vectorul este sortat.\n\nÎn cazul cel mai rău (vector ordonat descrescător) complexitatea este O(n²). Pe un vector deja sortat, algoritmul se oprește după o singură parcurgere.",
          "code": "#include <iostream>\nusing namespace std;\n\nint v[1005];\n\nint main() {\n    int n;\n    cin >> n;\n    for (int i = 0; i < n; i++) cin >> v[i];\n\n    bool schimbat = true;\n    while (schimbat) {\n        schimbat = false;\n        for (int i = 0; i < n - 1; i++) {\n            if (v[i] > v[i + 1]) {\n                int aux = v[i];\n                v[i] = v[i + 1];\n                v[i + 1] = aux;\n                schimbat = true;\n            }\n        }\n    }\n\n    for (int i = 0; i < n; i++) cout << v[i] << ' ';\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Căutarea binară",
          "text": "Într-un vector sortat, o valoare se poate găsi mult mai repede decât prin parcurgere element cu element.\n\nComparăm valoarea căutată x cu elementul din mijloc:\n• dacă sunt egale, am găsit-o;\n• dacă x este mai mic, continuăm doar în jumătatea stângă;\n• dacă x este mai mare, continuăm doar în jumătatea dreaptă.\n\nLa fiecare pas, zona de căutare se înjumătățește. Pentru un vector cu un milion de elemente sunt suficienți 20 de pași. Complexitatea este O(log n).",
          "code": "#include <iostream>\nusing namespace std;\n\nint v[100005];\n\nint main() {\n    int n, x;\n    cin >> n;\n    for (int i = 0; i < n; i++) cin >> v[i];   // vectorul este sortat crescător\n    cin >> x;\n\n    int st = 0, dr = n - 1, poz = -1;\n    while (st <= dr) {\n        int m = st + (dr - st) / 2;\n        if (v[m] == x) {\n            poz = m;\n            break;\n        }\n        if (v[m] < x) st = m + 1;\n        else dr = m - 1;\n    }\n\n    if (poz == -1) cout << \"NU\";\n    else cout << poz;\n    return 0;\n}",
          "lang": "cpp",
          "callout": "ATENȚIE:\nCăutarea binară dă rezultate corecte doar pe un vector sortat. Pe un vector nesortat poate răspunde „NU” chiar dacă valoarea există. Dacă datele nu vin ordonate, sortează-le întâi sau folosește căutarea liniară.",
        },
      ]
    },

    "cpp-10-matrix-basics": {
      "tag": "INFORMATICĂ // CLASA A 10-A // C++",
      "title": "Matrice în C++: Declarare & Parcurgere",
      "subtitle": "Tablouri cu linii și coloane: citire, parcurgere pe linii, pe coloane și pe contur.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Declarare și citire",
          "text": "O matrice (tablou bidimensional) este un tabel cu n linii și m coloane. Un element se accesează prin doi indici: `a[i][j]` este elementul de pe linia i și coloana j.\n\nLa declararea `int a[105][105];` primul număr este numărul maxim de linii, al doilea numărul maxim de coloane.\n\nParcurgerea se face cu două bucle `for` imbricate: cea din exterior alege linia, cea din interior coloana. În lecțiile despre matrice vom numerota liniile și coloanele de la 1, pentru că așa apar în enunțurile de Bacalaureat.",
          "code": "#include <iostream>\nusing namespace std;\n\nint a[105][105];\n\nint main() {\n    int n, m;\n    cin >> n >> m;\n    for (int i = 1; i <= n; i++)\n        for (int j = 1; j <= m; j++)\n            cin >> a[i][j];\n\n    for (int i = 1; i <= n; i++) {\n        for (int j = 1; j <= m; j++)\n            cout << a[i][j] << ' ';\n        cout << '\\n';\n    }\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Prelucrări pe linii și pe coloane",
          "text": "Pentru o prelucrare pe linii, bucla exterioară merge după `i`, iar rezultatul (suma, maximul) se resetează la începutul fiecărei linii.\n\nPentru o prelucrare pe coloane, cele două bucle își schimbă locul: în exterior stă `j`, în interior `i`. Elementul se scrie tot `a[i][j]`.",
          "code": "#include <iostream>\nusing namespace std;\n\nint a[105][105];\n\nint main() {\n    int n, m;\n    cin >> n >> m;\n    for (int i = 1; i <= n; i++)\n        for (int j = 1; j <= m; j++)\n            cin >> a[i][j];\n\n    // Suma fiecărei linii:\n    for (int i = 1; i <= n; i++) {\n        int s = 0;\n        for (int j = 1; j <= m; j++) s += a[i][j];\n        cout << \"Linia \" << i << \": \" << s << '\\n';\n    }\n\n    // Maximul fiecărei coloane:\n    for (int j = 1; j <= m; j++) {\n        int mx = a[1][j];\n        for (int i = 2; i <= n; i++)\n            if (a[i][j] > mx) mx = a[i][j];\n        cout << \"Coloana \" << j << \": \" << mx << '\\n';\n    }\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Parcurgerea conturului",
          "text": "Conturul (chenarul) matricei este format din prima linie, ultima linie, prima coloană și ultima coloană.\n\nUn element `a[i][j]` se află pe contur dacă `i == 1` sau `i == n` sau `j == 1` sau `j == m`. Cea mai simplă soluție parcurge toată matricea și testează această condiție. Fiecare element de pe contur este numărat o singură dată, inclusiv colțurile.",
          "code": "#include <iostream>\nusing namespace std;\n\nint a[105][105];\n\nint main() {\n    int n, m;\n    cin >> n >> m;\n    for (int i = 1; i <= n; i++)\n        for (int j = 1; j <= m; j++)\n            cin >> a[i][j];\n\n    long long suma = 0;\n    for (int i = 1; i <= n; i++)\n        for (int j = 1; j <= m; j++)\n            if (i == 1 || i == n || j == 1 || j == m)\n                suma += a[i][j];\n\n    cout << suma;\n    return 0;\n}",
          "lang": "cpp",
          "callout": "EROARE FRECVENTĂ:\nIndicii inversați. `a[i][j]` înseamnă întotdeauna linia i, coloana j. Într-o matrice cu n linii și m coloane, i merge până la n, iar j până la m. Dacă le încurci și matricea nu este pătratică, citești elemente care nu există.",
        },
      ]
    },

    "cpp-10-matrix-diagonals": {
      "tag": "INFORMATICĂ // CLASA A 10-A // C++",
      "title": "Diagonala Principală, Secundară & Zone Speciale",
      "subtitle": "Relațiile dintre indici care descriu diagonalele unei matrice pătratice și zonele dintre ele.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Cele două diagonale",
          "text": "Într-o matrice pătratică de ordin n (n linii și n coloane), cu indici de la 1:\n\n• Diagonala principală merge din colțul stânga-sus în colțul dreapta-jos. Elementele ei au `i == j`.\n• Diagonala secundară merge din colțul dreapta-sus în colțul stânga-jos. Elementele ei au `i + j == n + 1`.\n\nPentru că pe fiecare linie există un singur element din fiecare diagonală, ele se pot parcurge cu o singură buclă: `a[i][i]`, respectiv `a[i][n + 1 - i]`.\n\nDacă indicii pornesc de la 0, condiția pentru diagonala secundară devine `i + j == n - 1`.",
          "code": "#include <iostream>\nusing namespace std;\n\nint a[105][105];\n\nint main() {\n    int n;\n    cin >> n;\n    for (int i = 1; i <= n; i++)\n        for (int j = 1; j <= n; j++)\n            cin >> a[i][j];\n\n    int sumaP = 0, sumaS = 0;\n    for (int i = 1; i <= n; i++) {\n        sumaP += a[i][i];\n        sumaS += a[i][n + 1 - i];\n    }\n\n    cout << sumaP << ' ' << sumaS;\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Deasupra și dedesubtul diagonalelor",
          "text": "Fiecare diagonală împarte matricea în două triunghiuri:\n\n• deasupra diagonalei principale: `i < j`\n• sub diagonala principală: `i > j`\n• deasupra diagonalei secundare: `i + j < n + 1`\n• sub diagonala secundară: `i + j > n + 1`\n\nTriunghiul de deasupra diagonalei principale se poate parcurge și direct, fără if, pornind bucla interioară de la `i + 1`.",
          "code": "#include <iostream>\nusing namespace std;\n\nint a[105][105];\n\nint main() {\n    int n;\n    cin >> n;\n    for (int i = 1; i <= n; i++)\n        for (int j = 1; j <= n; j++)\n            cin >> a[i][j];\n\n    // Matricea este simetrică dacă a[i][j] == a[j][i] pentru orice i < j.\n    bool simetrica = true;\n    for (int i = 1; i <= n; i++)\n        for (int j = i + 1; j <= n; j++)\n            if (a[i][j] != a[j][i]) simetrica = false;\n\n    cout << (simetrica ? \"DA\" : \"NU\");\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Zonele Nord, Est, Sud, Vest",
          "text": "Cele două diagonale, luate împreună, împart matricea în patru zone triunghiulare. Fiecare zonă se descrie prin două condiții:\n\n• Nord: `i < j` și `i + j < n + 1`\n• Est: `i < j` și `i + j > n + 1`\n• Sud: `i > j` și `i + j > n + 1`\n• Vest: `i > j` și `i + j < n + 1`\n\nElementele de pe diagonale nu aparțin niciunei zone.",
          "code": "#include <iostream>\nusing namespace std;\n\nint a[105][105];\n\nint main() {\n    int n;\n    cin >> n;\n    for (int i = 1; i <= n; i++)\n        for (int j = 1; j <= n; j++)\n            cin >> a[i][j];\n\n    int nord = 0, sud = 0;\n    for (int i = 1; i <= n; i++)\n        for (int j = 1; j <= n; j++) {\n            if (i < j && i + j < n + 1) nord += a[i][j];\n            if (i > j && i + j > n + 1) sud += a[i][j];\n        }\n\n    cout << nord << ' ' << sud;\n    return 0;\n}",
          "lang": "cpp",
          "callout": "SFAT:\nNu memora condițiile pe de rost. Desenează o matrice 4 × 4, scrie în fiecare căsuță perechea (i, j) și uită-te ce au în comun căsuțele din zona care te interesează. Verifică întotdeauna și dacă enunțul numerotează de la 0 sau de la 1.",
        },
      ]
    },

    "cpp-10-strings-cstring": {
      "tag": "INFORMATICĂ // CLASA A 10-A // C++",
      "title": "Șiruri în stil C: char[] & Biblioteca cstring",
      "subtitle": "Șirul ca vector de caractere terminat cu '\\0' și funcțiile cerute la Bacalaureat.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Declarare, citire și terminatorul de șir",
          "text": "Un șir de caractere în stil C este un vector de tip `char` în care, după ultimul caracter, se află caracterul special `'\\0'` (cu codul 0). El marchează sfârșitul șirului.\n\nDe aceea, pentru un text de cel mult 100 de caractere se declară `char s[101];`: o poziție este rezervată terminatorului.\n\n• `cin >> s;` citește un singur cuvânt (se oprește la primul spațiu).\n• `cin.getline(s, 101);` citește o linie întreagă, cu tot cu spații.",
          "code": "#include <iostream>\n#include <cstring>\nusing namespace std;\n\nint main() {\n    char s[101];\n    cin.getline(s, 101);\n\n    int vocale = 0;\n    for (int i = 0; s[i] != '\\0'; i++)\n        if (strchr(\"aeiouAEIOU\", s[i]) != NULL)\n            vocale++;\n\n    cout << strlen(s) << \" caractere, \" << vocale << \" vocale\";\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Funcțiile de bază din cstring",
          "text": "Șirurile în stil C nu pot fi copiate cu `=` și nici comparate cu `==`. Pentru aceste operații se folosesc funcții din biblioteca `<cstring>`:\n\n• `strlen(s)` : lungimea șirului, fără terminator.\n• `strcpy(dest, sursa)` : copiază sursa în dest.\n• `strcat(dest, sursa)` : lipește sursa la sfârșitul lui dest.\n• `strcmp(a, b)` : compară alfabetic. Întoarce 0 dacă șirurile sunt egale, o valoare negativă dacă a este înaintea lui b și una pozitivă în caz contrar.\n• `strchr(s, c)` : adresa primei apariții a caracterului c în s sau NULL.\n• `strstr(s, t)` : adresa primei apariții a șirului t în s sau NULL.",
          "code": "#include <iostream>\n#include <cstring>\nusing namespace std;\n\nint main() {\n    char a[101], b[101], c[205];\n    cin >> a >> b;\n\n    if (strcmp(a, b) == 0)\n        cout << \"Cuvintele sunt egale\\n\";\n    else if (strcmp(a, b) < 0)\n        cout << a << \" este primul in ordine alfabetica\\n\";\n    else\n        cout << b << \" este primul in ordine alfabetica\\n\";\n\n    strcpy(c, a);\n    strcat(c, \" \");\n    strcat(c, b);\n    cout << c << '\\n';\n\n    char *p = strstr(c, \"na\");\n    if (p != NULL)\n        cout << \"\\\"na\\\" apare pe pozitia \" << p - c << '\\n';\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Împărțirea în cuvinte cu strtok",
          "text": "`strtok(s, separatori)` desparte un text în cuvinte. Primul apel primește șirul și întoarce adresa primului cuvânt. Apelurile următoare primesc `NULL` în locul șirului și întorc, pe rând, cuvintele următoare. Când nu mai există cuvinte, funcția întoarce `NULL`.\n\nAl doilea parametru este un șir care conține toate caracterele considerate separatori.",
          "code": "#include <iostream>\n#include <cstring>\nusing namespace std;\n\nint main() {\n    char s[256], celMaiLung[256] = \"\";\n    cin.getline(s, 256);\n\n    int nrCuvinte = 0;\n    char *p = strtok(s, \" ,.\");\n    while (p != NULL) {\n        nrCuvinte++;\n        if (strlen(p) > strlen(celMaiLung))\n            strcpy(celMaiLung, p);\n        p = strtok(NULL, \" ,.\");\n    }\n\n    cout << nrCuvinte << \" cuvinte, cel mai lung: \" << celMaiLung;\n    return 0;\n}",
          "lang": "cpp",
          "callout": "CAPCANE:\n1) `strtok` modifică șirul primit: pune `'\\0'` în locul separatorilor. Dacă mai ai nevoie de textul original, lucrează pe o copie făcută cu `strcpy`.\n2) `if (a == b)` compară adresele celor doi vectori, nu conținutul lor, deci este fals chiar și pentru două șiruri identice. Compararea corectă este `strcmp(a, b) == 0`.",
        },
      ]
    },

    "cpp-10-strings-class": {
      "tag": "INFORMATICĂ // CLASA A 10-A // C++",
      "title": "Clasa std::string în C++ Modern",
      "subtitle": "Șiruri care își gestionează singure memoria și se folosesc aproape ca un tip de bază.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Declarare, citire și operatori",
          "text": "Tipul `string` din biblioteca `<string>` scapă de grijile șirurilor în stil C: nu are dimensiune maximă declarată și nu trebuie să te ocupi de terminator.\n\nCu un `string` se poate lucra direct cu operatori:\n• `=` copiază;\n• `+` și `+=` concatenează;\n• `==`, `!=`, `<`, `>` compară alfabetic;\n• `s[i]` accesează caracterul de pe poziția i (de la 0).\n\n`cin >> s` citește un cuvânt, iar `getline(cin, s)` o linie întreagă.",
          "code": "#include <iostream>\n#include <string>\nusing namespace std;\n\nint main() {\n    string prenume, nume;\n    cin >> prenume >> nume;\n\n    string complet = prenume + \" \" + nume;\n    cout << complet << '\\n';\n    cout << \"Lungime: \" << complet.length() << '\\n';\n\n    if (prenume < nume)\n        cout << prenume << \" este inaintea lui \" << nume << \" in ordine alfabetica\\n\";\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Metodele uzuale",
          "text": "• `s.length()` sau `s.size()` : numărul de caractere.\n• `s.find(t)` : poziția primei apariții a lui t în s. Dacă t nu apare, întoarce valoarea specială `string::npos`.\n• `s.substr(poz, lung)` : subșirul care începe la poz și are lung caractere.\n• `s.erase(poz, lung)` : șterge lung caractere începând de la poz.\n• `s.insert(poz, t)` : inserează t la poziția poz.",
          "code": "#include <iostream>\n#include <string>\nusing namespace std;\n\nint main() {\n    string s = \"informatica\";\n\n    cout << s.substr(0, 4) << '\\n';      // info\n    cout << s.find(\"mat\") << '\\n';       // 5\n\n    if (s.find(\"xyz\") == string::npos)\n        cout << \"xyz nu apare\\n\";\n\n    s.erase(0, 2);                       // formatica\n    s.insert(0, \"re\");                   // reformatica\n    cout << s << '\\n';\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Parcurgere și prelucrare caracter cu caracter",
          "text": "Un `string` se parcurge ca un vector, cu indici de la 0 la `s.length() - 1`. Caracterele pot fi modificate direct.\n\nFuncțiile din `<cctype>` ajută la clasificarea și transformarea caracterelor: `isdigit(c)`, `isalpha(c)`, `islower(c)`, `isupper(c)`, `toupper(c)`, `tolower(c)`.",
          "code": "#include <iostream>\n#include <string>\n#include <cctype>\nusing namespace std;\n\nint main() {\n    string s;\n    getline(cin, s);\n\n    // Prima literă a fiecărui cuvânt devine majusculă.\n    for (int i = 0; i < (int)s.length(); i++)\n        if (isalpha(s[i]) && (i == 0 || s[i - 1] == ' '))\n            s[i] = toupper(s[i]);\n\n    cout << s;\n    return 0;\n}",
          "lang": "cpp",
          "callout": "ATENȚIE LA CITIRE:\nDupă `cin >> n;` în flux rămâne caracterul Enter. Dacă urmează imediat `getline(cin, s);`, acesta citește linia goală rămasă și s va fi vid. Pune `cin.ignore();` între cele două citiri ca să sari peste acel Enter.",
        },
      ]
    },

    "cpp-10-subprog-basics": {
      "tag": "INFORMATICĂ // CLASA A 10-A // C++",
      "title": "Subprograme: Antet, Prototip & Apel",
      "subtitle": "Cum împărțim un program în funcții și ce se întâmplă cu variabilele din ele.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Definirea și apelul unei funcții",
          "text": "Un subprogram (o funcție) este o secvență de instrucțiuni care are un nume și poate fi apelată ori de câte ori este nevoie.\n\nDefiniția are două părți:\n• antetul: `tip_returnat nume(lista de parametri)`\n• corpul: instrucțiunile dintre acolade.\n\nInstrucțiunea `return valoare;` încheie funcția și trimite rezultatul către locul din care a fost apelată. Un apel se poate folosi oriunde este permisă o valoare de acel tip: într-o expresie, într-o condiție, într-un `cout`.",
          "code": "#include <iostream>\nusing namespace std;\n\nint sumaCifre(int n) {\n    int s = 0;\n    while (n > 0) {\n        s += n % 10;\n        n /= 10;\n    }\n    return s;\n}\n\nint main() {\n    int a, b;\n    cin >> a >> b;\n\n    if (sumaCifre(a) == sumaCifre(b))\n        cout << \"Aceeasi suma a cifrelor\";\n    else\n        cout << sumaCifre(a) << ' ' << sumaCifre(b);\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Funcții void și funcții care întorc bool",
          "text": "O funcție care doar face ceva, fără să producă un rezultat, are tipul `void`. Ea se apelează ca o instrucțiune de sine stătătoare.\n\nFuncțiile care răspund la o întrebare cu da sau nu întorc `bool` și se folosesc direct în condiții. Într-o astfel de funcție, `return false;` pus în interiorul unei bucle oprește imediat căutarea.",
          "code": "#include <iostream>\nusing namespace std;\n\nbool estePrim(int n) {\n    if (n < 2) return false;\n    for (int d = 2; d * d <= n; d++)\n        if (n % d == 0) return false;\n    return true;\n}\n\nvoid afiseazaLinie(int lungime) {\n    for (int i = 1; i <= lungime; i++) cout << '-';\n    cout << '\\n';\n}\n\nint main() {\n    int n;\n    cin >> n;\n\n    afiseazaLinie(20);\n    for (int i = 2; i <= n; i++)\n        if (estePrim(i)) cout << i << ' ';\n    cout << '\\n';\n    afiseazaLinie(20);\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Prototipuri, variabile locale și globale",
          "text": "Compilatorul citește fișierul de sus în jos, așa că o funcție trebuie să fie cunoscută înainte de primul apel. Dacă vrem să scriem definiția după `main`, punem înainte doar prototipul: antetul urmat de punct și virgulă.\n\nVariabilele declarate într-o funcție sunt locale: există doar pe durata apelului și nu sunt vizibile din afară. Variabilele declarate în afara oricărei funcții sunt globale: sunt vizibile peste tot și sunt inițializate automat cu 0.",
          "code": "#include <iostream>\nusing namespace std;\n\nint apeluri;                 // variabilă globală, pornește de la 0\n\nint cmmdc(int a, int b);     // prototip\n\nint main() {\n    int x, y;\n    cin >> x >> y;\n    cout << cmmdc(x, y) << '\\n';\n    cout << \"Functia a fost apelata de \" << apeluri << \" ori\";\n    return 0;\n}\n\nint cmmdc(int a, int b) {\n    apeluri++;\n    while (b != 0) {\n        int r = a % b;       // r este locală funcției\n        a = b;\n        b = r;\n    }\n    return a;\n}",
          "lang": "cpp",
          "callout": "ATENȚIE:\nO funcție cu alt tip decât `void` trebuie să ajungă la un `return` pe orice drum posibil. Dacă `return` se află doar în interiorul unui `if` și condiția nu se îndeplinește, funcția se termină fără să întoarcă nimic, iar valoarea primită de apelant este imprevizibilă.",
        },
      ]
    },

    "cpp-10-subprog-params": {
      "tag": "INFORMATICĂ // CLASA A 10-A // C++",
      "title": "Parametri prin Valoare vs. Referință (&)",
      "subtitle": "Când lucrează funcția pe o copie și când modifică direct variabila apelantului.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Transmiterea prin valoare",
          "text": "În mod implicit, parametrii se transmit prin valoare: la apel, funcția primește o copie a fiecărei valori. Orice modificare făcută în funcție afectează doar copia, iar variabila din apelant rămâne neschimbată.\n\nAvantajul este că funcția poate „consuma” liniștită parametrul (de exemplu împărțindu-l repetat la 10) fără să strice ceva în afară.",
          "code": "#include <iostream>\nusing namespace std;\n\nvoid dubleaza(int x) {\n    x = x * 2;                // se modifică doar copia\n}\n\nint main() {\n    int a = 5;\n    dubleaza(a);\n    cout << a;                // 5\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Transmiterea prin referință",
          "text": "Dacă punem `&` între tip și numele parametrului, funcția nu mai primește o copie, ci lucrează direct cu variabila din apelant. Orice modificare se vede după apel.\n\nReferința se folosește în două situații:\n• când funcția trebuie să schimbe variabilele apelantului (interschimbare, citire);\n• când funcția are de întors mai multe rezultate. `return` poate întoarce o singură valoare, restul se transmit prin parametri referință.\n\nLa apel, pe poziția unui parametru referință trebuie pusă o variabilă, nu o constantă sau o expresie.",
          "code": "#include <iostream>\nusing namespace std;\n\nvoid interschimba(int &x, int &y) {\n    int aux = x;\n    x = y;\n    y = aux;\n}\n\n// Două rezultate: câtul și restul împărțirii lui a la b.\nvoid imparte(int a, int b, int &cat, int &rest) {\n    cat = a / b;\n    rest = a % b;\n}\n\nint main() {\n    int a = 17, b = 5;\n    interschimba(a, b);\n    cout << a << ' ' << b << '\\n';     // 5 17\n\n    int c, r;\n    imparte(b, a, c, r);               // 17 împărțit la 5\n    cout << c << ' ' << r << '\\n';     // 3 2\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Vectori ca parametri",
          "text": "Vectorii fac excepție de la regula copierii: un vector transmis unei funcții nu este copiat niciodată. Funcția lucrează direct pe vectorul original, deci modificările rămân, chiar dacă nu am scris `&`.\n\nFuncția nu știe câte elemente are vectorul, așa că numărul lor se transmite separat. Dacă funcția îl modifică pe n (cum se întâmplă la citire sau la ștergerea unui element), n trebuie transmis prin referință.",
          "code": "#include <iostream>\nusing namespace std;\n\nvoid citeste(int v[], int &n) {\n    cin >> n;\n    for (int i = 0; i < n; i++) cin >> v[i];\n}\n\nint maxim(int v[], int n) {\n    int mx = v[0];\n    for (int i = 1; i < n; i++)\n        if (v[i] > mx) mx = v[i];\n    return mx;\n}\n\nvoid adunaLaToate(int v[], int n, int k) {\n    for (int i = 0; i < n; i++) v[i] += k;    // modifică vectorul original\n}\n\nint main() {\n    int v[105], n;\n    citeste(v, n);\n    adunaLaToate(v, n, 10);\n    cout << maxim(v, n);\n    return 0;\n}",
          "lang": "cpp",
          "callout": "CAPCANĂ LA BACALAUREAT:\nLa subiectele în care se cere antetul sau definiția unui subprogram, citește cu atenție ce parametri „furnizează” rezultate. Dacă enunțul spune că subprogramul întoarce rezultatul prin parametrul k, iar tu scrii `int k` în loc de `int &k`, valoarea calculată se pierde la ieșirea din funcție.",
        },
      ]
    },

    "cpp-10-recursion-intro": {
      "tag": "INFORMATICĂ // CLASA A 10-A // C++",
      "title": "Noțiuni de Bază: Ce este Recursivitatea?",
      "subtitle": "Funcții care se apelează pe ele însele, condiția de oprire și stiva de apeluri.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Cazul de bază și pasul recursiv",
          "text": "O funcție este recursivă dacă se apelează pe ea însăși. Ca să funcționeze corect, are nevoie de două lucruri:\n\n• cazul de bază: o situație simplă, în care răspunsul se dă direct, fără alt apel;\n• pasul recursiv: problema se reduce la una mai mică, de același tip, care se apropie de cazul de bază.\n\nExemplu: suma primelor n numere naturale. S(n) = n + S(n - 1), iar S(0) = 0.",
          "code": "#include <iostream>\nusing namespace std;\n\nint suma(int n) {\n    if (n == 0) return 0;          // cazul de bază\n    return n + suma(n - 1);        // pasul recursiv\n}\n\nint main() {\n    cout << suma(4);               // 10\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Stiva de apeluri",
          "text": "La fiecare apel, calculatorul pune deoparte, într-o zonă de memorie numită stivă, parametrii și variabilele locale ale apelului respectiv. Când apelul se termină, zona lui este eliberată și execuția revine în apelul care l-a lansat.\n\nPentru `suma(3)` lucrurile se petrec așa:\n\nsuma(3) așteaptă rezultatul lui suma(2)\nsuma(2) așteaptă rezultatul lui suma(1)\nsuma(1) așteaptă rezultatul lui suma(0)\nsuma(0) întoarce 0\nsuma(1) întoarce 1 + 0 = 1\nsuma(2) întoarce 2 + 1 = 3\nsuma(3) întoarce 3 + 3 = 6\n\nExistă deci un drum „la dus”, pe care apelurile se adună pe stivă, și unul „la întors”, pe care se fac efectiv calculele.",
        },
        {
          "heading": "3. Înainte sau după apelul recursiv",
          "text": "Instrucțiunile scrise înaintea apelului recursiv se execută la dus. Cele scrise după apel se execută la întors, deci în ordine inversă.\n\nCele două funcții de mai jos diferă doar prin poziția lui `cout`, dar una afișează cifrele numărului în ordine inversă, iar cealaltă în ordinea normală.",
          "code": "#include <iostream>\nusing namespace std;\n\nvoid cifreInvers(int n) {\n    if (n == 0) return;\n    cout << n % 10 << ' ';     // afișare la dus\n    cifreInvers(n / 10);\n}\n\nvoid cifreNormal(int n) {\n    if (n == 0) return;\n    cifreNormal(n / 10);\n    cout << n % 10 << ' ';     // afișare la întors\n}\n\nint main() {\n    cifreInvers(1234);         // 4 3 2 1\n    cout << '\\n';\n    cifreNormal(1234);         // 1 2 3 4\n    return 0;\n}",
          "lang": "cpp",
          "callout": "EROARE CRITICĂ (STACK OVERFLOW):\nDacă lipsește cazul de bază sau dacă apelul recursiv nu se apropie de el (de exemplu `suma(n)` apelează tot `suma(n)`), apelurile se adună pe stivă până când memoria rezervată ei se termină, iar programul este oprit de sistemul de operare. Când scrii o funcție recursivă, începe întotdeauna cu cazul de bază.",
        },
      ]
    },

    "cpp-10-recursion-classic": {
      "tag": "INFORMATICĂ // CLASA A 10-A // C++",
      "title": "Algoritmi Clasici Recursivi: Factorial, CMMDC, Fibonacci",
      "subtitle": "Trei definiții matematice care se transcriu direct în funcții recursive și cât costă fiecare.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Factorialul",
          "text": "Definiția matematică este deja recursivă:\n\nn! = n · (n - 1)!, cu 0! = 1.\n\nFuncția face n apeluri, deci are complexitatea O(n). Rezultatul crește foarte repede: 13! depășește deja limita tipului `int`, iar 21! pe cea a tipului `long long`.",
          "code": "#include <iostream>\nusing namespace std;\n\nlong long factorial(int n) {\n    if (n <= 1) return 1;\n    return n * factorial(n - 1);\n}\n\nint main() {\n    int n;\n    cin >> n;\n    cout << factorial(n);\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. CMMDC cu algoritmul lui Euclid",
          "text": "Relația pe care se bazează algoritmul lui Euclid este tot o recurență:\n\ncmmdc(a, b) = cmmdc(b, a % b), cu cmmdc(a, 0) = a.\n\nVarianta recursivă are o singură linie utilă și face același număr de pași ca varianta cu `while`.",
          "code": "#include <iostream>\nusing namespace std;\n\nint cmmdc(int a, int b) {\n    if (b == 0) return a;\n    return cmmdc(b, a % b);\n}\n\nint main() {\n    int a, b;\n    cin >> a >> b;\n    cout << cmmdc(a, b);\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Șirul lui Fibonacci și costul recursivității",
          "text": "Șirul lui Fibonacci este definit prin F(1) = 1, F(2) = 1 și F(n) = F(n - 1) + F(n - 2).\n\nTranscrierea directă este corectă, dar foarte lentă. Fiecare apel lansează alte două, iar aceleași valori sunt recalculate de foarte multe ori: pentru F(5) se calculează F(3) de două ori și F(2) de trei ori. Numărul de apeluri crește exponențial, astfel că F(50) ar dura minute întregi.\n\nVarianta iterativă calculează fiecare termen o singură dată, în O(n).",
          "code": "#include <iostream>\nusing namespace std;\n\n// Recursiv: corect, dar exponențial.\nlong long fibRecursiv(int n) {\n    if (n <= 2) return 1;\n    return fibRecursiv(n - 1) + fibRecursiv(n - 2);\n}\n\n// Iterativ: O(n).\nlong long fibIterativ(int n) {\n    long long a = 1, b = 1;\n    for (int i = 3; i <= n; i++) {\n        long long c = a + b;\n        a = b;\n        b = c;\n    }\n    return b;\n}\n\nint main() {\n    int n;\n    cin >> n;\n    cout << fibIterativ(n);\n    return 0;\n}",
          "lang": "cpp",
          "callout": "REGULĂ DE REȚINUT:\nRecursivitatea este potrivită când fiecare apel lansează un singur apel mai mic (factorial, CMMDC, cifrele unui număr) sau când subproblemele nu se repetă. Dacă aceleași subprobleme apar de mai multe ori, ca la Fibonacci, folosește varianta iterativă sau memorează rezultatele deja calculate.",
        },
      ]
    },

    "cpp-10-d&i-intro": {
      "tag": "INFORMATICĂ // CLASA A 10-A // C++",
      "title": "Tehnica Divide et Impera & Căutarea Binară",
      "subtitle": "Împarte problema în bucăți mai mici, rezolvă-le separat și combină rezultatele.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Cei trei pași ai metodei",
          "text": "Divide et Impera („împarte și stăpânește”) rezolvă o problemă în trei pași:\n\n1. Divide: problema se împarte în două sau mai multe subprobleme de același tip, dar mai mici.\n2. Stăpânește: fiecare subproblemă se rezolvă recursiv. Subproblemele foarte mici se rezolvă direct.\n3. Combină: din soluțiile subproblemelor se construiește soluția problemei inițiale.\n\nPe vectori, subproblemele sunt de obicei cele două jumătăți ale secvenței curente, descrise prin capetele `st` și `dr`.",
        },
        {
          "heading": "2. Primul exemplu: maximul dintr-un vector",
          "text": "Maximul secvenței `v[st..dr]` este cel mai mare dintre maximul jumătății stângi și maximul jumătății drepte. O secvență cu un singur element își are maximul în acel element: acesta este cazul de bază.\n\nPentru această problemă metoda nu este mai rapidă decât o parcurgere simplă (tot O(n)), dar arată clar tiparul pe care îl vom folosi mai departe.",
          "code": "#include <iostream>\nusing namespace std;\n\nint v[100005];\n\nint maxim(int st, int dr) {\n    if (st == dr) return v[st];            // un singur element\n\n    int m = (st + dr) / 2;\n    int maxStanga = maxim(st, m);          // rezolvă jumătatea stângă\n    int maxDreapta = maxim(m + 1, dr);     // rezolvă jumătatea dreaptă\n\n    return maxStanga > maxDreapta ? maxStanga : maxDreapta;   // combină\n}\n\nint main() {\n    int n;\n    cin >> n;\n    for (int i = 0; i < n; i++) cin >> v[i];\n    cout << maxim(0, n - 1);\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Căutarea binară recursivă",
          "text": "Căutarea binară este cazul în care, după împărțire, mai trebuie rezolvată o singură jumătate: cealaltă este eliminată printr-o singură comparație cu elementul din mijloc.\n\nDe aceea numărul de pași nu este n, ci numărul de înjumătățiri necesare pentru a ajunge de la n la 1, adică aproximativ log₂ n. Pentru n = 1.000.000 sunt cel mult 20 de pași.",
          "code": "#include <iostream>\nusing namespace std;\n\nint v[100005];\n\n// Întoarce poziția lui x în v[st..dr] sau -1 dacă x nu apare.\nint cauta(int st, int dr, int x) {\n    if (st > dr) return -1;                // secvență vidă: x nu există\n\n    int m = st + (dr - st) / 2;\n    if (v[m] == x) return m;\n    if (x < v[m]) return cauta(st, m - 1, x);\n    return cauta(m + 1, dr, x);\n}\n\nint main() {\n    int n, x;\n    cin >> n;\n    for (int i = 0; i < n; i++) cin >> v[i];   // sortat crescător\n    cin >> x;\n    cout << cauta(0, n - 1, x);\n    return 0;\n}",
          "lang": "cpp",
          "callout": "ATENȚIE LA CAPETE:\nApelurile recursive trebuie făcute pe `m - 1` și `m + 1`, nu pe `m`. Elementul din mijloc a fost deja verificat. Dacă îl păstrezi în secvență, pentru o secvență de două elemente mijlocul rămâne același la nesfârșit și funcția nu se mai oprește.",
        },
      ]
    },

    "cpp-10-d&i-mergesort": {
      "tag": "INFORMATICĂ // CLASA A 10-A // C++",
      "title": "Sortarea prin Interclasare: MergeSort",
      "subtitle": "O sortare în O(n log n) construită pe interclasarea a două secvențe deja ordonate.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Interclasarea",
          "text": "Interclasarea combină două secvențe sortate într-una singură, tot sortată.\n\nȚinem câte un indice în fiecare secvență. La fiecare pas comparăm elementele curente, îl mutăm pe cel mai mic în rezultat și avansăm indicele din secvența din care a fost luat. Când una dintre secvențe se termină, copiem ce a rămas din cealaltă.\n\nFiecare element este mutat o singură dată, deci interclasarea a două secvențe cu n elemente în total se face în O(n).",
          "code": "#include <iostream>\nusing namespace std;\n\nint a[100005], b[100005], c[200005];\n\nint main() {\n    int n, m;\n    cin >> n;\n    for (int i = 0; i < n; i++) cin >> a[i];\n    cin >> m;\n    for (int i = 0; i < m; i++) cin >> b[i];\n\n    int i = 0, j = 0, k = 0;\n    while (i < n && j < m) {\n        if (a[i] <= b[j]) c[k++] = a[i++];\n        else c[k++] = b[j++];\n    }\n    while (i < n) c[k++] = a[i++];\n    while (j < m) c[k++] = b[j++];\n\n    for (int p = 0; p < k; p++) cout << c[p] << ' ';\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Algoritmul MergeSort",
          "text": "Sortarea prin interclasare aplică Divide et Impera astfel:\n\n1. Împarte secvența `v[st..dr]` în două jumătăți.\n2. Sortează recursiv fiecare jumătate.\n3. Interclasează cele două jumătăți sortate.\n\nO secvență cu un singur element este deja sortată: acesta este cazul de bază.\n\nInterclasarea are nevoie de un vector auxiliar `tmp`, din care rezultatul se copiază înapoi în `v`.",
          "code": "#include <iostream>\nusing namespace std;\n\nint v[100005], tmp[100005];\n\nvoid mergeSort(int st, int dr) {\n    if (st >= dr) return;\n\n    int m = (st + dr) / 2;\n    mergeSort(st, m);\n    mergeSort(m + 1, dr);\n\n    int i = st, j = m + 1, k = st;\n    while (i <= m && j <= dr) {\n        if (v[i] <= v[j]) tmp[k++] = v[i++];\n        else tmp[k++] = v[j++];\n    }\n    while (i <= m) tmp[k++] = v[i++];\n    while (j <= dr) tmp[k++] = v[j++];\n\n    for (k = st; k <= dr; k++) v[k] = tmp[k];\n}\n\nint main() {\n    int n;\n    cin >> n;\n    for (int i = 0; i < n; i++) cin >> v[i];\n    mergeSort(0, n - 1);\n    for (int i = 0; i < n; i++) cout << v[i] << ' ';\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. De ce este O(n log n)",
          "text": "Să urmărim nivelurile de recursivitate. Pe primul nivel avem o secvență de lungime n, pe al doilea două secvențe de lungime n / 2, pe al treilea patru de lungime n / 4 și așa mai departe. Înjumătățirea se poate repeta de aproximativ log₂ n ori.\n\nPe fiecare nivel, toate interclasările la un loc mută n elemente. Costul total este deci n · log₂ n.\n\nPentru n = 100.000 asta înseamnă aproximativ 1,7 milioane de operații, față de 10 miliarde pentru o sortare în O(n²).\n\nMergeSort mai are două proprietăți utile: timpul de execuție este același indiferent de datele de intrare, iar sortarea este stabilă, adică elementele egale își păstrează ordinea inițială. Prețul este memoria suplimentară pentru vectorul auxiliar.",
          "callout": "ATENȚIE:\nDeclară vectorul auxiliar `tmp` global, o singură dată. Dacă îl declari în interiorul funcției recursive, la fiecare apel se rezervă pe stivă încă un vector de 100.000 de elemente și programul se oprește cu stack overflow.",
        },
      ]
    },

    "cpp-10-d&i-quicksort": {
      "tag": "INFORMATICĂ // CLASA A 10-A // C++",
      "title": "Sortarea Rapidă: QuickSort",
      "subtitle": "Sortare prin partiționare în jurul unui pivot, fără vector auxiliar.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Ideea: pivotul și partiționarea",
          "text": "QuickSort alege un element al secvenței, numit pivot, și rearanjează elementele astfel încât cele mai mici decât pivotul să ajungă în stânga, iar cele mai mari în dreapta. Operația se numește partiționare.\n\nDupă partiționare, cele două părți se sortează recursiv, independent una de cealaltă. Spre deosebire de MergeSort, munca se face înaintea apelurilor recursive, iar la întoarcere nu mai este nimic de combinat.\n\nPartiționarea folosește doi indici: `i` pornește din stânga și sare peste elementele mai mici decât pivotul, `j` pornește din dreapta și sare peste cele mai mari. Când amândoi s-au oprit, elementele de pe cele două poziții sunt în părțile greșite și se interschimbă.",
        },
        {
          "heading": "2. Implementare",
          "text": "Varianta de mai jos alege ca pivot elementul din mijlocul secvenței. După bucla de partiționare, `j` a ajuns în stânga lui `i`, iar secvențele rămase de sortat sunt `v[st..j]` și `v[i..dr]`.",
          "code": "#include <iostream>\nusing namespace std;\n\nint v[100005];\n\nvoid quickSort(int st, int dr) {\n    if (st >= dr) return;\n\n    int pivot = v[(st + dr) / 2];\n    int i = st, j = dr;\n    while (i <= j) {\n        while (v[i] < pivot) i++;\n        while (v[j] > pivot) j--;\n        if (i <= j) {\n            int aux = v[i];\n            v[i] = v[j];\n            v[j] = aux;\n            i++;\n            j--;\n        }\n    }\n\n    quickSort(st, j);\n    quickSort(i, dr);\n}\n\nint main() {\n    int n;\n    cin >> n;\n    for (int i = 0; i < n; i++) cin >> v[i];\n    quickSort(0, n - 1);\n    for (int i = 0; i < n; i++) cout << v[i] << ' ';\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Cazul favorabil și cazul nefavorabil",
          "text": "Viteza depinde de cât de echilibrat împarte pivotul secvența.\n\n• Cazul favorabil: pivotul este aproape de valoarea mediană, iar cele două părți au lungimi apropiate. Apar aproximativ log₂ n niveluri de recursivitate, fiecare cu n operații: O(n log n).\n• Cazul nefavorabil: pivotul este de fiecare dată cel mai mic sau cel mai mare element. O parte rămâne aproape întreagă, apar n niveluri, iar complexitatea ajunge O(n²).\n\nDacă pivotul ar fi mereu primul element, cazul nefavorabil ar apărea tocmai pe un vector deja sortat. Alegerea elementului din mijloc evită această situație.\n\nÎn practică, QuickSort este de obicei mai rapid decât MergeSort și nu are nevoie de memorie suplimentară. În schimb nu este stabil și nu garantează O(n log n) pentru orice date.",
          "callout": "SFAT:\nÎn C++ nu trebuie să scrii de mână o sortare decât dacă problema o cere explicit. Funcția `sort(v, v + n)` din biblioteca `<algorithm>` sortează crescător în O(n log n) garantat. La Bacalaureat însă, biblioteca `<algorithm>` nu este de regulă permisă, așa că merită să știi să scrii singur cel puțin o metodă de sortare.",
        },
      ]
    },

    "cpp-10-struct": {
      "tag": "INFORMATICĂ // CLASA A 10-A // C++",
      "title": "Structuri Eterogene în C++: Tipul struct",
      "subtitle": "Cum grupăm într-o singură variabilă date de tipuri diferite care descriu același obiect.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Definirea unei structuri",
          "text": "Un vector păstrează mai multe valori de același tip. O structură grupează valori de tipuri diferite care aparțin aceluiași obiect: un elev are nume, vârstă și medie, un punct are două coordonate.\n\nCuvântul `struct` definește un tip nou. Componentele se numesc câmpuri și se accesează cu operatorul punct: `variabila.camp`.\n\nDouă variabile de același tip structură se pot atribui direct una alteia cu `=`: se copiază toate câmpurile.",
          "code": "#include <iostream>\nusing namespace std;\n\nstruct Elev {\n    char nume[31];\n    int varsta;\n    double medie;\n};\n\nint main() {\n    Elev e;\n    cin >> e.nume >> e.varsta >> e.medie;\n\n    Elev copie = e;               // se copiază toate câmpurile\n    copie.varsta++;\n\n    cout << e.nume << \" are \" << e.varsta << \" ani si media \" << e.medie << '\\n';\n    cout << \"La anul va avea \" << copie.varsta << \" ani\";\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Vectori de structuri",
          "text": "De cele mai multe ori avem de-a face cu mai multe obiecte de același fel, deci cu un vector în care fiecare element este o structură. Elementul se alege cu indicele, iar câmpul cu punctul: `v[i].medie`.\n\nLa sortare se compară un câmp, dar se interschimbă structurile întregi, astfel încât toate datele unui elev să rămână împreună.",
          "code": "#include <iostream>\nusing namespace std;\n\nstruct Elev {\n    char nume[31];\n    double medie;\n};\n\nElev v[105];\n\nint main() {\n    int n;\n    cin >> n;\n    for (int i = 0; i < n; i++)\n        cin >> v[i].nume >> v[i].medie;\n\n    // Sortare descrescătoare după medie.\n    for (int i = 0; i < n - 1; i++)\n        for (int j = i + 1; j < n; j++)\n            if (v[j].medie > v[i].medie) {\n                Elev aux = v[i];\n                v[i] = v[j];\n                v[j] = aux;\n            }\n\n    for (int i = 0; i < n; i++)\n        cout << v[i].nume << ' ' << v[i].medie << '\\n';\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Structuri imbricate și structuri ca parametri",
          "text": "Un câmp poate fi la rândul lui o structură. Accesul se face înlănțuind punctele: `c.centru.x`.\n\nO structură se transmite unei funcții la fel ca o variabilă obișnuită: prin valoare se copiază toate câmpurile, prin referință funcția lucrează pe original.",
          "code": "#include <iostream>\n#include <cmath>\nusing namespace std;\n\nstruct Punct {\n    double x, y;\n};\n\nstruct Cerc {\n    Punct centru;\n    double raza;\n};\n\ndouble distanta(Punct a, Punct b) {\n    return sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));\n}\n\nint main() {\n    Cerc c;\n    Punct p;\n    cin >> c.centru.x >> c.centru.y >> c.raza;\n    cin >> p.x >> p.y;\n\n    if (distanta(c.centru, p) <= c.raza)\n        cout << \"Punctul este in interiorul cercului\";\n    else\n        cout << \"Punctul este in afara cercului\";\n    return 0;\n}",
          "lang": "cpp",
          "callout": "EROARE FRECVENTĂ:\nDefiniția unei structuri se termină cu punct și virgulă după acolada de închidere: `};`. Dacă îl uiți, compilatorul semnalează eroarea abia la linia următoare, cu un mesaj care nu pare să aibă legătură cu structura.",
        },
      ]
    },

    "mat-10-complex": {
      "tag": "MATEMATICĂ // CLASA A 10-A // ALGEBRĂ",
      "title": "Numere Complexe: Forma Algebrică & Modul",
      "subtitle": "Unitatea imaginară, operații, conjugat, modul și ecuații de gradul al II-lea cu Δ negativ.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Forma algebrică",
          "text": "Ecuația x² = -1 nu are soluții reale. Se introduce un număr nou, notat i și numit unitatea imaginară, cu proprietatea:\n\ni² = -1\n\nUn număr complex are forma algebrică z = a + bi, unde a, b ∈ ℝ.\n• a = Re(z) este partea reală.\n• b = Im(z) este partea imaginară.\n\nMulțimea numerelor complexe se notează ℂ. Numerele reale sunt numerele complexe cu b = 0.\n\nDouă numere complexe sunt egale dacă și numai dacă au aceeași parte reală și aceeași parte imaginară:\na + bi = c + di ⟺ a = c și b = d\n\nPuterile lui i se repetă din 4 în 4:\ni¹ = i, i² = -1, i³ = -i, i⁴ = 1\n\nPentru a calcula i^n se împarte n la 4 și se folosește restul. Exemplu: 2023 = 4 · 505 + 3, deci i²⁰²³ = i³ = -i.",
        },
        {
          "heading": "2. Operații, conjugat și modul",
          "text": "Adunarea și înmulțirea se fac ca la expresiile algebrice, înlocuind i² cu -1:\n\n• (a + bi) + (c + di) = (a + c) + (b + d)i\n• (a + bi)(c + di) = (ac - bd) + (ad + bc)i\n\nConjugatul lui z = a + bi este z̄ = a - bi.\n\nModulul lui z este |z| = √(a² + b²). El reprezintă distanța de la origine la punctul de coordonate (a, b).\n\nProprietăți des folosite:\n• z · z̄ = a² + b² = |z|²\n• z + z̄ = 2a = 2 · Re(z)\n• |z₁ · z₂| = |z₁| · |z₂|\n• |z₁ / z₂| = |z₁| / |z₂|\n• z este real ⟺ z = z̄\n\nÎmpărțirea se face amplificând fracția cu conjugatul numitorului.\n\nExemplu: (3 + 2i) / (1 - i)\n= (3 + 2i)(1 + i) / ((1 - i)(1 + i))\n= (3 + 3i + 2i + 2i²) / (1 + 1)\n= (1 + 5i) / 2\n= 1/2 + (5/2)i",
        },
        {
          "heading": "3. Ecuații în ℂ",
          "text": "În ℂ, ecuația de gradul al II-lea az² + bz + c = 0 cu coeficienți reali are soluții și atunci când Δ < 0. Cum √Δ = i√(-Δ), soluțiile sunt:\n\nz₁,₂ = (-b ± i√(-Δ)) / (2a)\n\nEle sunt două numere complexe conjugate.\n\nExemplu: z² - 2z + 5 = 0\nΔ = 4 - 20 = -16, deci √Δ = 4i\nz₁,₂ = (2 ± 4i) / 2\nz₁ = 1 + 2i, z₂ = 1 - 2i\n\nVerificare cu relațiile lui Viète: z₁ + z₂ = 2 și z₁ · z₂ = 1 + 4 = 5.\n\nEcuațiile în care apar și z, și z̄ se rezolvă notând z = a + bi și egalând separat părțile reale și părțile imaginare.",
          "callout": "PROBLEMĂ TIPICĂ DE BACALAUREAT:\nSă se determine numărul complex z știind că 2z + z̄ = 6 + 2i.\nRezolvare:\nFie z = a + bi, deci z̄ = a - bi.\n2(a + bi) + (a - bi) = 6 + 2i\n3a + bi = 6 + 2i\nEgalăm părțile reale și părțile imaginare: 3a = 6 și b = 2.\nRezultă a = 2, b = 2, deci z = 2 + 2i.",
        },
      ]
    },

    "mat-10-combinatorics": {
      "tag": "MATEMATICĂ // CLASA A 10-A // ALGEBRĂ",
      "title": "Permutări, Aranjamente & Combinări",
      "subtitle": "Cum numărăm fără să enumerăm: factorial, aranjamente, combinări, binomul lui Newton și probabilități.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Permutări și aranjamente",
          "text": "Factorialul unui număr natural n este produsul numerelor de la 1 la n:\n\nn! = 1 · 2 · 3 · … · n, cu 0! = 1 prin convenție.\n\nÎn manuale, aranjamentele și combinările se scriu cu n jos și k sus. Aici le notăm A(n, k) și C(n, k).\n\nPermutări. Numărul de moduri în care pot fi așezate în ordine n obiecte distincte este:\n\nP(n) = n!\n\nExemplu: 4 cărți pot fi puse pe un raft în 4! = 24 de moduri.\n\nAranjamente. Numărul de moduri în care pot fi alese și ordonate k obiecte din n este:\n\nA(n, k) = n! / (n - k)! = n · (n - 1) · … · (n - k + 1)\n\nProdusul are exact k factori. Exemplu: podiumul (locurile 1, 2, 3) la o cursă cu 8 concurenți se poate ocupa în A(8, 3) = 8 · 7 · 6 = 336 de moduri.",
        },
        {
          "heading": "2. Combinări",
          "text": "La combinări ordinea nu contează: se alege doar grupul.\n\nC(n, k) = n! / (k! · (n - k)!) = A(n, k) / k!\n\nExemplu: o echipă de 3 elevi dintr-o clasă de 8 se poate forma în C(8, 3) = (8 · 7 · 6) / (3 · 2 · 1) = 56 de moduri.\n\nProprietăți:\n• C(n, 0) = C(n, n) = 1\n• C(n, 1) = n\n• Combinări complementare: C(n, k) = C(n, n - k)\n• Formula de recurență: C(n, k) = C(n - 1, k) + C(n - 1, k - 1)\n• Suma tuturor combinărilor: C(n, 0) + C(n, 1) + … + C(n, n) = 2^n\n\nCum alegi între aranjamente și combinări: întreabă-te dacă, schimbând ordinea elementelor alese, obții un rezultat diferit. Dacă da (un cod, un podium, un număr format din cifre), sunt aranjamente. Dacă nu (o echipă, o mână de cărți, o submulțime), sunt combinări.",
        },
        {
          "heading": "3. Binomul lui Newton și probabilități",
          "text": "Binomul lui Newton:\n\n(a + b)^n = C(n, 0)·a^n + C(n, 1)·a^(n - 1)·b + C(n, 2)·a^(n - 2)·b² + … + C(n, n)·b^n\n\nDezvoltarea are n + 1 termeni. Termenul general, cel de rang k + 1, este:\n\nT(k + 1) = C(n, k) · a^(n - k) · b^k, cu k de la 0 la n.\n\nExemplu: al treilea termen din dezvoltarea (x + 2)⁵ se obține pentru k = 2:\nT₃ = C(5, 2) · x³ · 2² = 10 · x³ · 4 = 40x³\n\nProbabilitatea unui eveniment, atunci când toate rezultatele sunt la fel de probabile:\n\nP = numărul cazurilor favorabile / numărul cazurilor posibile\n\nValoarea este întotdeauna între 0 și 1.",
          "callout": "PROBLEMĂ TIPICĂ DE BACALAUREAT:\nSă se calculeze probabilitatea ca, alegând la întâmplare un număr natural de două cifre, acesta să fie divizibil cu 5.\nRezolvare:\nCazuri posibile: numerele de la 10 la 99, adică 99 - 10 + 1 = 90.\nCazuri favorabile: 10, 15, 20, …, 95, adică (95 - 10) / 5 + 1 = 18.\nP = 18 / 90 = 1/5.",
        },
      ]
    },

    "cpp-11-backtracking-intro": {
      "tag": "INFORMATICĂ // CLASA A 11-A // C++",
      "title": "Backtracking: Mecanismul de Căutare cu Revenire",
      "subtitle": "Cum construim toate soluțiile unei probleme pas cu pas, renunțând devreme la drumurile greșite.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Ideea metodei",
          "text": "Backtracking se folosește la problemele în care soluția este un șir de alegeri x[1], x[2], …, x[n] și se cer toate soluțiile (sau una oarecare) care respectă anumite condiții.\n\nVarianta naivă ar genera toate șirurile posibile și le-ar verifica abia la sfârșit. Backtracking construiește soluția element cu element și verifică după fiecare alegere dacă ea mai poate duce la o soluție corectă. Dacă nu, renunță imediat la acea alegere și o încearcă pe următoarea. Astfel sunt evitate dintr-o singură mișcare toate șirurile care ar fi început cu acea alegere greșită.\n\nSoluția parțială se păstrează într-un vector folosit ca stivă, notat de obicei `x` sau `st`.",
        },
        {
          "heading": "2. Șablonul recursiv",
          "text": "Funcția `bkt(k)` completează poziția k a soluției:\n\n1. Încearcă pe rând toate valorile posibile pentru `x[k]`.\n2. Pentru fiecare valoare, verifică dacă este compatibilă cu ce s-a ales pe pozițiile 1 … k - 1 (funcția `valid`).\n3. Dacă este validă și soluția este completă, o afișează. Altfel trece la poziția următoare prin `bkt(k + 1)`.\n\n„Revenirea” se face singură: când `bkt(k + 1)` se termină, execuția se întoarce în bucla din `bkt(k)`, care încearcă valoarea următoare.\n\nExemplul generează toate șirurile de lungime n formate din valorile 1 … m în care oricare două elemente vecine sunt diferite.",
          "code": "#include <iostream>\nusing namespace std;\n\nint n, m, x[20];\n\nbool valid(int k) {\n    return k == 1 || x[k] != x[k - 1];\n}\n\nvoid afiseaza() {\n    for (int i = 1; i <= n; i++) cout << x[i] << ' ';\n    cout << '\\n';\n}\n\nvoid bkt(int k) {\n    for (int v = 1; v <= m; v++) {\n        x[k] = v;\n        if (valid(k)) {\n            if (k == n) afiseaza();\n            else bkt(k + 1);\n        }\n    }\n}\n\nint main() {\n    cin >> n >> m;\n    bkt(1);\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Ce trebuie stabilit înainte de a scrie codul",
          "text": "Orice problemă de backtracking se rezolvă răspunzând la patru întrebări:\n\n• Ce reprezintă `x[k]`? (al k-lea element al permutării, coloana damei de pe linia k, …)\n• Ce valori poate lua `x[k]`? (de la 1 la n, de la `x[k - 1] + 1` la n, doar 0 și 1, …)\n• Când este validă o alegere? (condițiile de continuare)\n• Când este soluția completă? (k == n, suma a ajuns la valoarea cerută, …)\n\nSoluțiile sunt generate în ordine lexicografică, pentru că valorile sunt încercate crescător pe fiecare poziție.\n\nBacktracking rămâne o metodă cu timp exponențial. Este potrivită doar pentru valori mici ale lui n (de obicei cel mult 10–15), iar condițiile de validare bine alese sunt cele care o fac utilizabilă.",
          "callout": "SFAT:\nVerifică o alegere cât mai devreme. O condiție testată la poziția k elimină toate soluțiile care ar fi continuat de acolo. Aceeași condiție testată abia când soluția este completă nu economisește nimic.",
        },
      ]
    },

    "cpp-11-backtracking-perm": {
      "tag": "INFORMATICĂ // CLASA A 11-A // C++",
      "title": "Generarea Permutărilor cu Backtracking",
      "subtitle": "Toate modurile de a ordona numerele de la 1 la n, cu și fără vector de utilizare.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Condiția de validare",
          "text": "O permutare a mulțimii {1, 2, …, n} este un șir de lungime n în care fiecare valoare de la 1 la n apare exact o dată.\n\nÎn termenii șablonului de backtracking:\n• `x[k]` este elementul de pe poziția k;\n• `x[k]` poate lua valori de la 1 la n;\n• alegerea este validă dacă valoarea nu a mai fost folosită pe pozițiile 1 … k - 1;\n• soluția este completă când k == n.\n\nExistă n! permutări: 6 pentru n = 3, 24 pentru n = 4, 3.628.800 pentru n = 10.",
          "code": "#include <iostream>\nusing namespace std;\n\nint n, x[15];\n\nbool valid(int k) {\n    for (int i = 1; i < k; i++)\n        if (x[i] == x[k]) return false;\n    return true;\n}\n\nvoid bkt(int k) {\n    for (int v = 1; v <= n; v++) {\n        x[k] = v;\n        if (valid(k)) {\n            if (k == n) {\n                for (int i = 1; i <= n; i++) cout << x[i] << ' ';\n                cout << '\\n';\n            } else {\n                bkt(k + 1);\n            }\n        }\n    }\n}\n\nint main() {\n    cin >> n;\n    bkt(1);\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Varianta cu vector de utilizare",
          "text": "Funcția `valid` de mai sus parcurge de fiecare dată toată soluția parțială. Verificarea se poate face într-un singur pas dacă ținem un vector `uz`, în care `uz[v]` este 1 dacă valoarea v este deja folosită.\n\nLa alegerea unei valori o marcăm, iar după întoarcerea din apelul recursiv o demarcăm, ca să poată fi folosită pe altă ramură a căutării.",
          "code": "#include <iostream>\nusing namespace std;\n\nint n, x[15], uz[15];\n\nvoid bkt(int k) {\n    if (k > n) {\n        for (int i = 1; i <= n; i++) cout << x[i] << ' ';\n        cout << '\\n';\n        return;\n    }\n    for (int v = 1; v <= n; v++) {\n        if (!uz[v]) {\n            uz[v] = 1;\n            x[k] = v;\n            bkt(k + 1);\n            uz[v] = 0;        // revenire: eliberăm valoarea\n        }\n    }\n}\n\nint main() {\n    cin >> n;\n    bkt(1);\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Permutările unui vector oarecare și condiții suplimentare",
          "text": "Pentru a permuta elementele unui vector `a`, generăm permutări de indici și afișăm `a[x[i]]` în loc de `x[i]`.\n\nMulte probleme cer doar permutările care respectă o condiție în plus. Condiția se adaugă la validare, astfel încât ramurile greșite să fie tăiate imediat. Exemplul generează permutările în care oricare două elemente vecine au parități diferite.",
          "code": "#include <iostream>\nusing namespace std;\n\nint n, x[15], uz[15];\n\nvoid bkt(int k) {\n    if (k > n) {\n        for (int i = 1; i <= n; i++) cout << x[i] << ' ';\n        cout << '\\n';\n        return;\n    }\n    for (int v = 1; v <= n; v++) {\n        // valoare nefolosită și de paritate diferită față de vecinul din stânga\n        if (!uz[v] && (k == 1 || (v + x[k - 1]) % 2 == 1)) {\n            uz[v] = 1;\n            x[k] = v;\n            bkt(k + 1);\n            uz[v] = 0;\n        }\n    }\n}\n\nint main() {\n    cin >> n;\n    bkt(1);\n    return 0;\n}",
          "lang": "cpp",
          "callout": "EROARE FRECVENTĂ:\nUitarea liniei `uz[v] = 0;` după apelul recursiv. Fără ea, valorile rămân marcate ca folosite și programul afișează o singură permutare (prima), apoi se oprește.",
        },
      ]
    },

    "cpp-11-backtracking-comb": {
      "tag": "INFORMATICĂ // CLASA A 11-A // C++",
      "title": "Generarea Combinărilor & Aranjamentelor",
      "subtitle": "Submulțimi de k elemente, cu și fără ordine, și generarea tuturor submulțimilor.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Aranjamente",
          "text": "Aranjamentele de n elemente luate câte k sunt șirurile de lungime k cu elemente distincte din {1, …, n}. Ordinea contează: (1, 2) și (2, 1) sunt aranjamente diferite.\n\nAlgoritmul este cel de la permutări, cu o singură schimbare: soluția este completă când s-au ales k elemente, nu n.\n\nNumărul lor este n · (n - 1) · … · (n - k + 1).",
          "code": "#include <iostream>\nusing namespace std;\n\nint n, k, x[15], uz[15];\n\nvoid bkt(int pas) {\n    if (pas > k) {\n        for (int i = 1; i <= k; i++) cout << x[i] << ' ';\n        cout << '\\n';\n        return;\n    }\n    for (int v = 1; v <= n; v++) {\n        if (!uz[v]) {\n            uz[v] = 1;\n            x[pas] = v;\n            bkt(pas + 1);\n            uz[v] = 0;\n        }\n    }\n}\n\nint main() {\n    cin >> n >> k;\n    bkt(1);\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Combinări",
          "text": "La combinări ordinea nu contează: {1, 2} și {2, 1} sunt aceeași submulțime și trebuie generată o singură dată.\n\nPentru a evita duplicatele, generăm fiecare submulțime doar cu elementele în ordine strict crescătoare. Asta se obține pornind valorile pentru `x[pas]` de la `x[pas - 1] + 1`. Punem `x[0] = 0`, astfel încât prima poziție să pornească de la 1.\n\nCondiția de ordine crescătoare garantează și că elementele sunt distincte, deci vectorul `uz` nu mai este necesar.",
          "code": "#include <iostream>\nusing namespace std;\n\nint n, k, x[20];\n\nvoid bkt(int pas) {\n    if (pas > k) {\n        for (int i = 1; i <= k; i++) cout << x[i] << ' ';\n        cout << '\\n';\n        return;\n    }\n    for (int v = x[pas - 1] + 1; v <= n; v++) {\n        x[pas] = v;\n        bkt(pas + 1);\n    }\n}\n\nint main() {\n    cin >> n >> k;\n    bkt(1);          // x[0] este 0, fiind variabilă globală\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Toate submulțimile unei mulțimi",
          "text": "Pentru a genera toate submulțimile mulțimii {1, …, n}, folosim un vector caracteristic: `x[i]` este 1 dacă elementul i face parte din submulțime și 0 dacă nu.\n\nFiecare poziție poate lua doar valorile 0 și 1 și nu există nicio condiție de validare, deci se generează toate cele 2^n șiruri binare de lungime n.",
          "code": "#include <iostream>\nusing namespace std;\n\nint n, x[20];\n\nvoid bkt(int k) {\n    if (k > n) {\n        cout << \"{ \";\n        for (int i = 1; i <= n; i++)\n            if (x[i] == 1) cout << i << ' ';\n        cout << \"}\\n\";\n        return;\n    }\n    for (int v = 0; v <= 1; v++) {\n        x[k] = v;\n        bkt(k + 1);\n    }\n}\n\nint main() {\n    cin >> n;\n    bkt(1);\n    return 0;\n}",
          "lang": "cpp",
          "callout": "SFAT PENTRU SUBIECTUL DE BACALAUREAT:\nLa exercițiile de tipul „care este soluția generată imediat după …”, nu rula tot algoritmul. Pornește de la soluția dată și mărește ultimul element care mai poate crește, apoi completează pozițiile de după el cu cele mai mici valori permise. Exact asta face backtracking la revenire.",
        },
      ]
    },

    "cpp-11-graphs-matrix": {
      "tag": "INFORMATICĂ // CLASA A 11-A // C++",
      "title": "Grafuri Neorientate: Matricea de Adiacență & Grad",
      "subtitle": "Noțiunile de bază despre grafuri și cea mai simplă reprezentare a lor în memorie.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Definiții",
          "text": "Un graf neorientat este format dintr-o mulțime de noduri (vârfuri) și o mulțime de muchii. O muchie leagă două noduri diferite și nu are sens de parcurgere: muchia [u, v] este aceeași cu [v, u].\n\n• Două noduri legate printr-o muchie se numesc adiacente (vecine).\n• Gradul unui nod este numărul de muchii care îl ating, adică numărul vecinilor săi.\n• Un nod cu gradul 0 se numește izolat, iar unul cu gradul 1 se numește terminal.\n• Un graf cu n noduri are cel mult n · (n - 1) / 2 muchii. Graful care le are pe toate se numește complet.\n\nSuma gradelor tuturor nodurilor este egală cu dublul numărului de muchii, pentru că fiecare muchie contribuie la gradul ambelor capete. De aici rezultă că numărul nodurilor cu grad impar este întotdeauna par.",
        },
        {
          "heading": "2. Matricea de adiacență",
          "text": "Matricea de adiacență este o matrice pătratică de ordin n în care `a[i][j]` este 1 dacă există muchie între i și j și 0 în caz contrar.\n\nProprietăți:\n• este simetrică față de diagonala principală: `a[i][j] == a[j][i]`;\n• are 0 pe diagonala principală, pentru că un nod nu este vecin cu el însuși;\n• suma elementelor de pe linia i este gradul nodului i;\n• suma tuturor elementelor este dublul numărului de muchii.\n\nGraful se citește de obicei ca listă de muchii: n, m și apoi m perechi de noduri.",
          "code": "#include <iostream>\nusing namespace std;\n\nint a[105][105];\n\nint main() {\n    int n, m;\n    cin >> n >> m;\n    for (int k = 1; k <= m; k++) {\n        int u, v;\n        cin >> u >> v;\n        a[u][v] = a[v][u] = 1;\n    }\n\n    for (int i = 1; i <= n; i++) {\n        for (int j = 1; j <= n; j++) cout << a[i][j] << ' ';\n        cout << '\\n';\n    }\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Gradele nodurilor",
          "text": "Cu matricea de adiacență construită, gradul unui nod se obține adunând elementele de pe linia lui. Programul de mai jos calculează gradele, afișează nodurile izolate și nodul cu grad maxim.",
          "code": "#include <iostream>\nusing namespace std;\n\nint a[105][105], grad[105];\n\nint main() {\n    int n, m;\n    cin >> n >> m;\n    for (int k = 1; k <= m; k++) {\n        int u, v;\n        cin >> u >> v;\n        a[u][v] = a[v][u] = 1;\n    }\n\n    int nodMax = 1;\n    for (int i = 1; i <= n; i++) {\n        for (int j = 1; j <= n; j++) grad[i] += a[i][j];\n        if (grad[i] > grad[nodMax]) nodMax = i;\n    }\n\n    cout << \"Noduri izolate: \";\n    for (int i = 1; i <= n; i++)\n        if (grad[i] == 0) cout << i << ' ';\n    cout << \"\\nGrad maxim: nodul \" << nodMax << \" (\" << grad[nodMax] << \")\";\n    return 0;\n}",
          "lang": "cpp",
          "callout": "ATENȚIE LA MEMORIE:\nMatricea de adiacență ocupă n² elemente, indiferent de câte muchii are graful. Este comodă până la aproximativ n = 1000. Pentru grafuri mai mari se folosesc liste de adiacență (`vector<int> adj[N]`), care ocupă memorie proporțională cu numărul de muchii.",
        },
      ]
    },

    "cpp-11-graphs-bfs": {
      "tag": "INFORMATICĂ // CLASA A 11-A // C++",
      "title": "Parcurgerea în Lățime a Grafurilor (BFS)",
      "subtitle": "Vizitarea nodurilor în ordinea distanței față de nodul de start, cu ajutorul unei cozi.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Cum funcționează",
          "text": "Parcurgerea în lățime (Breadth-First Search) pornește dintr-un nod s și vizitează nodurile „în valuri”: întâi s, apoi toți vecinii lui s, apoi vecinii nevizitați ai acestora și tot așa.\n\nOrdinea este ținută de o coadă: nodurile intră pe la un capăt și ies pe la celălalt, în ordinea în care au fost descoperite.\n\nPașii:\n1. Punem s în coadă și îl marcăm ca vizitat.\n2. Cât timp coada nu este vidă, scoatem primul nod.\n3. Pentru fiecare vecin nevizitat al lui, îl marcăm și îl adăugăm la sfârșitul cozii.\n\nUn nod trebuie marcat în momentul în care intră în coadă, nu când iese. Altfel poate fi adăugat de mai multe ori, de către vecini diferiți.",
        },
        {
          "heading": "2. Implementare cu matrice de adiacență",
          "text": "Coada se poate implementa cu un vector și doi indici: `prim` arată nodul care urmează să fie prelucrat, `ultim` arată ultimul nod adăugat. Cum fiecare nod intră în coadă cel mult o dată, un vector cu n elemente este suficient.\n\nDacă vecinii sunt căutați în ordine crescătoare, ca mai jos, nodurile de pe același nivel apar în ordine crescătoare.",
          "code": "#include <iostream>\nusing namespace std;\n\nint a[105][105], viz[105], coada[105];\n\nint main() {\n    int n, m, s;\n    cin >> n >> m >> s;\n    for (int k = 1; k <= m; k++) {\n        int u, v;\n        cin >> u >> v;\n        a[u][v] = a[v][u] = 1;\n    }\n\n    int prim = 1, ultim = 1;\n    coada[1] = s;\n    viz[s] = 1;\n\n    while (prim <= ultim) {\n        int nod = coada[prim++];\n        cout << nod << ' ';\n        for (int j = 1; j <= n; j++)\n            if (a[nod][j] == 1 && !viz[j]) {\n                viz[j] = 1;\n                coada[++ultim] = j;\n            }\n    }\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Drumuri minime într-un graf neponderat",
          "text": "Pentru că nodurile sunt vizitate în ordinea distanței față de s, BFS găsește drumul cu cel mai mic număr de muchii de la s la orice alt nod.\n\nEste suficient un vector `d`: când descoperim nodul j din nodul curent, `d[j] = d[nod] + 1`. Inițializăm `d` cu -1, astfel încât el să țină și locul vectorului de vizitare: un nod cu `d` egal cu -1 nu a fost încă atins.\n\nVarianta de mai jos folosește liste de adiacență și coada din biblioteca standard.",
          "code": "#include <iostream>\n#include <vector>\n#include <queue>\nusing namespace std;\n\nvector<int> adj[100005];\nint d[100005];\n\nint main() {\n    int n, m, s;\n    cin >> n >> m >> s;\n    for (int k = 1; k <= m; k++) {\n        int u, v;\n        cin >> u >> v;\n        adj[u].push_back(v);\n        adj[v].push_back(u);\n    }\n\n    for (int i = 1; i <= n; i++) d[i] = -1;\n    queue<int> q;\n    q.push(s);\n    d[s] = 0;\n\n    while (!q.empty()) {\n        int nod = q.front();\n        q.pop();\n        for (int vecin : adj[nod])\n            if (d[vecin] == -1) {\n                d[vecin] = d[nod] + 1;\n                q.push(vecin);\n            }\n    }\n\n    for (int i = 1; i <= n; i++) cout << d[i] << ' ';   // -1 = nu se poate ajunge\n    return 0;\n}",
          "lang": "cpp",
          "callout": "ATENȚIE:\nBFS dă drumul minim doar atunci când toate muchiile „costă” la fel. Dacă muchiile au costuri diferite, drumul cu cele mai puține muchii nu mai este neapărat cel mai ieftin și trebuie folosit algoritmul lui Dijkstra.",
        },
      ]
    },

    "cpp-11-graphs-dfs": {
      "tag": "INFORMATICĂ // CLASA A 11-A // C++",
      "title": "Parcurgerea în Adâncime a Grafurilor (DFS)",
      "subtitle": "Mergi cât de departe se poate pe un drum, apoi întoarce-te și încearcă alt vecin.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Cum funcționează",
          "text": "Parcurgerea în adâncime (Depth-First Search) pornește dintr-un nod și merge din vecin în vecin cât timp găsește noduri nevizitate. Când ajunge într-un nod fără vecini nevizitați, se întoarce la nodul anterior și încearcă următorul vecin al acestuia.\n\nComportamentul este exact cel al unei funcții recursive: „întoarcerea” este revenirea din apel. De aceea DFS se scrie în câteva linii:\n\n1. Marchează nodul curent ca vizitat.\n2. Pentru fiecare vecin nevizitat, apelează recursiv DFS din acel vecin.",
          "code": "#include <iostream>\nusing namespace std;\n\nint n, a[105][105], viz[105];\n\nvoid dfs(int nod) {\n    viz[nod] = 1;\n    cout << nod << ' ';\n    for (int j = 1; j <= n; j++)\n        if (a[nod][j] == 1 && !viz[j])\n            dfs(j);\n}\n\nint main() {\n    int m, s;\n    cin >> n >> m >> s;\n    for (int k = 1; k <= m; k++) {\n        int u, v;\n        cin >> u >> v;\n        a[u][v] = a[v][u] = 1;\n    }\n    dfs(s);\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Un exemplu urmărit pas cu pas",
          "text": "Fie graful cu 6 noduri și muchiile [1,2], [1,3], [2,4], [2,5], [3,6]. Pornim din nodul 1 și luăm vecinii în ordine crescătoare.\n\ndfs(1): vizitează 1, primul vecin nevizitat este 2\ndfs(2): vizitează 2, primul vecin nevizitat este 4\ndfs(4): vizitează 4, nu are vecini nevizitați, revine în dfs(2)\ndfs(2): următorul vecin nevizitat este 5\ndfs(5): vizitează 5, revine în dfs(2), care revine în dfs(1)\ndfs(1): următorul vecin nevizitat este 3\ndfs(3): vizitează 3, apoi dfs(6) vizitează 6\n\nOrdinea DFS: 1 2 4 5 3 6\nOrdinea BFS pentru același graf: 1 2 3 4 5 6\n\nAmbele parcurgeri vizitează aceleași noduri (cele la care se poate ajunge din nodul de start), doar ordinea diferă.",
        },
        {
          "heading": "3. Aplicație: detectarea unui ciclu",
          "text": "Într-un graf neorientat există un ciclu dacă, în timpul parcurgerii, dintr-un nod se vede un vecin deja vizitat care nu este nodul din care tocmai am venit (părintele din parcurgere).\n\nFuncția primește și părintele nodului curent, ca să nu considere drept ciclu muchia pe care a sosit. Bucla din `main` pornește câte o parcurgere din fiecare nod nevizitat, pentru a acoperi și grafurile care nu sunt conexe.",
          "code": "#include <iostream>\n#include <vector>\nusing namespace std;\n\nvector<int> adj[100005];\nint viz[100005];\nbool areCiclu = false;\n\nvoid dfs(int nod, int parinte) {\n    viz[nod] = 1;\n    for (int vecin : adj[nod]) {\n        if (!viz[vecin])\n            dfs(vecin, nod);\n        else if (vecin != parinte)\n            areCiclu = true;\n    }\n}\n\nint main() {\n    int n, m;\n    cin >> n >> m;\n    for (int k = 1; k <= m; k++) {\n        int u, v;\n        cin >> u >> v;\n        adj[u].push_back(v);\n        adj[v].push_back(u);\n    }\n\n    for (int i = 1; i <= n; i++)\n        if (!viz[i]) dfs(i, 0);\n\n    cout << (areCiclu ? \"Graful contine un ciclu\" : \"Graful este aciclic\");\n    return 0;\n}",
          "lang": "cpp",
          "callout": "SFAT:\nAlege BFS când problema cere distanțe sau drumuri cu număr minim de muchii. Alege DFS când trebuie doar să afli la ce noduri se poate ajunge (conexitate, componente, cicluri): codul este mai scurt și nu ai nevoie de coadă.",
        },
      ]
    },

    "cpp-11-graphs-connected": {
      "tag": "INFORMATICĂ // CLASA A 11-A // C++",
      "title": "Conexitate & Componente Conexe",
      "subtitle": "Cum afli dacă un graf este dintr-o bucată și cum îi numeri și etichetezi bucățile.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Graf conex și componente conexe",
          "text": "Un lanț este o succesiune de noduri în care oricare două noduri consecutive sunt legate printr-o muchie.\n\nUn graf neorientat este conex dacă între oricare două noduri ale sale există cel puțin un lanț.\n\nDacă graful nu este conex, el se împarte în componente conexe. O componentă conexă este un grup de noduri în care se poate ajunge de la oricare la oricare, și la care nu se mai poate adăuga niciun alt nod cu această proprietate.\n\nCâteva consecințe:\n• un nod izolat formează singur o componentă conexă;\n• un graf conex are exact o componentă conexă;\n• un graf conex cu n noduri are cel puțin n - 1 muchii.",
        },
        {
          "heading": "2. Numărarea componentelor conexe",
          "text": "O parcurgere (DFS sau BFS) pornită dintr-un nod vizitează exact nodurile din componenta lui conexă.\n\nAlgoritmul: parcurgem nodurile de la 1 la n. De fiecare dată când găsim un nod nevizitat, am descoperit o componentă nouă: mărim contorul și lansăm o parcurgere din acel nod, care îi marchează toată componenta.\n\nDacă în loc de 1 marcăm nodurile cu numărul componentei, obținem direct și eticheta fiecărui nod. Două noduri sunt în aceeași componentă dacă au aceeași etichetă.",
          "code": "#include <iostream>\n#include <vector>\nusing namespace std;\n\nvector<int> adj[100005];\nint comp[100005];        // comp[i] = numărul componentei nodului i, 0 = nevizitat\n\nvoid dfs(int nod, int eticheta) {\n    comp[nod] = eticheta;\n    for (int vecin : adj[nod])\n        if (comp[vecin] == 0)\n            dfs(vecin, eticheta);\n}\n\nint main() {\n    int n, m;\n    cin >> n >> m;\n    for (int k = 1; k <= m; k++) {\n        int u, v;\n        cin >> u >> v;\n        adj[u].push_back(v);\n        adj[v].push_back(u);\n    }\n\n    int nrComp = 0;\n    for (int i = 1; i <= n; i++)\n        if (comp[i] == 0) {\n            nrComp++;\n            dfs(i, nrComp);\n        }\n\n    cout << nrComp << '\\n';\n    for (int i = 1; i <= n; i++) cout << comp[i] << ' ';\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Cum faci un graf conex",
          "text": "Întrebare clasică: care este numărul minim de muchii care trebuie adăugate pentru ca graful să devină conex?\n\nO muchie adăugată între două componente diferite le unește într-una singură, deci numărul componentelor scade cu 1. Pentru a ajunge de la k componente la una singură sunt necesare și suficiente k - 1 muchii.\n\nMuchiile se pot alege simplu: se ia câte un nod reprezentant din fiecare componentă (de exemplu primul nod găsit) și se leagă reprezentantul fiecărei componente de reprezentantul componentei următoare.\n\nAlte întrebări care se reduc la același calcul:\n• Graful este conex dacă și numai dacă are o singură componentă.\n• Numărul maxim de muchii care pot fi eliminate astfel încât componentele să rămână aceleași este m - (n - k), unde k este numărul de componente.",
          "callout": "ATENȚIE:\nPentru a verifica dacă un graf este conex nu este suficient să numeri muchiile. Un graf cu n noduri și n - 1 muchii (sau chiar mai multe) poate avea un nod izolat, restul muchiilor fiind îngrămădite între celelalte noduri. Singura verificare sigură este o parcurgere urmată de testul că toate nodurile au fost vizitate.",
        },
      ]
    },

    "cpp-11-digraphs-intro": {
      "tag": "INFORMATICĂ // CLASA A 11-A // C++",
      "title": "Grafuri Orientate: Arcuri & Matrice de Adiacență",
      "subtitle": "Grafuri în care legăturile au sens: grade interioare și exterioare, drumuri și circuite.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Arce și grade",
          "text": "Într-un graf orientat, legăturile dintre noduri au sens și se numesc arce. Arcul (u, v) pleacă din u și ajunge în v. El nu este același lucru cu arcul (v, u).\n\nFiecare nod are două grade:\n• gradul exterior d+(x): numărul de arce care ies din x;\n• gradul interior d-(x): numărul de arce care intră în x.\n\nSuma gradelor exterioare este egală cu suma gradelor interioare și cu numărul de arce, pentru că fiecare arc iese dintr-un nod și intră în altul.\n\nUn graf orientat cu n noduri are cel mult n · (n - 1) arce.",
        },
        {
          "heading": "2. Matricea de adiacență",
          "text": "În matricea de adiacență, `a[i][j]` este 1 dacă există arc de la i la j. La citirea unui arc se completează un singur element, deci matricea nu mai este, în general, simetrică.\n\n• Suma elementelor de pe linia i este gradul exterior al nodului i.\n• Suma elementelor de pe coloana i este gradul interior al nodului i.",
          "code": "#include <iostream>\nusing namespace std;\n\nint a[105][105];\n\nint main() {\n    int n, m;\n    cin >> n >> m;\n    for (int k = 1; k <= m; k++) {\n        int u, v;\n        cin >> u >> v;\n        a[u][v] = 1;                 // doar într-un sens\n    }\n\n    for (int i = 1; i <= n; i++) {\n        int gradExt = 0, gradInt = 0;\n        for (int j = 1; j <= n; j++) {\n            gradExt += a[i][j];      // linia i\n            gradInt += a[j][i];      // coloana i\n        }\n        cout << \"Nodul \" << i << \": exterior \" << gradExt << \", interior \" << gradInt << '\\n';\n    }\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Drumuri, circuite și accesibilitate",
          "text": "Un drum este o succesiune de noduri în care de la fiecare nod la următorul există un arc, parcurs în sensul lui. Un circuit este un drum care se termină în nodul din care a pornit.\n\nSpunem că nodul y este accesibil din x dacă există un drum de la x la y. Relația nu este simetrică: se poate ajunge de la x la y fără să se poată ajunge înapoi.\n\nNodurile accesibile dintr-un nod dat se află cu aceeași parcurgere DFS ca la grafurile neorientate, cu diferența că arcele sunt urmate doar în sensul lor.",
          "code": "#include <iostream>\nusing namespace std;\n\nint n, a[105][105], viz[105];\n\nvoid dfs(int nod) {\n    viz[nod] = 1;\n    for (int j = 1; j <= n; j++)\n        if (a[nod][j] == 1 && !viz[j])\n            dfs(j);\n}\n\nint main() {\n    int m, s;\n    cin >> n >> m >> s;\n    for (int k = 1; k <= m; k++) {\n        int u, v;\n        cin >> u >> v;\n        a[u][v] = 1;\n    }\n\n    dfs(s);\n    cout << \"Noduri accesibile din \" << s << \": \";\n    for (int i = 1; i <= n; i++)\n        if (viz[i] && i != s) cout << i << ' ';\n    return 0;\n}",
          "lang": "cpp",
          "callout": "EROARE FRECVENTĂ:\nScrierea din obișnuință a liniei `a[u][v] = a[v][u] = 1;` la citirea unui graf orientat. Programul se compilează și rulează, dar lucrează pe un graf neorientat, iar gradele și drumurile ies greșite.",
        },
      ]
    },

    "cpp-11-trees-rooted": {
      "tag": "INFORMATICĂ // CLASA A 11-A // C++",
      "title": "Arbori cu Rădăcină: Vectorul de Tați & Frunze",
      "subtitle": "Grafuri conexe fără cicluri, reprezentate printr-un singur vector.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Ce este un arbore",
          "text": "Un arbore este un graf neorientat conex și fără cicluri.\n\nPentru un graf cu n noduri, următoarele afirmații spun același lucru:\n• graful este arbore;\n• graful este conex și are n - 1 muchii;\n• graful nu are cicluri și are n - 1 muchii;\n• între oricare două noduri există exact un lanț.\n\nDacă dintr-un arbore se elimină o muchie, el nu mai este conex. Dacă i se adaugă o muchie, apare un ciclu.\n\nAlegând un nod drept rădăcină, arborele capătă o ierarhie:\n• fiecare nod, în afară de rădăcină, are un singur tată (nodul vecin dinspre rădăcină);\n• vecinii dinspre partea opusă rădăcinii sunt fiii nodului;\n• un nod fără fii se numește frunză;\n• nivelul unui nod este numărul de muchii de pe drumul de la rădăcină până la el.",
        },
        {
          "heading": "2. Vectorul de tați",
          "text": "Pentru că fiecare nod are un singur tată, un arbore cu rădăcină se poate memora într-un singur vector: `t[i]` este tatăl nodului i, iar pentru rădăcină `t[rad] = 0`.\n\nDin acest vector se obțin direct:\n• rădăcina: nodul cu `t[i] == 0`;\n• fiii unui nod x: toate nodurile i cu `t[i] == x`;\n• frunzele: nodurile care nu apar deloc ca valoare în vector.",
          "code": "#include <iostream>\nusing namespace std;\n\nint t[105], nrFii[105];\n\nint main() {\n    int n;\n    cin >> n;\n    int radacina = 0;\n    for (int i = 1; i <= n; i++) {\n        cin >> t[i];\n        if (t[i] == 0) radacina = i;\n        else nrFii[t[i]]++;\n    }\n\n    cout << \"Radacina: \" << radacina << '\\n';\n    cout << \"Frunze: \";\n    for (int i = 1; i <= n; i++)\n        if (nrFii[i] == 0) cout << i << ' ';\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Drumul spre rădăcină și nivelul unui nod",
          "text": "Pornind dintr-un nod și trecând repetat la tatăl său, ajungem la rădăcină. Numărul de pași făcuți este nivelul nodului, iar nodurile întâlnite sunt strămoșii lui.\n\nÎnălțimea arborelui este cel mai mare nivel al unui nod.\n\nExemplu pentru vectorul de tați (0, 1, 1, 2, 2, 3): rădăcina este 1, nodurile 2 și 3 sunt pe nivelul 1, iar nodurile 4, 5 și 6 pe nivelul 2. Frunzele sunt 4, 5 și 6, iar înălțimea este 2.",
          "code": "#include <iostream>\nusing namespace std;\n\nint t[105];\n\nint nivel(int nod) {\n    int pasi = 0;\n    while (t[nod] != 0) {\n        nod = t[nod];\n        pasi++;\n    }\n    return pasi;\n}\n\nint main() {\n    int n, x;\n    cin >> n;\n    for (int i = 1; i <= n; i++) cin >> t[i];\n    cin >> x;\n\n    cout << \"Drumul de la \" << x << \" la radacina: \";\n    for (int nod = x; nod != 0; nod = t[nod]) cout << nod << ' ';\n\n    int inaltime = 0;\n    for (int i = 1; i <= n; i++)\n        if (nivel(i) > inaltime) inaltime = nivel(i);\n    cout << \"\\nInaltimea arborelui: \" << inaltime;\n    return 0;\n}",
          "lang": "cpp",
          "callout": "SFAT PENTRU BACALAUREAT:\nLa întrebările cu vector de tați, primul lucru de făcut este desenul arborelui: găsește rădăcina (valoarea 0), apoi așază sub fiecare nod fiii lui. Aproape toate cerințele (frunze, descendenți, nivel, înălțime, lanțuri) se citesc apoi direct de pe desen.",
        },
      ]
    },

    "cpp-11-dp-intro": {
      "tag": "INFORMATICĂ // CLASA A 11-A // C++",
      "title": "Programare Dinamică: Memoizare & Recurență",
      "subtitle": "Rezolvă fiecare subproblemă o singură dată și păstrează rezultatul.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Problema: aceleași calcule, făcute de multe ori",
          "text": "Unele probleme se descompun în subprobleme care se repetă. Funcția recursivă pentru șirul lui Fibonacci calculează F(n - 2) atât direct, cât și în interiorul lui F(n - 1), iar fenomenul se amplifică la fiecare nivel. Pentru n = 50 rezultă miliarde de apeluri, deși există doar 50 de valori diferite de calculat.\n\nProgramarea dinamică pornește de la o idee simplă: fiecare subproblemă se rezolvă o singură dată, iar rezultatul se păstrează într-un tablou, de unde este refolosit.\n\nMetoda se aplică atunci când:\n• problema se poate exprima printr-o relație de recurență între subprobleme mai mici;\n• aceleași subprobleme apar de mai multe ori.\n\nFață de Divide et Impera, unde subproblemele sunt independente, aici ele se suprapun.",
        },
        {
          "heading": "2. Cele două moduri de implementare",
          "text": "Memoizare (de sus în jos). Se păstrează funcția recursivă, dar înainte de a calcula ceva se verifică dacă rezultatul există deja în tablou.\n\nTabelare (de jos în sus). Se renunță la recursivitate: tabloul se completează cu o buclă, de la subproblemele cele mai mici către cea cerută.\n\nAmbele variante de mai jos calculează F(n) în O(n).",
          "code": "#include <iostream>\nusing namespace std;\n\nlong long memo[95];\n\n// Memoizare: recursiv, cu rezultatele păstrate.\nlong long fibMemo(int n) {\n    if (n <= 2) return 1;\n    if (memo[n] != 0) return memo[n];          // deja calculat\n    memo[n] = fibMemo(n - 1) + fibMemo(n - 2);\n    return memo[n];\n}\n\n// Tabelare: iterativ, de la mic la mare.\nlong long fibTabel(int n) {\n    long long dp[95];\n    dp[1] = dp[2] = 1;\n    for (int i = 3; i <= n; i++)\n        dp[i] = dp[i - 1] + dp[i - 2];\n    return dp[n];\n}\n\nint main() {\n    int n;\n    cin >> n;                                   // 1 <= n <= 90\n    cout << fibMemo(n) << ' ' << fibTabel(n);\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Un exemplu complet: urcarea scărilor",
          "text": "O scară are n trepte. La fiecare pas se poate urca o treaptă sau două. În câte moduri se poate ajunge pe treapta n?\n\nPașii de gândire sunt aceiași la orice problemă de programare dinamică:\n\n1. Starea: `dp[i]` = numărul de moduri de a ajunge pe treapta i.\n2. Recurența: pe treapta i se ajunge fie de pe treapta i - 1, fie de pe treapta i - 2, deci `dp[i] = dp[i - 1] + dp[i - 2]`.\n3. Cazurile de bază: `dp[0] = 1` (există un singur mod de a sta pe loc) și `dp[1] = 1`.\n4. Ordinea de calcul: crescător după i, pentru că `dp[i]` depinde de valori cu indice mai mic.\n5. Răspunsul: `dp[n]`.",
          "code": "#include <iostream>\nusing namespace std;\n\nlong long dp[95];\n\nint main() {\n    int n;\n    cin >> n;\n\n    dp[0] = 1;\n    dp[1] = 1;\n    for (int i = 2; i <= n; i++)\n        dp[i] = dp[i - 1] + dp[i - 2];\n\n    cout << dp[n];\n    return 0;\n}",
          "lang": "cpp",
          "callout": "REGULĂ DE LUCRU:\nScrie pe hârtie, în cuvinte, ce înseamnă `dp[i]` înainte de a scrie vreo linie de cod. Dacă definiția stării este clară, recurența și cazurile de bază rezultă aproape singure. Cele mai multe soluții greșite pornesc de la o stare definită vag.",
        },
      ]
    },

    "cpp-11-dp-subseq": {
      "tag": "INFORMATICĂ // CLASA A 11-A // C++",
      "title": "Subșirul Crescător Maximal (LIS)",
      "subtitle": "Cel mai lung subșir strict crescător al unui vector, cu reconstituirea elementelor lui.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Enunț și definirea stării",
          "text": "Un subșir se obține dintr-un vector eliminând zero sau mai multe elemente, fără a schimba ordinea celor rămase. Elementele unui subșir nu trebuie să fie vecine în vector (spre deosebire de o secvență).\n\nSe cere lungimea maximă a unui subșir strict crescător.\n\nExemplu: pentru v = (5, 2, 8, 6, 3, 6, 9, 7), un subșir crescător de lungime maximă este (2, 3, 6, 9), cu lungimea 4.\n\nStarea: `dp[i]` = lungimea celui mai lung subșir crescător care se termină exact cu elementul `v[i]`.\n\nFixarea ultimului element este cheia: știind cu ce valoare se termină un subșir, putem decide dacă îl putem prelungi.",
        },
        {
          "heading": "2. Recurența și calculul lungimii",
          "text": "Un subșir care se termină în `v[i]` este fie format doar din `v[i]`, fie obținut prin adăugarea lui `v[i]` la un subșir care se termină într-un element mai mic, aflat înaintea lui:\n\n`dp[i] = 1 + max(dp[j])`, pentru toți j < i cu `v[j] < v[i]`\n\nDacă nu există niciun astfel de j, `dp[i] = 1`.\n\nRăspunsul este maximul din tot vectorul `dp`, nu `dp[n]`: subșirul cel mai lung nu se termină neapărat în ultimul element.\n\nPentru exemplul de mai sus, dp = (1, 1, 2, 2, 2, 3, 4, 4).\n\nCele două bucle imbricate dau complexitatea O(n²).",
          "code": "#include <iostream>\nusing namespace std;\n\nint v[1005], dp[1005];\n\nint main() {\n    int n;\n    cin >> n;\n    for (int i = 1; i <= n; i++) cin >> v[i];\n\n    int lungMax = 0;\n    for (int i = 1; i <= n; i++) {\n        dp[i] = 1;\n        for (int j = 1; j < i; j++)\n            if (v[j] < v[i] && dp[j] + 1 > dp[i])\n                dp[i] = dp[j] + 1;\n        if (dp[i] > lungMax) lungMax = dp[i];\n    }\n\n    cout << lungMax;\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Reconstituirea subșirului",
          "text": "Pentru a afișa și elementele, reținem pentru fiecare poziție de unde a venit valoarea optimă: `pred[i]` este poziția elementului aflat înaintea lui `v[i]` în subșirul optim care se termină în i (sau 0 dacă `v[i]` este primul).\n\nDupă calcul, pornim din poziția în care `dp` este maxim și mergem înapoi din predecesor în predecesor. Elementele rezultă în ordine inversă, așa că le afișăm cu o funcție recursivă care tipărește la întoarcere.",
          "code": "#include <iostream>\nusing namespace std;\n\nint v[1005], dp[1005], pred[1005];\n\nvoid afiseaza(int i) {\n    if (i == 0) return;\n    afiseaza(pred[i]);\n    cout << v[i] << ' ';\n}\n\nint main() {\n    int n;\n    cin >> n;\n    for (int i = 1; i <= n; i++) cin >> v[i];\n\n    int pozMax = 1;\n    for (int i = 1; i <= n; i++) {\n        dp[i] = 1;\n        pred[i] = 0;\n        for (int j = 1; j < i; j++)\n            if (v[j] < v[i] && dp[j] + 1 > dp[i]) {\n                dp[i] = dp[j] + 1;\n                pred[i] = j;\n            }\n        if (dp[i] > dp[pozMax]) pozMax = i;\n    }\n\n    cout << dp[pozMax] << '\\n';\n    afiseaza(pozMax);\n    return 0;\n}",
          "lang": "cpp",
          "callout": "ATENȚIE LA ENUNȚ:\nVerifică dacă se cere subșir strict crescător (`v[j] < v[i]`) sau doar crescător (`v[j] <= v[i]`). Pentru vectorul (3, 3, 3) răspunsul este 1 în primul caz și 3 în al doilea.",
        },
      ]
    },

    "cpp-11-dp-knapsack": {
      "tag": "INFORMATICĂ // CLASA A 11-A // C++",
      "title": "Problema Rucsacului Discret (0-1 Knapsack)",
      "subtitle": "Alegerea obiectelor de valoare maximă care încap într-o capacitate dată.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Enunț și de ce nu merge o strategie lacomă",
          "text": "Avem n obiecte. Obiectul i are greutatea `g[i]` și valoarea `val[i]`. Rucsacul suportă greutatea totală G. Fiecare obiect poate fi luat întreg sau lăsat (de aici „0-1”). Se cere valoarea totală maximă.\n\nIdeea de a lua mereu obiectul cu cel mai bun raport valoare / greutate nu funcționează. Exemplu, cu G = 10:\n\n• obiectul 1: greutate 6, valoare 30 (raport 5)\n• obiectul 2: greutate 5, valoare 20 (raport 4)\n• obiectul 3: greutate 5, valoare 20 (raport 4)\n\nStrategia lacomă ia obiectul 1 și nu mai are loc pentru altceva: valoare 30. Soluția optimă ia obiectele 2 și 3: valoare 40.\n\nEste nevoie de o metodă care să țină cont de toate combinațiile, fără să le enumere pe toate.",
        },
        {
          "heading": "2. Soluția cu matrice",
          "text": "Starea: `dp[i][j]` = valoarea maximă care se poate obține folosind doar primele i obiecte, cu greutatea totală cel mult j.\n\nPentru obiectul i există două posibilități:\n• nu îl luăm: valoarea rămâne `dp[i - 1][j]`;\n• îl luăm (doar dacă `g[i] <= j`): câștigăm `val[i]`, iar pentru restul de greutate folosim cea mai bună soluție cu primele i - 1 obiecte, `dp[i - 1][j - g[i]]`.\n\n`dp[i][j] = max(dp[i - 1][j], dp[i - 1][j - g[i]] + val[i])`\n\nLinia 0 (niciun obiect) este plină de zerouri. Răspunsul este `dp[n][G]`. Complexitatea este O(n · G), atât ca timp, cât și ca memorie.",
          "code": "#include <iostream>\nusing namespace std;\n\nint g[105], val[105], dp[105][10005];\n\nint main() {\n    int n, G;\n    cin >> n >> G;\n    for (int i = 1; i <= n; i++) cin >> g[i] >> val[i];\n\n    for (int i = 1; i <= n; i++)\n        for (int j = 0; j <= G; j++) {\n            dp[i][j] = dp[i - 1][j];                       // nu luăm obiectul i\n            if (g[i] <= j && dp[i - 1][j - g[i]] + val[i] > dp[i][j])\n                dp[i][j] = dp[i - 1][j - g[i]] + val[i];   // îl luăm\n        }\n\n    cout << dp[n][G];\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Optimizarea memoriei: un singur vector",
          "text": "Linia i a matricei depinde doar de linia i - 1, deci este suficient un singur vector `dp[j]`, actualizat pentru fiecare obiect.\n\nSensul de parcurgere devine esențial: j trebuie să meargă descrescător, de la G la `g[i]`. Astfel, în momentul în care calculăm `dp[j]`, valoarea `dp[j - g[i]]` este încă cea de la pasul anterior, adică fără obiectul i.\n\nMemoria scade de la O(n · G) la O(G).",
          "code": "#include <iostream>\nusing namespace std;\n\nint dp[10005];\n\nint main() {\n    int n, G;\n    cin >> n >> G;\n\n    for (int i = 1; i <= n; i++) {\n        int g, val;\n        cin >> g >> val;\n        for (int j = G; j >= g; j--)\n            if (dp[j - g] + val > dp[j])\n                dp[j] = dp[j - g] + val;\n    }\n\n    cout << dp[G];\n    return 0;\n}",
          "lang": "cpp",
          "callout": "CAPCANĂ:\nDacă în varianta cu un singur vector parcurgi j crescător, `dp[j - g]` poate conține deja obiectul curent, iar același obiect ajunge să fie luat de mai multe ori. Rezultatul este soluția altei probleme: rucsacul în care fiecare obiect este disponibil în oricâte exemplare.",
        },
      ]
    },

    "mat-11-matrices": {
      "tag": "MATEMATICĂ // CLASA A 11-A // ALGEBRĂ",
      "title": "Algebră Liniară: Operații cu Matrice",
      "subtitle": "Adunarea, înmulțirea cu un număr, produsul a două matrice și puterile unei matrice.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Matrice, egalitate și transpusă",
          "text": "O matrice cu m linii și n coloane este un tablou dreptunghiular de numere. Elementul de pe linia i și coloana j se notează a_ij. Mulțimea acestor matrice cu elemente reale se notează M(m, n)(ℝ), iar pentru matricele pătratice de ordin n se scrie M_n(ℝ).\n\nMatrice particulare:\n• matricea nulă O_n are toate elementele 0;\n• matricea unitate I_n are 1 pe diagonala principală și 0 în rest. Exemplu: I₂ = [ [1, 0], [0, 1] ].\n\nDouă matrice sunt egale dacă au același tip și elementele de pe aceleași poziții sunt egale.\n\nTranspusa unei matrice A, notată A^t, se obține schimbând liniile cu coloanele. Exemplu:\nA = [ [1, 2, 3], [4, 5, 6] ] are transpusa A^t = [ [1, 4], [2, 5], [3, 6] ].\n\nUrma unei matrice pătratice, Tr(A), este suma elementelor de pe diagonala principală.",
        },
        {
          "heading": "2. Adunarea și înmulțirea cu un număr",
          "text": "Adunarea se face element cu element și este definită doar pentru matrice de același tip.\n\nExemplu: [ [1, 2], [3, 4] ] + [ [5, 0], [-1, 2] ] = [ [6, 2], [2, 6] ]\n\nÎnmulțirea cu un număr real înmulțește fiecare element cu acel număr.\n\nExemplu: 3 · [ [1, -2], [0, 4] ] = [ [3, -6], [0, 12] ]\n\nProprietăți ale adunării:\n• este comutativă: A + B = B + A;\n• este asociativă: (A + B) + C = A + (B + C);\n• matricea nulă este element neutru: A + O = A;\n• orice matrice are o opusă, -A, cu A + (-A) = O.",
        },
        {
          "heading": "3. Înmulțirea matricelor",
          "text": "Produsul A · B este definit doar dacă numărul de coloane ale lui A este egal cu numărul de linii ale lui B. Dacă A are tipul (m, n) și B are tipul (n, p), produsul are tipul (m, p).\n\nElementul de pe linia i și coloana j al produsului se obține înmulțind linia i din A cu coloana j din B, element cu element, și adunând rezultatele.\n\nExemplu: A = [ [1, 2], [3, 4] ], B = [ [0, 1], [2, 3] ]\n\nA · B:\n• linia 1, coloana 1: 1·0 + 2·2 = 4\n• linia 1, coloana 2: 1·1 + 2·3 = 7\n• linia 2, coloana 1: 3·0 + 4·2 = 8\n• linia 2, coloana 2: 3·1 + 4·3 = 15\n\nA · B = [ [4, 7], [8, 15] ]\n\nCalculând în ordinea inversă se obține B · A = [ [3, 4], [11, 16] ], deci A · B ≠ B · A.\n\nProprietăți:\n• înmulțirea este asociativă: (A · B) · C = A · (B · C);\n• este distributivă față de adunare: A · (B + C) = A · B + A · C;\n• matricea unitate este element neutru: A · I_n = I_n · A = A;\n• în general nu este comutativă.\n\nPuterile unei matrice pătratice: A² = A · A, A³ = A² · A și așa mai departe.",
          "callout": "PROBLEMĂ TIPICĂ DE BACALAUREAT:\nFie A = [ [1, 1], [0, 1] ]. Să se calculeze A^n, pentru n natural nenul.\nRezolvare:\nA² = [ [1, 2], [0, 1] ] și A³ = [ [1, 3], [0, 1] ].\nPresupunem că A^n = [ [1, n], [0, 1] ] și demonstrăm prin inducție.\nPentru n = 1 afirmația este adevărată.\nDacă este adevărată pentru n, atunci A^(n+1) = A^n · A = [ [1, n], [0, 1] ] · [ [1, 1], [0, 1] ] = [ [1, n + 1], [0, 1] ].\nPrin urmare A^n = [ [1, n], [0, 1] ] pentru orice n ≥ 1.",
        },
      ]
    },

    "mat-11-limits": {
      "tag": "MATEMATICĂ // CLASA A 11-A // ANALIZĂ",
      "title": "Analiză: Limite de Funcții & Cazuri de Nedeterminare",
      "subtitle": "Calculul limitelor, eliminarea nedeterminărilor și limitele remarcabile.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Limite care se calculează direct",
          "text": "Pentru funcțiile elementare (polinoame, radicali, exponențiale, logaritmi, funcții trigonometrice), limita într-un punct din domeniul de definiție se obține prin înlocuire:\n\nlim (x→2) (x² + 3x) = 4 + 6 = 10\n\nReguli utile la infinit:\n• lim (x→∞) 1/x = 0\n• un polinom se comportă la infinit ca termenul său de grad maxim;\n• lim (x→∞) a^x = ∞ dacă a > 1 și 0 dacă 0 < a < 1;\n• lim (x→∞) ln x = ∞, iar lim (x→0, x>0) ln x = -∞.\n\nOperații cu infinit care au rezultat sigur:\n• ∞ + ∞ = ∞\n• ∞ · ∞ = ∞\n• c / ∞ = 0, pentru orice număr real c\n• c / 0 este +∞ sau -∞ (pentru c ≠ 0), în funcție de semne.\n\nCazurile de nedeterminare, în care rezultatul nu se poate spune direct, sunt:\n0/0, ∞/∞, ∞ - ∞, 0 · ∞, 1^∞, 0^0, ∞^0",
        },
        {
          "heading": "2. Cazurile ∞/∞ și 0/0",
          "text": "Cazul ∞/∞ la funcții raționale. Se dă factor comun forțat puterea cea mai mare a lui x. Rezultatul depinde doar de gradele numărătorului și numitorului:\n• grade egale: limita este raportul coeficienților dominanți;\n• gradul numărătorului mai mic: limita este 0;\n• gradul numărătorului mai mare: limita este +∞ sau -∞.\n\nExemplu:\nlim (x→∞) (3x² + 5x - 1) / (2x² - x + 4) = 3/2\n\nCazul 0/0 la funcții raționale. Dacă numărătorul și numitorul se anulează amândouă în x₀, ambele se divid cu (x - x₀). Se descompun în factori și se simplifică.\n\nExemplu:\nlim (x→2) (x² - 4) / (x² - 3x + 2)\n= lim (x→2) (x - 2)(x + 2) / ((x - 2)(x - 1))\n= lim (x→2) (x + 2) / (x - 1)\n= 4\n\nCazul 0/0 sau ∞ - ∞ cu radicali. Se amplifică cu expresia conjugată.\n\nExemplu:\nlim (x→∞) (√(x² + x) - x)\n= lim (x→∞) (x² + x - x²) / (√(x² + x) + x)\n= lim (x→∞) x / (x · (√(1 + 1/x) + 1))\n= 1/2",
        },
        {
          "heading": "3. Limite remarcabile și regula lui l'Hospital",
          "text": "Limite remarcabile, valabile când x → 0:\n• lim sin x / x = 1\n• lim tg x / x = 1\n• lim (e^x - 1) / x = 1\n• lim ln(1 + x) / x = 1\n• lim (a^x - 1) / x = ln a\n• lim (1 + x)^(1/x) = e\n\nLa infinit: lim (x→∞) (1 + 1/x)^x = e\n\nFormulele rămân valabile dacă în locul lui x apare o expresie u(x) care tinde la 0.\n\nExemplu: lim (x→0) sin(3x) / x = lim (x→0) 3 · sin(3x) / (3x) = 3 · 1 = 3\n\nRegula lui l'Hospital. Dacă lim f(x) / g(x) este în cazul 0/0 sau ∞/∞, funcțiile sunt derivabile în vecinătatea punctului și există limita raportului derivatelor, atunci:\n\nlim f(x) / g(x) = lim f'(x) / g'(x)\n\nExemplu: lim (x→0) (e^x - 1 - x) / x² este în cazul 0/0.\nAplicăm regula: lim (x→0) (e^x - 1) / (2x), din nou 0/0.\nAplicăm încă o dată: lim (x→0) e^x / 2 = 1/2.\n\nAsimptota orizontală: dacă lim (x→∞) f(x) = L, cu L finit, dreapta y = L este asimptotă orizontală spre +∞.\nAsimptota verticală: dacă o limită laterală în x₀ este infinită, dreapta x = x₀ este asimptotă verticală.",
          "callout": "ATENȚIE LA REGULA LUI L'HOSPITAL:\n1) Se derivează separat numărătorul și numitorul. Nu se aplică formula de derivare a câtului.\n2) Regula se aplică doar în cazurile 0/0 și ∞/∞. Verifică de fiecare dată cazul înainte de a deriva. Aplicată în afara lor, dă un rezultat greșit: lim (x→1) (x + 1) / x este 2, dar raportul derivatelor este 1.",
        },
      ]
    },

    "cpp-12-oop-classes": {
      "tag": "INFORMATICĂ // CLASA A 12-A // C++",
      "title": "OOP în C++: Clase, Obiecte & Modificatori de Acces",
      "subtitle": "Cum punem la un loc datele și funcțiile care lucrează cu ele și cine are voie să le folosească.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Clasă și obiect",
          "text": "Programarea orientată pe obiecte (OOP) organizează programul în jurul obiectelor: entități care au atât date, cât și funcții proprii.\n\n• Clasa este tiparul: descrie ce date are un obiect (atribute, date membre) și ce poate face (metode, funcții membre).\n• Obiectul este o variabilă de tipul clasei, numită și instanță. Fiecare obiect are propriile valori ale atributelor.\n\nMembrii unui obiect se accesează cu operatorul punct, ca la `struct`. O metodă se apelează pentru un anumit obiect și lucrează direct cu atributele acestuia.",
          "code": "#include <iostream>\nusing namespace std;\n\nclass Dreptunghi {\npublic:\n    double lungime, latime;\n\n    double aria() {\n        return lungime * latime;\n    }\n\n    double perimetru() {\n        return 2 * (lungime + latime);\n    }\n};\n\nint main() {\n    Dreptunghi d1, d2;            // două obiecte ale aceleiași clase\n    d1.lungime = 4;  d1.latime = 3;\n    d2.lungime = 10; d2.latime = 2;\n\n    cout << d1.aria() << ' ' << d2.aria() << '\\n';     // 12 20\n    cout << d1.perimetru();                            // 14\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Modificatorii de acces",
          "text": "Fiecare membru al unei clase are un nivel de acces:\n\n• `public` : poate fi folosit de oriunde din program.\n• `private` : poate fi folosit doar de metodele clasei.\n• `protected` : ca `private`, dar accesibil și claselor derivate (apare la moștenire).\n\nÎntr-o clasă, tot ce nu este marcat altfel este `private`. Aceasta este singura diferență dintre `class` și `struct`: la `struct`, accesul implicit este `public`.\n\nRegula obișnuită este ca atributele să fie private, iar metodele prin care lumea din afară lucrează cu obiectul să fie publice.",
          "code": "#include <iostream>\nusing namespace std;\n\nclass ContBancar {\nprivate:\n    double sold;\n\npublic:\n    void initializeaza() {\n        sold = 0;\n    }\n\n    void depune(double suma) {\n        if (suma > 0) sold += suma;\n    }\n\n    bool retrage(double suma) {\n        if (suma <= 0 || suma > sold) return false;\n        sold -= suma;\n        return true;\n    }\n\n    double getSold() {\n        return sold;\n    }\n};\n\nint main() {\n    ContBancar c;\n    c.initializeaza();\n    c.depune(500);\n\n    if (!c.retrage(800)) cout << \"Fonduri insuficiente\\n\";\n    cout << c.getSold();          // 500\n\n    // c.sold = 1000000;          // eroare la compilare: sold este private\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Definirea metodelor în afara clasei",
          "text": "În clasele mai mari, în interiorul clasei se scriu doar prototipurile metodelor, iar definițiile se pun după. Numele metodei este atunci precedat de numele clasei și de operatorul de rezoluție `::`.\n\nÎn corpul unei metode, cuvântul `this` este un pointer către obiectul pentru care a fost apelată metoda. Se folosește mai ales când un parametru are același nume cu un atribut.",
          "code": "#include <iostream>\nusing namespace std;\n\nclass Punct {\nprivate:\n    int x, y;\n\npublic:\n    void seteaza(int x, int y);\n    void muta(int dx, int dy);\n    void afiseaza();\n};\n\nvoid Punct::seteaza(int x, int y) {\n    this->x = x;         // this->x este atributul, x este parametrul\n    this->y = y;\n}\n\nvoid Punct::muta(int dx, int dy) {\n    x += dx;\n    y += dy;\n}\n\nvoid Punct::afiseaza() {\n    cout << '(' << x << \", \" << y << \")\\n\";\n}\n\nint main() {\n    Punct p;\n    p.seteaza(2, 3);\n    p.muta(5, -1);\n    p.afiseaza();        // (7, 2)\n    return 0;\n}",
          "lang": "cpp",
          "callout": "EROARE FRECVENTĂ:\nLa fel ca la `struct`, definiția unei clase se încheie cu punct și virgulă după acolada de închidere. A doua greșeală des întâlnită este uitarea lui `public:`. Într-o clasă fără niciun modificator, toți membrii sunt privați și nu pot fi folosiți din `main`.",
        },
      ]
    },

    "cpp-12-oop-constructors": {
      "tag": "INFORMATICĂ // CLASA A 12-A // C++",
      "title": "Constructori, Destructori & Încapsulare",
      "subtitle": "Cum ia naștere un obiect cu valori corecte, ce se întâmplă când dispare și de ce ascundem datele.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Constructorul",
          "text": "Constructorul este o metodă specială care se execută automat în momentul în care este creat un obiect. Rolul lui este să dea atributelor valori inițiale corecte.\n\nReguli:\n• are exact numele clasei;\n• nu are tip returnat, nici măcar `void`;\n• poate avea parametri, iar o clasă poate avea mai mulți constructori, cu liste diferite de parametri (supraîncărcare).\n\nConstructorul fără parametri se numește constructor implicit. El este folosit la declarații de forma `Fractie f;`.",
          "code": "#include <iostream>\nusing namespace std;\n\nclass Fractie {\nprivate:\n    int numarator, numitor;\n\npublic:\n    Fractie() {                       // constructor implicit\n        numarator = 0;\n        numitor = 1;\n    }\n\n    Fractie(int a, int b) {           // constructor cu parametri\n        numarator = a;\n        numitor = (b != 0) ? b : 1;\n    }\n\n    void afiseaza() {\n        cout << numarator << '/' << numitor << '\\n';\n    }\n};\n\nint main() {\n    Fractie f1;            // apelează constructorul implicit\n    Fractie f2(3, 4);      // apelează constructorul cu parametri\n    f1.afiseaza();         // 0/1\n    f2.afiseaza();         // 3/4\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Lista de inițializare și constructorul de copiere",
          "text": "Atributele pot fi inițializate și printr-o listă de inițializare, scrisă între antetul constructorului și corpul lui. Este forma recomandată și singura posibilă pentru atributele constante.\n\nConstructorul de copiere creează un obiect nou ca o copie a unuia existent. Primește ca parametru o referință constantă la un obiect din aceeași clasă. Dacă nu îl scriem, compilatorul generează unul care copiază atributele unul câte unul.",
          "code": "#include <iostream>\nusing namespace std;\n\nclass Punct {\nprivate:\n    int x, y;\n\npublic:\n    Punct(int x0, int y0) : x(x0), y(y0) {}        // listă de inițializare\n\n    Punct(const Punct &p) : x(p.x), y(p.y) {       // constructor de copiere\n        cout << \"Copiere\\n\";\n    }\n\n    void afiseaza() {\n        cout << '(' << x << \", \" << y << \")\\n\";\n    }\n};\n\nint main() {\n    Punct a(1, 2);\n    Punct b = a;          // se apelează constructorul de copiere\n    b.afiseaza();         // (1, 2)\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Destructorul",
          "text": "Destructorul se execută automat când obiectul își încetează existența: la ieșirea din blocul în care a fost declarat sau la `delete`, pentru obiectele alocate dinamic.\n\n• are numele clasei precedat de `~`;\n• nu are parametri și nu are tip returnat;\n• o clasă are un singur destructor.\n\nDevine necesar atunci când obiectul deține o resursă care trebuie eliberată, de exemplu memorie alocată cu `new`.",
          "code": "#include <iostream>\nusing namespace std;\n\nclass Vector {\nprivate:\n    int n;\n    int *elemente;\n\npublic:\n    Vector(int dim) : n(dim) {\n        elemente = new int[n];           // resursă alocată în constructor\n        for (int i = 0; i < n; i++) elemente[i] = 0;\n        cout << \"Construit\\n\";\n    }\n\n    ~Vector() {\n        delete[] elemente;               // eliberată în destructor\n        cout << \"Distrus\\n\";\n    }\n\n    void seteaza(int poz, int val) {\n        if (poz >= 0 && poz < n) elemente[poz] = val;\n    }\n};\n\nint main() {\n    {\n        Vector v(10);\n        v.seteaza(3, 42);\n    }                                    // aici se apelează destructorul\n    cout << \"Sfarsit\";\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "4. Încapsularea",
          "text": "Încapsularea înseamnă că datele unui obiect sunt ascunse (`private`), iar accesul la ele se face doar prin metode publice care verifică ce primesc.\n\nAvantaje:\n• obiectul nu poate ajunge într-o stare greșită (o vârstă negativă, un numitor egal cu zero);\n• modul în care sunt păstrate datele poate fi schimbat mai târziu fără a modifica restul programului.\n\nMetodele care doar citesc un atribut se numesc de obicei getteri (`getVarsta`), iar cele care îl modifică, setteri (`setVarsta`).",
          "code": "#include <iostream>\nusing namespace std;\n\nclass Elev {\nprivate:\n    int varsta;\n    double medie;\n\npublic:\n    Elev(int v, double m) : varsta(14), medie(1) {\n        setVarsta(v);\n        setMedie(m);\n    }\n\n    int getVarsta() const { return varsta; }\n    double getMedie() const { return medie; }\n\n    void setVarsta(int v) {\n        if (v >= 6 && v <= 25) varsta = v;\n    }\n\n    void setMedie(double m) {\n        if (m >= 1 && m <= 10) medie = m;\n    }\n};\n\nint main() {\n    Elev e(17, 9.25);\n    e.setMedie(15);                   // valoare respinsă\n    cout << e.getMedie();             // 9.25\n    return 0;\n}",
          "lang": "cpp",
          "callout": "ATENȚIE:\nDacă o clasă are un constructor cu parametri și niciun constructor implicit, declarația `Fractie f;` nu se mai compilează: compilatorul nu mai generează singur constructorul fără parametri. Fie adaugi unul, fie dai valori implicite parametrilor.",
        },
      ]
    },

    "cpp-12-oop-inheritance": {
      "tag": "INFORMATICĂ // CLASA A 12-A // C++",
      "title": "Moștenirea în C++ (Inheritance)",
      "subtitle": "Cum construim o clasă nouă pornind de la una existentă, fără a rescrie ce au în comun.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Clasă de bază și clasă derivată",
          "text": "Moștenirea exprimă relația „este un fel de”: un elev este o persoană, un cerc este o figură geometrică.\n\nClasa derivată primește toate atributele și metodele clasei de bază și poate adăuga altele noi. Codul comun se scrie o singură dată, în clasa de bază.\n\nSintaxa este `class Derivata : public Baza { ... };`.",
          "code": "#include <iostream>\n#include <string>\nusing namespace std;\n\nclass Persoana {\npublic:\n    string nume;\n    int varsta;\n\n    void prezinta() {\n        cout << nume << \", \" << varsta << \" ani\\n\";\n    }\n};\n\nclass Elev : public Persoana {\npublic:\n    double medie;\n\n    void afiseazaMedia() {\n        cout << \"Media: \" << medie << '\\n';\n    }\n};\n\nint main() {\n    Elev e;\n    e.nume = \"Ana\";          // moștenit din Persoana\n    e.varsta = 17;           // moștenit din Persoana\n    e.medie = 9.5;           // propriu clasei Elev\n\n    e.prezinta();            // metodă moștenită\n    e.afiseazaMedia();\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Membrii protected și constructorii",
          "text": "Membrii `private` ai clasei de bază există în obiectul derivat, dar metodele clasei derivate nu îi pot accesa direct. Pentru membrii care trebuie ascunși de exterior, dar folosiți de clasele derivate, există nivelul `protected`.\n\nConstructorii nu se moștenesc. La crearea unui obiect derivat se execută întâi constructorul clasei de bază, apoi cel al clasei derivate. Parametrii pentru constructorul bazei se transmit prin lista de inițializare.\n\nLa distrugere, ordinea este inversă: întâi destructorul clasei derivate, apoi cel al clasei de bază.",
          "code": "#include <iostream>\n#include <string>\nusing namespace std;\n\nclass Persoana {\nprotected:\n    string nume;\n    int varsta;\n\npublic:\n    Persoana(string n, int v) : nume(n), varsta(v) {\n        cout << \"Constructor Persoana\\n\";\n    }\n};\n\nclass Elev : public Persoana {\nprivate:\n    double medie;\n\npublic:\n    Elev(string n, int v, double m) : Persoana(n, v), medie(m) {\n        cout << \"Constructor Elev\\n\";\n    }\n\n    void afiseaza() {\n        // nume și varsta sunt protected, deci accesibile aici\n        cout << nume << \", \" << varsta << \" ani, media \" << medie << '\\n';\n    }\n};\n\nint main() {\n    Elev e(\"Mihai\", 18, 8.75);\n    e.afiseaza();\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Redefinirea metodelor",
          "text": "O clasă derivată poate redefini o metodă moștenită, scriind una cu același nume și aceiași parametri. Pentru obiectele clasei derivate se va apela versiunea nouă.\n\nVersiunea din clasa de bază rămâne disponibilă și poate fi apelată explicit, cu numele clasei și operatorul `::`. Astfel, metoda nouă poate completa comportamentul vechi în loc să îl rescrie.",
          "code": "#include <iostream>\n#include <string>\nusing namespace std;\n\nclass Angajat {\nprotected:\n    string nume;\n    double salariu;\n\npublic:\n    Angajat(string n, double s) : nume(n), salariu(s) {}\n\n    void afiseaza() {\n        cout << nume << \", salariu \" << salariu;\n    }\n};\n\nclass Manager : public Angajat {\nprivate:\n    int subordonati;\n\npublic:\n    Manager(string n, double s, int sub) : Angajat(n, s), subordonati(sub) {}\n\n    void afiseaza() {\n        Angajat::afiseaza();                      // partea comună\n        cout << \", \" << subordonati << \" subordonati\";\n    }\n};\n\nint main() {\n    Manager m(\"Ioana\", 9000, 6);\n    m.afiseaza();        // Ioana, salariu 9000, 6 subordonati\n    return 0;\n}",
          "lang": "cpp",
          "callout": "ATENȚIE LA TIPUL MOȘTENIRII:\nScrie întotdeauna `: public Baza`. Dacă omiți cuvântul `public`, moștenirea unei clase este privată: toți membrii moșteniți devin privați în clasa derivată, iar `e.prezinta()` din `main` nu se mai compilează.",
        },
      ]
    },

    "cpp-12-oop-polymorphism": {
      "tag": "INFORMATICĂ // CLASA A 12-A // C++",
      "title": "Polimorfism & Funcții Virtuale (virtual)",
      "subtitle": "Același apel, comportament diferit, în funcție de tipul real al obiectului.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Problema: pointer la bază, obiect derivat",
          "text": "Un pointer (sau o referință) de tipul clasei de bază poate indica un obiect al oricărei clase derivate. Asta permite, de exemplu, păstrarea mai multor tipuri de figuri într-un singur vector.\n\nFără alte precizări, compilatorul alege metoda apelată după tipul pointerului, nu după tipul obiectului. Decizia se ia la compilare și se numește legare statică. În exemplul de mai jos, deși obiectul este un câine, se apelează metoda din `Animal`.",
          "code": "#include <iostream>\nusing namespace std;\n\nclass Animal {\npublic:\n    void sunet() { cout << \"Sunet generic\\n\"; }\n};\n\nclass Caine : public Animal {\npublic:\n    void sunet() { cout << \"Ham!\\n\"; }\n};\n\nint main() {\n    Caine c;\n    Animal *p = &c;       // pointer la bază, obiect derivat\n    p->sunet();           // Sunet generic\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "2. Funcții virtuale",
          "text": "Dacă metoda este declarată `virtual` în clasa de bază, alegerea se face la execuție, după tipul real al obiectului. Mecanismul se numește legare dinamică, iar comportamentul obținut, polimorfism.\n\nÎn clasele derivate, metoda redefinită se marchează cu `override`. Cuvântul nu este obligatoriu, dar îl obligă pe compilator să verifice că metoda chiar suprascrie una virtuală din bază. O greșeală de tipar în nume sau în parametri devine astfel eroare de compilare.",
          "code": "#include <iostream>\nusing namespace std;\n\nclass Animal {\npublic:\n    virtual void sunet() { cout << \"Sunet generic\\n\"; }\n    virtual ~Animal() {}\n};\n\nclass Caine : public Animal {\npublic:\n    void sunet() override { cout << \"Ham!\\n\"; }\n};\n\nclass Pisica : public Animal {\npublic:\n    void sunet() override { cout << \"Miau!\\n\"; }\n};\n\nint main() {\n    Animal *animale[3] = { new Caine(), new Pisica(), new Animal() };\n\n    for (int i = 0; i < 3; i++)\n        animale[i]->sunet();          // Ham!  Miau!  Sunet generic\n\n    for (int i = 0; i < 3; i++)\n        delete animale[i];\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Funcții virtuale pure și clase abstracte",
          "text": "Uneori clasa de bază nu are cum să implementeze o metodă: nu putem calcula aria unei „figuri” în general. Metoda se declară atunci virtuală pură, cu `= 0` în loc de corp.\n\nO clasă care are cel puțin o metodă virtuală pură este abstractă. Ea nu poate fi instanțiată și servește doar ca bază comună. Clasele derivate sunt obligate să implementeze toate metodele pure. Altfel rămân și ele abstracte.",
          "code": "#include <iostream>\nusing namespace std;\n\nclass Figura {\npublic:\n    virtual double aria() const = 0;        // virtuală pură\n    virtual ~Figura() {}\n};\n\nclass Dreptunghi : public Figura {\n    double lungime, latime;\npublic:\n    Dreptunghi(double a, double b) : lungime(a), latime(b) {}\n    double aria() const override { return lungime * latime; }\n};\n\nclass Cerc : public Figura {\n    double raza;\npublic:\n    Cerc(double r) : raza(r) {}\n    double aria() const override { return 3.14159265 * raza * raza; }\n};\n\nint main() {\n    Figura *figuri[2] = { new Dreptunghi(4, 5), new Cerc(1) };\n\n    double total = 0;\n    for (int i = 0; i < 2; i++) total += figuri[i]->aria();\n    cout << total;                           // 23.1416\n\n    for (int i = 0; i < 2; i++) delete figuri[i];\n    return 0;\n}",
          "lang": "cpp",
          "callout": "REGULĂ:\nO clasă care are metode virtuale trebuie să aibă și destructor virtual. Altfel, la `delete` printr-un pointer la clasa de bază se execută doar destructorul bazei, iar resursele alocate de clasa derivată nu mai sunt eliberate.",
        },
      ]
    },

    "db-12-sql-intro": {
      "tag": "INFORMATICĂ // CLASA A 12-A // SQL",
      "title": "Baze de Date: Modelul Relațional & Tabele",
      "subtitle": "Cum sunt organizate datele în tabele și cum se leagă tabelele între ele.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Tabele, înregistrări și câmpuri",
          "text": "O bază de date relațională păstrează datele în tabele.\n\n• Fiecare coloană se numește câmp (atribut) și are un nume și un tip de date.\n• Fiecare linie se numește înregistrare și descrie un singur obiect: un elev, o carte, o comandă.\n\nTipuri de date folosite frecvent:\n• `INT` : număr întreg.\n• `DECIMAL(p, s)` : număr cu virgulă, cu p cifre în total, dintre care s zecimale.\n• `VARCHAR(n)` : text de cel mult n caractere.\n• `DATE` : dată calendaristică.\n\nLimbajul în care se lucrează cu o bază de date relațională se numește SQL (Structured Query Language). Cuvintele rezervate nu țin cont de majuscule, dar prin convenție se scriu cu litere mari.",
        },
        {
          "heading": "2. Cheia primară",
          "text": "Cheia primară este câmpul (sau grupul de câmpuri) care identifică în mod unic fiecare înregistrare a unui tabel.\n\nReguli:\n• două înregistrări nu pot avea aceeași valoare a cheii primare;\n• cheia primară nu poate fi necompletată (`NULL`);\n• un tabel are o singură cheie primară.\n\nNumele nu este o cheie bună, pentru că pot exista doi elevi cu același nume. De obicei se adaugă un câmp numeric special, un identificator.\n\nAlte restricții care pot fi puse pe un câmp:\n• `NOT NULL` : valoarea este obligatorie.\n• `UNIQUE` : valorile nu se pot repeta.\n• `DEFAULT valoare` : valoarea folosită când nu se precizează alta.",
          "code": "CREATE TABLE Clase (\n    id_clasa INT PRIMARY KEY,\n    denumire VARCHAR(10) NOT NULL,\n    profil   VARCHAR(40)\n);",
          "lang": "SQL",
        },
        {
          "heading": "3. Cheia străină și relațiile dintre tabele",
          "text": "O cheie străină este un câmp dintr-un tabel care conține valori ale cheii primare din alt tabel. Prin ea se leagă înregistrările celor două tabele.\n\nÎn exemplu, fiecare elev aparține unei clase. Tabelul `Elevi` are câmpul `id_clasa`, care trimite către tabelul `Clase`. Baza de date nu va permite înscrierea unui elev într-o clasă care nu există. Această garanție se numește integritate referențială.\n\nTipuri de relații:\n• unu la mai mulți (1:N): o clasă are mai mulți elevi, un elev este într-o singură clasă. Cheia străină se pune în tabelul de pe partea „mai mulți”.\n• mai mulți la mai mulți (M:N): un elev participă la mai multe cercuri, un cerc are mai mulți elevi. Se rezolvă cu un al treilea tabel, de legătură, care conține cheile ambelor tabele.\n• unu la unu (1:1): mai rară, de exemplu un elev și fișa lui medicală.",
          "code": "CREATE TABLE Elevi (\n    id_elev  INT PRIMARY KEY,\n    nume     VARCHAR(50) NOT NULL,\n    prenume  VARCHAR(50) NOT NULL,\n    medie    DECIMAL(4, 2),\n    id_clasa INT,\n    FOREIGN KEY (id_clasa) REFERENCES Clase(id_clasa)\n);",
          "lang": "SQL",
          "callout": "SFAT DE PROIECTARE:\nNu păstra aceeași informație în două locuri. Dacă în tabelul `Elevi` ai scrie de fiecare dată și profilul clasei, o schimbare de profil ar trebui făcută pe zeci de linii, iar una uitată ar lăsa date contradictorii. Informația despre clasă stă o singură dată, în `Clase`, iar elevii doar trimit către ea prin cheia străină.",
        },
      ]
    },

    "db-12-sql-select": {
      "tag": "INFORMATICĂ // CLASA A 12-A // SQL",
      "title": "Interogarea Datelor: Instrucțiunea SELECT",
      "subtitle": "Cum extragem dintr-un tabel exact liniile și coloanele de care avem nevoie.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Forma de bază",
          "text": "Toate exemplele din această lecție folosesc tabelul `Elevi(id_elev, nume, prenume, medie, id_clasa)`.\n\nInstrucțiunea `SELECT` are forma generală:\n\n`SELECT` coloane `FROM` tabel `WHERE` condiție `ORDER BY` criteriu\n\n• După `SELECT` se scriu coloanele dorite, separate prin virgulă. Semnul `*` înseamnă toate coloanele.\n• `FROM` precizează tabelul.\n• `WHERE` și `ORDER BY` sunt opționale.\n• `DISTINCT` elimină liniile identice din rezultat.\n• `AS` dă un alt nume unei coloane în rezultat.",
          "code": "SELECT * FROM Elevi;\n\nSELECT nume, prenume, medie FROM Elevi;\n\nSELECT DISTINCT id_clasa FROM Elevi;\n\nSELECT nume, medie AS media_generala FROM Elevi;",
          "lang": "SQL",
        },
        {
          "heading": "2. Filtrarea cu WHERE",
          "text": "Clauza `WHERE` păstrează doar înregistrările care îndeplinesc o condiție.\n\nOperatori:\n• comparare: `=`, `<>` (diferit), `<`, `<=`, `>`, `>=`\n• logici: `AND`, `OR`, `NOT`\n• `BETWEEN a AND b` : valoare în intervalul [a, b], cu capetele incluse.\n• `IN (v1, v2, ...)` : valoare dintr-o listă.\n• `LIKE` : potrivire după un șablon. `%` ține locul oricâtor caractere (chiar și niciunuia), iar `_` ține locul unui singur caracter.\n• `IS NULL` și `IS NOT NULL` : verifică dacă un câmp este necompletat.\n\nTextele se scriu între apostrofuri.",
          "code": "SELECT nume, prenume FROM Elevi\nWHERE medie >= 9;\n\nSELECT nume, medie FROM Elevi\nWHERE medie BETWEEN 7 AND 8.99 AND id_clasa = 3;\n\nSELECT nume FROM Elevi\nWHERE id_clasa IN (1, 2, 5);\n\nSELECT nume, prenume FROM Elevi\nWHERE nume LIKE 'Pop%';\n\nSELECT nume FROM Elevi\nWHERE medie IS NULL;",
          "lang": "SQL",
        },
        {
          "heading": "3. Ordonarea și funcțiile de agregare",
          "text": "`ORDER BY` ordonează rezultatul după una sau mai multe coloane. Ordinea implicită este crescătoare (`ASC`). Pentru descrescător se scrie `DESC`. Dacă se dau mai multe criterii, al doilea se aplică doar între liniile egale după primul.\n\nFuncțiile de agregare calculează o singură valoare din mai multe linii:\n• `COUNT(*)` : numărul de înregistrări.\n• `SUM(camp)`, `AVG(camp)` : suma și media aritmetică.\n• `MIN(camp)`, `MAX(camp)` : valoarea minimă și cea maximă.\n\n`GROUP BY` împarte înregistrările în grupuri și aplică funcția de agregare separat pentru fiecare grup. `HAVING` filtrează grupurile, așa cum `WHERE` filtrează liniile.",
          "code": "SELECT nume, prenume, medie FROM Elevi\nORDER BY medie DESC, nume ASC;\n\nSELECT COUNT(*) AS numar_elevi, AVG(medie) AS media_scolii\nFROM Elevi;\n\nSELECT id_clasa, COUNT(*) AS numar_elevi, AVG(medie) AS media_clasei\nFROM Elevi\nGROUP BY id_clasa\nHAVING AVG(medie) >= 8\nORDER BY media_clasei DESC;",
          "lang": "SQL",
          "callout": "CAPCANĂ:\nUn câmp necompletat nu se compară cu `=`. Condiția `WHERE medie = NULL` nu este adevărată pentru nicio linie, deci nu întoarce nimic, fără niciun mesaj de eroare. Forma corectă este `WHERE medie IS NULL`.",
        },
      ]
    },

    "db-12-sql-crud": {
      "tag": "INFORMATICĂ // CLASA A 12-A // SQL",
      "title": "Comenzile INSERT, UPDATE & DELETE",
      "subtitle": "Adăugarea, modificarea și ștergerea înregistrărilor dintr-un tabel.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. INSERT: adăugarea înregistrărilor",
          "text": "`INSERT INTO` adaugă una sau mai multe înregistrări noi.\n\nForma recomandată precizează lista de câmpuri, iar valorile se dau în aceeași ordine. Câmpurile care lipsesc din listă primesc valoarea implicită sau `NULL`.\n\nDacă lista de câmpuri este omisă, trebuie date valori pentru toate câmpurile, în ordinea în care au fost definite în tabel.\n\nInserarea este respinsă dacă încalcă o restricție: o cheie primară care există deja, un câmp `NOT NULL` lăsat necompletat sau o cheie străină care trimite către o înregistrare inexistentă.",
          "code": "INSERT INTO Elevi (id_elev, nume, prenume, medie, id_clasa)\nVALUES (101, 'Popescu', 'Andrei', 9.25, 3);\n\nINSERT INTO Elevi (id_elev, nume, prenume, id_clasa)\nVALUES (102, 'Ionescu', 'Maria', 3);\n\nINSERT INTO Elevi (id_elev, nume, prenume, medie, id_clasa)\nVALUES (103, 'Stan', 'Vlad', 7.80, 1),\n       (104, 'Dinu', 'Elena', 8.60, 1);",
          "lang": "SQL",
        },
        {
          "heading": "2. UPDATE: modificarea înregistrărilor",
          "text": "`UPDATE` schimbă valorile unor câmpuri în înregistrările care îndeplinesc condiția din `WHERE`.\n\n• După `SET` se pot modifica mai multe câmpuri, separate prin virgulă.\n• Noua valoare poate fi calculată din cea veche.",
          "code": "UPDATE Elevi\nSET medie = 9.50\nWHERE id_elev = 102;\n\nUPDATE Elevi\nSET id_clasa = 2, medie = medie + 0.25\nWHERE id_elev = 103;\n\nUPDATE Elevi\nSET id_clasa = 4\nWHERE id_clasa = 3 AND medie < 5;",
          "lang": "SQL",
        },
        {
          "heading": "3. DELETE: ștergerea înregistrărilor",
          "text": "`DELETE FROM` șterge înregistrările care îndeplinesc condiția din `WHERE`. Structura tabelului rămâne neschimbată.\n\nȘtergerea poate fi refuzată de baza de date dacă înregistrarea este referită printr-o cheie străină din alt tabel. De exemplu, o clasă nu poate fi ștearsă cât timp mai există elevi care trimit către ea.\n\nNu confunda:\n• `DELETE FROM Elevi;` șterge toate înregistrările, dar tabelul rămâne.\n• `DROP TABLE Elevi;` șterge tabelul cu totul, cu structură și date.",
          "code": "DELETE FROM Elevi\nWHERE id_elev = 104;\n\nDELETE FROM Elevi\nWHERE medie IS NULL;",
          "lang": "SQL",
          "callout": "ATENȚIE MAXIMĂ:\nUn `UPDATE` sau un `DELETE` fără clauza `WHERE` se aplică tuturor înregistrărilor din tabel. Înainte de a rula o astfel de comandă, rulează un `SELECT` cu aceeași condiție și verifică dacă rezultatul conține exact liniile pe care vrei să le modifici sau să le ștergi.",
        },
      ]
    },

    "bac-12-info-sub1": {
      "tag": "INFORMATICĂ // CLASA A 12-A // BACALAUREAT",
      "title": "Bacalaureat: Strategii pentru Subiectul I (Grile & Expresii)",
      "subtitle": "Cum abordezi itemii cu alegere multiplă: expresii C++, recursivitate, backtracking și grafuri.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Ce conține Subiectul I",
          "text": "Subiectul I este format din itemi cu un singur răspuns corect dintre patru variante. Temele se repetă de la an la an:\n\n• valoarea sau echivalența unor expresii C++;\n• rezultatul apelului unui subprogram recursiv;\n• soluțiile generate de un algoritm de tip backtracking;\n• proprietăți ale grafurilor și arborilor;\n• tablouri, șiruri de caractere sau structuri.\n\nPentru că nu se cere justificare, contează doar litera aleasă. Asta nu înseamnă că se ghicește: fiecare item se rezolvă pe ciornă, apoi se caută rezultatul printre variante.\n\nVerifică în programa și în modelele publicate pentru anul tău structura exactă și punctajul. Acestea pot fi modificate de la un an la altul.",
        },
        {
          "heading": "2. Expresii C++",
          "text": "Reguli care decid majoritatea itemilor cu expresii:\n\n• Împărțirea a două numere întregi este întreagă: `7 / 2` este `3`, iar `1 / 2 * 4` este `0`.\n• `%` are aceeași prioritate ca `*` și `/`, iar operatorii cu aceeași prioritate se aplică de la stânga la dreapta.\n• Ordinea priorităților: `!`, apoi `*` `/` `%`, apoi `+` `-`, apoi comparațiile `<` `<=` `>` `>=`, apoi `==` `!=`, apoi `&&`, apoi `||`.\n• O expresie logică are valoarea 1 (adevărat) sau 0 (fals).\n\nNegarea unei condiții compuse se face cu legile lui De Morgan:\n• `!(a && b)` este echivalent cu `!a || !b`\n• `!(a || b)` este echivalent cu `!a && !b`\n\nLa negare, `<` devine `>=`, iar `==` devine `!=`.\n\nExemplu: condiția „x nu aparține intervalului [3, 7]” se scrie `!(x >= 3 && x <= 7)`, adică `x < 3 || x > 7`.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int x = 17, y = 5;\n\n    cout << x / y * y + x % y << '\\n';     // 3 * 5 + 2 = 17\n    cout << x / (y * 2) << '\\n';           // 17 / 10 = 1\n    cout << (x % 2 == 1 && y > 3) << '\\n'; // 1\n    cout << (x / 10 % 10) << '\\n';         // cifra zecilor: 1\n    cout << (x > 20 || !(y == 5)) << '\\n'; // 0\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Recursivitate și backtracking",
          "text": "Recursivitate. Nu încerca să ții apelurile în minte. Scrie pe ciornă lanțul de apeluri, unul sub altul, până la cazul de bază, apoi completează valorile de jos în sus. Fii atent dacă afișarea se face înainte sau după apelul recursiv: de asta depinde ordinea în care apar valorile.\n\nPentru funcția de mai jos, f(5) = 5 + f(3) = 5 + 3 + f(1) = 5 + 3 + 1 + f(-1) = 9.\n\nBacktracking. Itemii cer de obicei soluția care urmează după una dată sau a câta este o anumită soluție. Stabilește întâi regula de generare (elemente distincte, ordine crescătoare, alte condiții) din exemplele date în enunț. Soluția următoare se obține mărind ultimul element care mai poate fi mărit și completând pozițiile de după el cu cele mai mici valori permise.\n\nExemplu: combinările de 5 elemente luate câte 3, în ordine lexicografică. După (1, 4, 5) urmează (2, 3, 4): ultimele două poziții nu mai pot crește, deci crește prima, iar restul se completează cu cele mai mici valori.",
          "code": "#include <iostream>\nusing namespace std;\n\nint f(int n) {\n    if (n <= 0) return 0;\n    return n + f(n - 2);\n}\n\nint main() {\n    cout << f(5);        // 9\n    return 0;\n}",
          "lang": "cpp",
          "callout": "SFAT PENTRU GRAFURI ȘI ARBORI:\nDesenează întotdeauna graful pe ciornă, chiar dacă întrebarea pare simplă. Ține minte trei relații: suma gradelor este dublul numărului de muchii, un arbore cu n noduri are n - 1 muchii, un graf complet cu n noduri are n(n - 1) / 2 muchii. O bună parte din itemi se rezolvă direct cu ele.",
        },
      ]
    },

    "bac-12-info-sub2": {
      "tag": "INFORMATICĂ // CLASA A 12-A // BACALAUREAT",
      "title": "Bacalaureat: Rezolvarea Eficientă a Subiectului II",
      "subtitle": "Algoritmul în pseudocod, declarările de structuri și secvențele scurte de program.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Algoritmul în pseudocod",
          "text": "Prima problemă pornește de la un algoritm scris în pseudocod și are, de regulă, patru cerințe:\n\na) Ce se afișează pentru anumite date de intrare. Fă un tabel de urmărire: câte o coloană pentru fiecare variabilă și câte o linie pentru fiecare pas. Nu sări peste pași.\n\nb) Găsirea unor date de intrare pentru care se obține un rezultat dat. Întâi trebuie să înțelegi ce calculează algoritmul. Rezultatul de la punctul a) te ajută.\n\nc) Scrierea programului C++ corespunzător. Traducerea se face linie cu linie.\n\nd) Rescrierea algoritmului cu alt tip de structură repetitivă.\n\nNotații de reținut:\n• `[a/b]` este câtul întreg, în C++ `a / b` pentru numere întregi;\n• `a%b` este restul împărțirii;\n• `←` este atribuirea, în C++ `=`;\n• `=` în pseudocod este comparare, în C++ `==`;\n• `≠` devine `!=`.",
        },
        {
          "heading": "2. Transformarea structurilor repetitive",
          "text": "Echivalențele folosite la cerința d):\n\n• „pentru i ← a, b execută S” este echivalent cu: i ← a, apoi „cât timp i ≤ b execută S, i ← i + 1”.\n\n• „cât timp C execută S” este echivalent cu: „dacă C atunci (repetă S până când NOT C)”. Testul din față este necesar pentru că structura cu test final execută S cel puțin o dată.\n\n• „repetă S până când C” este echivalent cu: S, apoi „cât timp NOT C execută S”.\n\nÎn C++, „repetă … până când C” se scrie `do { ... } while (!C);`. Condiția se neagă, pentru că `do-while` continuă cât timp condiția este adevărată, iar „repetă” se oprește când condiția devine adevărată.",
          "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n;\n    cin >> n;\n\n    // Pseudocod:\n    //   s <- 0\n    //   repeta\n    //       s <- s + n%10\n    //       n <- [n/10]\n    //   pana cand n = 0\n    //   scrie s\n    int s = 0;\n    do {\n        s = s + n % 10;\n        n = n / 10;\n    } while (n != 0);          // negarea condiției „n = 0”\n\n    cout << s;\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "3. Structuri și secvențe scurte de program",
          "text": "Celelalte probleme cer de obicei completarea sau scrierea unei secvențe scurte: declararea unei structuri, o prelucrare pe o matrice, pe un șir de caractere sau o expresie care accesează un câmp.\n\nLa declarările de structuri, citește cu atenție enunțul: numele variabilei, numele câmpurilor și tipurile lor trebuie să fie exact cele din expresiile date. Dacă enunțul folosește `e.data.zi`, atunci `e` are un câmp `data`, care este la rândul lui o structură cu un câmp `zi`.\n\nLa secvențele pe matrice, enunțul precizează dacă liniile și coloanele sunt numerotate de la 0 sau de la 1. Condițiile pentru diagonale se schimbă în funcție de asta.\n\nLa șirurile de caractere, funcțiile cerute cel mai des sunt `strlen`, `strcpy`, `strcat`, `strcmp`, `strchr` și `strstr`.",
          "code": "#include <iostream>\n#include <cstring>\nusing namespace std;\n\nstruct Data {\n    int zi, luna, an;\n};\n\nstruct Elev {\n    char nume[31];\n    Data nastere;\n    double medie;\n};\n\nint main() {\n    Elev e;\n    strcpy(e.nume, \"Ionescu\");\n    e.nastere.zi = 14;\n    e.nastere.luna = 3;\n    e.nastere.an = 2007;\n    e.medie = 9.40;\n\n    // Ștergerea primului caracter dintr-un șir:\n    char s[31];\n    strcpy(s, e.nume);\n    strcpy(s, s + 1);\n\n    cout << s << ' ' << e.nastere.an;      // onescu 2007\n    return 0;\n}",
          "lang": "cpp",
          "callout": "ATENȚIE LA TRADUCEREA ÎN C++:\nCele mai multe puncte se pierd la detalii: `=` în loc de `==` într-o condiție, lipsa acoladelor când „execută” este urmat de mai multe instrucțiuni, variabile nedeclarate și uitarea citirii datelor de intrare. După ce ai scris programul, rulează-l pe ciornă cu datele de la punctul a) și verifică dacă obții același rezultat.",
        },
      ]
    },

    "bac-12-info-sub3": {
      "tag": "INFORMATICĂ // CLASA A 12-A // BACALAUREAT",
      "title": "Bacalaureat: Algoritmi Eficienți la Subiectul III (Problema 3)",
      "subtitle": "Subprograme, prelucrări pe tablouri și problema cu fișier, rezolvată eficient și justificată.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Ce se cere",
          "text": "Subiectul III cere programe scrise integral.\n\n• Un subprogram cu antet precizat. Se scrie doar definiția completă a subprogramului, nu și programul principal. Respectă exact numele, ordinea și tipul parametrilor. Dacă un parametru „furnizează” un rezultat, el se transmite prin referință.\n\n• Un program complet care prelucrează un tablou sau un șir de caractere. Aici se punctează declarările, citirea, prelucrarea și afișarea.\n\n• O problemă cu date citite dintr-un fișier, pentru care se cere un algoritm eficient ca timp de execuție și ca memorie, însoțit de o descriere în limbaj natural a algoritmului și de justificarea eficienței.\n\nPentru ultima problemă, o soluție corectă, dar neeficientă, primește doar o parte din punctaj. Dacă nu găsești soluția eficientă, scrie-o pe cea pe care o ai: valorează mult mai mult decât o pagină goală.",
        },
        {
          "heading": "2. Cum arată un algoritm eficient",
          "text": "Fișierul conține de obicei un șir foarte lung de numere (până la 10⁶ valori). Eficient înseamnă, aproape întotdeauna, două lucruri:\n\n• timp liniar: fiecare număr este prelucrat o singură dată, în momentul în care este citit;\n• memorie constantă: numerele nu se păstrează într-un vector. Se rețin doar câteva variabile.\n\nTehnici care apar des:\n• Maxime și minime actualizate din mers: cel mai mare, al doilea cel mai mare, ultima valoare cu o anumită proprietate.\n• Contoare și sume parțiale: lungimea secvenței curente, suma secvenței curente.\n• Vector de frecvență, atunci când valorile sunt mici (cifre, numere de cel mult două sau trei cifre). Dimensiunea lui depinde de valorile posibile, nu de câte numere sunt în fișier, deci memoria rămâne constantă.\n• Folosirea unei proprietăți a datelor date în enunț, de exemplu faptul că șirul este deja ordonat.\n\nO soluție care păstrează toate numerele într-un vector și apoi le sortează sau le compară două câte două nu este eficientă nici ca timp, nici ca memorie.",
        },
        {
          "heading": "3. Exemplu rezolvat",
          "text": "Enunț: fișierul `bac.txt` conține un șir de cel mult 10⁶ numere naturale din intervalul [0, 10⁹], separate prin spații. Se cere lungimea maximă a unei secvențe de termeni aflați pe poziții consecutive care sunt în ordine strict crescătoare.\n\nExemplu: pentru șirul 5 7 9 4 6 8 10 3 se afișează 4 (secvența 4 6 8 10).\n\nIdee: nu ne interesează întregul șir, ci doar termenul anterior și lungimea secvenței crescătoare care se termină în termenul curent. Dacă termenul curent este mai mare decât cel anterior, secvența se prelungește. Altfel începe una nouă, de lungime 1.",
          "code": "#include <iostream>\n#include <fstream>\nusing namespace std;\n\nint main() {\n    ifstream fin(\"bac.txt\");\n\n    int anterior, x;\n    int lungime = 0, lungimeMax = 0;\n\n    if (fin >> anterior) {\n        lungime = lungimeMax = 1;\n        while (fin >> x) {\n            if (x > anterior) lungime++;\n            else lungime = 1;\n\n            if (lungime > lungimeMax) lungimeMax = lungime;\n            anterior = x;\n        }\n    }\n\n    cout << lungimeMax;\n    fin.close();\n    return 0;\n}",
          "lang": "cpp",
        },
        {
          "heading": "4. Descrierea algoritmului și justificarea eficienței",
          "text": "Descrierea se scrie în cuvinte, în trei-patru fraze, și trebuie să conțină ideea algoritmului și motivul pentru care este eficient. Pentru exemplul de mai sus:\n\n„Se citesc numerele pe rând din fișier. Se rețin termenul anterior și lungimea secvenței strict crescătoare care se termină în termenul curent. Dacă termenul curent este mai mare decât cel anterior, lungimea crește cu 1, altfel devine 1. La fiecare pas se actualizează lungimea maximă. Algoritmul este eficient ca timp de execuție, deoarece parcurge șirul o singură dată, și ca memorie, deoarece folosește doar câteva variabile simple, fără a memora șirul într-un tablou.”\n\nÎnainte de a preda lucrarea, verifică:\n• numele fișierului este exact cel din enunț;\n• citirea se face cu `while (fin >> x)`, nu după un număr de elemente presupus;\n• cazurile limită funcționează: un singur număr, toate numerele egale, șir descrescător;\n• rezultatul încape în tipul ales. Sumele a multe numere mari cer `long long`.",
          "callout": "CAPCANĂ:\nNu declara „pentru orice eventualitate” un vector cu un milion de elemente dacă soluția nu are nevoie de el. La această problemă, simpla prezență a unui tablou în care se memorează șirul duce la pierderea punctajului pentru eficiența memoriei, chiar dacă algoritmul este liniar.",
        },
      ]
    },

    "mat-12-laws": {
      "tag": "MATEMATICĂ // CLASA A 12-A // ALGEBRĂ",
      "title": "Legi de Compoziție & Proprietăți Fundamentale",
      "subtitle": "Parte stabilă, asociativitate, comutativitate, element neutru și elemente simetrizabile.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Lege de compoziție și parte stabilă",
          "text": "O lege de compoziție pe o mulțime nevidă M este o regulă care asociază oricăror două elemente x, y ∈ M un element x ∗ y ∈ M.\n\nExemple: adunarea și înmulțirea pe ℝ, adunarea matricelor pe M₂(ℝ), compunerea funcțiilor.\n\nParte stabilă. O submulțime nevidă H ⊂ M este parte stabilă a lui M în raport cu legea ∗ dacă:\n\npentru orice x, y ∈ H rezultă x ∗ y ∈ H.\n\nExemplu: pe ℝ se definește x ∗ y = xy - 2x - 2y + 6. Arătăm că H = (2, ∞) este parte stabilă.\n\nScriem legea sub formă de produs: x ∗ y = (x - 2)(y - 2) + 2.\nDacă x, y ∈ (2, ∞), atunci x - 2 > 0 și y - 2 > 0, deci (x - 2)(y - 2) > 0.\nRezultă x ∗ y > 2, adică x ∗ y ∈ H.\n\nScrierea legii în forma (x - a)(y - a) + a este pasul care simplifică aproape toate cerințele ce urmează.",
        },
        {
          "heading": "2. Asociativitate, comutativitate și element neutru",
          "text": "Legea ∗ este:\n\n• comutativă, dacă x ∗ y = y ∗ x pentru orice x, y ∈ M;\n• asociativă, dacă (x ∗ y) ∗ z = x ∗ (y ∗ z) pentru orice x, y, z ∈ M.\n\nElement neutru. Un element e ∈ M este element neutru dacă x ∗ e = e ∗ x = x pentru orice x ∈ M. Dacă există, elementul neutru este unic.\n\nContinuăm exemplul x ∗ y = (x - 2)(y - 2) + 2.\n\nComutativitate: (x - 2)(y - 2) + 2 = (y - 2)(x - 2) + 2, deci legea este comutativă.\n\nAsociativitate:\n(x ∗ y) ∗ z = ((x ∗ y) - 2)(z - 2) + 2 = (x - 2)(y - 2)(z - 2) + 2\nx ∗ (y ∗ z) = (x - 2)((y ∗ z) - 2) + 2 = (x - 2)(y - 2)(z - 2) + 2\nCele două expresii sunt egale, deci legea este asociativă.\n\nElement neutru: căutăm e cu x ∗ e = x pentru orice x.\n(x - 2)(e - 2) + 2 = x\n(x - 2)(e - 2) = x - 2\n(x - 2)(e - 3) = 0, pentru orice x\nRezultă e = 3.",
        },
        {
          "heading": "3. Elemente simetrizabile",
          "text": "Fie ∗ o lege asociativă cu element neutru e. Un element x ∈ M este simetrizabil dacă există x' ∈ M astfel încât:\n\nx ∗ x' = x' ∗ x = e\n\nElementul x' se numește simetricul lui x. La adunare simetricul este opusul (-x), iar la înmulțire este inversul (1/x).\n\nProprietăți:\n• simetricul unui element, dacă există, este unic;\n• (x')' = x;\n• (x ∗ y)' = y' ∗ x'.\n\nÎn exemplul nostru, cu e = 3:\n(x - 2)(x' - 2) + 2 = 3\n(x - 2)(x' - 2) = 1\nx' = 2 + 1 / (x - 2), pentru x ≠ 2\n\nElementul x = 2 nu este simetrizabil. Mai mult, 2 ∗ y = (2 - 2)(y - 2) + 2 = 2 pentru orice y. Un astfel de element se numește element absorbant.",
          "callout": "PROBLEMĂ TIPICĂ DE BACALAUREAT:\nPentru legea x ∗ y = (x - 2)(y - 2) + 2, să se calculeze 1 ∗ 2 ∗ 3 ∗ … ∗ 2024.\nRezolvare:\nLegea este asociativă, deci putem grupa termenii oricum. Printre factori se află elementul absorbant 2, iar a ∗ 2 = 2 ∗ a = 2 pentru orice a.\nScriem expresia ca (1) ∗ 2 ∗ (3 ∗ … ∗ 2024). Notând b = 3 ∗ … ∗ 2024, avem 1 ∗ 2 = 2 și 2 ∗ b = 2.\nRezultatul este 2.",
        },
      ]
    },

    "mat-12-groups": {
      "tag": "MATEMATICĂ // CLASA A 12-A // ALGEBRĂ",
      "title": "Grupuri Comutative (Abeliene) & Morfisme",
      "subtitle": "Axiomele grupului, reguli de calcul și funcțiile care păstrează structura de grup.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Definiția grupului",
          "text": "O mulțime nevidă G, împreună cu o lege de compoziție ∗ definită pe G, formează un grup dacă sunt îndeplinite următoarele condiții, numite axiomele grupului:\n\nG1. Legea este asociativă.\nG2. Legea admite element neutru e ∈ G.\nG3. Orice element din G este simetrizabil, iar simetricul lui se află tot în G.\n\nDacă, în plus, legea este comutativă, grupul se numește comutativ sau abelian.\n\nÎnainte de verificarea axiomelor trebuie arătat că legea este bine definită pe G, adică x ∗ y ∈ G pentru orice x, y ∈ G (G este parte stabilă).\n\nExemple de grupuri abeliene:\n• (ℤ, +), (ℚ, +), (ℝ, +), (ℂ, +), cu elementul neutru 0;\n• (ℚ*, ·), (ℝ*, ·), (ℂ*, ·), cu elementul neutru 1;\n• (ℤ_n, +), clasele de resturi modulo n, cu adunarea.\n\nContraexemple:\n• (ℕ, +) nu este grup: numerele nenule nu au opus în ℕ;\n• (ℝ, ·) nu este grup: 0 nu are invers.",
        },
        {
          "heading": "2. Un grup construit pe un interval",
          "text": "Pe G = (2, ∞) se consideră legea x ∗ y = (x - 2)(y - 2) + 2. Arătăm că (G, ∗) este grup abelian.\n\nParte stabilă: dacă x, y > 2, atunci (x - 2)(y - 2) > 0, deci x ∗ y > 2.\n\nAsociativitate: (x ∗ y) ∗ z = x ∗ (y ∗ z) = (x - 2)(y - 2)(z - 2) + 2.\n\nElement neutru: din (x - 2)(e - 2) + 2 = x pentru orice x rezultă e = 3, iar 3 ∈ G.\n\nElemente simetrizabile: din (x - 2)(x' - 2) = 1 rezultă x' = 2 + 1 / (x - 2). Cum x > 2, avem 1 / (x - 2) > 0, deci x' > 2, adică x' ∈ G.\n\nComutativitate: evidentă, din comutativitatea înmulțirii numerelor reale.\n\nReguli de calcul valabile în orice grup:\n• simplificarea: din a ∗ x = a ∗ y rezultă x = y;\n• ecuația a ∗ x = b are soluția unică x = a' ∗ b;\n• (x ∗ y)' = y' ∗ x'.\n\nExemplu: în grupul de mai sus, ecuația x ∗ x = 11 devine (x - 2)² + 2 = 11, deci (x - 2)² = 9. Cum x - 2 > 0, rezultă x - 2 = 3, adică x = 5.",
        },
        {
          "heading": "3. Morfisme și izomorfisme de grupuri",
          "text": "Fie (G, ∗) și (H, ∘) două grupuri. O funcție f : G → H este morfism de grupuri dacă:\n\nf(x ∗ y) = f(x) ∘ f(y), pentru orice x, y ∈ G.\n\nUn morfism bijectiv se numește izomorfism. Două grupuri între care există un izomorfism se numesc izomorfe: au aceeași structură, doar elementele poartă alte „nume”.\n\nProprietăți ale unui morfism f:\n• f(e_G) = e_H: elementul neutru este dus în elementul neutru;\n• f(x') = (f(x))': simetricul este dus în simetric.\n\nExemplu clasic: f : (ℝ, +) → ((0, ∞), ·), f(x) = e^x.\nf(x + y) = e^(x+y) = e^x · e^y = f(x) · f(y), deci f este morfism. Funcția exponențială este bijectivă de la ℝ la (0, ∞), deci f este izomorfism.\n\nPentru a demonstra că o funcție este izomorfism, urmează trei pași:\n1. arată că f este morfism;\n2. arată că f este injectivă (de exemplu, este strict monotonă);\n3. arată că f este surjectivă (pentru orice y din codomeniu, ecuația f(x) = y are soluție în domeniu).",
          "callout": "PROBLEMĂ TIPICĂ DE BACALAUREAT:\nFie G = (2, ∞) cu legea x ∗ y = (x - 2)(y - 2) + 2. Să se arate că f : G → (0, ∞), f(x) = x - 2 este izomorfism de la (G, ∗) la ((0, ∞), ·).\nRezolvare:\nMorfism: f(x ∗ y) = (x ∗ y) - 2 = (x - 2)(y - 2) = f(x) · f(y).\nBijectivitate: f este funcție de gradul I, strict crescătoare, deci injectivă. Pentru orice y > 0, ecuația x - 2 = y are soluția x = y + 2 > 2, deci f este surjectivă.\nPrin urmare f este izomorfism de grupuri.",
        },
      ]
    },

    "mat-12-polynomials": {
      "tag": "MATEMATICĂ // CLASA A 12-A // ALGEBRĂ",
      "title": "Inele de Polinoame & Relațiile lui Viète",
      "subtitle": "Împărțirea polinoamelor, teorema restului, schema lui Horner, rădăcini multiple și relațiile lui Viète.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Împărțirea polinoamelor și teorema restului",
          "text": "Un polinom cu coeficienți într-un corp K (ℚ, ℝ, ℂ sau ℤ_p) are forma:\n\nf = a_n·X^n + … + a₁X + a₀, cu a_n ≠ 0\n\nNumărul n este gradul polinomului, iar a_n coeficientul dominant.\n\nTeorema împărțirii cu rest. Pentru orice polinoame f și g, cu g ≠ 0, există și sunt unice polinoamele q (câtul) și r (restul) astfel încât:\n\nf = g · q + r, cu grad r < grad g\n\nTeorema restului. Restul împărțirii lui f la X - a este f(a).\n\nTeorema lui Bézout. Polinomul f se divide cu X - a dacă și numai dacă f(a) = 0, adică a este rădăcină a lui f.\n\nCând împărțitorul are gradul 2, restul are forma mX + n. Coeficienții m și n se află dând lui X, în relația f = g · q + r, valorile rădăcinilor împărțitorului.\n\nExemplu: restul împărțirii lui f = X¹⁰ + X + 1 la X² - 1.\nScriem f = (X² - 1) · q + mX + n.\nPentru X = 1: f(1) = 3 = m + n.\nPentru X = -1: f(-1) = 1 = -m + n.\nRezultă m = 1, n = 2, deci restul este X + 2.",
        },
        {
          "heading": "2. Schema lui Horner și rădăcinile multiple",
          "text": "Schema lui Horner calculează rapid câtul și restul împărțirii la X - a.\n\nSe scriu coeficienții lui f, în ordinea descrescătoare a puterilor (cu 0 pentru puterile care lipsesc). Primul coeficient se coboară neschimbat. Fiecare valoare următoare se obține înmulțind valoarea anterioară cu a și adunând coeficientul următor. Ultima valoare este restul, iar celelalte sunt coeficienții câtului.\n\nExemplu: f = X³ - 6X² + 11X - 6 împărțit la X - 1.\nCoeficienți: 1, -6, 11, -6\n• se coboară 1\n• 1 · 1 + (-6) = -5\n• (-5) · 1 + 11 = 6\n• 6 · 1 + (-6) = 0\n\nRestul este 0, deci 1 este rădăcină, iar câtul este X² - 5X + 6 = (X - 2)(X - 3).\nPrin urmare f = (X - 1)(X - 2)(X - 3).\n\nRădăcini multiple. Numărul a este rădăcină de ordin k a lui f dacă f se divide cu (X - a)^k, dar nu și cu (X - a)^(k+1).\n\nCriteriu cu derivate:\n• a este rădăcină dublă dacă f(a) = 0, f'(a) = 0 și f''(a) ≠ 0;\n• a este rădăcină triplă dacă f(a) = f'(a) = f''(a) = 0 și f'''(a) ≠ 0.\n\nRădăcini raționale. Dacă f are coeficienți întregi, orice rădăcină rațională p/q (fracție ireductibilă) are p divizor al termenului liber și q divizor al coeficientului dominant. Rădăcinile întregi se caută deci printre divizorii termenului liber.",
        },
        {
          "heading": "3. Relațiile lui Viète și polinoamele ireductibile",
          "text": "Pentru polinomul de gradul al III-lea f = aX³ + bX² + cX + d, cu rădăcinile x₁, x₂, x₃:\n\n• x₁ + x₂ + x₃ = -b/a\n• x₁x₂ + x₁x₃ + x₂x₃ = c/a\n• x₁x₂x₃ = -d/a\n\nPentru gradul al IV-lea, f = aX⁴ + bX³ + cX² + dX + e:\n\n• S₁ = x₁ + x₂ + x₃ + x₄ = -b/a\n• S₂ = suma produselor de câte două rădăcini = c/a\n• S₃ = suma produselor de câte trei rădăcini = -d/a\n• S₄ = x₁x₂x₃x₄ = e/a\n\nSemnele alternează, începând cu minus.\n\nFormulă folosită foarte des:\nx₁² + x₂² + x₃² = (x₁ + x₂ + x₃)² - 2(x₁x₂ + x₁x₃ + x₂x₃) = S₁² - 2S₂\n\nPolinoame ireductibile:\n• peste ℂ, sunt ireductibile doar polinoamele de gradul I;\n• peste ℝ, sunt ireductibile polinoamele de gradul I și cele de gradul al II-lea cu Δ < 0.\n\nDacă un polinom cu coeficienți reali are rădăcina complexă a + bi, atunci are și rădăcina conjugată a - bi. Dacă un polinom cu coeficienți raționali are rădăcina a + √b (cu √b irațional), atunci are și rădăcina a - √b.",
          "callout": "PROBLEMĂ TIPICĂ DE BACALAUREAT:\nFie f = X³ - 3X² + 5X - 1, cu rădăcinile x₁, x₂, x₃. Să se arate că f nu are toate rădăcinile reale.\nRezolvare:\nDin relațiile lui Viète: S₁ = 3 și S₂ = 5.\nx₁² + x₂² + x₃² = S₁² - 2S₂ = 9 - 10 = -1.\nDacă toate rădăcinile ar fi reale, suma pătratelor lor ar fi mai mare sau egală cu 0. Cum suma este -1, polinomul nu are toate rădăcinile reale.",
        },
      ]
    },

    "mat-12-primitives": {
      "tag": "MATEMATICĂ // CLASA A 12-A // CALCUL INTEGRAL",
      "title": "Primitive & Integrale Nedefinite",
      "subtitle": "Ce este o primitivă, tabelul integralelor uzuale și cum se folosește liniaritatea.",
      "author": defaultAuthor,
      "date": defaultDate,
      "sections": [
        {
          "heading": "1. Primitiva unei funcții",
          "text": "Fie f : I → ℝ o funcție definită pe un interval I. O funcție F : I → ℝ se numește primitivă a lui f dacă F este derivabilă pe I și:\n\nF'(x) = f(x), pentru orice x ∈ I.\n\nDacă F este o primitivă a lui f, atunci toate primitivele lui f au forma F + C, unde C este o constantă reală. Mulțimea lor se numește integrala nedefinită a lui f și se notează:\n\n∫ f(x) dx = F(x) + C\n\nFapte de reținut:\n• orice funcție continuă pe un interval admite primitive;\n• două primitive ale aceleiași funcții diferă printr-o constantă;\n• orice primitivă este o funcție derivabilă, deci continuă.\n\nCum arăți că F este o primitivă a lui f: calculezi F'(x) și verifici că obții f(x). Nu este nevoie de nicio integrare.\n\nExemplu: F(x) = x · ln x - x este o primitivă a funcției f(x) = ln x pe (0, ∞), pentru că\nF'(x) = ln x + x · (1/x) - 1 = ln x.",
        },
        {
          "heading": "2. Tabelul integralelor uzuale",
          "text": "Fiecare formulă se verifică derivând membrul drept.\n\n• ∫ x^n dx = x^(n+1) / (n + 1) + C, pentru n ≠ -1\n• ∫ 1/x dx = ln |x| + C\n• ∫ e^x dx = e^x + C\n• ∫ a^x dx = a^x / ln a + C, pentru a > 0, a ≠ 1\n• ∫ sin x dx = -cos x + C\n• ∫ cos x dx = sin x + C\n• ∫ 1 / cos² x dx = tg x + C\n• ∫ 1 / sin² x dx = -ctg x + C\n• ∫ 1 / (x² + a²) dx = (1/a) · arctg (x/a) + C\n• ∫ 1 / (x² - a²) dx = (1 / (2a)) · ln |(x - a) / (x + a)| + C\n• ∫ 1 / √(a² - x²) dx = arcsin (x/a) + C\n• ∫ 1 / √(x² + a²) dx = ln (x + √(x² + a²)) + C\n\nRadicalii și fracțiile simple se integrează cu prima formulă, după ce au fost scrise ca puteri:\n• √x = x^(1/2), deci ∫ √x dx = (2/3) · x · √x + C\n• 1/x² = x^(-2), deci ∫ 1/x² dx = -1/x + C",
        },
        {
          "heading": "3. Liniaritatea integralei",
          "text": "Integrala unei sume este suma integralelor, iar constantele ies în fața integralei:\n\n∫ (a · f(x) + b · g(x)) dx = a · ∫ f(x) dx + b · ∫ g(x) dx\n\nAtenție: nu există o regulă asemănătoare pentru produs sau pentru cât. Integrala unui produs nu este produsul integralelor.\n\nExemplul 1:\n∫ (3x² - 4x + 5) dx = 3 · x³/3 - 4 · x²/2 + 5x + C = x³ - 2x² + 5x + C\n\nExemplul 2: fracțiile cu un singur termen la numitor se despart în fracții simple.\n∫ (x² + 1) / x dx = ∫ (x + 1/x) dx = x²/2 + ln |x| + C\n\nExemplul 3: produsele de paranteze se desfac înainte de integrare.\n∫ (x + 1)² dx = ∫ (x² + 2x + 1) dx = x³/3 + x² + x + C\n\nDeterminarea unei primitive anume. Dacă se cere primitiva F care îndeplinește o condiție, de exemplu F(1) = 2, se scrie forma generală F(x) + C și se află constanta din condiție.\n\nExemplu: primitiva lui f(x) = 2x + 1 cu F(1) = 5.\nF(x) = x² + x + C. Din F(1) = 5 rezultă 2 + C = 5, deci C = 3 și F(x) = x² + x + 3.",
          "callout": "PROBLEMĂ TIPICĂ DE BACALAUREAT:\nFie f : ℝ → ℝ, f(x) = e^x + 2x. Să se arate că orice primitivă a lui f este funcție convexă.\nRezolvare:\nFie F o primitivă a lui f. Atunci F'(x) = f(x), deci F''(x) = f'(x) = e^x + 2.\nCum e^x > 0 pentru orice x real, avem F''(x) > 0 pe ℝ, deci F este convexă.\nObservă că nu a fost nevoie să calculăm primitiva: monotonia lui F se citește din semnul lui f, iar convexitatea din semnul lui f'.",
        },
      ]
    },
  };
}