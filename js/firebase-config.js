/**
 * CardioCare AI - Firebase Configuration & Initialization
 * Project: healthcare-xai
 */

const firebaseConfig = {
  apiKey: "AIzaSyCVtfCHB27aszRGQvvMf13JAXq4EZL9CX0",
  authDomain: "healthcare-xai.firebaseapp.com",
  projectId: "healthcare-xai",
  storageBucket: "healthcare-xai.firebasestorage.app",
  messagingSenderId: "506715356518",
  appId: "1:506715356518:web:20f72d91be3f66583edca7",
  measurementId: "G-E5PEK4MJMR"
};

let db = null;
let auth = null;

function isFirebaseConfigured() {
  return Boolean(
    firebaseConfig &&
    firebaseConfig.apiKey &&
    firebaseConfig.apiKey !== "YOUR_API_KEY" &&
    firebaseConfig.projectId !== "YOUR_PROJECT_ID"
  );
}

// Khởi tạo Firebase
if (typeof firebase !== 'undefined' && isFirebaseConfigured()) {
  try {
    if (!firebase.apps.length) {
      firebase.initializeApp(firebaseConfig);
    }
    db = firebase.firestore();
    auth = firebase.auth();
    console.log("Firebase Cloud Firestore (healthcare-xai) đã kết nối thành công!");
  } catch (e) {
    console.warn("Chưa thể kết nối Firebase:", e);
  }
}
