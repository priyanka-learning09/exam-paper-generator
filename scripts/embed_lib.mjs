const DIM = 384;
const STOP = new Set(['the','a','an','is','are','of','to','in','and','or','which','what','does','for','on','by','as','that','this','be','it','its','with','from']);

function hash(str) {
  let h = 2166136261;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

function add(vec, key, weight) {
  const idx = hash(key) % DIM;
  const sign = hash('s' + key) % 2 === 0 ? 1 : -1;
  vec[idx] += sign * weight;
}

export function embed(text) {
  const vec = new Array(DIM).fill(0);
  const words = text.toLowerCase().replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/).filter(w => w && !STOP.has(w));
  for (const w of words) {
    add(vec, 'w:' + w, 1.0);
    const p = '^' + w + '$';
    for (let i = 0; i <= p.length - 3; i++) add(vec, 't:' + p.slice(i, i + 3), 0.3);
  }
  const norm = Math.sqrt(vec.reduce((s, x) => s + x * x, 0)) || 1;
  return '[' + vec.map(x => (x / norm).toFixed(6)).join(',') + ']';
}