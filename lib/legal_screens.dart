import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppColors {
  static const Color bg = Color(0xFFF9F7F1);
  static const Color ink = Color(0xFF2C363F);
  static const Color sunset = Color(0xFFE75A41);
  static const Color forest = Color(0xFF3C7A61);
  static const Color mustard = Color(0xFFEAB334);
  static const Color cloud = Color(0xFFE2DFD2);
  static const Color sky = Color(0xFF5BA8B5);
}

class RetroBlock extends StatelessWidget {
  final Widget child;
  final Color bgColor;
  final double padding;
  final double shadowOffset;
  final Color borderColor;

  const RetroBlock({
    super.key,
    required this.child,
    this.bgColor = Colors.white,
    this.padding = 24.0,
    this.shadowOffset = 6.0,
    this.borderColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}

class RetroButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color bgColor;
  final Color textColor;
  final bool isFullWidth;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor = AppColors.sunset,
    this.textColor = Colors.white,
    this.isFullWidth = false,
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool isPressed = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) {
          setState(() => isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.isFullWidth ? double.infinity : null,
          transform: Matrix4.translationValues(
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            isPressed ? 4.0 : (isHovered ? -2.0 : 0.0),
            0,
          ),
          decoration: BoxDecoration(
            color: widget.bgColor,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink,
                offset: isPressed ? const Offset(0, 0) : const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Text(
            widget.text.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildSection(String title, String content) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: const [
              BoxShadow(color: AppColors.ink, offset: Offset(4, 4)),
            ],
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink, size: 32),
          onPressed: () => context.go('/inregistrare'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: AppColors.ink, height: 3),
        ),
        title: const Text(
            "TERMS OF SERVICE",
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 2.0)
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: RetroBlock(
              bgColor: AppColors.cloud,
              padding: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: AppColors.mustard,
                        border: Border.all(color: AppColors.ink, width: 2)
                    ),
                    child: const Text("OFFICIAL SYSTEM DOCUMENT", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 24),
                  const Text("USER AGREEMENT", style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  const Text("LAST LOG: NOVEMBER 1, 2024", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 48),

                  _buildSection(
                    "1. SYSTEM ACCESS",
                    "Acest document reprezintă un acord legal între dumneavoastră (în calitate de utilizator, profesor sau elev) și platforma iMeditatii. Prin crearea unui cont și utilizarea serviciilor noastre, confirmați că ați citit, ați înțeles și acceptați integral acești Termeni și Condiții. Dacă nu sunteți de acord, vă rugăm să nu utilizați platforma.",
                  ),
                  _buildSection(
                    "2. PLATFORM STATUS",
                    "iMeditatii funcționează exclusiv ca un furnizor de tehnologie și intermediar (marketplace). Noi punem la dispoziție o infrastructură digitală pentru ca elevii și profesorii să poată comunica, partaja resurse și desfășura apeluri video. iMeditatii nu este angajatorul profesorilor înregistrați pe platformă. Fiecare profesor activează ca un profesionist independent.",
                  ),
                  _buildSection(
                    "3. USER VERIFICATION",
                    "Utilizatorii se obligă să furnizeze informații reale, precise și complete. Conturile de profesor sunt supuse unui proces de verificare internă înainte de a deveni active pe platformă. Ne rezervăm dreptul de a respinge sau suspenda orice cont care prezintă informații false sau care încalcă standardele noastre de calitate.",
                  ),
                  _buildSection(
                    "4. TRANSACTIONS",
                    "Toate tranzacțiile financiare sunt procesate în mod securizat prin partenerul nostru, Stripe. Elevii achită contravaloarea ședințelor direct prin platformă. iMeditatii va reține un comision de administrare și procesare din suma achitată, restul fiind transferat direct în contul bancar al profesorului.\n\nProfesorii sunt unici responsabili pentru declararea veniturilor obținute și plata taxelor și impozitelor aferente conform legislației fiscale din România.",
                  ),
                  _buildSection(
                    "5. SYSTEM RULES",
                    "Ne dorim o comunitate sigură și respectuoasă. Este strict interzisă utilizarea unui limbaj licențios, hărțuirea, discriminarea sau partajarea de conținut inadecvat. De asemenea, încercarea de a ocoli sistemul de plăți al platformei (ex. solicitarea plății în numerar sau prin alte aplicații) va duce la suspendarea permanentă a conturilor implicate.",
                  ),
                  _buildSection(
                    "6. LIMITATIONS",
                    "Deși depunem eforturi constante pentru a asigura calitatea profesorilor, iMeditatii nu garantează obținerea unor anumite note sau rezultate academice. Responsabilitatea actului educațional revine profesorului, iar responsabilitatea asimilării informației revine elevului. Nu răspundem pentru eventualele întreruperi de funcționare cauzate de furnizorii de internet sau forță majoră.",
                  ),

                  const SizedBox(height: 32),
                  Container(height: 3, color: AppColors.ink),
                  const SizedBox(height: 32),

                  RetroButton(
                    text: "ACKNOWLEDGE & RETURN",
                    isFullWidth: true,
                    bgColor: AppColors.sky,
                    textColor: AppColors.ink,
                    onPressed: () => context.go('/inregistrare'),
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

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink, size: 32),
          onPressed: () => context.go('/inregistrare'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: AppColors.ink, height: 3),
        ),
        title: const Text(
            "PRIVACY POLICY",
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 2.0)
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: RetroBlock(
              bgColor: AppColors.cloud,
              padding: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: AppColors.forest,
                        border: Border.all(color: AppColors.ink, width: 2)
                    ),
                    child: const Text("GDPR COMPLIANT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 24),
                  const Text("DATA DIRECTIVE", style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  const Text("LAST LOG: NOVEMBER 1, 2024", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 48),

                  _buildSection(
                    "1. DATA COLLECTION",
                    "Când vă creați un cont pe iMeditatii, colectăm informații cu caracter personal precum: numele complet, adresa de email, numărul de telefon și, opțional, fotografia de profil. Pentru procesarea plăților, detaliile bancare sunt colectate direct de procesatorul nostru securizat (Stripe) și nu sunt stocate pe serverele noastre.",
                  ),
                  _buildSection(
                    "2. DATA USAGE",
                    "Datele dumneavoastră sunt utilizate exclusiv pentru a asigura buna funcționare a platformei. Aceasta include: crearea și administrarea contului, facilitarea comunicării (chat și apeluri video) între elevi și profesori, procesarea plăților, afișarea profilului public (pentru profesori) și trimiterea de notificări legate de activitatea contului.",
                  ),
                  _buildSection(
                    "3. SYSTEM SECURITY",
                    "Siguranța datelor dumneavoastră este o prioritate. Folosim infrastructura securizată Firebase (operată de Google) pentru stocarea bazei de date. Toate comunicațiile și datele transferate între dispozitivul dumneavoastră și serverele noastre sunt criptate (SSL/TLS).",
                  ),
                  _buildSection(
                    "4. THIRD-PARTY SHARING",
                    "Nu vindem, nu închiriem și nu comercializăm datele dumneavoastră personale. Informațiile sunt partajate doar cu parteneri de încredere esențiali funcționării serviciului, precum Stripe (pentru procesarea plăților) și Google Firebase (pentru găzduire cloud), ambii fiind conformi cu reglementările GDPR.",
                  ),
                  _buildSection(
                    "5. USER RIGHTS",
                    "Conform Regulamentului General privind Protecția Datelor (GDPR), aveți următoarele drepturi:\n• Dreptul de acces: Puteți solicita un raport cu datele pe care le deținem despre dumneavoastră.\n• Dreptul la rectificare: Puteți corecta datele inexacte din secțiunea 'Editează profil'.\n• Dreptul la ștergere ('Dreptul de a fi uitat'): Puteți solicita oricând ștergerea permanentă a contului și a datelor asociate.\n\nPentru exercitarea acestor drepturi, ne puteți contacta la adresa de email de suport afișată pe platformă.",
                  ),

                  const SizedBox(height: 32),
                  Container(height: 3, color: AppColors.ink),
                  const SizedBox(height: 32),

                  RetroButton(
                    text: "ACKNOWLEDGE & RETURN",
                    isFullWidth: true,
                    bgColor: AppColors.sky,
                    textColor: AppColors.ink,
                    onPressed: () => context.go('/inregistrare'),
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