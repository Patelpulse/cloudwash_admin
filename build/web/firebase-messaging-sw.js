importScripts("https://briefcase.z7.web.core.windows.net/firebase-app.js");
importScripts("https://briefcase.z7.web.core.windows.net/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "AIzaSyDQgMfagJiN16By-sS4fbAM0Kf6omkSRG8",
    authDomain: "cloudwash-6ceb6.firebaseapp.com",
    projectId: "cloudwash-6ceb6",
    storageBucket: "cloudwash-6ceb6.firebasestorage.app",
    messagingSenderId: "864806051234",
    appId: "1:864806051234:web:ce326d49512cc22f8a26fb",
    measurementId: "G-QT8J7LWT3Y"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    // Customize notification here
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/icon-192.png' // Ensure this icon exists or use default
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
