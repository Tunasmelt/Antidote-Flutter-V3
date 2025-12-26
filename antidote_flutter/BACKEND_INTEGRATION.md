# Backend Integration Guide

## ✅ Integration Complete

The Flutter app is now fully integrated with the Node.js/Express backend API. All screens use real API endpoints instead of mock data.

## 🔌 API Configuration

### Base URL
The app is configured to connect to `http://localhost:5000` by default (matching the backend server port).

**Configuration File:** `lib/config/app_config.dart`

To change the base URL:
1. Update `AppConfig.defaultBaseUrl` in `app_config.dart`
2. Or pass a custom URL when creating `ApiClient`:
   ```dart
   final apiClient = ApiClient(baseUrl: 'http://your-server:5000');
   ```

### Platform-Specific URLs
- **Web (Chrome)**: `http://localhost:5000` ✅
- **Android Emulator**: `http://10.0.2.2:5000` (use this instead of localhost)
- **iOS Simulator**: `http://localhost:5000` ✅
- **Physical Device**: `http://<your-computer-ip>:5000`

## 📡 API Endpoints Integrated

### ✅ Analysis
- **POST** `/api/analyze`
  - Request: `{ "url": "spotify_playlist_url" }`
  - Response: `PlaylistAnalysis` model
  - Used in: `AnalysisScreen`

### ✅ Battle
- **POST** `/api/battle`
  - Request: `{ "url1": "playlist1_url", "url2": "playlist2_url" }`
  - Response: `BattleResult` model
  - Used in: `BattleScreen`

### ✅ Recommendations
- **GET** `/api/recommendations`
  - Query params: `type`, `playlistId`, `seed_tracks`, `seed_genres`, `seed_artists`
  - Response: Array of track objects
  - Used in: `MusicAssistantScreen`

### ✅ History
- **GET** `/api/history`
  - Response: Array of analysis and battle history items
  - Used in: `HistoryScreen`

### ✅ Saved Playlists
- **GET** `/api/playlists`
  - Response: Array of playlist objects
  - Used in: `SavedPlaylistsScreen`

### ✅ Stats
- **GET** `/api/stats`
  - Response: `{ analysesCount, battlesCount, averageScore }`
  - Used in: `ProfileScreen`

## 🏗️ Architecture

### API Client
**File:** `lib/services/api_client.dart`

- Uses `Dio` for HTTP requests
- Automatic error handling and conversion to `ApiException`
- Request/response logging in debug mode
- CORS error handling
- 30-second timeout for long-running requests

### Data Models
All models in `lib/models/` match the backend response formats:
- `PlaylistAnalysis` - Analysis results
- `BattleResult` - Battle comparison results
- `User` - User profile (ready for auth integration)

### State Management
- **Riverpod** providers for API client and state
- **AsyncValue** for loading/error/success states
- Automatic error handling in UI

## 🚀 Running the App

### 1. Start Backend Server
```bash
# From project root
cd server
npm install
npm run dev
# Server runs on http://localhost:5000
```

### 2. Run Flutter App
```bash
# From antidote_flutter directory
cd antidote_flutter
flutter pub get
flutter run -d chrome  # For web
```

### 3. Test Integration
1. Open the app in Chrome
2. Navigate to Home screen
3. Enter a Spotify playlist URL
4. Click "Analyze" - should connect to backend and show results

## 🔧 Troubleshooting

### Connection Errors

**Error:** `Connection failed. Make sure the backend server is running`

**Solutions:**
1. Verify backend is running: `curl http://localhost:5000/api/stats`
2. Check CORS settings in `server/index.ts` (should allow all origins)
3. For Android emulator, use `http://10.0.2.2:5000` instead of `localhost`
4. For physical device, use your computer's IP address

### CORS Issues

The backend is configured with CORS enabled:
```typescript
app.use(cors({
  origin: true,
  credentials: true,
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
}));
```

If you still see CORS errors:
1. Check browser console for specific error
2. Verify backend CORS configuration
3. Ensure backend is running on the expected port

### Timeout Errors

If requests timeout:
1. Increase timeout in `ApiClient` (currently 30 seconds)
2. Check backend logs for slow queries
3. Verify network connectivity

## 📝 Next Steps

### Authentication Integration
The auth service is ready for Supabase integration:
- `lib/services/auth_service.dart` - Placeholder ready for implementation
- `lib/providers/auth_provider.dart` - Riverpod provider ready
- Once auth is implemented, add auth headers to `ApiClient`

### Environment Variables
For production, consider:
1. Using `flutter_dotenv` for environment-specific configs
2. Build-time configuration with `--dart-define`
3. Runtime configuration from a config file

### Error Handling
Current error handling:
- ✅ Network errors → User-friendly messages
- ✅ API errors → Displayed in UI
- ✅ Validation errors → Shown to user

Consider adding:
- Retry logic for failed requests
- Offline caching with local storage
- Better error recovery

## ✅ Integration Checklist

- [x] API Client configured with correct base URL
- [x] All endpoints integrated (analyze, battle, recommendations, history, playlists, stats)
- [x] Data models match backend response formats
- [x] Error handling implemented
- [x] Loading states in all screens
- [x] Mock data replaced with real API calls
- [x] CORS configuration verified
- [ ] Authentication headers (when auth is implemented)
- [ ] Offline caching (optional)
- [ ] Request retry logic (optional)

## 🎉 Status

**Backend integration is complete and ready for use!**

All screens now connect to the real backend API. The app is ready for:
- ✅ Development and testing
- ✅ Production deployment (with proper environment config)
- ✅ Authentication integration (when ready)

