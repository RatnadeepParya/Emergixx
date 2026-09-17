/**
 * Emergixx Firebase Cloud Functions
 * Automated event triggers for push notifications, incident aggregation, and retention cleanup.
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Triggered whenever a new emergency SOS alert is written to Firestore.
 * Immediately sends a maximum-priority push notification (FCM) to all registered responders.
 */
exports.onSosCreated = functions.firestore
  .document('emergencies/{sosId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const sosId = context.params.sosId;

    const emergencyType = data.emergencyType || 'GENERAL DISTRESS';
    const sender = data.senderDeviceId || 'Unknown Device';
    const lat = data.latitude ? data.latitude.toFixed(4) : 'N/A';
    const lng = data.longitude ? data.longitude.toFixed(4) : 'N/A';

    const message = {
      topic: 'emergency_responders',
      notification: {
        title: `🚨 EMERGENCY SOS: ${emergencyType}`,
        body: `From ${sender} at (${lat}, ${lng}). Tap for triage.`,
      },
      data: {
        sosId: sosId,
        type: 'SOS_ALERT',
        latitude: String(data.latitude || ''),
        longitude: String(data.longitude || ''),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'emergixx_critical_alerts',
          priority: 'max',
          defaultSound: true,
          defaultVibrateTimings: true,
          color: '#FF3B30',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'emergency_alarm.caf',
            critical: 1,
            volume: 1.0,
          },
        },
      },
    };

    try {
      const response = await admin.messaging().send(message);
      console.log(`[FCM] Successfully sent emergency push notification for SOS ${sosId}:`, response);
      return response;
    } catch (error) {
      console.error(`[FCM] Error sending emergency notification for SOS ${sosId}:`, error);
      return null;
    }
  });

/**
 * Triggered on new safety check-in.
 * Updates family circle notifications and sector headcount counters.
 */
exports.onCheckInCreated = functions.firestore
  .document('checkins/{checkinId}')
  .onCreate(async (snap, context) => {
    const checkin = snap.data();
    const groupId = checkin.groupId;

    if (groupId) {
      const notification = {
        topic: `group_${groupId}`,
        notification: {
          title: `Safety Check-In: ${checkin.displayName || checkin.deviceId}`,
          body: `Status: ${checkin.status} • "${checkin.note || 'No notes'}"`,
        },
        data: {
          checkinId: context.params.checkinId,
          type: 'SAFETY_CHECKIN',
          groupId: groupId,
        },
      };

      try {
        await admin.messaging().send(notification);
        console.log(`[FCM] Check-in notification sent to group_${groupId}`);
      } catch (err) {
        console.error(`[FCM] Failed to notify group:`, err);
      }
    }
  });

/**
 * Scheduled Cron Job: Runs every 6 hours.
 * Enforces data retention and privacy policies by purging expired mesh transit packets older than TTL.
 */
exports.pruneExpiredMessagesCron = functions.pubsub
  .schedule('every 6 hours')
  .onRun(async (context) => {
    const now = Date.now();
    const db = admin.firestore();

    console.log(`[Retention] Executing scheduled expired packet cleanup at ${new Date(now).toISOString()}`);

    const expiredQuery = db
      .collection('messages')
      .where('expiresAt', '<', now)
      .limit(500);

    const snapshot = await expiredQuery.get();
    if (snapshot.empty) {
      console.log('[Retention] No expired packets found.');
      return null;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`[Retention] Successfully purged ${snapshot.size} expired packets.`);
    return snapshot.size;
  });
