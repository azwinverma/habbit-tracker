package com.daily.mantra

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import androidx.core.app.NotificationCompat

class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra("id", 0)
        val spec = AlarmScheduler.get(context, id)

        if (spec == null) {
            // Not in the store => created by a pre-2.0 build.
            if (AlarmScheduler.isLegacyCleanup(context)) {
                // Migration has run and every live reminder was re-created with a
                // new id, so this is a duplicate or an orphan (deleted habit,
                // removed time, finished session). Drop it and do NOT re-arm.
                return
            }
            // Migration hasn't run yet (user hasn't opened the new version):
            // preserve the old behaviour exactly, without persisting.
            val title = intent.getStringExtra("title") ?: "Reminder"
            val body = intent.getStringExtra("body") ?: ""
            showNotification(context, id, title, body)
            if (intent.getBooleanExtra("daily", false)) {
                val hour = intent.getIntExtra("hour", 8)
                val minute = intent.getIntExtra("minute", 0)
                val next = AlarmScheduler.nextDaily(hour, minute, System.currentTimeMillis())
                AlarmScheduler.arm(context, id, next, title, body, true, hour, minute)
            }
            return
        }

        val title = spec.optString("title", "Reminder")
        val body = spec.optString("body", "")
        showNotification(context, id, title, body)

        if (spec.optBoolean("daily", false)) {
            val hour = spec.optInt("hour", 8)
            val minute = spec.optInt("minute", 0)
            val end = if (spec.has("end")) spec.optLong("end") else null
            val next = AlarmScheduler.nextDaily(hour, minute, System.currentTimeMillis())
            if (end != null && next > end) {
                AlarmScheduler.remove(context, id) // e.g. medicine course finished
            } else {
                AlarmScheduler.schedule(context, id, next, title, body, true, hour, minute, end)
            }
        } else {
            AlarmScheduler.remove(context, id)
        }
    }

    private fun showNotification(context: Context, id: Int, title: String, body: String) {
        val channelId = "habit_channel_native_v1"
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                channelId, "Habit Reminders",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Daily habit reminder notifications"
                enableLights(true)
                lightColor = Color.GREEN
                enableVibration(true)
            }
            nm.createNotificationChannel(ch)
        }

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val contentPi = PendingIntent.getActivity(
            context, id, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notif = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(contentPi)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .build()

        nm.notify(id, notif)
    }
}
