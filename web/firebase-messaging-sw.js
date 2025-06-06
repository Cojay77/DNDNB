// web/firebase-messaging-sw.js

importScripts('https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyA2hHdz8fse7fMJP8ygu05LtPUDbAqPKVQ",
  authDomain: "dispo-des-bros.firebaseapp.com",
  projectId: "dispo-des-bros",
  messagingSenderId: "604239799472",
  appId: "1:604239799472:android:7162ed4aeaae3665c88775",
});

const messaging = firebase.messaging();

// Background
messaging.onBackgroundMessage((payload) => {
  console.log('📦 Message reçu en arrière-plan : ', payload);
  self.registration.showNotification(payload.notification.title, {
    body: payload.notification.body,
    icon: '/DDB/icons/Icon-192.png'
  });
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();

  event.waitUntil(
    clients.matchAll({ type: 'window' }).then(function(clientList) {
      // Si une fenêtre est déjà ouverte, on la focus
      for (var i = 0; i < clientList.length; i++) {
        var client = clientList[i];
        if (client.url.includes('/') && 'focus' in client) {
          return client.focus();
        }
      }
      // Sinon, on en ouvre une nouvelle
      if (clients.openWindow) {
        return clients.openWindow('/'); 
      }
    })
  );
});

