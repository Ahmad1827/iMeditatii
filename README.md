# iMeditatii

A gamified, retro-terminal styled tutoring platform designed to level up the learning experience. Students can find verified "Guild Masters" (teachers), track their "Player Stats" (progress), and complete "Daily Quests" (exercises) to gain EXP.

## Features

*   **Retro UI/UX**: Terminal-inspired aesthetic with Bento-box layouts and high-contrast color palettes.
*   **Role-Based Access**: Dedicated dashboards and profiles for Players (Students) and Guild Masters (Teachers).
*   **Guild Roster**: Browse verified teachers by discipline (Mathematics, Computer Science, Languages, etc.).
*   **Secure Comms**: Real-time messaging and Video/Audio calls powered by Firebase and Agora.
*   **Financial Core**: Integrated Stripe onboarding for teachers to receive payments.
*   **Quest Progression**: Track completed exercises and monitor skill levels across different subjects.

## Tech Stack

*   **Frontend**: Flutter (Mobile & Web Support)
*   **Backend / Database**: Firebase Firestore & Firebase Auth
*   **Storage**: Firebase Cloud Storage
*   **Real-time Communication**: Agora RTC Engine
*   **Payments**: Stripe
*   **Routing**: `go_router` for seamless deep-linking and web navigation

## Getting Started

1. Clone the repository:
   `git clone https://github.com/YourUsername/iMeditatii.git`
2. Navigate to the project directory:
   `cd iMeditatii`
3. Install dependencies:
   `flutter pub get`
4. Set up Firebase (requires FlutterFire CLI):
   `flutterfire configure`
5. Set up Environment Variables:
   Create a `.env` file in the root directory and add your private keys (do NOT commit this file):
   `AGORA_APP_ID=your_agora_app_id_here`
6. Run the app:
   `flutter run -d chrome`

## 🤝 How to Contribute (Join the Guild)

Contributions, bug fixes, and feature suggestions are highly encouraged! If you want to help improve the system or add new quests, here is how you can join the party:

1. **Fork** the repository.
2. **Create a new branch** for your feature (`git checkout -b feature/NewAwesomeQuest`).
3. **Commit** your changes (`git commit -m 'Added a new awesome quest'`).
4. **Push** to the branch (`git push origin feature/NewAwesomeQuest`).
5. **Open a Pull Request** and let me review your code!

## 🛑 Copyright & Usage

While I absolutely welcome contributions and encourage you to look at the code to learn, **this codebase is NOT open-source for commercial reuse, redistribution, or white-labeling.**

*   ✅ **DO**: Fork the repo to submit Pull Requests to this main repository.
*   ✅ **DO**: Read the code to learn how things are built.
*   ❌ **DO NOT**: Clone this app, slap your own logo on it, and try to sell it, host it, or publish it as your own.
*   ❌ **DO NOT**: Rip the proprietary UI/UX assets or retro branding for your own commercial projects.

**All Rights Reserved.** If you are interested in using parts of this architecture for a commercial project, please reach out to me directly to discuss licensing.