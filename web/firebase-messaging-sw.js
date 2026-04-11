/* eslint-disable no-undef */
// Background FCM for Flutter web — keep versions in sync with https://firebase.google.com/docs/web/setup
importScripts('https://www.gstatic.com/firebasejs/11.0.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.0.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDTwJc24_jqSQ_Q3H8y8ToOv7e4WcrGHvA',
  appId: '1:692713078513:web:fb2d423a5f57479d10b350',
  messagingSenderId: '692713078513',
  projectId: 'building-guard-app',
  authDomain: 'building-guard-app.firebaseapp.com',
  storageBucket: 'building-guard-app.firebasestorage.app',
  measurementId: 'G-LYQE226Q4R',
});

const messaging = firebase.messaging();
