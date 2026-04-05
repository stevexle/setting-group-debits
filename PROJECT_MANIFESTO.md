# BillShare - Project Manifesto 📜

This document defines the core principles and development standards for the BillShare application. Every new feature must strictly adhere to these rules.

## 💎 0. THE CORE: BillShare Settlement Engine
- **Priority:** This is the heart of the application. All other features (Planning, Tracking, Analytics) are inputs or enhancements to this core.
- **Goal:** Provide the most accurate and minimal-step "Who owes who" calculation for any group of people.
- **Status:** **FROZEN**. The existing Settlement screens are immutable.

## 📁 1. GROUP TYPES (ARCHITECTURE)
- **Type 1: Shared Settlement (BillShare):** Traditional group debts (Frozen).
- **Type 2: Strategic Planning (Budgeting):** Planned events/trips with Estimated vs Actual analysis.
- **Type 3: Personal Asset Flow (Loss Analysis):** Manage personal cash, bank accounts, gold, and detect "unplanned losses".

## 🗺️ 2. UI BLUEPRINT (6 SCREENS)
1. **Wallet Dashboard:** Overview of all money sources (Bank, Cash, Gold).
2. **Account Details:** Transaction flow specifically for one source.
3. **Personal log:** Diary of personal/unplanned spending.
4. **Analysis/Synthesis:** Comparison of Actual vs Plan & Loss detection.
5. **Plans Hub:** List of projects (Trips, Weddings, Events).
6. **Plan Detail:** Budget breakdown, references (TikTok/FB links), and dedicated transactions.

## 🎨 3. UI/UX: Liquid Glass Architecture
- **Style:** Modern "Liquid Glass" theme (frosted glass effects, ambient gradients).
- **Core Widgets:** Use `Material 3` with custom `GlassContainer` and consistent `Outfit` typography.
- **Responsiveness:** Support both Light and Dark modes.
- **Localization:** Dual-language support (Vietnamese & English) via `AppStrings`.

## 🔄 4. Data Strategy: Two-Way Synchronization
- **Mirror Sync:** Local state and Cloud (Firebase Firestore) state must remain in real-time sync.
- **Cross-Analysis:** Synthesis of expenses from all groups tied back to a single **User Source Account**.
- **Universal Wallet:** Accounts belong to the **User**, making it easy to track "Loss" from Bank to any group transaction.

## 🛡️ 5. Security & Integrity
- **Self-Deletion Restriction:** Users cannot delete their own member profile from a group.
- **Auth:** Google Sign-In as primary identity provider.
- **Git Hygiene:** No auto-pushing without explicit command. No secrets in version control.

## 📡 5. Observability & Logging
- **LogService:** Standardized logging using `LogService`.
- **Environment Aware:** Clean terminal logs in Debug; Crashlytics tracking in Release.
- **Error Tracking:** Every fatal/non-fatal error must be recorded with the user ID for troubleshooting.

---
*Created and maintained by Antigravity (AI Architect) in collaboration with the Product Owner.*
