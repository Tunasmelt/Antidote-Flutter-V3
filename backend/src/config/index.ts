// Backend Configuration Management System
// Validates and provides type-safe access to environment variables

export interface AppConfig {
  port: number;
  nodeEnv: 'development' | 'production' | 'test';
  cors: {
    origins: string[];
    credentials: boolean;
    maxAge: number;
  };
  spotify: {
    clientId: string;
    clientSecret: string;
  };
  supabase: {
    url: string;
    serviceKey: string;
  };
  rateLimit: {
    windowMs: number;
    maxRequests: number;
    authMaxRequests: number;
  };
  cache: {
    ttl: number;
    maxSize: number;
  };
  logging: {
    level: 'debug' | 'info' | 'warn' | 'error';
  };
}

class ConfigurationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ConfigurationError';
  }
}

function validateConfig(): AppConfig {
  const missingVars: string[] = [];
  
  // Required variables
  const requiredEnvVars = {
    SPOTIFY_CLIENT_ID: process.env.SPOTIFY_CLIENT_ID,
    SPOTIFY_CLIENT_SECRET: process.env.SPOTIFY_CLIENT_SECRET,
  };
  
  Object.entries(requiredEnvVars).forEach(([key, value]) => {
    if (!value) missingVars.push(key);
  });
  
  if (missingVars.length > 0) {
    throw new ConfigurationError(
      `Missing required environment variables: ${missingVars.join(', ')}`
    );
  }
  
  // Parse CORS origins
  const corsOriginsRaw = process.env.CORS_ORIGINS || '';
  const corsOrigins = corsOriginsRaw
    ? corsOriginsRaw.split(',').map(s => s.trim()).filter(Boolean)
    : getDefaultCorsOrigins();
  
  return {
    port: parseInt(process.env.PORT || '5000', 10),
    nodeEnv: (process.env.NODE_ENV as AppConfig['nodeEnv']) || 'development',
    cors: {
      origins: corsOrigins,
      credentials: true,
      maxAge: 86400,
    },
    spotify: {
      clientId: process.env.SPOTIFY_CLIENT_ID!,
      clientSecret: process.env.SPOTIFY_CLIENT_SECRET!,
    },
    supabase: {
      url: process.env.SUPABASE_URL || '',
      serviceKey: process.env.SUPABASE_SERVICE_ROLE_KEY || '',
    },
    rateLimit: {
      windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10),
      maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '20', 10),
      authMaxRequests: parseInt(process.env.RATE_LIMIT_AUTH_MAX || '5', 10),
    },
    cache: {
      ttl: parseInt(process.env.CACHE_TTL_SECONDS || '3600', 10),
      maxSize: parseInt(process.env.CACHE_MAX_SIZE || '1000', 10),
    },
    logging: {
      level: (process.env.LOG_LEVEL as AppConfig['logging']['level']) || 'info',
    },
  };
}

function getDefaultCorsOrigins(): string[] {
  const nodeEnv = process.env.NODE_ENV;
  
  if (nodeEnv === 'production') {
    return [
      'https://antidote.app',
      'https://www.antidote.app',
      process.env.FRONTEND_URL,
    ].filter(Boolean) as string[];
  }
  
  // Development origins
  return [
    'http://localhost:3000',
    'http://localhost:5000',
    'http://localhost:8080',
  ];
}

// Singleton pattern for config
let configInstance: AppConfig | null = null;

export function getConfig(): AppConfig {
  if (!configInstance) {
    configInstance = validateConfig();
  }
  return configInstance;
}

// For testing - allows resetting config
export function resetConfig(): void {
  configInstance = null;
}
