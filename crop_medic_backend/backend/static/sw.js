const CACHE = "cropdoc-v1";
const SHELL = ["/", "/static/app.js", "/static/style.css"];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)));
});

self.addEventListener("fetch", (e) => {
  if (e.request.url.includes("/api/")) return;
  e.respondWith(caches.match(e.request).then((r) => r || fetch(e.request)));
});
