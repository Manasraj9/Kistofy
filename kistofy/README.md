# 📦 Kistofy – Billing & Inventory Simplified

**Kistofy** is a modern, lightweight Flutter app designed for small business owners and shopkeepers who need an all-in-one solution for billing, inventory management, and customer ledgers — without the complexity.

Built using **Flutter** for cross-platform support and powered by **Supabase** for secure cloud sync, Kistofy is your smart Munshi.

---

## 🚀 Features

### 🧾 Billing
- Create itemized GST-ready bills
- Generate & share invoices via WhatsApp/SMS
- Public bill viewing links (no login required)
- Invoice PDF downloads and thermal printing support

### 📦 Inventory Management
- Add, edit, and remove stock items
- Set low-stock alerts
- Barcode scanning (coming soon)
- Voice-based stock entry (for less tech-savvy users)

### 📁 Customer Ledger
- Track credit (उधार) transactions per customer
- View complete purchase/payment history
- Export ledger as PDF or CSV

### ☁️ Cloud Sync & Backup
- Real-time sync using **Supabase**
- Automatic backup to the cloud
- Option for Google Drive integration (future)

### 🔒 Authentication
- Login via phone or email OTP using Supabase Auth
- Secure user-specific data storage using Row Level Security (RLS)

---

## 🛠️ Tech Stack

| Layer      | Tech Used         |
|------------|-------------------|
| Frontend   | Flutter (Dart)    |
| Backend    | Supabase (Postgres, Auth, Storage) |
| Hosting    | Supabase + HTML/CSS for invoice viewer |
| Database   | Supabase Tables with RLS |
| Other      | Voice API (planned), QR generation, PDF rendering |

---

## 📸 Screenshots (Coming Soon)

- Dashboard
- Invoice page
- Inventory control
- Ledger view

---

## 📁 Project Structure (Simplified)

```
kistofy/
├── lib/
│   ├── screens/
│   ├── services/
│   ├── models/
│   └── widgets/
├── public/
│   └── invoice.html
├── sitemap.xml
└── README.md
```

---

## 🧪 How to Run

1. Clone the repo:
   ```bash
   git clone https://github.com/yourusername/kistofy.git
   cd kistofy
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up `.env` with your Supabase URL and anon key:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

4. Run the app:
   ```bash
   flutter run
   ```



## 🧑‍💻 Author

**Manas Raj**  
[manasraj.xyz](https://manasraj.xyz)  
Reach out on [LinkedIn](https://www.linkedin.com/in/manas-raj-274780236/)  
Made with ❤️ in India 🇮🇳

---

## 📄 License

MIT License


