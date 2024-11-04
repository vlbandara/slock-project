import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const sendUnlockNotification = functions.database
  .ref("/lockState")
  .onUpdate(async (change, context) => {
    const lockState = change.after.val();
    if (lockState === false) {
      const payload = {
        notification: {
          title: "Door Unlocked",
          body: The door was unlocked!,
        },
      };
      await sendNotificationToAllUsers(payload);
    }
    return null;
  });

export const checkFailedAttempts = functions.database
  .ref("/failedAttempts/{pushId}")
  .onCreate(async (snapshot, context) => {
    const now = Date.now();
    const timeWindow = 5 * 60 * 1000; // 5 minutes in milliseconds

    const query = admin
      .database()
      .ref("/failedAttempts")
      .orderByChild("timestamp")
      .startAt(now - timeWindow)
      .endAt(now);

    const failedAttemptsSnapshot = await query.once("value");
    const recentAttempts = failedAttemptsSnapshot.numChildren();

    if (recentAttempts >= 3) {
      const payload = {
        notification: {
          title: "Warning: Multiple Failed Access Attempts",
          body: There have been ${recentAttempts} failed access attempts in the last 5 minutes.,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          status: "failed_attempts",
          count: recentAttempts.toString(),
        },
      };
      await sendNotificationToAllUsers(payload);
    }
    return null;
  });

async function sendNotificationToAllUsers(
  payload: admin.messaging.MessagingPayload
) {
  try {
    const tokensSnapshot = await admin.database().ref("users").once("value");
    const tokens: string[] = [];
    tokensSnapshot.forEach((userSnapshot) => {
      const fcmTokens = userSnapshot.child("fcmTokens").val();
      if (fcmTokens) {
        Object.keys(fcmTokens).forEach((token) => {
          tokens.push(token);
        });
      }
    });

    if (tokens.length > 0) {
      const response = await admin.messaging().sendToDevice(tokens, payload);
      console.log("Notifications sent successfully");

      const tokensToRemove: Promise<void>[] = [];
      response.results.forEach((result, index) => {
        const error = result.error;
        if (error) {
          console.error(
            "Failure sending notification to",
            tokens[index],
            error
          );
          if (
            error.code === "messaging/invalid-registration-token" ||
            error.code === "messaging/registration-token-not-registered"
          ) {
            tokensToRemove.push(
              admin.database().ref(users/${tokens[index]}).remove()
            );
          }
        }
      });
      await Promise.all(tokensToRemove);
    } else {
      console.log("No tokens to send notifications to");
    }
  } catch (error) {
    console.error("Error sending notification:", error);
  }
}
