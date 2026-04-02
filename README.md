# BillShare – Premium Group Expense Management

**BillShare** is a state-of-the-art Flutter application designed to simplify social financial management. Featuring a stunning **"Liquid Glass"** UI, it allows groups of friends, colleagues, or roommates to track expenses, calculate debts, and settle balances with precision and elegance.

---

## ✨ Key Features

### 💎 Next-Gen Liquid Glass UI
*   **Glassmorphism Aesthetic**: Deep translucent layers, frosted glass effects, and vibrant ambient glows.
*   **Adaptive Theme**: Seamless switching between sophisticated Dark mode and clean Light mode.
*   **Micro-animations**: Smooth transitions and interactive Haptic feedback for a premium mobile experience.

### 📊 Advanced Splitting Logic
*   **Equal Split (TH1)**: Automatically distribute costs evenly among participants with one tap.
*   **Custom Split (TH2)**: Manually allocate specific amounts for each individual (e.g., *Tiền 17k, Minh 13k, Quân 20k*).
*   **Real-time Validation**: Dynamic balance guide that calculates remaining amounts to ensure perfectly balanced accounting.

### 🧠 Intelligent Settlement Engine
*   **Greedy Algorithm**: Minimizes the total number of transactions required to clear all debts within a group.
*   **Settlement Tracking**: Clear visual indicators of who owes whom, with a "Settle Now" workflow.

### 📁 Group & Member Management
*   **Multi-Group Support**: Create separate groups for different occasions (Vacation, Monthly Room, Team Lunch).
*   **Personalization**: Custom avatars and color-coded profiles for every member.

### 🌐 Internationalization (i18n)
*   Full support for **English** and **Vietnamese**.

---

## 🚀 Tech Stack

*   **Framework**: Flutter 3.x
*   **State Management**: `Provider` with `ChangeNotifier` for reactive UI updates.
*   **Data Persistence**: `shared_preferences` for reliable local storage of transactions and group data.
*   **Algorithm**: Custom Greedy Debt Settlement Engine.
*   **UI Assets**: Google Fonts (Outfit), Custom Glassmorphic widgets.

---

## 🛠 Getting Started

### Prerequisites
*   Flutter SDK installed (Channel Stable)
*   Xcode (for iOS) or Android Studio (for Android)

### Installation
1.  Clone the repository:
    ```bash
    git clone https://github.com/your-repo/billshare.git
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Generate localization (optional if using `strings.dart`):
    ```bash
    flutter gen-l10n
    ```
4.  Run the application:
    ```bash
    flutter run
    ```

---

## 📱 Screenshots & Design Highlights

*   **Compact Mode**: Optimized layouts for smaller screens and dense data visualization.
*   **Financial Insights**: Weekly and Monthly summaries categorized by types (Food, Drink, Shopping, etc.).
*   **Unified Avatars**: Consistent visual identity for users across all dashboards and modals.

---

## 📝 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Developed with ❤️ by **Minh Tien**.
