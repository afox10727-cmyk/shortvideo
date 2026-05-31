/**
 * ShortVideo - Firebase Cloud Functions
 *
 * Functions:
 *   processVideoOnUpload  - Triggers on video doc creation, transcodes to HLS
 *   sendNotificationOnEvent - Triggers on like/follow/comment, sends push
 *   updateCountersOnEvent   - Triggers on like/follow/comment, updates counts
 *   cleanupUserData       - Triggers on user deletion
 */

import * as admin from 'firebase-admin';

admin.initializeApp();

export { processVideoOnUpload } from './processVideo.js';
export { sendNotificationOnEvent } from './sendNotification.js';
export { updateCountersOnEvent } from './updateCounters.js';
export { cleanupUserData } from './cleanupUser.js';
