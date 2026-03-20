# 🚀 One-Click Production Deployment

Follow these steps to host your AI Life OS backend in under 5 minutes.

## 1. Choose a Provider (Recommended: Render)
1. Go to [render.com](https://render.com) and create a free account.
2. Click **"New +"** -> **"Web Service"**.
3. Connect your GitHub repository (or upload this folder).
4. **Build Command**: `npm install`
5. **Start Command**: `node server.js`

## 2. Configure Environment Variables
In the Render dashboard, go to the **"Environment"** tab and add:
- `GEMINI_API_KEY`: [Your Google Gemini API Key]
- `PORT`: 10000 (usually set automatically)

## 3. Update the Flutter App
Once deployed, Render will providing a URL (e.g., `https://life-os-backend.onrender.com`).
1. Open `lib/providers/providers.dart`.
2. Update the `apiBaseUrlProvider` with your new URL.
3. Re-build the app (`flutter build apk`).

---
*Your backend is now secure and globally accessible.*
