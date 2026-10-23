// The site offline: whatever a visitor has opened once (the app, its assets,
// the C++ and Python runners) is kept here and served when the network is
// gone. Online, the network always wins (checked with the server, not the
// browser's own copy), so a deploy shows up on the next load.
// Lessons and problems stored in Firestore are kept by Firestore itself
// (persistence is on, see main.dart), not here.
'use strict';

const CACHE = 'imeditatii-v1';
const SHELL = new URL('./', self.registration.scope).href; // index.html; also what every deep link loads

// Fetched once and never changed (versioned URLs, fonts): from the cache first.
const CDN = ['fonts.gstatic.com', 'www.gstatic.com', 'cdn.jsdelivr.net'];
// Small and can change: from the cache at once, refreshed in the background.
const REFRESHED = ['fonts.googleapis.com'];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE).then((cache) =>
      Promise.all(
        [
          SHELL, 'flutter_bootstrap.js', 'main.dart.js', 'manifest.json', 'favicon.png', 'icons/Icon-192.png', 'py_runner.js', 'cpp_runner.js',
          // every problem, so any of them opens offline, not only those seen
          'assets/assets/data/exercises.json', 'assets/assets/data/exercise_details.json', 'assets/assets/data/problem_quizzes.json',
        ]
          .map((path) => new URL(path, self.registration.scope).href)
          .map((url) => fetch(url, { cache: 'no-cache' }).then((res) => (res.ok ? cache.put(url, res) : null)).catch(() => null))
      )
    )
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      for (const key of await caches.keys()) if (key !== CACHE) await caches.delete(key);
      await self.clients.claim();
    })()
  );
});

// The page sends what it loaded before this worker took over (the first
// visit), so that is kept too: CanvasKit, fonts, assets.
self.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.type !== 'keep' || !Array.isArray(data.urls)) return;
  event.waitUntil(
    caches.open(CACHE).then((cache) =>
      Promise.all(
        data.urls.filter(wanted).map(async (url) => {
          if (await cache.match(url)) return;
          try {
            const res = await fetch(url);
            if (res.ok) await cache.put(url, res);
          } catch (_) {}
        })
      )
    )
  );
});

function wanted(url) {
  try {
    const u = new URL(url);
    if (u.origin === self.location.origin) return !u.pathname.endsWith('/sw.js');
    return CDN.includes(u.hostname) || REFRESHED.includes(u.hostname);
  } catch (_) {
    return false;
  }
}

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  if (req.mode === 'navigate') {
    event.respondWith(page(req));
  } else if (url.origin === self.location.origin) {
    if (url.pathname.endsWith('/sw.js')) return;
    event.respondWith(networkFirst(req));
  } else if (CDN.includes(url.hostname)) {
    event.respondWith(cacheFirst(req));
  } else if (REFRESHED.includes(url.hostname)) {
    event.respondWith(staleWhileRevalidate(req, event));
  }
  // anything else (Firestore, Auth, Storage, Stripe, ...) goes straight to the network
});

// Every path is the same app (GitHub Pages answers deep links with 404.html,
// a copy of index.html, with status 404), so one copy serves them all offline.
async function page(req) {
  const cache = await caches.open(CACHE);
  try {
    // no-cache: ask the server (a small 304 when nothing changed), so a deploy
    // shows at once instead of after the browser's 10-minute copy expires
    const res = await fetch(req.url, { cache: 'no-cache', credentials: 'same-origin' });
    if (res.status < 500) cache.put(SHELL, res.clone());
    return res;
  } catch (e) {
    const hit = await cache.match(SHELL);
    if (hit) return hit;
    throw e;
  }
}

async function networkFirst(req) {
  const cache = await caches.open(CACHE);
  try {
    const res = await fetch(req, { cache: 'no-cache' });
    if (res.ok) cache.put(req, res.clone());
    return res;
  } catch (e) {
    const hit = await cache.match(req, { ignoreSearch: true });
    if (hit) return hit;
    throw e;
  }
}

async function cacheFirst(req) {
  const cache = await caches.open(CACHE);
  const hit = await cache.match(req);
  if (hit) return hit;
  const res = await fetch(req);
  if (res.ok || res.type === 'opaque') cache.put(req, res.clone());
  return res;
}

async function staleWhileRevalidate(req, event) {
  const cache = await caches.open(CACHE);
  const hit = await cache.match(req);
  const fresh = fetch(req).then((res) => {
    if (res.ok || res.type === 'opaque') cache.put(req, res.clone());
    return res;
  });
  if (hit) {
    event.waitUntil(fresh.catch(() => null));
    return hit;
  }
  return fresh;
}
