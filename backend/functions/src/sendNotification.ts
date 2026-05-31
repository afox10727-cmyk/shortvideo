/**
 * sendNotificationOnEvent
 *
 * Trigger: Firestore onDocumentCreated on likes, follows, comments
 * What: Creates a notification document for the recipient and sends FCM push.
 */
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { db, notificationsRef, videosRef, usersRef } from './utils/firebase.js';
import * as admin from 'firebase-admin';

export const sendNotificationOnEvent = onDocumentCreated(
  {
    document: [
      'likes/{likeDoc}',
      'follows/{followDoc}',
      'videos/{videoId}/comments/{commentId}',
    ],
    region: 'us-central1',
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const docPath = event.params;
    const data = snapshot.data();
    const match = event.document?.match(/\/(likes|follows|videos)\//);
    const collection = match ? match[1] : null;

    let recipientId: string;
    let senderId: string;
    let type: 'like' | 'comment' | 'follow';
    let message: string;
    let videoId: string | null = null;
    let commentId: string | null = null;

    try {
      switch (collection) {
        case 'likes': {
          type = 'like';
          senderId = data.userId;
          videoId = data.videoId;

          const videoDoc = await videosRef.doc(videoId).get();
          recipientId = videoDoc.data()?.userId;

          const senderDoc = await usersRef.doc(senderId).get();
          const senderName = senderDoc.data()?.username ?? 'Someone';
          message = `@${senderName} 赞了你的视频`;
          break;
        }

        case 'follows': {
          type = 'follow';
          senderId = data.followerId;
          recipientId = data.followingId;

          const senderDoc = await usersRef.doc(senderId).get();
          const senderName = senderDoc.data()?.username ?? 'Someone';
          message = `@${senderName} 关注了你`;
          break;
        }

        case 'videos': {
          type = 'comment';
          senderId = data.userId;
          videoId = docPath['videoId'];
          commentId = docPath['commentId'];

          const videoDoc = await videosRef.doc(videoId!).get();
          recipientId = videoDoc.data()?.userId;

          const senderDoc = await usersRef.doc(senderId).get();
          const senderName = senderDoc.data()?.username ?? 'Someone';
          message = `@${senderName} 评论了你的视频`;
          break;
        }

        default:
          console.log('Unknown collection trigger, skipping');
          return;
      }

      // Don't notify self
      if (recipientId === senderId) return;

      // Create notification document
      await notificationsRef.add({
        recipientId,
        senderId,
        type,
        videoId,
        commentId,
        message,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Send FCM push
      const recipientDoc = await usersRef.doc(recipientId).get();
      const fcmToken = recipientDoc.data()?.fcmToken;

      if (fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: 'ShortVideo',
            body: message,
          },
          data: {
            type,
            senderId,
            ...(videoId && { videoId }),
            ...(commentId && { commentId }),
          },
        });
      }

      console.log(`Notification sent: ${type} from ${senderId} to ${recipientId}`);
    } catch (error) {
      console.error('Failed to send notification:', error);
    }
  }
);
