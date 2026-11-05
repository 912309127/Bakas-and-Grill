# Integrated Real-Time Point-of-Sale and Recipe-Based Inventory System for Bakas & Grill

An integrated cross-platform system designed to synchronize kitchen inventory depletion with cashier sales transactions in real time using an automated recipe-based deduction engine.

---

## 👥 Research & Development Team

* **Christian Sam L. Bolo** – Project Manager
* **Reyven B. Apurillo** – Programmer
* **Japheth Jay O. Roa** – System Analyst
* **Antonnette Love L. Munoz** – UI/UX Designer
* **Clifford D. Custodio** – Technical Writer

*Date of Completion: March 2026*

---

## 📌 Project Overview

Disconnecting Point-of-Sale (POS) registers from kitchen inventory often leads to selling out-of-stock items, paper-based restocking delays, and lack of real-time sales visibility. 

The **Bakas & Grill Integrated System** solves these issues through a **3-Tier Role-Based Architecture**:
1. **Automated Recipe Deduction:** Automatically deducts exact quantities of raw ingredients (measured in grams or pieces) when a menu item is sold.
2. **Dynamic Stock Locking:** Automatically locks or blurs depleted menu items on the cashier POS to prevent ordering unavailable items.
3. **Digital Kitchen Restock Requests:** Replaces paper requests with real-time electronic restock notifications sent directly from the kitchen to management.

---

## 🛠️ Tech Stack & System Architecture

### 3-Tier Architecture
* **Presentation Layer:**
  * **Web (Admin & Cashier Terminals):** HTML5, CSS3, Vanilla JavaScript (`admin.html`, `cashier.html`, `login.html`)
  * **Mobile App (Kitchen Hub):** Flutter / Dart (`kitchen.dart`, `cashier.dart`, `admin.dart`, `log-in.dart`)
* **Application Layer:** Firebase Client SDKs handling real-time data synchronization, authentication routing, and recipe deduction logic.
* **Data Layer:** Cloud Firestore (Centralized NoSQL Database).

### Directory Structure

```text
Bakas-and-Grill/
├── login.html             # Web authentication page & role-based access router
├── admin.html             # Web dashboard, analytics, inventory, menu & recipe management
├── cashier.html           # Web POS checkout register & real-time order tracking
└── Bakas-and-Grill/       # Flutter Mobile Application directory (Kitchen Hub)
    └── lib/
        ├── kitchen.dart   # Mobile app interface for kitchen stock monitoring & requests
        ├── cashier.dart   # Mobile cashier interface
        ├── admin.dart     # Mobile admin dashboard interface
        └── log-in.dart    # Mobile login screen
