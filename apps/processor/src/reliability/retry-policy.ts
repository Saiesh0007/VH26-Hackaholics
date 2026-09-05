import { ErrorClassification, ReliabilityConfig } from './types';

export class RetryPolicy {
  constructor(private config: ReliabilityConfig) {}

  /**
   * Determines if the event should be retried based on classification and attempt count.
   */
  shouldRetry(classification: ErrorClassification, currentAttempt: number): boolean {
    if (classification === ErrorClassification.DUPLICATE) return false;
    if (classification === ErrorClassification.PERMANENT) return false;
    
    return currentAttempt <= this.config.maxRetries;
  }

  getMaxRetries(): number {
    return this.config.maxRetries;
  }
}
