# Antidote v3 - Music Playlist Analytics Platform
## Product Specification Document

### 🎯 Executive Summary

Antidote v3 is the next evolution of the music playlist analytics platform, building upon the solid foundation of v2 while incorporating enhanced UI features from the React Native design documentation. This version focuses on implementing the complete backend logic, AI engine, and database infrastructure to power the existing UI components. The platform transforms any playlist URL into comprehensive analysis with advanced AI-powered insights, beautiful interactive visualizations, and intelligent music recommendations.

**Target Audience**: Music enthusiasts, playlist curators, content creators, and anyone seeking deep musical self-discovery through data-driven analytics.

**Key Value Proposition**: Instant playlist DNA analysis with AI personality insights, compatibility scoring, health metrics, and personalized recommendations - all powered by sophisticated algorithms and presented through the existing cosmic-themed UI.

**Development Focus**: Leverage existing React UI components and implement complete backend logic including AI engine, database operations, API integrations, and recommendation algorithms.

---

## 📋 Table of Contents

- [Executive Summary](#-executive-summary)
- [Product Overview](#-product-overview)
- [Feature Mapping: v2 Spec ↔ Design Doc](#-feature-mapping-v2-spec--design-doc)
- [New Features from Design Documentation](#-new-features-from-design-documentation)
- [Core Features (v3 Implementation)](#-core-features-v3-implementation)
- [Technical Architecture (v3)](#-technical-architecture-v3)
- [AI Engine & Algorithms](#-ai-engine--algorithms)
- [Database Design & SQL Scripts](#-database-design--sql-scripts)
- [API Implementation](#-api-implementation)
- [Local Development Environment](#-local-development-environment)
- [Implementation Roadmap](#-implementation-roadmap)

---

## 🎵 Product Overview

### Mission Statement
"Unlock the DNA of your music taste through AI-powered analytics and personalized insights."

### Product Vision
Become the definitive platform for music discovery and playlist intelligence, combining advanced audio analysis with AI-driven recommendations and social features.

### Key Differentiators
- **Multi-Platform Analysis**: Support for Spotify, Apple Music, YouTube Music, SoundCloud
- **Advanced AI Engine**: 8-dimensional audio analysis with personality decoding
- **Real-time Compatibility**: Instant playlist battles with detailed scoring
- **Existing UI Leverage**: Utilize all designed React components and animations
- **Complete Backend Implementation**: Build full logic layer for all features

---

## 🔗 Feature Mapping: v2 Spec ↔ Design Doc

### Common Features (v2 Spec + Design Doc)

| Feature Category | v2 Specification | Design Documentation | Status |
|------------------|------------------|----------------------|---------|
| **Single Playlist Analysis** | Audio features, mood detection, personality insights, genre intelligence, artist analytics, popularity analysis, health metrics | Analysis screen with radar chart, health score, personality decoded, genre distribution, subgenre breakdown, overall rating | ✅ UI Exists - Needs Logic Implementation |
| **Playlist Battle Mode** | Compatibility scoring, visual comparisons, energy curves, winner determination, shared content analysis | Battle screen with compatibility analysis, winner declaration, playlist scores, shared artists/genres/tracks, add from other playlist, combined audio DNA | ✅ UI Exists - Enhanced Features Need Logic |
| **Playlist Health Check** | Energy consistency, genre clutter, replay potential, overall health score | Health score card with animated counter and progress bar | ✅ UI Exists - Needs Algorithm Implementation |
| **AI-Powered Recommendations** | Cosine similarity, genre alignment, artist alignment, flavor profiles, multi-strategy search | Music Decision Assistant with 6 suggestion types (Best Next Track, Mood-Safe Pick, Rare Match, Return to Familiar, Short Session, Energy Adjustment) | ✅ UI Exists - Needs AI Engine |
| **User Management** | Authentication, saved analyses, analysis history, profile system | Profile screen with stats, history, settings, logout | ✅ UI Exists - Needs Backend Integration |

### UI Components Available for Implementation

**From Design Documentation:**
- MobileLayout wrapper with iPhone frame
- Animated home screen with shooting stars, logo bob, feature cards
- Analysis screen with radar charts, health scores, personality traits
- Battle screen with VS animations, compatibility cards, shared content
- Music Decision Assistant with suggestion type cards
- Profile screen with stats grid and menu animations
- All micro-interactions, hover effects, and staggered animations

---

## ✨ New Features from Design Documentation

### Enhanced Analysis Features
1. **Personality Decoded Section** ⭐ NEW
   - 4 personality traits with descriptions (Experimental, Mood-Driven, Eclectic, Trend-Aware)
   - Left border accent with icons
   - Staggered entry animations

2. **Genre Distribution Visualization** ⭐ NEW
   - 6 genres with animated progress bars
   - Color-coded bars (purple, cyan, pink, amber, green, gray)
   - Percentage labels and animated fills

3. **Subgenre Distribution** ⭐ NEW
   - Top 6 subgenres in cards
   - Cyan percentage text
   - Staggered animations

4. **Overall Rating System** ⭐ NEW
   - 5-star rating with animation
   - Numerical rating (4.5/5.0)
   - Descriptive feedback

### Enhanced Battle Features
5. **Detailed Winner Declaration** ⭐ NEW
   - Trophy icon with outcome reasoning
   - Color-coded backgrounds (yellow for winner, blue for loser, cyan for tie)

6. **Shared Tracks Section** ⭐ NEW
   - Green checkmarks for common tracks
   - Track details display

7. **Add from Other Playlist** ⭐ NEW
   - Interactive checkboxes for track selection
   - Checked state with cyan background

8. **Combined Audio DNA Radar** ⭐ NEW
   - Dual-layer radar chart
   - Cyan line for playlist 1, pink for playlist 2
   - 6 axes: Energy, Dance, Valence, Acoustic, Tempo, Live

### New Screen: Music Decision Assistant ⭐ NEW
9. **6 Suggestion Types** ⭐ NEW
   - Best Next Track (AI picks perfect continuation)
   - Mood-Safe Pick (maintains current vibe)
   - Rare Match For You (hidden gems)
   - Return To Familiar (deep cuts from loved artists)
   - Short Session Mode (5-10 minute tracks)
   - Energy Adjustment (shift energy levels)

10. **Auth Notice Card** ⭐ NEW
    - Pro tip about personalization benefits
    - Encourages signup for enhanced features

---

## ✨ Core Features (v3 Implementation)

### 1. Single Playlist Analysis
**Backend Implementation Required:**
- Spotify Web API integration for track fetching
- Audio features extraction (energy, valence, danceability, tempo, acousticness, speechiness, instrumentalness, liveness)
- Mood classification algorithm
- Personality insight generation using AI
- Genre and subgenre classification
- Artist analytics and diversity scoring
- Popularity distribution analysis
- Health metrics calculation (energy consistency, genre clutter, replay potential)

**UI Components to Power:**
- Radar chart visualization
- Health score with animated counter
- Personality decoded section
- Genre distribution bars
- Subgenre breakdown
- Overall rating stars

### 2. Playlist Battle Mode
**Backend Implementation Required:**
- Two-playlist comparison algorithm
- Compatibility scoring (0-100 scale)
- Winner determination logic
- Shared content analysis (artists, genres, tracks)
- Audio feature comparison
- Energy curve analysis

**UI Components to Power:**
- Compatibility analysis card
- Winner declaration with trophy
- Playlist score cards
- Shared artists/genres sections
- Shared tracks list
- Add from other playlist checkboxes
- Combined audio DNA radar chart

### 3. Playlist Health Check
**Backend Implementation Required:**
- Energy consistency algorithm
- Genre diversity analysis
- Replay potential prediction
- Overall health scoring (0-100)

**UI Components to Power:**
- Health score card with progress bar
- Status badges (Exceptional, Good, Average, Needs Work)

### 4. AI-Powered Recommendations (Music Decision Assistant)
**Backend Implementation Required:**
- 6 different recommendation algorithms
- Cosine similarity for audio features
- Genre alignment scoring
- Artist collaboration analysis
- Flavor profile system
- Multi-strategy search implementation

**UI Components to Power:**
- 6 suggestion type cards
- Auth notice for premium features
- Recommendation results display

### 5. User Management & Social Features
**Backend Implementation Required:**
- Supabase authentication integration
- User profile management
- Saved analyses storage
- Analysis history tracking
- Privacy controls and data deletion

**UI Components to Power:**
- Profile screen with stats
- Authentication flows
- Settings and logout functionality

---

## 🏗 Technical Architecture (v3)

### Frontend Stack (Existing)
```
Framework: React 18 (Web Implementation)
Routing: Wouter
Styling: Tailwind CSS 4.1
UI Components: Shadcn/UI + Custom Components
Animations: Framer Motion
Charts: Recharts
State Management: React Query + Context
```

### Backend Stack (To Implement)
```
Runtime: Node.js
Framework: Express.js / Fastify
Database: PostgreSQL (Free tier: Supabase / Railway / PlanetScale)
Authentication: Supabase Auth
External APIs: Spotify Web API
AI/ML: OpenAI API / Custom algorithms
Caching: Redis (optional, free tier available)
```

### Key Libraries to Add
- **@supabase/supabase-js**: Database and auth
- **spotify-web-api-node**: Spotify API integration
- **openai**: AI personality insights and recommendations
- **pg**: PostgreSQL client
- **redis**: Caching layer
- **zod**: API validation
- **bcryptjs**: Password hashing
- **jsonwebtoken**: JWT handling

---

## 🤖 AI Engine & Algorithms

### Audio Analysis Engine
```typescript
interface AudioFeatures {
  energy: number      // 0-1: Intensity and activity
  valence: number     // 0-1: Musical positiveness
  tempo: number       // BPM
  danceability: number // 0-1: Dance suitability
  acousticness: number // 0-1: Acoustic vs electronic
  speechiness: number  // 0-1: Spoken word presence
  instrumentalness: number // 0-1: Instrumental vs vocal
  liveness: number    // 0-1: Live performance likelihood
}
```

### Personality Insight Generation
**Algorithm**: GPT-3.5-turbo powered personality analysis
- Input: Audio features averages, genre distribution, artist diversity
- Output: 4 personality traits with descriptions
- Categories: Experimental, Mood-Driven, Eclectic, Trend-Aware

### Recommendation Engine
**6 Strategy Types:**
1. **Best Next Track**: Cosine similarity on 8D audio vector
2. **Mood-Safe Pick**: Maintain valence ±0.1, energy ±0.2
3. **Rare Match**: Low popularity (<30) with high similarity (>0.85)
4. **Return to Familiar**: Same artists, different tracks
5. **Short Session**: Duration 5-10 minutes, high engagement
6. **Energy Adjustment**: Gradual energy shift (±0.3)

### Compatibility Scoring
**Algorithm**: Weighted compatibility calculation
- Audio Features: 40% (cosine similarity)
- Genre Overlap: 30% (Jaccard similarity)
- Artist Overlap: 20% (shared artist percentage)
- Mood Alignment: 10% (valence/energy correlation)

---

## 💾 Database Design & SQL Scripts

### Database Schema (PostgreSQL)

#### Core Tables

```sql
-- Users table (extends Supabase auth.users)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Playlists table
CREATE TABLE playlists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('spotify', 'apple_music', 'youtube_music', 'soundcloud')),
  name TEXT,
  owner TEXT,
  total_tracks INTEGER,
  cover_url TEXT,
  analyzed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tracks table
CREATE TABLE tracks (
  id TEXT PRIMARY KEY, -- Spotify ID or generated
  playlist_id UUID REFERENCES playlists(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  artists TEXT[] NOT NULL,
  album TEXT,
  release_date DATE,
  duration_ms INTEGER,
  popularity INTEGER,
  genres TEXT[],
  audio_features JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Analyses table
CREATE TABLE analyses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  playlist_id UUID REFERENCES playlists(id) ON DELETE CASCADE,
  mood TEXT,
  personality_insight TEXT,
  overall_rating DECIMAL(3,1),
  health_score INTEGER,
  audio_features_avg JSONB,
  genre_distribution JSONB,
  artist_stats JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comparisons table
CREATE TABLE comparisons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  playlist1_id UUID REFERENCES playlists(id) ON DELETE CASCADE,
  playlist2_id UUID REFERENCES playlists(id) ON DELETE CASCADE,
  compatibility_score INTEGER,
  winner TEXT CHECK (winner IN ('playlist1', 'playlist2', 'tie')),
  winner_reason TEXT,
  shared_artists JSONB,
  shared_genres JSONB,
  shared_tracks JSONB,
  audio_comparison JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recommendations table
CREATE TABLE recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  playlist_id UUID REFERENCES playlists(id) ON DELETE CASCADE,
  strategy TEXT NOT NULL,
  recommended_tracks JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Database Setup Scripts

#### 1. Initial Schema Creation
```sql
-- Run this script to create all tables
-- File: database/init.sql

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create all tables (see above schemas)

-- Create indexes for performance
CREATE INDEX idx_playlists_user_id ON playlists(user_id);
CREATE INDEX idx_tracks_playlist_id ON tracks(playlist_id);
CREATE INDEX idx_analyses_playlist_id ON analyses(playlist_id);
CREATE INDEX idx_comparisons_user_id ON comparisons(user_id);
CREATE INDEX idx_recommendations_playlist_id ON recommendations(playlist_id);

-- Row Level Security policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE comparisons ENABLE ROW LEVEL SECURITY;
ALTER TABLE recommendations ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- Similar policies for other tables...
```

#### 2. Seed Data Script
```sql
-- Sample data for testing
-- File: database/seed.sql

-- Insert sample user
INSERT INTO users (id, username, display_name) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'testuser', 'Test User');

-- Insert sample playlist
INSERT INTO playlists (id, user_id, url, platform, name, owner, total_tracks) VALUES
('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440000',
 'https://open.spotify.com/playlist/37i9dQZF1DX0XUsuxWHRQd', 'spotify', 'Late Night Drive', 'spotify', 50);
```

### Free Database Services

**Recommended Options:**
1. **Supabase** (Primary)
   - PostgreSQL database
   - Built-in authentication
   - Free tier: 500MB database, 50MB file storage
   - Real-time subscriptions
   - Row Level Security

2. **Railway** (Alternative)
   - PostgreSQL databases
   - Free tier: 512MB RAM, 1GB storage
   - Easy deployment

3. **PlanetScale** (Alternative)
   - MySQL compatible
   - Free tier: 1 database, 1GB storage
   - Branching for development

---

## 📡 API Implementation

### Core Endpoints to Implement

#### Analysis Endpoints
```typescript
POST /api/analyze
// Analyze single playlist
// Input: { url: string }
// Output: Full analysis result with all UI data

POST /api/analyze/batch
// Batch analyze multiple tracks
// Input: { trackIds: string[] }
// Output: Audio features for all tracks
```

#### Comparison Endpoints
```typescript
POST /api/compare
// Compare two playlists
// Input: { url1: string, url2: string }
// Output: Full comparison result with compatibility data
```

#### Recommendation Endpoints
```typescript
POST /api/recommend
// Get recommendations for playlist
// Input: { playlistId: string, strategy: string }
// Output: Recommended tracks with reasoning

GET /api/recommend/strategies
// List available recommendation strategies
// Output: Array of 6 strategy objects
```

#### User Endpoints
```typescript
GET /api/user/profile
// Get user profile and stats

GET /api/user/analyses
// Get user's saved analyses

POST /api/user/save-analysis
// Save analysis result

DELETE /api/user/analysis/:id
// Delete saved analysis
```

### External API Integrations

#### Spotify Web API
```typescript
// Key endpoints to implement:
// 1. Get playlist tracks: GET /playlists/{playlist_id}/tracks
// 2. Get audio features: GET /audio-features?ids={track_ids}
// 3. Get track details: GET /tracks?ids={track_ids}
// 4. Search tracks: GET /search?q={query}&type=track
```

#### OpenAI Integration
```typescript
// For personality insights
const personalityPrompt = `
Analyze this music profile and generate 4 personality traits:
Audio features: ${JSON.stringify(audioFeatures)}
Top genres: ${genres.join(', ')}
Artist diversity: ${artistCount}

Return JSON with 4 traits, each having 'name' and 'description'
`;
```

---

## 🛠 Local Development Environment

### Prerequisites
- Node.js 18+
- PostgreSQL (local or Docker)
- Git
- VS Code (recommended)

### Environment Setup

#### 1. Clone and Install
```bash
git clone <repository-url>
cd antidote-v3
npm install
```

#### 2. Environment Variables
```env
# .env.local
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/antidote_v3

# Supabase (for auth and hosted DB)
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Spotify API
SPOTIFY_CLIENT_ID=your_spotify_client_id
SPOTIFY_CLIENT_SECRET=your_spotify_client_secret

# OpenAI
OPENAI_API_KEY=your_openai_api_key

# App Config
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development
```

#### 3. Database Setup
```bash
# Using Docker
docker run --name antidote-db -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres:15

# Or using Supabase CLI
npm install -g supabase
supabase start

# Run migrations
npm run db:migrate
npm run db:seed
```

#### 4. Development Commands
```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "db:migrate": "tsx script/migrate.ts",
    "db:seed": "tsx script/seed.ts",
    "db:studio": "drizzle-kit studio",
    "test": "vitest",
    "lint": "eslint src --ext ts,tsx --report-unused-disable-directives --max-warnings 0"
  }
}
```

### Development Workflow
1. **Frontend Development**: Use existing UI components
2. **API Development**: Implement endpoints in `/server/routes.ts`
3. **Database Development**: Use Drizzle ORM for schema changes
4. **Testing**: Unit tests for algorithms, integration tests for APIs
5. **Deployment**: Vercel for frontend, Railway/Supabase for backend

---

## 🛣 Implementation Roadmap

### Phase 1: Core Infrastructure (Week 1-2)
- [ ] Set up PostgreSQL database with schema
- [ ] Implement Supabase authentication
- [ ] Create API route handlers structure
- [ ] Set up Spotify API integration
- [ ] Configure OpenAI API for AI features

### Phase 2: Single Playlist Analysis (Week 3-4)
- [ ] Implement playlist URL parsing
- [ ] Build audio features extraction
- [ ] Create mood detection algorithm
- [ ] Develop personality insight generation
- [ ] Add genre and artist analytics
- [ ] Implement health scoring system

### Phase 3: Playlist Battle Mode (Week 5-6)
- [ ] Build playlist comparison logic
- [ ] Implement compatibility scoring
- [ ] Create winner determination algorithm
- [ ] Add shared content analysis
- [ ] Develop combined audio DNA visualization data

### Phase 4: AI Recommendations (Week 7-8)
- [ ] Implement 6 recommendation strategies
- [ ] Build cosine similarity algorithms
- [ ] Create flavor profile system
- [ ] Add multi-strategy search logic
- [ ] Integrate with existing UI components

### Phase 5: User Management & Polish (Week 9-10)
- [ ] Complete user authentication flows
- [ ] Implement saved analyses functionality
- [ ] Add analysis history tracking
- [ ] Polish UI interactions and animations
- [ ] Performance optimization and testing

### Phase 6: Deployment & Launch (Week 11-12)
- [ ] Set up production database
- [ ] Configure production environment
- [ ] Deploy to Vercel/Railway
- [ ] Final testing and bug fixes
- [ ] Launch Antidote v3

---

## 🎯 Success Metrics (v3)

### Technical Metrics
- **API Response Time**: < 2 seconds for analysis, < 3 seconds for comparison
- **Database Query Performance**: < 500ms for complex analytics
- **AI Generation Time**: < 5 seconds for personality insights
- **Error Rate**: < 2% API failure rate

### Feature Completion
- **Analysis Accuracy**: > 95% successful playlist parsing
- **Recommendation Quality**: > 80% user satisfaction with suggestions
- **Compatibility Scoring**: > 85% accuracy in user validation

### Performance Targets
- **Concurrent Users**: Support 500+ simultaneous analysis requests
- **Database Load**: Handle 1000+ analysis operations per hour
- **Caching Hit Rate**: > 70% for repeated analyses

---

## 📞 Development Support

### Key Implementation Notes
- **Leverage Existing UI**: All React components are ready - focus on data flow
- **Modular Architecture**: Build algorithms as separate modules for testing
- **Error Handling**: Comprehensive error handling for all external API calls
- **Rate Limiting**: Implement proper rate limiting for Spotify API calls
- **Data Validation**: Use Zod schemas for all API inputs and outputs

### Recommended Development Approach
1. **Start with Data Layer**: Build database models and basic CRUD operations
2. **Implement Core Algorithms**: Develop audio analysis and AI features
3. **Create API Endpoints**: Build RESTful APIs that power the UI
4. **Integrate with UI**: Connect existing components to new backend
5. **Testing & Optimization**: Comprehensive testing and performance tuning

---

*Document Version: 3.0*
*Last Updated: December 25, 2025*
*Author: Antidote Development Team*
*Focus: Backend Implementation for Existing UI*