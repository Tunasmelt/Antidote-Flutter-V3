/**
 * Rate Limiting Middleware for Express
 * 
 * Implements a simple in-memory rate limiter to prevent API abuse
 * Particularly useful for unauthenticated endpoints like /api/analyze and /api/battle
 */

interface RateLimitStore {
  [key: string]: {
    count: number;
    resetTime: number;
  };
}

const rateLimitStore: RateLimitStore = {};

// Clean up old entries every 5 minutes
setInterval(() => {
  const now = Date.now();
  Object.keys(rateLimitStore).forEach((key) => {
    if (rateLimitStore[key].resetTime < now) {
      delete rateLimitStore[key];
    }
  });
}, 5 * 60 * 1000);

export interface RateLimitOptions {
  windowMs?: number; // Time window in milliseconds (default: 15 minutes)
  max?: number; // Max requests per window (default: 100)
  message?: string; // Error message to send when rate limit exceeded
  skipSuccessfulRequests?: boolean; // Don't count successful requests
  skipFailedRequests?: boolean; // Don't count failed requests
  keyGenerator?: (req: any) => string; // Custom key generator function
}

/**
 * Rate limit middleware factory
 * @param options Rate limiting options
 * @returns Express middleware function
 */
export function rateLimit(options: RateLimitOptions = {}) {
  const {
    windowMs = 15 * 60 * 1000, // 15 minutes
    max = 100,
    message = 'Too many requests, please try again later.',
    skipSuccessfulRequests = false,
    skipFailedRequests = false,
    keyGenerator = (req) => {
      // Default: use IP address or user ID
      return req.userId || req.ip || req.connection.remoteAddress || 'unknown';
    },
  } = options;

  return (req: any, res: any, next: any) => {
    const key = keyGenerator(req);
    const now = Date.now();

    // Initialize or get current rate limit data
    if (!rateLimitStore[key] || rateLimitStore[key].resetTime < now) {
      rateLimitStore[key] = {
        count: 0,
        resetTime: now + windowMs,
      };
    }

    // Increment count
    rateLimitStore[key].count++;

    // Check if rate limit exceeded
    if (rateLimitStore[key].count > max) {
      const retryAfter = Math.ceil((rateLimitStore[key].resetTime - now) / 1000);
      res.set({
        'X-RateLimit-Limit': max,
        'X-RateLimit-Remaining': 0,
        'X-RateLimit-Reset': rateLimitStore[key].resetTime,
        'Retry-After': retryAfter,
      });
      
      return res.status(429).json({
        error: message,
        code: 'RATE_LIMIT_EXCEEDED',
        retryAfter,
      });
    }

    // Set rate limit headers
    const remaining = max - rateLimitStore[key].count;
    res.set({
      'X-RateLimit-Limit': max,
      'X-RateLimit-Remaining': remaining,
      'X-RateLimit-Reset': rateLimitStore[key].resetTime,
    });

    // Handle skip options
    if (skipSuccessfulRequests || skipFailedRequests) {
      const originalSend = res.send;
      res.send = function (body: any) {
        const statusCode = res.statusCode;
        
        // Decrement count if we should skip this request
        if (
          (skipSuccessfulRequests && statusCode < 400) ||
          (skipFailedRequests && statusCode >= 400)
        ) {
          rateLimitStore[key].count--;
        }
        
        return originalSend.call(this, body);
      };
    }

    next();
  };
}

/**
 * Create a rate limiter for unauthenticated users only
 * Authenticated users bypass rate limiting
 */
export function rateLimitUnauthenticated(options: RateLimitOptions = {}) {
  const limiter = rateLimit(options);
  
  return (req: any, res: any, next: any) => {
    // Skip rate limiting for authenticated users
    if (req.userId) {
      return next();
    }
    
    return limiter(req, res, next);
  };
}

/**
 * Preset: Strict rate limiting for resource-intensive operations
 * 10 requests per 15 minutes per IP
 */
export const strictRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: 'Too many requests for this resource-intensive operation. Please try again in 15 minutes.',
});

/**
 * Preset: Moderate rate limiting for standard API endpoints
 * 100 requests per 15 minutes per IP
 */
export const moderateRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: 'Too many requests. Please try again in a few minutes.',
});

/**
 * Preset: Lenient rate limiting for frequently accessed endpoints
 * 300 requests per 15 minutes per IP
 */
export const lenientRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  message: 'Rate limit exceeded. Please slow down your requests.',
});
