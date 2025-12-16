# 📱 Item Trading Mobile App

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)
![Status](https://img.shields.io/badge/Status-Learning%20Project-blue)

A cross-platform mobile application that enables users to **trade items directly with one another** in a peer-to-peer environment. The app focuses on **item-for-item exchanges** rather than monetary transactions and was built as a **learning-focused Flutter project**.

The goal of this project was to explore **mobile app development with Flutter**, integrate **Firebase for backend services**, and model real-world trading workflows such as listings, trade requests, and user interactions.

---

## 🚀 Features

- 👤 **User Accounts**
  - Firebase Authentication support
  - User profiles stored in Firestore

- 📦 **Item Listings**
  - Create, edit, and remove items available for trade
  - Item details such as title, description, category, and images

- 🔄 **Trade Requests**
  - Propose item-for-item trades
  - Accept or decline trade offers
  - Track trade status (pending, accepted, declined)

- 🔍 **Browse & Discover**
  - View items listed by other users
  - Firestore-backed queries for scalability

- 📱 **Cross-Platform UI**
  - Single codebase for Android & iOS
  - Built with Flutter widgets and Material design

---

## 🛠️ Tech Stack

- **Framework:** Flutter  
- **Language:** Dart  
- **Backend:** Firebase  
  - Firebase Authentication  
  - Cloud Firestore  
  - Firebase Storage (for item images)  
- **IDE:** Android Studio / VS Code  

---

## 🧠 Learning Goals

This project was created to:

- Learn **Flutter & Dart fundamentals**
- Understand **cross-platform mobile development**
- Integrate **Firebase services** into a real application
- Model NoSQL data structures with Firestore
- Practice clean UI layout and state management
- Build a functional app incrementally

---

## 📂 Project Structure (High-Level)

```text
lib/
├── screens/          # App screens (home, profile, trade views)
├── widgets/          # Reusable UI components
├── models/           # Data models (User, Item, Trade)
├── services/         # Firebase services (auth, firestore)
├── utils/            # Helper functions and constants
└── main.dart
