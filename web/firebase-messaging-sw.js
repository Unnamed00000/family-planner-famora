importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBr_HhIWRjbueqQ1itZKKbG1ZOMDYzAlvA',
  authDomain: 'family-planner-famora.firebaseapp.com',
  projectId: 'family-planner-famora',
  storageBucket: 'family-planner-famora.firebasestorage.app',
  messagingSenderId: '827139414796',
  appId: '1:827139414796:web:b12bcfd6ee4006dd524729',
  measurementId: 'G-0C01CGN78J',
});

firebase.messaging();
