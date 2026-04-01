# API Key Management for Maitree App

## 🔐 Secure API Key Setup

This guide explains how to securely manage your Gemini API key for the Maitree application.

### Step 1: Get Your API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create or select a project
3. Generate a new API key
4. Copy the API key (starts with `AIzaSy...`)

### Step 2: Set Up Environment File

1. Create a `.env` file in the project root (already done)
2. Add your API key to the `.env` file:
   ```
   GEMINI_API_KEY=your_actual_api_key_here
   ```

### Step 3: Running the App

#### Option A: Use the provided scripts (Recommended)

**For development:**
```powershell
# Run on Chrome (default)
.\run-app.ps1

# Run on Windows desktop
.\run-app.ps1 windows

# Run on specific device
.\run-app.ps1 edge
```

**For building APK:**
```powershell
.\build-apk.ps1
```

#### Option B: Manual commands

**Run app:**
```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=your_api_key_here
```

**Build APK:**
```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_api_key_here
```

### 🛡️ Security Best Practices

1. **Never commit API keys** to version control
   - The `.env` file is already added to `.gitignore`
   
2. **Regenerate compromised keys** immediately
   - If an API key is accidentally exposed, generate a new one
   
3. **Use different keys** for different environments
   - Consider separate keys for development, testing, and production
   
4. **Monitor API usage** regularly
   - Check your Google Cloud Console for unexpected usage

### 🔧 Troubleshooting

**"Gemini API key not set" error:**
- Make sure your `.env` file exists and contains the correct API key
- Verify the API key starts with `AIzaSy`
- Check for any extra spaces or quotes around the key

**API calls failing:**
- Verify the API key is valid in Google AI Studio
- Check your internet connection
- Ensure you haven't exceeded API quotas

### 📁 File Structure

```
maitree/
├── .env                 # Your API keys (NOT committed)
├── .gitignore          # Includes .env files
├── run-app.ps1         # Development script
├── build-apk.ps1       # Build script
└── lib/services/
    └── gemini_service.dart  # API key usage
```

### 🚨 Important Notes

- The `.env` file is automatically ignored by Git
- API keys are passed via `--dart-define` for security
- The app gracefully handles missing API keys
- All scripts mask the API key in console output