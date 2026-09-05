export class Backoff {
  /**
   * Calculates deterministic exponential backoff bounded by maxDelayMs.
   */
  static calculateDelay(attempt: number, baseDelayMs: number, maxDelayMs: number): number {
    if (attempt <= 1) return baseDelayMs;
    
    // Exponential backoff: baseDelayMs * 2^(attempt - 1)
    const exponentialDelay = baseDelayMs * Math.pow(2, attempt - 1);
    
    return Math.min(exponentialDelay, maxDelayMs);
  }

  /**
   * Asynchronously wait for the given duration.
   */
  static async wait(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
