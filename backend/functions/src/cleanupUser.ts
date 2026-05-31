/**
 * cleanupUserData
 *
 * Trigger: Auth onUserDeleted
 * What: Deletes all user data when account is removed.
 */
import { onUserDeleted } from 'firebase-functions/v2/identity';
import { db, storage } from './utils/firebase.js';

export const cleanupUserData = onUserDeleted(
  {
    region: 'us-central1',
    timeoutSeconds: 300,
  },
  async (event) => {
    const uid = event.data?.uid;
    if (!uid) return;

    console.log(`Cleaning up data for deleted user: ${uid}`);

    try {
      // Delete user document
      await db.collection('users').doc(uid).delete();

      // Delete user's videos (documents + Storage files)
      const userVideos = await db.collection('videos')
        .where('userId', '==', uid)
        .get();

      const batch = db.batch();
      const storageDeletions: Promise<void>[] = [];

      for (const doc of userVideos.docs) {
        const data = doc.data();

        // Queue Storage file deletions
        if (data.videoUrl) {
          storageDeletions.push(
            storage.bucket().file(data.videoUrl).delete().catch(() => {})
          );
        }
        if (data.thumbnailUrl) {
          storageDeletions.push(
            storage.bucket().file(data.thumbnailUrl).delete().catch(() => {})
          );
        }

        batch.delete(doc.ref);
      }

      await batch.commit();
      await Promise.all(storageDeletions);

      // Delete likes by this user
      const userLikes = await db.collection('likes')
        .where('userId', '==', uid)
        .get();
      const likeBatch = db.batch();
      userLikes.docs.forEach(doc => likeBatch.delete(doc.ref));
      await likeBatch.commit();

      // Delete follows involving this user
      const userFollows = await db.collection('follows')
        .where('followerId', '==', uid)
        .get();
      const followedByUser = await db.collection('follows')
        .where('followingId', '==', uid)
        .get();
      const followBatch = db.batch();
      userFollows.docs.forEach(doc => followBatch.delete(doc.ref));
      followedByUser.docs.forEach(doc => followBatch.delete(doc.ref));
      await followBatch.commit();

      // Delete notifications for this user
      const userNotifs = await db.collection('notifications')
        .where('recipientId', '==', uid)
        .get();
      const notifBatch = db.batch();
      userNotifs.docs.forEach(doc => notifBatch.delete(doc.ref));
      await notifBatch.commit();

      // Delete username reservation
      const usernameDocs = await db.collection('usernames')
        .where('uid', '==', uid)
        .get();
      const usernameBatch = db.batch();
      usernameDocs.docs.forEach(doc => usernameBatch.delete(doc.ref));
      await usernameBatch.commit();

      // Delete avatar
      try {
        await storage.bucket().file(`avatars/${uid}.jpg`).delete();
      } catch {
        // Avatar may not exist
      }

      console.log(`Cleanup complete for user: ${uid}`);
    } catch (error) {
      console.error(`Failed to cleanup user ${uid}:`, error);
    }
  }
);
