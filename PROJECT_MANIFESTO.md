# BillShare - Project Manifesto 📜

This document defines the core principles and development standards for the BillShare application. Every new feature must strictly adhere to these rules.

## 💎 0. THE CORE: BillShare Settlement Engine
- **Priority:** This is the heart of the application. All other features (Planning, Tracking, Analytics) are inputs or enhancements to this core.
- **Goal:** Provide the most accurate and minimal-step "Who owes who" calculation for any group of people.
- **Status:** Frozen and Protected. Any new feature must integrate with this engine.

## 🎨 1. UI/UX: Liquid Glass Architecture
- **Style:** Modern "Liquid Glass" theme (frosted glass effects, ambient gradients).
- **Core Widgets:** Use `Material 3` with custom `GlassContainer` and consistent `Outfit` typography.
- **Responsiveness:** Support both Light and Dark modes.
- **Localization:** Dual-language support (Vietnamese & English) via `AppStrings`.

## 🔄 2. Data Strategy: Two-Way Synchronization
- **Mirror Sync:** Local state and Cloud (Firebase Firestore) state must remain in real-time sync.
- **Local -> Cloud:** Any local change (Transaction/Member) is immediately pushed to the cloud.
- **Cloud -> Local:** Real-time listeners (Streams) ensure external changes by other group members reflect locally instantly.
- **Offline Logic:** Data is cached locally using `SharedPreferences` for offline-first resilience.

## 👥 3. The Group Principle (Shared Consistency)
- **Shared Data:** All data belongs to the **Group**, not the individual user.
- **Financial Consistency:** Settlement calculations (Greedy Algorithm) must return identical results for every member in a group.
- **Cross-Identity:** Auto-link Google UID to group members to ensure "Me" identification across devices.

## 🛡️ 4. Security & Integrity
- **Self-Deletion Restriction:** For stability, users are strictly prohibited from deleting their own member profile from a group.
- **Auth:** Google Sign-In is the primary identity provider.
- **Git Hygiene:** No secrets or Firebase private configs in version control.

## 📡 5. Observability & Logging
- **LogService:** Standardized logging using `LogService`.
- **Environment Aware:** Clean terminal logs in Debug; Crashlytics tracking in Release.
- **Error Tracking:** Every fatal/non-fatal error must be recorded with the user ID for troubleshooting.

---
*Created and maintained by Antigravity (AI Architect) in collaboration with the Product Owner.*
