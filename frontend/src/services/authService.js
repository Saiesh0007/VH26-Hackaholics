/**
 * Auth service — uses Supabase Auth and keeps the existing app session shape.
 *
 * Stores the JWT in sessionStorage under 'flashflow-token'.
 * Stores the user profile under 'flashflow-user'.
 *
 * Demo credentials (pre-seeded in backend/database.py):
 *   Admin:    admin@flashflow.dev  / admin123
 *   Customer: maya@flashflow.dev   / user123
 *   Customer: demo@flashflow.dev   / demo123
 */

import { supabase } from "./supabase";
import { apiRequest } from "./api";

const USER_KEY = "flashflow-user";
const TOKEN_KEY = "flashflow-token";

function _profile(user) {
  return {
    id: user.id,
    name: user.user_metadata?.name || user.email?.split("@")[0] || "User",
    email: user.email,
    role: user.user_metadata?.role || "customer",
  };
}

function _saveSession(token, user) {
  sessionStorage.setItem(TOKEN_KEY, token);
  sessionStorage.setItem(USER_KEY, JSON.stringify(user));
}

async function _loadProfile(session) {
  sessionStorage.setItem(TOKEN_KEY, session.access_token);
  const profile = await apiRequest("/auth/me");
  _saveSession(session.access_token, profile);
  return profile;
}

export const authService = {
  /**
   * Log in with email + password.
   * Returns the user object: { id, name, email, role }
   */
  login: async (email, password) => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error) throw error;
    return _loadProfile(data.session);
  },

  /**
   * Create a new account.
   * Returns the user object: { id, name, email, role }
   */
  signup: async (name, email, password, role = "customer") => {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { name, role: "customer" } },
    });
    if (error) throw error;
    if (!data.session)
      throw new Error("Check your email to confirm your account.");
    return _loadProfile(data.session);
  },

  /**
   * Return the currently logged-in user from sessionStorage, or null.
   */
  current: () => {
    try {
      return JSON.parse(sessionStorage.getItem(USER_KEY));
    } catch {
      return null;
    }
  },

  /**
   * Clear session (logout).
   */
  logout: () => {
    supabase.auth.signOut();
    sessionStorage.removeItem(USER_KEY);
    sessionStorage.removeItem(TOKEN_KEY);
  },
};
