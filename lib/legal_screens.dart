import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // 🚀 Importul necesar pentru navigare

// ==========================================
// COMPONENTĂ REUTILIZABILĂ PENTRU SECȚIUNI
// ==========================================
Widget _buildSection(String title, String content) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade700,
            height: 1.6,
          ),
        ),
      ],
    ),
  );
}

// ==========================================
// ECRAN: TERMENI ȘI CONDIȚII
// ==========================================
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        // 🚀 AICI: Adăugăm manual săgeata de Back
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.go('/inregistrare'), // Ne întoarcem la înregistrare
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
        title: const Text("Termeni și Condiții", style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800), // Optimizat pentru Desktop & Mobile
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Text("DOCUMENT OFICIAL", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 16),
                  const Text("Termeni și Condiții de Utilizare", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1)),
                  const SizedBox(height: 8),
                  Text("Ultima actualizare: 1 Noiembrie 2024", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 40),

                  _buildSection(
                    "1. Introducere",
                    "Acest document reprezintă un acord legal între dumneavoastră (în calitate de utilizator, profesor sau elev) și platforma iMeditatii. Prin crearea unui cont și utilizarea serviciilor noastre, confirmați că ați citit, ați înțeles și acceptați integral acești Termeni și Condiții. Dacă nu sunteți de acord, vă rugăm să nu utilizați platforma.",
                  ),
                  _buildSection(
                    "2. Statutul Platformei",
                    "iMeditatii funcționează exclusiv ca un furnizor de tehnologie și intermediar (marketplace). Noi punem la dispoziție o infrastructură digitală pentru ca elevii și profesorii să poată comunica, partaja resurse și desfășura apeluri video. iMeditatii nu este angajatorul profesorilor înregistrați pe platformă. Fiecare profesor activează ca un profesionist independent.",
                  ),
                  _buildSection(
                    "3. Crearea și Verificarea Conturilor",
                    "Utilizatorii se obligă să furnizeze informații reale, precise și complete. Conturile de profesor sunt supuse unui proces de verificare internă înainte de a deveni active pe platformă. Ne rezervăm dreptul de a respinge sau suspenda orice cont care prezintă informații false sau care încalcă standardele noastre de calitate.",
                  ),
                  _buildSection(
                    "4. Plăți și Comisioane",
                    "Toate tranzacțiile financiare sunt procesate în mod securizat prin partenerul nostru, Stripe. Elevii achită contravaloarea ședințelor direct prin platformă. iMeditatii va reține un comision de administrare și procesare din suma achitată, restul fiind transferat direct în contul bancar al profesorului.\n\nProfesorii sunt unici responsabili pentru declararea veniturilor obținute și plata taxelor și impozitelor aferente conform legislației fiscale din România.",
                  ),
                  _buildSection(
                    "5. Reguli de Conduită",
                    "Ne dorim o comunitate sigură și respectuoasă. Este strict interzisă utilizarea unui limbaj licențios, hărțuirea, discriminarea sau partajarea de conținut inadecvat. De asemenea, încercarea de a ocoli sistemul de plăți al platformei (ex. solicitarea plății în numerar sau prin alte aplicații) va duce la suspendarea permanentă a conturilor implicate.",
                  ),
                  _buildSection(
                    "6. Răspundere și Limitări",
                    "Deși depunem eforturi constante pentru a asigura calitatea profesorilor, iMeditatii nu garantează obținerea unor anumite note sau rezultate academice. Responsabilitatea actului educațional revine profesorului, iar responsabilitatea asimilării informației revine elevului. Nu răspundem pentru eventualele întreruperi de funcționare cauzate de furnizorii de internet sau forță majoră.",
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // 🚀 Aici folosim context.go ca să ne întoarcem la ecranul de Sign Up
                      onPressed: () => context.go('/inregistrare'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("Am înțeles și revin la înregistrare", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ECRAN: POLITICA DE CONFIDENȚIALITATE (GDPR)
// ==========================================
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        // 🚀 AICI: Adăugăm manual săgeata de Back
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.go('/inregistrare'), // Ne întoarcem la înregistrare
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
        title: const Text("Politica de Confidențialitate", style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Text("CONFORMITATE GDPR", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 16),
                  const Text("Politica de Confidențialitate", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1)),
                  const SizedBox(height: 8),
                  Text("Ultima actualizare: 1 Noiembrie 2024", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 40),

                  _buildSection(
                    "1. Ce date colectăm?",
                    "Când vă creați un cont pe iMeditatii, colectăm informații cu caracter personal precum: numele complet, adresa de email, numărul de telefon și, opțional, fotografia de profil. Pentru procesarea plăților, detaliile bancare sunt colectate direct de procesatorul nostru securizat (Stripe) și nu sunt stocate pe serverele noastre.",
                  ),
                  _buildSection(
                    "2. Cum folosim aceste date?",
                    "Datele dumneavoastră sunt utilizate exclusiv pentru a asigura buna funcționare a platformei. Aceasta include: crearea și administrarea contului, facilitarea comunicării (chat și apeluri video) între elevi și profesori, procesarea plăților, afișarea profilului public (pentru profesori) și trimiterea de notificări legate de activitatea contului.",
                  ),
                  _buildSection(
                    "3. Securitatea Datelor",
                    "Siguranța datelor dumneavoastră este o prioritate. Folosim infrastructura securizată Firebase (operată de Google) pentru stocarea bazei de date. Toate comunicațiile și datele transferate între dispozitivul dumneavoastră și serverele noastre sunt criptate (SSL/TLS).",
                  ),
                  _buildSection(
                    "4. Partajarea informațiilor cu terțe părți",
                    "Nu vindem, nu închiriem și nu comercializăm datele dumneavoastră personale. Informațiile sunt partajate doar cu parteneri de încredere esențiali funcționării serviciului, precum Stripe (pentru procesarea plăților) și Google Firebase (pentru găzduire cloud), ambii fiind conformi cu reglementările GDPR.",
                  ),
                  _buildSection(
                    "5. Drepturile Dumneavoastră",
                    "Conform Regulamentului General privind Protecția Datelor (GDPR), aveți următoarele drepturi:\n• Dreptul de acces: Puteți solicita un raport cu datele pe care le deținem despre dumneavoastră.\n• Dreptul la rectificare: Puteți corecta datele inexacte din secțiunea 'Editează profil'.\n• Dreptul la ștergere ('Dreptul de a fi uitat'): Puteți solicita oricând ștergerea permanentă a contului și a datelor asociate.\n\nPentru exercitarea acestor drepturi, ne puteți contacta la adresa de email de suport afișată pe platformă.",
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // 🚀 Aici folosim context.go
                      onPressed: () => context.go('/inregistrare'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("Am înțeles și revin la înregistrare", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}