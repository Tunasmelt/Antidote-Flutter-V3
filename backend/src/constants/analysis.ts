// Constants for audio analysis and personality determination
// Extracts magic numbers into named constants

export const AUDIO_ANALYSIS_THRESHOLDS = {
  // Personality Type Thresholds
  EXPERIMENTALIST: {
    MIN_INSTRUMENTALNESS: 0.3,
    HIGH_ENERGY: 0.8,
    LOW_DANCEABILITY: 0.4,
  },
  MOOD_DRIVEN: {
    MIN_ACOUSTICNESS: 0.5,
    LOW_VALENCE: 0.3,
    HIGH_VALENCE: 0.8,
  },
  PARTY_STARTER: {
    MIN_ENERGY: 0.7,
    MIN_DANCEABILITY: 0.7,
    HIGH_TEMPO: 140,
  },
  CHILL_CURATOR: {
    MAX_ENERGY: 0.5,
    MIN_ACOUSTICNESS: 0.4,
    MID_VALENCE_MIN: 0.4,
    MID_VALENCE_MAX: 0.7,
  },
  ECLECTIC_EXPLORER: {
    MIN_GENRE_DIVERSITY: 5,
    MIN_ENERGY_VARIANCE: 0.3,
  },
  
  // Health Score Thresholds
  HEALTH: {
    EXCELLENT: 80,
    GOOD: 60,
    FAIR: 40,
    NEEDS_WORK: 20,
  },
  
  // Audio Feature Ranges
  FEATURE_RANGES: {
    VERY_LOW: 0.3,
    LOW: 0.5,
    MEDIUM: 0.7,
    HIGH: 0.85,
  },
  
  // Tempo Categories (BPM)
  TEMPO: {
    VERY_SLOW: 80,
    SLOW: 100,
    MODERATE: 120,
    FAST: 140,
    VERY_FAST: 160,
  },
} as const;

export const BATCH_SIZES = {
  SPOTIFY_ARTISTS: 50,
  SPOTIFY_TRACKS: 100,
  DATABASE_INSERT: 100,
  CACHE_CLEANUP: 1000,
} as const;

export const CACHE_TTL = {
  ARTIST_DATA: 3600,      // 1 hour
  TRACK_FEATURES: 1800,   // 30 minutes
  PLAYLIST_METADATA: 600, // 10 minutes
  USER_PROFILE: 300,      // 5 minutes
} as const;

export const GENRE_WEIGHTS = {
  PRIMARY_GENRE: 1.0,
  SECONDARY_GENRE: 0.7,
  TERTIARY_GENRE: 0.3,
} as const;

export const RECOMMENDATION_LIMITS = {
  SEED_TRACKS_MAX: 5,
  SEED_ARTISTS_MAX: 5,
  SEED_GENRES_MAX: 5,
  TOTAL_SEEDS_MAX: 5,
  RESULTS_MIN: 1,
  RESULTS_MAX: 100,
  DEFAULT_RESULTS: 20,
} as const;

export const DATABASE_LIMITS = {
  MAX_TRACKS_PER_PLAYLIST: 10000,
  MAX_PLAYLISTS_PER_USER: 1000,
  MAX_ANALYSES_PER_USER: 10000,
  MAX_BATTLES_PER_USER: 1000,
} as const;

// Personality descriptions
export const PERSONALITY_TYPES = {
  'The Experimentalist': {
    description: 'You embrace the unconventional with sophisticated instrumental pieces and high-energy experimental tracks.',
    traits: ['Adventurous', 'Sophisticated', 'Open-minded'],
  },
  'The Mood Driven': {
    description: 'Your music mirrors your emotions with a rich acoustic palette.',
    traits: ['Emotional', 'Authentic', 'Introspective'],
  },
  'The Party Starter': {
    description: 'High-energy, danceable tracks that get everyone moving.',
    traits: ['Energetic', 'Social', 'Fun-loving'],
  },
  'The Chill Curator': {
    description: 'Mellow, acoustic vibes for relaxation and contemplation.',
    traits: ['Calm', 'Thoughtful', 'Relaxed'],
  },
  'The Eclectic Explorer': {
    description: 'Diverse musical tastes spanning multiple genres and styles.',
    traits: ['Curious', 'Open-minded', 'Diverse'],
  },
  'The Balanced Listener': {
    description: 'Well-rounded tastes with a mix of all musical elements.',
    traits: ['Versatile', 'Adaptable', 'Well-rounded'],
  },
} as const;

export type PersonalityType = keyof typeof PERSONALITY_TYPES;
