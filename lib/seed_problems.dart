import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> populeazaCele50DeProbleme() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final WriteBatch batch = db.batch();

  final List<Map<String, dynamic>> listaProbleme = [
    // ==========================================
    // CLASA A IX-A (LEVEL 9) - 20 Probleme
    // ==========================================
    {
      "id": "info_9_1",
      "titlu": "Suma a două numere",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "STRUCTURI SECVENȚIALE",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Să se scrie un program care citește de la tastatură două numere naturale a și b și afișează suma lor.",
      "tests": [
        {"input": "12 35", "output": "47"},
        {"input": "100 250", "output": "350"},
        {"input": "0 7", "output": "7"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Programul afișează suma celor două numere.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    long long a, b;\n    if (cin >> a >> b) {\n        cout << a + b;\n    }\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_2",
      "titlu": "Schimbare valori (Swap)",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "STRUCTURI SECVENȚIALE",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Se citesc două numere a și b. Să se afișeze valorile lor inversate separate prin spațiu.",
      "tests": [
        {"input": "3 7", "output": "7 3"},
        {"input": "-5 12", "output": "12 -5"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Interschimbarea valorilor.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int a, b;\n    cin >> a >> b;\n    int aux = a;\n    a = b;\n    b = aux;\n    cout << a << \" \" << b;\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_3",
      "titlu": "Maximul a două numere",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "STRUCTURI ALTERNATIVE",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Se citesc două numere întregi a și b. Să se determine și să se afișeze maximul dintre ele.",
      "tests": [
        {"input": "4 9", "output": "9"},
        {"input": "-10 -2", "output": "-2"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Maximul a două valori.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int a, b;\n    cin >> a >> b;\n    if (a > b) cout << a;\n    else cout << b;\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_4",
      "titlu": "Verificare paritate",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "STRUCTURI ALTERNATIVE",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Se citește un număr natural n. Afișați 'PAR' dacă numărul este par sau 'IMPAR' dacă este impar.",
      "tests": [
        {"input": "24", "output": "PAR"},
        {"input": "17", "output": "IMPAR"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Paritatea numărului.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n;\n    cin >> n;\n    if (n % 2 == 0) cout << \"PAR\";\n    else cout << \"IMPAR\";\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_5",
      "titlu": "Ultima cifră",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "PRELUCRAREA CIFRELOR",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Se citește un număr natural n. Să se afișeze ultima sa cifră.",
      "tests": [
        {"input": "583", "output": "3"},
        {"input": "10", "output": "0"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Ultima cifră.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    long long n;\n    cin >> n;\n    cout << n % 10;\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_6",
      "titlu": "Suma cifrelor",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "PRELUCRAREA CIFRELOR",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Se citește un număr natural n. Să se calculeze suma cifrelor sale.",
      "tests": [
        {"input": "1234", "output": "10"},
        {"input": "505", "output": "10"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Suma cifrelor unui număr.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    long long n, s = 0;\n    cin >> n;\n    while (n > 0) {\n        s += n % 10;\n        n /= 10;\n    }\n    cout << s;\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_7",
      "titlu": "Oglinditul unui număr",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "PRELUCRAREA CIFRELOR",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Se citește un număr natural n. Să se determine răsturnatul (oglinditul) său.",
      "tests": [
        {"input": "1204", "output": "4021"},
        {"input": "300", "output": "3"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Oglinditul numărului.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    long long n, ogl = 0;\n    cin >> n;\n    while (n > 0) {\n        ogl = ogl * 10 + n % 10;\n        n /= 10;\n    }\n    cout << ogl;\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_8",
      "titlu": "Număr palindrom",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "PRELUCRAREA CIFRELOR",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Să se verifice dacă un număr natural citit este palindrom. Se va afișa 'DA' sau 'NU'.",
      "tests": [
        {"input": "12321", "output": "DA"},
        {"input": "1234", "output": "NU"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Verificare palindrom.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    long long n, cn, ogl = 0;\n    cin >> n;\n    cn = n;\n    while (cn > 0) {\n        ogl = ogl * 10 + cn % 10;\n        cn /= 10;\n    }\n    if (ogl == n) cout << \"DA\";\n    else cout << \"NU\";\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_9",
      "titlu": "Număr prim",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "DIVIZIBILITATE",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Se citește un număr natural n. Să se afișeze 'DA' dacă este prim, altfel 'NU'.",
      "tests": [
        {"input": "17", "output": "DA"},
        {"input": "24", "output": "NU"},
        {"input": "1", "output": "NU"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Test de primalitate.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    long long n;\n    cin >> n;\n    if (n < 2) { cout << \"NU\"; return 0; }\n    for (long long d = 2; d * d <= n; d++) {\n        if (n % d == 0) {\n            cout << \"NU\";\n            return 0;\n        }\n    }\n    cout << \"DA\";\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_10",
      "titlu": "CMMDC - Algoritmul lui Euclid",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "DIVIZIBILITATE",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Să se calculeze cel mai mare divizor comun a două numere a și b.",
      "tests": [
        {"input": "24 36", "output": "12"},
        {"input": "13 17", "output": "1"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "CMMDC cu împărțiri repetate.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    long long a, b;\n    cin >> a >> b;\n    while (b) {\n        long long r = a % b;\n        a = b;\n        b = r;\n    }\n    cout << a;\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_11",
      "titlu": "Descompunere în factori primi",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "DIVIZIBILITATE",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Se citește n. Să se afișeze factorii primi și puterea lor, fiecare pereche pe o linie nouă.",
      "tests": [
        {"input": "12", "output": "2 2\n3 1"},
        {"input": "20", "output": "2 2\n5 1"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Descompunere în factori primi.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n, d = 2;\n    cin >> n;\n    while (n > 1) {\n        int p = 0;\n        while (n % d == 0) { p++; n /= d; }\n        if (p > 0) cout << d << \" \" << p << \"\\n\";\n        d++;\n        if (d * d > n && n > 1) { cout << n << \" 1\\n\"; break; }\n    }\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_12",
      "titlu": "Suma elementelor unui vector",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "TABLOURI UNIDIMENSIONALE",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Se dă un vector cu n elemente. Să se determine suma componentelor sale.",
      "tests": [
        {"input": "4\n1 5 2 3", "output": "11"},
        {"input": "3\n10 20 30", "output": "60"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Suma elementelor din tablou.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n; cin >> n;\n    long long s = 0, x;\n    for (int i = 0; i < n; i++) {\n        cin >> x;\n        s += x;\n    }\n    cout << s;\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_13",
      "titlu": "Minimul și Maximul dintr-un vector",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "TABLOURI UNIDIMENSIONALE",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Să se găsească minimul și maximul dintr-un vector cu n elemente.",
      "tests": [
        {"input": "5\n7 2 9 1 5", "output": "1 9"},
        {"input": "3\n4 4 4", "output": "4 4"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Min și Max.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n; cin >> n;\n    int minv, maxv, x;\n    cin >> x; minv = maxv = x;\n    for (int i = 1; i < n; i++) {\n        cin >> x;\n        if (x < minv) minv = x;\n        if (x > maxv) maxv = x;\n    }\n    cout << minv << \" \" << maxv;\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_14",
      "titlu": "Căutare liniară",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "TABLOURI UNIDIMENSIONALE",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Se dau un vector cu n elemente și un număr x. Să se afișeze poziția (1-indexed) unde apare prima dată x sau 'NU'.",
      "tests": [
        {"input": "5\n3 8 2 9 4\n2", "output": "3"},
        {"input": "4\n1 2 3 4\n7", "output": "NU"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Căutare liniară element.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n, x, v[1005];\n    cin >> n;\n    for (int i = 1; i <= n; i++) cin >> v[i];\n    cin >> x;\n    for (int i = 1; i <= n; i++) {\n        if (v[i] == x) {\n            cout << i;\n            return 0;\n        }\n    }\n    cout << \"NU\";\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_15",
      "titlu": "Căutare binară",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "TABLOURI UNIDIMENSIONALE",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Se dă un vector sortat crescător cu n elemente și o valoare x. Afișați 1 dacă x există, 0 altfel.",
      "tests": [
        {"input": "5\n1 4 7 9 12\n9", "output": "1"},
        {"input": "5\n1 4 7 9 12\n5", "output": "0"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Căutare binară logaritmică.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n, x, v[100005];\n    cin >> n;\n    for (int i = 0; i < n; i++) cin >> v[i];\n    cin >> x;\n    int st = 0, dr = n - 1, gasit = 0;\n    while (st <= dr) {\n        int m = st + (dr - st) / 2;\n        if (v[m] == x) { gasit = 1; break; }\n        else if (v[m] < x) st = m + 1;\n        else dr = m - 1;\n    }\n    cout << gasit;\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_16",
      "titlu": "Sortare prin selecție",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "TABLOURI UNIDIMENSIONALE",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Să se sorteze crescător un vector cu n numere naturale.",
      "tests": [
        {"input": "4\n9 2 5 1", "output": "1 2 5 9"},
        {"input": "3\n3 1 2", "output": "1 2 3"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Sortare elemente vector.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n, v[1005];\n    cin >> n;\n    for (int i = 0; i < n; i++) cin >> v[i];\n    for (int i = 0; i < n - 1; i++)\n        for (int j = i + 1; j < n; j++)\n            if (v[i] > v[j]) swap(v[i], v[j]);\n    for (int i = 0; i < n; i++) cout << v[i] << \" \";\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_17",
      "titlu": "Vector de frecvență",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "TABLOURI UNIDIMENSIONALE",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Se dau n numere naturale < 1000. Afișați numărul care are numărul maxim de apariții.",
      "tests": [
        {"input": "6\n4 2 4 3 4 2", "output": "4"},
        {"input": "5\n10 10 20 20 20", "output": "20"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Frecvența maximă.",
        "code": "#include <iostream>\nusing namespace std;\n\nint fr[1005];\nint main() {\n    int n, x, maxFr = 0, valMax = 0;\n    cin >> n;\n    for (int i = 0; i < n; i++) {\n        cin >> x;\n        fr[x]++;\n        if (fr[x] > maxFr) { maxFr = fr[x]; valMax = x; }\n    }\n    cout << valMax;\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_18",
      "titlu": "Interclasare doi vectori",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "TABLOURI UNIDIMENSIONALE",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Se dau doi vectori sortați. Să se construiască și să se afișeze vectorul interclasat ordonat crescător.",
      "tests": [
        {"input": "3\n1 4 7\n3\n2 5 6", "output": "1 2 4 5 6 7"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Interclasare O(n+m).",
        "code": "#include <iostream>\nusing namespace std;\n\nint a[100005], b[100005];\nint main() {\n    int n, m;\n    cin >> n;\n    for (int i = 0; i < n; i++) cin >> a[i];\n    cin >> m;\n    for (int i = 0; i < m; i++) cin >> b[i];\n    int i = 0, j = 0;\n    while (i < n && j < m) {\n        if (a[i] < b[j]) cout << a[i++] << \" \";\n        else cout << b[j++] << \" \";\n    }\n    while (i < n) cout << a[i++] << \" \";\n    while (j < m) cout << b[j++] << \" \";\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_19",
      "titlu": "Secvență de sumă maximă (Kadane)",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "TABLOURI UNIDIMENSIONALE",
      "dificultate": "Grea",
      "tip_exercitiu": "cod",
      "enunt": "Se dă un vector cu n numere întregi. Determinați suma maximă a unei secvențe continue nevide.",
      "tests": [
        {"input": "6\n-2 1 -3 4 -1 2", "output": "5"},
        {"input": "4\n-5 -2 -8 -1", "output": "-1"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Algoritmul lui Kadane O(n).",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n; cin >> n;\n    long long x, sum = 0, maxSum = -1e18;\n    for (int i = 0; i < n; i++) {\n        cin >> x;\n        sum += x;\n        if (sum > maxSum) maxSum = sum;\n        if (sum < 0) sum = 0;\n    }\n    cout << maxSum;\n    return 0;\n}"
      }
    },
    {
      "id": "info_9_20",
      "titlu": "Ciurul lui Eratostene",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 9",
      "clasa": 9,
      "categorie": "DIVIZIBILITATE",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Se citește n. Să se afișeze numărul de numere prime mai mici sau egale cu n.",
      "tests": [
        {"input": "10", "output": "4"},
        {"input": "20", "output": "8"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Numărare prime cu Ciur.",
        "code": "#include <iostream>\n#include <vector>\nusing namespace std;\n\nint main() {\n    int n; cin >> n;\n    vector<bool> prim(n + 1, true);\n    prim[0] = prim[1] = false;\n    for (int p = 2; p * p <= n; p++)\n        if (prim[p])\n            for (int i = p * p; i <= n; i += p)\n                prim[i] = false;\n    int cnt = 0;\n    for (int i = 2; i <= n; i++) if (prim[i]) cnt++;\n    cout << cnt;\n    return 0;\n}"
      }
    },

    // ==========================================
    // CLASA A X-A (LEVEL 10) - 15 Probleme
    // ==========================================
    {
      "id": "info_10_1",
      "titlu": "Suma pe diagonala principală",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 10",
      "clasa": 10,
      "categorie": "MATRICE",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Se dă o matrice pătratică de ordin n. Să se calculeze suma elementelor de pe diagonala principală.",
      "tests": [
        {"input": "3\n1 2 3\n4 5 6\n7 8 9", "output": "15"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Suma elementelor cu i == j.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n, x; cin >> n;\n    long long s = 0;\n    for (int i = 0; i < n; i++)\n        for (int j = 0; j < n; j++) {\n            cin >> x;\n            if (i == j) s += x;\n        }\n    cout << s;\n    return 0;\n}"
      }
    },
    {
      "id": "info_10_2",
      "titlu": "Diagonala secundară",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 10",
      "clasa": 10,
      "categorie": "MATRICE",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Să se calculeze produsul elementelor de pe diagonala secundară a unei matrice pătratice de ordin n.",
      "tests": [
        {"input": "3\n1 2 3\n4 2 6\n1 8 9", "output": "6"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Produs elemente i + j == n - 1.",
        "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int n, x; cin >> n;\n    long long p = 1;\n    for (int i = 0; i < n; i++)\n        for (int j = 0; j < n; j++) {\n            cin >> x;\n            if (i + j == n - 1) p *= x;\n        }\n    cout << p;\n    return 0;\n}"
      }
    },
    {
      "id": "info_10_3",
      "titlu": "Matrice transpusă",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 10",
      "clasa": 10,
      "categorie": "MATRICE",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Se dă o matrice cu n linii și m coloane. Să se afișeze transpusa sa.",
      "tests": [
        {"input": "2 3\n1 2 3\n4 5 6", "output": "1 4\n2 5\n3 6"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Inversare linii și coloane.",
        "code": "#include <iostream>\nusing namespace std;\n\nint a[105][105];\nint main() {\n    int n, m;\n    cin >> n >> m;\n    for (int i = 0; i < n; i++)\n        for (int j = 0; j < m; j++)\n            cin >> a[i][j];\n    for (int j = 0; j < m; j++) {\n        for (int i = 0; i < n; i++) {\n            cout << a[i][j] << \" \";\n        }\n        cout << \"\\n\";\n    }\n    return 0;\n}"
      }
    },
    {
      "id": "info_10_4",
      "titlu": "Numărare vocale în text",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 10",
      "clasa": 10,
      "categorie": "ȘIRURI DE CARACTERE",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Se dă un șir de caractere. Să se determine numărul total de vocale (a, e, i, o, u).",
      "tests": [
        {"input": "informatica", "output": "5"},
        {"input": "pbinfo", "output": "2"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Parcurgere șir caractere.",
        "code": "#include <iostream>\n#include <string>\nusing namespace std;\n\nint main() {\n    string s;\n    cin >> s;\n    int cnt = 0;\n    for (char c : s) {\n        c = tolower(c);\n        if (c=='a'||c=='e'||c=='i'||c=='o'||c=='u') cnt++;\n    }\n    cout << cnt;\n    return 0;\n}"
      }
    },
    {
      "id": "info_10_5",
      "titlu": "Verificare anagrame",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 10",
      "clasa": 10,
      "categorie": "ȘIRURI DE CARACTERE",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Se dau două cuvinte. Să se verifice dacă sunt anagrame. Afișați 1 sau 0.",
      "tests": [
        {"input": "arc car", "output": "1"},
        {"input": "mama tata", "output": "0"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Sortare și comparare șiruri.",
        "code": "#include <iostream>\n#include <algorithm>\n#include <string>\nusing namespace std;\n\nint main() {\n    string a, b;\n    cin >> a >> b;\n    sort(a.begin(), a.end());\n    sort(b.begin(), b.end());\n    cout << (a == b ? 1 : 0);\n    return 0;\n}"
      }
    },
    {
      "id": "info_10_6",
      "titlu": "Factorial recursiv",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 10",
      "clasa": 10,
      "categorie": "RECURSIVITATE",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Să se scrie un program care calculează recursiv valoarea n!.",
      "tests": [
        {"input": "5", "output": "120"},
        {"input": "0", "output": "1"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Calcul n! recursiv.",
        "code": "#include <iostream>\nusing namespace std;\n\nlong long fact(int n) {\n    if (n <= 1) return 1;\n    return n * fact(n - 1);\n}\n\nint main() {\n    int n; cin >> n;\n    cout << fact(n);\n    return 0;\n}"
      }
    },
    {
      "id": "info_10_7",
      "titlu": "Fibonacci recursiv",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 10",
      "clasa": 10,
      "categorie": "RECURSIVITATE",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Determinați al n-lea termen din șirul Fibonacci prin recursivitate (F(1)=1, F(2)=1).",
      "tests": [
        {"input": "7", "output": "13"},
        {"input": "1", "output": "1"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Calcul termen Fibonacci.",
        "code": "#include <iostream>\nusing namespace std;\n\nint fib(int n) {\n    if (n <= 2) return 1;\n    return fib(n - 1) + fib(n - 2);\n}\n\nint main() {\n    int n; cin >> n;\n    cout << fib(n);\n    return 0;\n}"
      }
    },
    {
      "id": "info_10_8",
      "titlu": "Turnurile din Hanoi",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 10",
      "clasa": 10,
      "categorie": "RECURSIVITATE",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Să se afișeze mutările pentru problema Turnurilor din Hanoi cu n discuri.",
      "tests": [
        {"input": "2", "output": "A->B\nA->C\nB->C"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Rezolvare Hanoi.",
        "code": "#include <iostream>\nusing namespace std;\n\nvoid hanoi(int n, char a, char b, char c) {\n    if (n == 1) {\n        cout << a << \"->\" << c << \"\\n\";\n        return;\n    }\n    hanoi(n - 1, a, c, b);\n    cout << a << \"->\" << c << \"\\n\";\n    hanoi(n - 1, b, a, c);\n}\n\nint main() {\n    int n; cin >> n;\n    hanoi(n, 'A', 'B', 'C');\n    return 0;\n}"
      }
    },
    {
      "id": "info_10_9",
      "titlu": "Ridicare la putere în timp logaritmic",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 10",
      "clasa": 10,
      "categorie": "DIVIDE ET IMPERA",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Calculați a^b modulo 1.000.000.007 în timp O(log b).",
      "tests": [
        {"input": "2 10", "output": "1024"},
        {"input": "3 5", "output": "243"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Exponențiere rapidă.",
        "code": "#include <iostream>\nusing namespace std;\n\nlong long lgput(long long a, long long b) {\n    long long res = 1, mod = 1000000007;\n    a %= mod;\n    while (b > 0) {\n        if (b & 1) res = (res * a) % mod;\n        a = (a * a) % mod;\n        b >>= 1;\n    }\n    return res;\n}\n\nint main() {\n    long long a, b; cin >> a >> b;\n    cout << lgput(a, b);\n    return 0;\n}"
      }
    },
    {
      "id": "info_10_10",
      "titlu": "Merge Sort",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 10",
      "clasa": 10,
      "categorie": "DIVIDE ET IMPERA",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Să se sorteze crescător un vector cu n elemente folosind Merge Sort.",
      "tests": [
        {"input": "5\n8 3 1 7 4", "output": "1 3 4 7 8"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Sortare Divide et Impera.",
        "code": "#include <iostream>\n#include <algorithm>\nusing namespace std;\n\nint main() {\n    int n, v[100005];\n    cin >> n;\n    for (int i = 0; i < n; i++) cin >> v[i];\n    sort(v, v + n);\n    for (int i = 0; i < n; i++) cout << v[i] << \" \";\n    return 0;\n}"
      }
    },
    {
      "id": "info_10_11",
      "titlu": "Parantezare corectă (Stivă)",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 10",
      "clasa": 10,
      "categorie": "STRUCTURI DE DATE",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Se dă un șir de paranteze rotunde '()' și pătrate '[]'. Afișați 1 dacă este parantezat corect, 0 altfel.",
      "tests": [
        {"input": "([()])", "output": "1"},
        {"input": "([)]", "output": "0"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Validare cu stivă STL.",
        "code": "#include <iostream>\n#include <stack>\n#include <string>\nusing namespace std;\n\nint main() {\n    string s; cin >> s;\n    stack<char> st;\n    for (char c : s) {\n        if (c == '(' || c == '[') st.push(c);\n        else {\n            if (st.empty()) { cout << 0; return 0; }\n            if (c == ')' && st.top() != '(') { cout << 0; return 0; }\n            if (c == ']' && st.top() != '[') { cout << 0; return 0; }\n            st.pop();\n        }\n    }\n    cout << (st.empty() ? 1 : 0);\n    return 0;\n}"
      }
    },
    {
      "id": "info_10_12",
      "titlu": "Inversare șir de caractere",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 10",
      "clasa": 10,
      "categorie": "ȘIRURI DE CARACTERE",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Se citește un cuvânt. Să se afișeze cuvântul inversat.",
      "tests": [
        {"input": "hello", "output": "olleh"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Inversare șir.",
        "code": "#include <iostream>\n#include <string>\n#include <algorithm>\nusing namespace std;\n\nint main() {\n    string s; cin >> s;\n    reverse(s.begin(), s.end());\n    cout << s;\n    return 0;\n}"
      }
    },
    {
      "id": "info_10_13",
      "titlu": "Parcurgere în spirală",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 10",
      "clasa": 10,
      "categorie": "MATRICE",
      "dificultate": "Grea",
      "tip_exercitiu": "cod",
      "enunt": "Se dă o matrice pătratică de ordin n. Să se afișeze elementele parcurse în spirală.",
      "tests": [
        {"input": "3\n1 2 3\n8 9 4\n7 6 5", "output": "1 2 3 4 5 6 7 8 9"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Parcurgere spirală matrice.",
        "code": "#include <iostream>\nusing namespace std;\n\nint a[55][55];\nint main() {\n    int n; cin >> n;\n    for(int i=0;i<n;i++) for(int j=0;j<n;j++) cin >> a[i][j];\n    int top=0, bottom=n-1, left=0, right=n-1;\n    while(top <= bottom && left <= right) {\n        for(int j=left; j<=right; j++) cout << a[top][j] << \" \";\n        top++;\n        for(int i=top; i<=bottom; i++) cout << a[i][right] << \" \";\n        right--;\n        if(top <= bottom) {\n            for(int j=right; j>=left; j--) cout << a[bottom][j] << \" \";\n            bottom--;\n        }\n        if(left <= right) {\n            for(int i=bottom; i>=top; i--) cout << a[i][left] << \" \";\n            left++;\n        }\n    }\n    return 0;\n}"
      }
    },
    {
      "id": "info_10_14",
      "titlu": "Subșiruri distincte",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 10",
      "clasa": 10,
      "categorie": "ȘIRURI DE CARACTERE",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Se dă un șir de caractere. Să se determine numărul de litere mici distincte care apar în șir.",
      "tests": [
        {"input": "abracadabra", "output": "5"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Frecvență litere distincte.",
        "code": "#include <iostream>\n#include <string>\n#include <set>\nusing namespace std;\n\nint main() {\n    string s; cin >> s;\n    set<char> st;\n    for(char c : s) st.insert(c);\n    cout << st.size();\n    return 0;\n}"
      }
    },
    {
      "id": "info_10_15",
      "titlu": "Coada de priorități - Simulare",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 10",
      "clasa": 10,
      "categorie": "STRUCTURI DE DATE",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Se citesc n numere naturale. Să se afișeze cele mai mari 3 numere distincte în ordine descrescătoare.",
      "tests": [
        {"input": "5\n10 4 20 15 20", "output": "20 15 10"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Extragere top 3.",
        "code": "#include <iostream>\n#include <set>\nusing namespace std;\n\nint main() {\n    int n, x; cin >> n;\n    set<int, greater<int>> s;\n    for(int i=0;i<n;i++) { cin >> x; s.insert(x); }\n    int count = 0;\n    for(int val : s) {\n        cout << val << \" \";\n        if(++count == 3) break;\n    }\n    return 0;\n}"
      }
    },

    // ==========================================
    // CLASA A XI-A (LEVEL 11) - 15 Probleme
    // ==========================================
    {
      "id": "info_11_1",
      "titlu": "Generarea permutărilor",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 11",
      "clasa": 11,
      "categorie": "BACKTRACKING",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Să se genereze permutările mulțimii {1, 2, ..., n} în ordine lexicografică.",
      "tests": [
        {"input": "3", "output": "1 2 3\n1 3 2\n2 1 3\n2 3 1\n3 1 2\n3 2 1"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Permutări clasice Backtracking.",
        "code": "#include <iostream>\nusing namespace std;\n\nint n, st[15], uz[15];\nvoid bkt(int k) {\n    if (k > n) {\n        for (int i = 1; i <= n; i++) cout << st[i] << \" \";\n        cout << \"\\n\";\n        return;\n    }\n    for (int i = 1; i <= n; i++)\n        if (!uz[i]) {\n            uz[i] = 1; st[k] = i;\n            bkt(k + 1);\n            uz[i] = 0;\n        }\n}\nint main() { cin >> n; bkt(1); return 0; }"
      }
    },
    {
      "id": "info_11_2",
      "titlu": "Generarea combinărilor",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 11",
      "clasa": 11,
      "categorie": "BACKTRACKING",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Generați combinările de n elemente luate câte k în ordine lexicografică.",
      "tests": [
        {"input": "4 2", "output": "1 2\n1 3\n1 4\n2 3\n2 4\n3 4"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Combinări Backtracking.",
        "code": "#include <iostream>\nusing namespace std;\n\nint n, k, st[20];\nvoid bkt(int pas) {\n    if (pas > k) {\n        for (int i = 1; i <= k; i++) cout << st[i] << \" \";\n        cout << \"\\n\";\n        return;\n    }\n    for (int i = st[pas - 1] + 1; i <= n; i++) {\n        st[pas] = i;\n        bkt(pas + 1);\n    }\n}\nint main() { cin >> n >> k; bkt(1); return 0; }"
      }
    },
    {
      "id": "info_11_3",
      "titlu": "Problema Damelor (N-Queens)",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 11",
      "clasa": 11,
      "categorie": "BACKTRACKING",
      "dificultate": "Grea",
      "tip_exercitiu": "cod",
      "enunt": "Determinați numărul de moduri de a plasa n dame pe o tablă n×n fără să se atace reciproc.",
      "tests": [
        {"input": "4", "output": "2"},
        {"input": "8", "output": "92"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Număr de configurații Dame.",
        "code": "#include <iostream>\n#include <cmath>\nusing namespace std;\n\nint n, cnt = 0, st[20];\nbool ok(int k) {\n    for (int i = 1; i < k; i++)\n        if (st[i] == st[k] || abs(st[k] - st[i]) == k - i) return false;\n    return true;\n}\nvoid bkt(int k) {\n    if (k > n) { cnt++; return; }\n    for (int i = 1; i <= n; i++) {\n        st[k] = i;\n        if (ok(k)) bkt(k + 1);\n    }\n}\nint main() { cin >> n; bkt(1); cout << cnt; return 0; }"
      }
    },
    {
      "id": "info_11_4",
      "titlu": "Matricea de adiacență",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 11",
      "clasa": 11,
      "categorie": "GRAFURI NEORIENTATE",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Se dă un graf neorientat cu n noduri și m muchii. Să se afișeze matricea de adiacență.",
      "tests": [
        {"input": "3 2\n1 2\n2 3", "output": "0 1 0\n1 0 1\n0 1 0"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Matrice de adiacență binară.",
        "code": "#include <iostream>\nusing namespace std;\n\nint a[105][105];\nint main() {\n    int n, m, u, v;\n    cin >> n >> m;\n    while (m--) {\n        cin >> u >> v;\n        a[u][v] = a[v][u] = 1;\n    }\n    for (int i = 1; i <= n; i++) {\n        for (int j = 1; j <= n; j++) cout << a[i][j] << \" \";\n        cout << \"\\n\";\n    }\n    return 0;\n}"
      }
    },
    {
      "id": "info_11_5",
      "titlu": "Gradele nodurilor",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 11",
      "clasa": 11,
      "categorie": "GRAFURI NEORIENTATE",
      "dificultate": "Ușoară",
      "tip_exercitiu": "cod",
      "enunt": "Să se calculeze gradul fiecărui nod de la 1 la n într-un graf neorientat.",
      "tests": [
        {"input": "4 3\n1 2\n1 3\n1 4", "output": "3 1 1 1"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Vector de grade.",
        "code": "#include <iostream>\nusing namespace std;\n\nint grad[105];\nint main() {\n    int n, m, u, v;\n    cin >> n >> m;\n    while (m--) {\n        cin >> u >> v;\n        grad[u]++; grad[v]++;\n    }\n    for (int i = 1; i <= n; i++) cout << grad[i] << \" \";\n    return 0;\n}"
      }
    },
    {
      "id": "info_11_6",
      "titlu": "Parcurgere în lățime (BFS)",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 11",
      "clasa": 11,
      "categorie": "GRAFURI",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Să se afișeze ordinea de vizitare a nodurilor unui graf pornind dintr-un nod sursă folosind BFS.",
      "tests": [
        {"input": "4 3 1\n1 2\n1 3\n2 4", "output": "1 2 3 4"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "BFS cu coadă STL.",
        "code": "#include <iostream>\n#include <vector>\n#include <queue>\nusing namespace std;\n\nvector<int> adj[1005];\nbool viz[1005];\nint main() {\n    int n, m, s, u, v;\n    cin >> n >> m >> s;\n    while(m--) { cin >> u >> v; adj[u].push_back(v); adj[v].push_back(u); }\n    queue<int> q;\n    q.push(s); viz[s] = true;\n    while(!q.empty()) {\n        int nod = q.front(); q.pop();\n        cout << nod << \" \";\n        for(int vecin : adj[nod])\n            if(!viz[vecin]) { viz[vecin] = true; q.push(vecin); }\n    }\n    return 0;\n}"
      }
    },
    {
      "id": "info_11_7",
      "titlu": "Parcurgere în adâncime (DFS)",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 11",
      "clasa": 11,
      "categorie": "GRAFURI",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Afișați ordinea de vizitare a nodurilor prin parcurgere recursivă DFS dintr-un nod dat.",
      "tests": [
        {"input": "4 3 1\n1 2\n2 3\n3 4", "output": "1 2 3 4"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "DFS recursiv.",
        "code": "#include <iostream>\n#include <vector>\nusing namespace std;\n\nvector<int> adj[1005];\nbool viz[1005];\nvoid dfs(int nod) {\n    viz[nod] = true;\n    cout << nod << \" \";\n    for(int vecin : adj[nod])\n        if(!viz[vecin]) dfs(vecin);\n}\nint main() {\n    int n, m, s, u, v;\n    cin >> n >> m >> s;\n    while(m--) { cin >> u >> v; adj[u].push_back(v); adj[v].push_back(u); }\n    dfs(s);\n    return 0;\n}"
      }
    },
    {
      "id": "info_11_8",
      "titlu": "Componente conexe",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 11",
      "clasa": 11,
      "categorie": "GRAFURI NEORIENTATE",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Să se determine numărul total de componente conexe dintr-un graf neorientat.",
      "tests": [
        {"input": "5 2\n1 2\n4 5", "output": "3"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Numărare componente conexe cu DFS.",
        "code": "#include <iostream>\n#include <vector>\nusing namespace std;\n\nvector<int> adj[1005];\nbool viz[1005];\nvoid dfs(int nod) {\n    viz[nod] = true;\n    for(int v : adj[nod]) if(!viz[v]) dfs(v);\n}\nint main() {\n    int n, m, u, v;\n    cin >> n >> m;\n    while(m--) { cin >> u >> v; adj[u].push_back(v); adj[v].push_back(u); }\n    int c = 0;\n    for(int i = 1; i <= n; i++)\n        if(!viz[i]) { c++; dfs(i); }\n    cout << c;\n    return 0;\n}"
      }
    },
    {
      "id": "info_11_9",
      "titlu": "Arbore parțial de cost minim (Kruskal)",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 11",
      "clasa": 11,
      "categorie": "GRAFURI PONDERATE",
      "dificultate": "Grea",
      "tip_exercitiu": "cod",
      "enunt": "Determinați costul minim al unui arbore parțial de acoperire pentru un graf conex ponderat.",
      "tests": [
        {"input": "3 3\n1 2 2\n2 3 3\n1 3 1", "output": "3"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Kruskal cu DSU.",
        "code": "#include <iostream>\n#include <vector>\n#include <algorithm>\nusing namespace std;\n\nstruct Muchie { int u, v, c; };\nbool cmp(Muchie a, Muchie b) { return a.c < b.c; }\nint t[1005];\nint rad(int x) { return t[x] == x ? x : t[x] = rad(t[x]); }\n\nint main() {\n    int n, m; cin >> n >> m;\n    vector<Muchie> e(m);\n    for(int i=0;i<m;i++) cin >> e[i].u >> e[i].v >> e[i].c;\n    sort(e.begin(), e.end(), cmp);\n    for(int i=1;i<=n;i++) t[i]=i;\n    int cost = 0;\n    for(auto mch : e) {\n        int ru = rad(mch.u), rv = rad(mch.v);\n        if(ru != rv) { t[ru] = rv; cost += mch.c; }\n    }\n    cout << cost;\n    return 0;\n}"
      }
    },
    {
      "id": "info_11_10",
      "titlu": "Algoritmul lui Dijkstra (Drum minim)",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 11",
      "clasa": 11,
      "categorie": "GRAFURI PONDERATE",
      "dificultate": "Grea",
      "tip_exercitiu": "cod",
      "enunt": "Determinați lungimea drumului minim de la sursă la toate celelalte noduri.",
      "tests": [
        {"input": "3 3 1\n1 2 5\n2 3 2\n1 3 10", "output": "0 5 7"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Dijkstra cu Priority Queue.",
        "code": "#include <iostream>\n#include <vector>\n#include <queue>\nusing namespace std;\n\nconst int INF = 1e9;\nint main() {\n    int n, m, s; cin >> n >> m >> s;\n    vector<pair<int,int>> adj[1005];\n    for(int i=0;i<m;i++){\n        int u, v, c; cin >> u >> v >> c;\n        adj[u].push_back({v, c});\n    }\n    vector<int> d(n + 1, INF);\n    priority_queue<pair<int,int>, vector<pair<int,int>>, greater<pair<int,int>>> pq;\n    d[s] = 0; pq.push({0, s});\n    while(!pq.empty()) {\n        int dist = pq.top().first, u = pq.top().second;\n        pq.pop();\n        if(dist > d[u]) continue;\n        for(auto edge : adj[u]) {\n            int v = edge.first, w = edge.second;\n            if(d[u] + w < d[v]) { d[v] = d[u] + w; pq.push({d[v], v}); }\n        }\n    }\n    for(int i = 1; i <= n; i++) cout << (d[i] == INF ? -1 : d[i]) << \" \";\n    return 0;\n}"
      }
    },
    {
      "id": "info_11_11",
      "titlu": "Problema Rucsacului (0-1)",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 11",
      "clasa": 11,
      "categorie": "PROGRAMARE DINAMICĂ",
      "dificultate": "Grea",
      "tip_exercitiu": "cod",
      "enunt": "Avem n obiecte cu greutăți și valori și un rucsac de capacitate G. Determinați valoarea maximă.",
      "tests": [
        {"input": "3 10\n4 30\n5 40\n7 60", "output": "70"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Rucsac DP 0-1.",
        "code": "#include <iostream>\n#include <vector>\n#include <algorithm>\nusing namespace std;\n\nint dp[10005];\nint main() {\n    int n, G; cin >> n >> G;\n    for(int i=0;i<n;i++){\n        int w, v; cin >> w >> v;\n        for(int j=G; j>=w; j--)\n            dp[j] = max(dp[j], dp[j - w] + v);\n    }\n    cout << dp[G];\n    return 0;\n}"
      }
    },
    {
      "id": "info_11_12",
      "titlu": "Cel mai lung subșir crescător (LIS)",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 11",
      "clasa": 11,
      "categorie": "PROGRAMARE DINAMICĂ",
      "dificultate": "Grea",
      "tip_exercitiu": "cod",
      "enunt": "Determinați lungimea maximă a unui subșir strict crescător din vector.",
      "tests": [
        {"input": "6\n5 2 8 6 3 7", "output": "3"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "LIS O(n^2).",
        "code": "#include <iostream>\n#include <vector>\n#include <algorithm>\nusing namespace std;\n\nint main() {\n    int n; cin >> n;\n    vector<int> v(n), dp(n, 1);\n    for(int i=0;i<n;i++) cin >> v[i];\n    int ans = 1;\n    for(int i=0;i<n;i++){\n        for(int j=0;j<i;j++)\n            if(v[j] < v[i]) dp[i] = max(dp[i], dp[j] + 1);\n        ans = max(ans, dp[i]);\n    }\n    cout << ans;\n    return 0;\n}"
      }
    },
    {
      "id": "info_11_13",
      "titlu": "Traseu de sumă maximă în matrice",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 11",
      "clasa": 11,
      "categorie": "PROGRAMARE DINAMICĂ",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Pornind din (1,1) către (n,m) cu deplasare doar la dreapta și în jos, determinați suma maximă a traseului.",
      "tests": [
        {"input": "3 3\n1 3 1\n1 5 1\n4 2 1", "output": "12"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Traseu sumă maximă DP.",
        "code": "#include <iostream>\n#include <algorithm>\nusing namespace std;\n\nint a[505][505], dp[505][505];\nint main() {\n    int n, m; cin >> n >> m;\n    for(int i=1;i<=n;i++)\n        for(int j=1;j<=m;j++) cin >> a[i][j];\n    for(int i=1;i<=n;i++)\n        for(int j=1;j<=m;j++)\n            dp[i][j] = a[i][j] + max(dp[i-1][j], dp[i][j-1]);\n    cout << dp[n][m];\n    return 0;\n}"
      }
    },
    {
      "id": "info_11_14",
      "titlu": "Subșirul comun maximal (LCS)",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 11",
      "clasa": 11,
      "categorie": "PROGRAMARE DINAMICĂ",
      "dificultate": "Grea",
      "tip_exercitiu": "cod",
      "enunt": "Se dau două șiruri de caractere. Să se determine lungimea celui mai lung subșir comun.",
      "tests": [
        {"input": "abac\nac", "output": "2"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "LCS cu DP.",
        "code": "#include <iostream>\n#include <string>\n#include <vector>\n#include <algorithm>\nusing namespace std;\n\nint dp[1005][1005];\nint main() {\n    string a, b; cin >> a >> b;\n    int n = a.size(), m = b.size();\n    for(int i=1;i<=n;i++)\n        for(int j=1;j<=m;j++) {\n            if(a[i-1] == b[j-1]) dp[i][j] = dp[i-1][j-1] + 1;\n            else dp[i][j] = max(dp[i-1][j], dp[i][j-1]);\n        }\n    cout << dp[n][m];\n    return 0;\n}"
      }
    },
    {
      "id": "info_11_15",
      "titlu": "Problema Monedelor (Restul minim)",
      "subject": "Informatică",
      "materie": "Informatică",
      "level": "LEVEL 11",
      "clasa": 11,
      "categorie": "PROGRAMARE DINAMICĂ",
      "dificultate": "Medie",
      "tip_exercitiu": "cod",
      "enunt": "Determinați numărul minim de monede necesare pentru a achita o sumă S sau -1 dacă nu se poate.",
      "tests": [
        {"input": "3 6\n1 3 4", "output": "2"}
      ],
      "official_solution": {
        "language": "C++",
        "subject": "Informatică",
        "output": "Coin Change DP.",
        "code": "#include <iostream>\n#include <vector>\n#include <algorithm>\nusing namespace std;\n\nconst int INF = 1e9;\nint main() {\n    int n, S; cin >> n >> S;\n    vector<int> c(n), dp(S + 1, INF);\n    for(int i=0;i<n;i++) cin >> c[i];\n    dp[0] = 0;\n    for(int i=1;i<=S;i++)\n        for(int coin : c)\n            if(i >= coin) dp[i] = min(dp[i], dp[i - coin] + 1);\n    cout << (dp[S] >= INF ? -1 : dp[S]);\n    return 0;\n}"
      }
    }
  ];

  print("Începe popularea colecției 'exercises' cu 50 de probleme PbInfo...");

  for (var prob in listaProbleme) {
    // Folosim ID-ul specific din listă (ex: info_9_1) pentru potrivire exactă
    String docId = prob["id"] as String;
    DocumentReference docRef = db.collection('exercises').doc(docId);
    batch.set(docRef, prob);
  }

  await batch.commit();
  print("Toate cele 50 de probleme au fost salvate în 'exercises'!");
}