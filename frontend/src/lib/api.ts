export const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api';
export async function api(endpoint, opts={}) { ... }
export function mockApi(data, delay=600) {
  return new Promise(r => setTimeout(() => r({data, error: null}), delay));
}
