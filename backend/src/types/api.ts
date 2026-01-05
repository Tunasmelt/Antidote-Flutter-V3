// API Response Types and Helpers
// Standardizes API responses across all endpoints

export interface ApiSuccessResponse<T> {
  success: true;
  data: T;
  meta: {
    requestId: string;
    timestamp: string;
    version: string;
  };
  pagination?: PaginationMeta;
}

export interface ApiErrorResponse {
  success: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
  meta: {
    requestId: string;
    timestamp: string;
  };
}

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
  hasMore: boolean;
  hasPrevious: boolean;
}

// Request ID generation
let requestCounter = 0;
function generateRequestId(): string {
  const timestamp = Date.now().toString(36);
  const counter = (++requestCounter).toString(36).padStart(4, '0');
  const random = Math.random().toString(36).substring(2, 7);
  return `${timestamp}-${counter}-${random}`;
}

// Success response helper
export function successResponse<T>(
  data: T,
  pagination?: PaginationMeta
): ApiSuccessResponse<T> {
  return {
    success: true,
    data,
    meta: {
      requestId: generateRequestId(),
      timestamp: new Date().toISOString(),
      version: 'v1',
    },
    pagination,
  };
}

// Error response helper
export function errorResponse(
  code: string,
  message: string,
  details?: unknown
): ApiErrorResponse {
  return {
    success: false,
    error: {
      code,
      message,
      details,
    },
    meta: {
      requestId: generateRequestId(),
      timestamp: new Date().toISOString(),
    },
  };
}

// Pagination helper
export function createPaginationMeta(
  page: number,
  limit: number,
  total: number
): PaginationMeta {
  const totalPages = Math.ceil(total / limit);
  
  return {
    page,
    limit,
    total,
    totalPages,
    hasMore: page < totalPages,
    hasPrevious: page > 1,
  };
}

// Standard error codes
export const ErrorCodes = {
  // Authentication & Authorization
  AUTH_REQUIRED: 'AUTH_REQUIRED',
  TOKEN_EXPIRED: 'TOKEN_EXPIRED',
  TOKEN_INVALID: 'TOKEN_INVALID',
  TOKEN_REQUIRED: 'TOKEN_REQUIRED',
  INSUFFICIENT_PERMISSIONS: 'INSUFFICIENT_PERMISSIONS',
  
  // Validation
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  INVALID_INPUT: 'INVALID_INPUT',
  MISSING_REQUIRED_FIELD: 'MISSING_REQUIRED_FIELD',
  
  // Resources
  NOT_FOUND: 'NOT_FOUND',
  ALREADY_EXISTS: 'ALREADY_EXISTS',
  RESOURCE_DELETED: 'RESOURCE_DELETED',
  
  // External Services
  SPOTIFY_ERROR: 'SPOTIFY_ERROR',
  SPOTIFY_RATE_LIMIT: 'SPOTIFY_RATE_LIMIT',
  DATABASE_ERROR: 'DATABASE_ERROR',
  
  // Server
  INTERNAL_ERROR: 'INTERNAL_ERROR',
  SERVICE_UNAVAILABLE: 'SERVICE_UNAVAILABLE',
  TIMEOUT: 'TIMEOUT',
  
  // Rate Limiting
  RATE_LIMIT_EXCEEDED: 'RATE_LIMIT_EXCEEDED',
} as const;

export type ErrorCode = typeof ErrorCodes[keyof typeof ErrorCodes];
