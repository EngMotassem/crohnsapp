const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Cloud Function to send push notifications
exports.sendNotification = functions.https.onCall(async (data, context) => {
  // Verify the user is authenticated and is an admin
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { title, body, targetAudience } = data;

  if (!title || !body || !targetAudience) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  try {
    // Get users based on target audience
    let usersQuery = db.collection('users');
    
    if (targetAudience !== 'all') {
      usersQuery = usersQuery.where('role', '==', targetAudience);
    }

    const usersSnapshot = await usersQuery.get();
    const tokens = [];

    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
        tokens.push(...userData.fcmTokens);
      }
    });

    if (tokens.length === 0) {
      return { success: true, message: 'No users with FCM tokens found', sentCount: 0 };
    }

    // Remove duplicate tokens
    const uniqueTokens = [...new Set(tokens)];

    // Send notifications in batches of 500 (FCM limit)
    const batchSize = 500;
    let successCount = 0;
    let failureCount = 0;

    for (let i = 0; i < uniqueTokens.length; i += batchSize) {
      const batch = uniqueTokens.slice(i, i + batchSize);
      
      const message = {
        notification: {
          title: title,
          body: body,
        },
        tokens: batch,
      };

      const response = await messaging.sendEachForMulticast(message);
      successCount += response.successCount;
      failureCount += response.failureCount;

      // Remove invalid tokens
      response.responses.forEach((resp, idx) => {
        if (!resp.success && resp.error) {
          const errorCode = resp.error.code;
          if (errorCode === 'messaging/invalid-registration-token' ||
              errorCode === 'messaging/registration-token-not-registered') {
            // Remove invalid token from user's fcmTokens
            const invalidToken = batch[idx];
            removeInvalidToken(invalidToken);
          }
        }
      });
    }

    // Save notification to history
    await db.collection('notifications').add({
      title: title,
      body: body,
      targetAudience: targetAudience,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      successCount: successCount,
      failureCount: failureCount,
      totalTokens: uniqueTokens.length,
    });

    return {
      success: true,
      message: `Notification sent to ${successCount} devices`,
      sentCount: successCount,
      failedCount: failureCount,
    };

  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});

// Helper function to remove invalid tokens
async function removeInvalidToken(token) {
  try {
    const usersSnapshot = await db.collection('users')
      .where('fcmTokens', 'array-contains', token)
      .get();

    const batch = db.batch();
    usersSnapshot.forEach((doc) => {
      batch.update(doc.ref, {
        fcmTokens: admin.firestore.FieldValue.arrayRemove(token),
      });
    });

    await batch.commit();
  } catch (error) {
    console.error('Error removing invalid token:', error);
  }
}

// Trigger when a new notification is created (alternative approach)
exports.onNotificationCreated = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    // Skip if already processed (has sentCount)
    if (notification.sentCount !== undefined) {
      return null;
    }

    const { title, body, targetAudience } = notification;

    if (!title || !body) {
      return null;
    }

    try {
      let usersQuery = db.collection('users');
      
      if (targetAudience && targetAudience !== 'all') {
        usersQuery = usersQuery.where('role', '==', targetAudience);
      }

      const usersSnapshot = await usersQuery.get();
      const tokens = [];

      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
          tokens.push(...userData.fcmTokens);
        }
      });

      if (tokens.length === 0) {
        await snap.ref.update({ sentCount: 0, status: 'no_tokens' });
        return null;
      }

      const uniqueTokens = [...new Set(tokens)];
      
      const message = {
        notification: {
          title: title,
          body: body,
        },
        tokens: uniqueTokens.slice(0, 500), // FCM limit
      };

      const response = await messaging.sendEachForMulticast(message);
      
      await snap.ref.update({
        sentCount: response.successCount,
        failedCount: response.failureCount,
        status: 'sent',
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    } catch (error) {
      console.error('Error in onNotificationCreated:', error);
      await snap.ref.update({ status: 'error', error: error.message });
      return null;
    }
  });
