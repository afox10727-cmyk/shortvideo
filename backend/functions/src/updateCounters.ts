/**
 * updateCountersOnEvent
 *
 * Trigger: Firestore onDocumentWritten on likes, follows, comments
 * What: Updates denormalized counters (likeCount, followerCount, etc.)
 */
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { videosRef, usersRef, increment, commentsRef } from './utils/firebase.js';

export const updateCountersOnEvent = onDocumentWritten(
  {
    document: [
      'likes/{likeDoc}',
      'follows/{followDoc}',
      'videos/{videoId}/comments/{commentId}',
    ],
    region: 'us-central1',
  },
  async (event) => {
    const { before, after } = event.data || {};
    const docPath = event.params;
    const isCreate = !before?.exists && after?.exists;
    const isDelete = before?.exists && !after?.exists;

    // Only handle create and delete (not updates)
    if (!isCreate && !isDelete) return;
    const delta = isCreate ? 1 : -1;

    const match = event.document?.match(/\/(likes|follows|videos)\//);
    const collection = match ? match[1] : null;

    try {
      switch (collection) {
        case 'likes': {
          const videoId = isCreate ? after!.data()!.videoId : before!.data()!.videoId;
          await videosRef.doc(videoId).update({
            likeCount: increment(delta),
          });
          break;
        }

        case 'follows': {
          const data = isCreate ? after!.data()! : before!.data()!;
          const followerId = data.followerId;
          const followingId = data.followingId;

          await usersRef.doc(followingId).update({
            followerCount: increment(delta),
          });
          await usersRef.doc(followerId).update({
            followingCount: increment(delta),
          });
          break;
        }

        case 'videos': {
          const videoId = docPath['videoId'];
          await videosRef.doc(videoId).update({
            commentCount: increment(delta),
          });
          break;
        }
      }
    } catch (error) {
      console.error('Failed to update counters:', error);
    }
  }
);
