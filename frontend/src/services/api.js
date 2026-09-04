/**
 * Central API client.
 *
 * Reads VITE_API_BASE_URL from env (falls back to http://localhost:8000/api).
 * Automatically injects the JWT Bearer token from sessionStorage.
 *
 * Usage:
 *   import { apiRequest } from './api'
 *   const data = await apiRequest('/products')
 *   const data = await apiRequest('/orders', { method: 'POST', body: JSON.stringify(payload) })
 */

export const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:8000/api";

// Keep MOCK flag so existing mock-only pages continue working during dev
export const USE_MOCK = import.meta.env.VITE_USE_MOCK_API === "true";

/**
 * Make an authenticated request to the FlashFlow API.
 * @param {string} path  - API path, e.g. '/products'
 * @param {RequestInit} options - Fetch options (method, body, etc.)
 * @returns {Promise<any>} Parsed JSON response
 */
export async function apiRequest(path, options = {}) {
  const token = sessionStorage.getItem("flashflow-token");

  const headers = {
    "Content-Type": "application/json",
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(options.headers || {}),
  };

  const res = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers,
  });

  if (!res.ok) {
    let detail = `API error ${res.status}`;
    try {
      const err = await res.json();
      detail = err.detail || detail;
    } catch (_) {}
    throw new Error(detail);
  }

  return res.json();
}

// Legacy alias used by older parts of the codebase
export const request = apiRequest;
