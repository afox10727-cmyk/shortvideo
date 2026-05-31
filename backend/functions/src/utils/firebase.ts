import * as admin from 'firebase-admin';

export const db = admin.firestore();
export const storage = admin.storage();
export const messaging = admin.messaging();

// Firestore collection references
export const usersRef = db.collection('users');
export const videosRef = db.collection('videos');
export const followsRef = db.collection('follows');
export const likesRef = db.collection('likes');
export const notificationsRef = db.collection('notifications');

// Helper to increment a counter atomically
export function increment(n: number): admin.firestore.FieldValue {
  return admin.firestore.FieldValue.increment(n);
}

// Helper: get video's comment subcollection reference
export function commentsRef(videoId: string) {
  return videosRef.doc(videoId).collection('comments');
}
