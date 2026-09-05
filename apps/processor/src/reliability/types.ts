export enum ErrorClassification {
  TRANSIENT = 'TRANSIENT',
  PERMANENT = 'PERMANENT',
  DUPLICATE = 'DUPLICATE',
}

export interface ReliabilityConfig {
  maxRetries: number;
  baseDelayMs: number;
  maxDelayMs: number;
}
