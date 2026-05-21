// web/firebase-messaging-sw.js
// Handles FCM messages when the app is in the background or closed.

importScripts('https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyA2hHdz8fse7fMJP8ygu05LtPUDbAqPKVQ",
  authDomain: "dispo-des-bros.firebaseapp.com",
  projectId: "dispo-des-bros",
  messagingSenderId: "604239799472",
  appId: "1:604239799472:web:c1eb4d25703e47f6c88775",
});

const messaging = firebase.messaging();

// Background / closed app: show the notification
messaging.onBackgroundMessage((payload) => {
  console.log('[SW] Message reçu en arrière-plan :', payload);

  // FCM automatically displays a notification if the payload contains a 'notification' object.
  // If we also manually show it, the user will receive 2 duplicate notifications.
  if (payload.notification) {
    console.log('[SW] Notification payload found. FCM will display it automatically.');
    return;
  }

  const title = payload.data?.title ?? 'D&D&B';
  const body  = payload.data?.body  ?? '';

  self.registration.showNotification(title, {
    body,
    icon:             '/icons/Icon-192.png',
    badge:            '/icons/Icon-72.png',
    requireInteraction: false,   // dismiss automatically (don't stick)
    vibrate:          [200, 100, 200],
    data: {
      // Store the target URL so the click handler knows where to navigate
      url: '/',
    },
  });
});

// Notification click: focus or open the app, then close the notification
self.addEventListener('notificationclick', function (event) {
  event.notification.close(); // dismiss immediately on click

  const targetUrl = event.notification.data?.url ?? '/';

  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then(function (clientList) {
        // If the app is already open in a tab, focus it
        for (const client of clientList) {
          if ('focus' in client) {
            return client.focus();
          }
        }
        // Otherwise open a new tab/window
        if (clients.openWindow) {
          return clients.openWindow(targetUrl);
        }
      })
  );
});
