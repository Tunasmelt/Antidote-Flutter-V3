# Antidote - Music Playlist Analytics Platform

A Flutter mobile application with Node.js backend for analyzing Spotify playlists, comparing playlists, and getting music recommendations.

## Quick Start

### Prerequisites

- **Flutter SDK** >= 3.16.0
- **Dart SDK** >= 3.2.0
- **Node.js** >= 18.0.0
- **npm** or **yarn**

### Frontend Setup

```bash
cd frontend
flutter pub get
flutter run
```

### Backend Setup

```bash
cd backend
npm install
cp env.example .env
# Edit .env with your Spotify Client ID and Supabase credentials
npm run dev
```

## Project Structure

```
antidote/
├── frontend/          # Flutter mobile application
├── backend/           # Node.js/TypeScript API server
├── database/          # Supabase SQL scripts
├── scripts/           # Deployment and utility scripts
└── docs/              # Documentation
```

## Features

- **Playlist Analysis**: Analyze Spotify playlists with detailed metrics
- **Playlist Battle**: Compare two playlists head-to-head
- **Music Recommendations**: Get personalized song recommendations
- **User History**: Track your analysis and battle history
- **Saved Playlists**: Save and manage your favorite playlists

## Documentation

For detailed documentation, see the [`docs/`](docs/) directory:

- [Design Documentation](docs/ANTIDOTE_DESIGN_DOCUMENTATION.md)
- [V3 Specification](docs/ANTIDOTE_V3_SPECIFICATION.md)
- [Supabase Setup Guide](docs/SUPABASE_SETUP_GUIDE.md)
- [Database Schema](database/DATABASE_MAPPING.md)

## Development

### Backend Development

```bash
npm run dev:backend    # Start backend in development mode
npm run build:backend  # Build backend for production
npm test:backend       # Run backend tests
```

### Frontend Development

```bash
cd frontend
flutter run            # Run on connected device/emulator
flutter test           # Run unit tests
flutter test integration_test/app_test.dart  # Run integration tests
```

## Environment Variables

### Backend (.env)

```env
PORT=5000
SPOTIFY_CLIENT_ID=your_spotify_client_id
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### Frontend

See `frontend/.env.development` and `frontend/.env.production` for configuration templates.

## License

MIT

