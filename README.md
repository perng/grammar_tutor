# Grammar Tutor — Handy Grammar

A Flutter app for practicing English grammar on the go. Designed for convenient single-handed operation with 33 topics and 1,500+ quiz questions.

## Why It Matters

For students learning English as a second language, consistent grammar practice is one of the hardest habits to build — textbooks are bulky, tutors are expensive, and most apps treat grammar as an afterthought. Grammar Tutor was built to close that gap. By breaking the full scope of English grammar into 33 bite-sized, quiz-driven topics, the app lets middle and high school students drill real grammar rules in the spare minutes of their day — on a bus, between classes, or before bed — without needing both hands or a stable internet connection. The immediate feedback on every question reinforces correct patterns before wrong ones become habits, and the mock test mode mirrors the timed, mixed-topic format students face in school exams. With a UI available in English, Traditional Chinese, and Simplified Chinese, the app meets learners where they are linguistically, lowering the barrier to entry for students whose native language is Chinese. The app is available on the [App Store](https://apps.apple.com/us/app/%E5%96%AE%E6%89%8B%E5%AD%B8-%E8%8B%B1%E6%96%87%E6%96%87%E6%B3%95/id6757502709) and is actively used by a growing community of middle and high school students as a daily grammar companion alongside their formal studies.

![App Logo](docs/images/hg-logo2.png)

## Features

- **33 grammar topics** organized into 6 categories
- **1,500+ multiple-choice quiz questions** with instant feedback and explanations
- **Mock test mode** — randomized exams drawn from all topics with configurable question count and score history
- **Progress tracking** across individual topics
- **Light and dark themes**
- **Multilingual UI** — English, Traditional Chinese (繁體中文), Simplified Chinese (简体中文)

## Grammar Topics

| Category | Topics |
|---|---|
| **Tenses** | Be Verbs, Verb Tenses, Present Continuous, Present Perfect, Past Tenses, Future Tenses, Imperative, Subjunctive, Passive Voice |
| **Modals** | Modal Verbs |
| **Nouns & Pronouns** | Singular/Plural, Countable/Uncountable, Pronouns, Other Pronouns, Possessives, Articles (A/An/The), Determiners |
| **Adjectives & Adverbs** | Adjectives, Adjective Order, Comparisons, Construction Patterns, Adverbs |
| **Sentence Structure** | Questions, Tag Questions, Negatives, Conditionals, Relative Clauses, Conjunctions, Transitive/Intransitive Verbs |
| **Prepositions** | Prepositions, Phrasal Verbs, Gerunds & Infinitives |

## Screenshots

<p float="left">
  <img src="docs/images/ios-6.5-inch-phone/image1.jpg" width="200" />
  <img src="docs/images/ios-6.5-inch-phone/image2.jpg" width="200" />
  <img src="docs/images/ios-6.5-inch-phone/image3.jpg" width="200" />
</p>

## Getting Started

### Prerequisites

- Flutter SDK `^3.10.3`
- Dart SDK `^3.10.3`
- Xcode (iOS) or Android Studio (Android)

### Run locally

```bash
flutter pub get
flutter run
```

### Build

```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
```

See [docs/release_build.md](docs/release_build.md) for full release instructions.

## Tech Stack

- **Flutter** + **Dart**
- **go_router** — navigation
- **provider** — state management
- **shared_preferences** — local persistence
- **google_fonts** / **NotoSansTC** — typography
- **flutter_localizations** — i18n (en, zh-TW, zh-CN)

## Privacy & Support

- [Privacy Policy](docs/handy_grammar_privacy_policy.html)
- [Support](docs/handy_grammar_support.html)
