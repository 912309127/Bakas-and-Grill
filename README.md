# Integrated Real-Time Point-of-Sale and Recipe-Based Inventory System for Bakas & Grill

An integrated cross-platform system designed to synchronize kitchen inventory depletion with cashier sales transactions in real time using an automated recipe-based deduction engine[span_0](start_span)[span_0](end_span).

---

## 👥 Research & Development Team

* **Christian Sam L. Bolo** – Project Manager[span_1](start_span)[span_1](end_span)
* **Reyven B. Apurillo** – Programmer[span_2](start_span)[span_2](end_span)
* **Japheth Jay O. Roa** – System Analyst[span_3](start_span)[span_3](end_span)
* **Antonnette Love L. Munoz** – UI/UX Designer[span_4](start_span)[span_4](end_span)
* **Clifford D. Custodio** – Technical Writer[span_5](start_span)[span_5](end_span)

*Date of Completion: March 2026*[span_6](start_span)[span_6](end_span)

---

## 📌 Project Overview

Disconnecting Point-of-Sale (POS) registers from kitchen inventory often leads to selling out-of-stock items, paper-based restocking delays, and lack of real-time sales visibility[span_7](start_span)[span_7](end_span). 

The **Bakas & Grill Integrated System** solves these issues through a **3-Tier Role-Based Architecture**[span_8](start_span)[span_8](end_span):
1. **Automated Recipe Deduction:** Automatically deducts exact quantities of raw ingredients (measured in grams or pieces) when a menu item is sold[span_9](start_span)[span_9](end_span).
2. **Dynamic Stock Locking:** Automatically locks or blurs depleted menu items on the cashier POS to prevent ordering unavailable items[span_10](start_span)[span_10](end_span).
3. **Digital Kitchen Restock Requests:** Replaces paper requests with real-time electronic restock notifications sent directly from the kitchen to management[span_11](start_span)[span_11](end_span).

---

## 🛠️ Tech Stack & System Architecture

### 3-Tier Architecture
* **Presentation Layer:**
  * **Web (Admin & Cashier Terminals):** HTML5, CSS3, Vanilla JavaScript (`admin.html`, `cashier.html`, `login.html`)
  * **Mobile App (Kitchen Hub):** Flutter / Dart (`kitchen.dart`)
* **Application Layer:** Firebase Client SDKs handling real-time data synchronization, authentication routing, and recipe deduction logic[span_12](start_span)[span_12](end_span).
* **Data Layer:** Cloud Firestore (Centralized NoSQL Database)[span_13](start_span)[span_13](end_span).

### Directory Structure

```text
Bakas-and-Grill/
├── login.html             # Web authentication page & role-based access router
├── admin.html             # Web dashboard, analytics, inventory, menu & recipe management
├── cashier.html           # Web POS checkout register & real-time order tracking
└── Bakas-and-Grill/       # Flutter Mobile Application directory (Kitchen Hub)
    └── lib/
        ├── kitchen.dart   # Mobile app interface for kitchen stock monitoring & requests
        ├── cashier.dart
        ├── admin.dart
        └── log-in.dart
