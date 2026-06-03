# Insight Mate

Insight Mate is a premium, AI-integrated productivity and data analysis assistant built with a **Flutter** frontend and a **Node.js (Express)** backend database synchronizer. 

It provides interactive natural language data analysis, real-time product barcode nutrition scanners, vocal assistants, and cloud-synced conversation history.

---

## Key Features

1. **AI-Powered Data Analysis & Visualization (Insights)**:
   - Load preloaded datasets (Sales & Revenue, Personal Finance, Fitness Logs) or paste custom CSV data.
   - Type queries in plain English (e.g., *"Show monthly sales vs profit as a line chart"*).
   - Gemini/OpenAI analyzes the data and renders dynamic **Line, Bar, or Pie charts** on the fly using `fl_chart` with interactive animations.
   
2. **Barcode Scanner & Nutritionist API**:
   - Frame and scan barcodes (UPC/EAN) in real time.
   - Fetches product name, brand, ingredients list, and calorie tables from **Open Food Facts API**.
   - Gemini AI reads the ingredients, scores the healthiness out of 10.0, tags dietary profiles (e.g. Vegan, Gluten-Free), and recommends healthier alternatives.

3. **Dual AI Engine Chat (Gemini & OpenAI)**:
   - Fluid chat assistant that defaults to Gemini, but supports OpenAI GPT models.
   - Enter your personal API key directly inside the settings page or configure it on the backend server.

4. **MongoDB Cloud History Sync**:
   - Implements local-first offline storage utilizing `SharedPreferences`.
   - Automatically synchronizes chats, scanned items, and visual reports to a cloud MongoDB instance whenever connected.

---

## Project Structure

```
├── insightmate/              # Flutter Frontend Application
│   ├── lib/                  # Dart source code
│   │   ├── app/              # Router, Gate, Theme configuration
│   │   ├── features/         # Screen modules (Chat, Scan, Insights, Settings)
│   │   └── shared/           # Models, widgets, and services (API, History)
│   └── pubspec.yaml          # Flutter dependencies
│
└── backend/                  # Node.js Express Backend
    ├── src/
    │   ├── routes/           # Router endpoints (Chat, Barcode, History, Image)
    │   └── server.js         # Port listener & MongoDB connector
    └── package.json          # Node.js dependencies
```

---

## Setup Instructions

### 1. Backend Server Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install npm dependencies:
   ```bash
   npm install
   ```
3. Create a `.env` file in the backend root:
   ```env
   PORT=8080
   MONGO_URI=mongodb+srv://<username>:<password>@cluster.mongodb.net/insightmate
   GEMINI_API_KEY=your_google_gemini_api_key
   OPENAI_API_KEY=your_openai_api_key
   ```
4. Start the server:
   ```bash
   npm start
   # Or for development reload:
   npm run dev
   ```

### 2. Frontend Flutter Setup

1. Retrieve packages:
   ```bash
   flutter pub get
   ```
2. Configure the `.env` file in the Flutter root:
   ```env
   BACKEND_BASE_URL=http://localhost:8080
   ```
3. Run the app:
   ```bash
   flutter run
   ```

---

## Development Stack
* **Frontend**: Flutter SDK (Dart), `fl_chart`, `provider`, `mobile_scanner`, `shared_preferences`.
* **Backend**: Node.js, Express, Mongoose (MongoDB), `@google/generative-ai` SDK, `openai` SDK.
