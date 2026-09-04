/**
 * Auth service — talks to the FastAPI backend.
 *
 * Stores the JWT in sessionStorage under 'flashflow-token'.
 * Stores the user profile under 'flashflow-user'.
 *
 * Demo credentials (pre-seeded in backend/database.py):
 *   Admin:    admin@flashflow.dev  / admin123
 *   Customer: maya@flashflow.dev   / user123
 *   Customer: demo@flashflow.dev   / demo123
 */

import { apiRequest } from './api'

const USER_KEY  = 'flashflow-user'
const TOKEN_KEY = 'flashflow-token'

function _saveSession(token, user) {
  sessionStorage.setItem(TOKEN_KEY, token)
  sessionStorage.setItem(USER_KEY, JSON.stringify(user))
}

export const authService = {
  /**
   * Log in with email + password.
   * Returns the user object: { id, name, email, role }
   */
  login: async (email, password) => {
    const res = await apiRequest('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    })
    _saveSession(res.access_token, res.user)
    return res.user
  },

  /**
   * Create a new account.
   * Returns the user object: { id, name, email, role }
   */
  signup: async (name, email, password, role = 'customer') => {
    const res = await apiRequest('/auth/signup', {
      method: 'POST',
      body: JSON.stringify({ name, email, password, role }),
    })
    _saveSession(res.access_token, res.user)
    return res.user
  },

  /**
   * Return the currently logged-in user from sessionStorage, or null.
   */
  current: () => {
    try {
      return JSON.parse(sessionStorage.getItem(USER_KEY))
    } catch {
      return null
    }
  },

  /**
   * Clear session (logout).
   */
  logout: () => {
    sessionStorage.removeItem(USER_KEY)
    sessionStorage.removeItem(TOKEN_KEY)
  },
}
