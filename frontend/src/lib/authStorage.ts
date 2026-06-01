import type { AuthSession } from "../types/demo";

const STORAGE_KEY = "gartner-demo-auth-session";

function isAuthSession(value: unknown): value is AuthSession {
  if (!value || typeof value !== "object") return false;
  const v = value as Record<string, unknown>;
  if (typeof v.token !== "string" || v.token.length === 0) return false;
  const user = v.user;
  if (!user || typeof user !== "object") return false;
  const u = user as Record<string, unknown>;
  return (
    typeof u.id === "number" &&
    typeof u.name === "string" &&
    typeof u.email === "string" &&
    typeof u.role === "string"
  );
}

export function loadPersistedSession(): AuthSession | null {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    const parsed: unknown = JSON.parse(raw);
    if (!isAuthSession(parsed)) {
      localStorage.removeItem(STORAGE_KEY);
      return null;
    }
    return parsed;
  } catch {
    localStorage.removeItem(STORAGE_KEY);
    return null;
  }
}

export function persistSession(session: AuthSession): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(session));
}

export function clearPersistedSession(): void {
  localStorage.removeItem(STORAGE_KEY);
}
