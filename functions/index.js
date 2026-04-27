const admin = require("firebase-admin");
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

const ALERT_COOLDOWN_MINUTES = 30;
const OFFLINE_TIMEOUT_MINUTES = 3;

exports.notifyOnExcessConsumption = onDocumentWritten(
  "users/{uid}/devices/{deviceId}/sensors/{sensorId}",
  async (event) => {
    const beforeData = event.data.before.exists ? event.data.before.data() : null;
    const afterData = event.data.after.exists ? event.data.after.data() : null;

    if (!afterData) {
      return;
    }

    const uid = event.params.uid;
    const sensorId = event.params.sensorId;
    const sensorName = readSensorName(afterData, sensorId);
    const currentWatts = readNumber(
      afterData.current_watts ?? afterData.watts ?? afterData.value,
    );
    const limitWatts = Math.max(
      1,
      readNumber(afterData.limit_watts ?? afterData.limitWatts, 600),
    );

    const wasAlerting = isAlerting(beforeData);
    const isNowAlerting = currentWatts > limitWatts;
    if (!isNowAlerting || wasAlerting === isNowAlerting) {
      if (wasAlerting && !isNowAlerting) {
        await event.data.after.ref.set(
          {
            alert_active: false,
            alert_recovered_at: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true},
        );
      }
      return;
    }

    const now = Date.now();
    const lastAlertSentAt = toMillis(afterData.last_alert_sent_at);
    const cooldownMs = ALERT_COOLDOWN_MINUTES * 60 * 1000;
    if (lastAlertSentAt && now - lastAlertSentAt < cooldownMs) {
      await event.data.after.ref.set(
        {alert_active: true},
        {merge: true},
      );
      return;
    }

    const tokens = await fetchUserTokens(uid);
    if (!tokens.length) {
      await event.data.after.ref.set(
        {
          alert_active: true,
          last_alert_sent_at: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      return;
    }

    const excess = Math.max(0, Math.round(currentWatts - limitWatts));
    const message = {
      tokens,
      notification: {
        title: "Consumo excessivo detetado",
        body: `${sensorName} ultrapassou o limite em ${excess} W.`,
      },
      data: {
        type: "energy_alert",
        sensorId,
        sensorName,
        currentWatts: String(Math.round(currentWatts)),
        limitWatts: String(Math.round(limitWatts)),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "energy_alerts",
        },
      },
    };

    const response = await messaging.sendEachForMulticast(message);
    await cleanupInvalidTokens(uid, tokens, response.responses);

    await event.data.after.ref.set(
      {
        alert_active: true,
        last_alert_sent_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    await db
      .collection("users")
      .doc(uid)
      .collection("alert_history")
      .add({
        sensor_id: sensorId,
        sensor_name: sensorName,
        current_watts: currentWatts,
        limit_watts: limitWatts,
        excess_watts: excess,
        sent_at: admin.firestore.FieldValue.serverTimestamp(),
      });
  },
);

exports.notifyOnDeviceStatusChange = onDocumentWritten(
  "users/{uid}/devices/{deviceId}",
  async (event) => {
    const beforeData = event.data.before.exists ? event.data.before.data() : null;
    const afterData = event.data.after.exists ? event.data.after.data() : null;

    if (!afterData) {
      return;
    }

    const beforeOnline = readOnlineStatus(beforeData);
    const afterOnline = readOnlineStatus(afterData);

    if (afterOnline === null || beforeOnline === afterOnline) {
      return;
    }

    if (beforeOnline === null && afterOnline === false) {
      return;
    }

    const uid = event.params.uid;
    const deviceId = event.params.deviceId;
    const deviceName = readDeviceName(afterData, deviceId);
    const tokens = await fetchUserTokens(uid);
    const statusText = afterOnline ? "ligado" : "desligado";
    const title = afterOnline ? "Dispositivo ligado" : "Dispositivo desligado";
    const body = `${deviceName} está ${statusText}.`;

    if (tokens.length) {
      const message = {
        tokens,
        notification: {
          title,
          body,
        },
        data: {
          type: "device_status",
          deviceId,
          deviceName,
          isOnline: String(afterOnline),
        },
        android: {
          priority: "high",
          notification: {
            channelId: "energy_alerts",
          },
        },
      };

      const response = await messaging.sendEachForMulticast(message);
      await cleanupInvalidTokens(uid, tokens, response.responses);
    }

    await event.data.after.ref.set(
      {
        last_status_notification_sent_at: admin.firestore.FieldValue.serverTimestamp(),
        last_status_notification_state: statusText,
      },
      {merge: true},
    );

    await db
      .collection("users")
      .doc(uid)
      .collection("device_status_history")
      .add({
        device_id: deviceId,
        device_name: deviceName,
        is_online: afterOnline,
        status: statusText,
        sent_at: admin.firestore.FieldValue.serverTimestamp(),
      });
  },
);

exports.markStaleDevicesOffline = onSchedule(
  "every 5 minutes",
  async () => {
    const cutoffMs = Date.now() - OFFLINE_TIMEOUT_MINUTES * 60 * 1000;
    const snapshot = await db
      .collectionGroup("devices")
      .where("is_online", "==", true)
      .get();

    const batch = db.batch();
    let updates = 0;

    snapshot.docs.forEach((doc) => {
      const lastSeenMs = toMillis(doc.data().last_seen);

      if (!lastSeenMs || lastSeenMs >= cutoffMs) {
        return;
      }

      batch.set(
        doc.ref,
        {
          is_online: false,
          offline_detected_at: admin.firestore.FieldValue.serverTimestamp(),
          offline_reason: "heartbeat_timeout",
        },
        {merge: true},
      );
      updates += 1;
    });

    if (updates > 0) {
      await batch.commit();
    }
  },
);

function readSensorName(data, fallback) {
  const name = (data.name ?? data.sensor_name ?? "").toString().trim();
  return name || fallback;
}

function readDeviceName(data, fallback) {
  const name = (data.name ?? data.device_name ?? "").toString().trim();
  return name || fallback;
}

function readOnlineStatus(data) {
  if (!data || data.is_online === undefined) {
    return null;
  }
  if (typeof data.is_online === "boolean") {
    return data.is_online;
  }
  if (typeof data.is_online === "string") {
    const normalized = data.is_online.trim().toLowerCase();
    if (["true", "1", "online", "ligado"].includes(normalized)) {
      return true;
    }
    if (["false", "0", "offline", "desligado"].includes(normalized)) {
      return false;
    }
  }
  return null;
}

function readNumber(value, fallback = 0) {
  if (typeof value === "number") {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number.parseFloat(value.replace(",", "."));
    return Number.isFinite(parsed) ? parsed : fallback;
  }
  return fallback;
}

function isAlerting(data) {
  if (!data) {
    return false;
  }
  const currentWatts = readNumber(data.current_watts ?? data.watts ?? data.value);
  const limitWatts = Math.max(1, readNumber(data.limit_watts ?? data.limitWatts, 600));
  return currentWatts > limitWatts || data.alert_active === true;
}

function toMillis(value) {
  if (!value) {
    return null;
  }
  if (typeof value.toMillis === "function") {
    return value.toMillis();
  }
  if (value instanceof Date) {
    return value.getTime();
  }
  if (typeof value === "number") {
    return value;
  }
  return null;
}

async function fetchUserTokens(uid) {
  const snapshot = await db
    .collection("users")
    .doc(uid)
    .collection("notification_tokens")
    .get();

  return snapshot.docs
    .map((doc) => doc.data().token)
    .filter((token) => typeof token === "string" && token.length > 0);
}

async function cleanupInvalidTokens(uid, tokens, responses) {
  const removals = [];
  for (let index = 0; index < responses.length; index += 1) {
    const result = responses[index];
    if (result.success) {
      continue;
    }

    const code = result.error?.code ?? "";
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-argument"
    ) {
      removals.push(
        db
          .collection("users")
          .doc(uid)
          .collection("notification_tokens")
          .doc(tokens[index])
          .delete(),
      );
    }
  }

  await Promise.all(removals);
}
