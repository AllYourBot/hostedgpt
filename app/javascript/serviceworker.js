import './serviceworker'

if ('serviceWorker' in navigator && navigator !== null) {
  navigator.serviceWorker.register('/serviceworker.js')
}

self.addEventListener('install', (event) => {
  // Perform install steps
  event.waitUntil(
    caches.open('static').then(function (cache) {
      return cache.addAll(['/', '/index.html', '/css/style.css', '/js/app.js'])
    })
  )
})

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then(function (response) {
      // Cache hit - return response
      if (response) {
        return response
      }
      return fetch(event.request)
    })
  )
})
