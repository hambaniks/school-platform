export const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api';

export async function api<T>(
  endpoint: string,
  opts: { method?: string; body?: unknown; headers?: Record<string, string>; params?: Record<string, string> } = {}
): Promise<{ data: T | null; error: string | null }> {
  try {
    let url = API_BASE + endpoint;
    if (opts.params) {
      const qs = new URLSearchParams(opts.params).toString();
      url += '?' + qs;
    }
    const res = await fetch(url, {
      method: opts.method || 'GET',
      headers: { 'Content-Type': 'application/json', ...opts.headers },
      body: opts.body ? JSON.stringify(opts.body) : undefined,
    });
    if (!res.ok) return { data: null, error: 'HTTP ' + res.status };
    return { data: (await res.json()) as T, error: null };
  } catch (e) {
    return { data: null, error: String(e) };
  }
}

export function mockApi<T>(
  data: T,
  delay = 600
): Promise<{ data: T | null; error: string | null }> {
  return new Promise((r) => setTimeout(() => r({ data, error: null }), delay));
}
