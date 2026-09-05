import { ErrorClassification } from './types';

export class ErrorClassifier {
  /**
   * Classifies an error into TRANSIENT, PERMANENT, or DUPLICATE.
   */
  static classify(error: any): ErrorClassification {
    // PostgreSQL Unique Violation
    if (error && String(error.code) === '23505') {
      return ErrorClassification.DUPLICATE;
    }

    const errorMessage = error?.message?.toLowerCase() || '';

    // Check for simulated or explicit permanent errors
    if (error?.isPermanent || errorMessage.includes('permanent') || errorMessage.includes('business')) {
      return ErrorClassification.PERMANENT;
    }

    // Default to transient for network errors, database timeouts, etc.
    // Also captures 'simulateError: transient'
    return ErrorClassification.TRANSIENT;
  }
}
