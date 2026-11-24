package com.daily.mantra

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Handles the "Taken" / "Snooze" buttons on medicine notifications.
 *
 * "Taken" is queued in SharedPreferences ([AlarmScheduler.recordDoseAction]) and
 * imported into the app database the next time the app opens — the app does
 * not need to be running. "Snooze" re-arms a one-shot copy of the reminder.
 */
class DoseActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val notifId = intent.getIntExtra(EXTRA_NOTIF_ID, 0)
        val dose = intent.getStringExtra(EXTRA_DOSE) ?: return // "<habitId>|HH:mm"
        val day = intent.getStringExtra(EXTRA_DAY) ?: today()
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        when (intent.action) {
            ACTION_TAKEN -> {
                val sep = dose.lastIndexOf('|')
                if (sep <= 0) return
                val habitId = dose.substring(0, sep)
                val hhmm = dose.substring(sep + 1)
                AlarmScheduler.recordDoseAction(context, "$habitId|$day|$hhmm|taken")
                nm.cancel(notifId)
            }
            ACTION_SNOOZE -> {
                val title = intent.getStringExtra(EXTRA_TITLE) ?: "Medicine Reminder"
                val body = intent.getStringExtra(EXTRA_BODY) ?: ""
                val snoozeId = AlarmScheduler.snoozeId(notifId)
                val at = System.currentTimeMillis() + SNOOZE_MILLIS
                val cal = java.util.Calendar.getInstance().apply { timeInMillis = at }
                AlarmScheduler.schedule(
                    context, snoozeId, at, title, body, false,
                    cal.get(java.util.Calendar.HOUR_OF_DAY), cal.get(java.util.Calendar.MINUTE), null,
                    dose,
                    doseDay = day // "Taken" after midnight still lands on the dose's day
                )
                nm.cancel(notifId)
            }
        }
    }

    companion object {
        const val ACTION_TAKEN = "com.daily.mantra.DOSE_TAKEN"
        const val ACTION_SNOOZE = "com.daily.mantra.DOSE_SNOOZE"
        private const val EXTRA_NOTIF_ID = "notifId"
        private const val EXTRA_DOSE = "dose"
        private const val EXTRA_DAY = "day"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_BODY = "body"
        private const val SNOOZE_MILLIS = 10 * 60 * 1000L

        fun today(): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

        fun pendingIntent(
            context: Context, notifId: Int, action: String, dose: String, day: String,
            title: String, body: String
        ): PendingIntent {
            val i = Intent(context, DoseActionReceiver::class.java).apply {
                this.action = action
                putExtra(EXTRA_NOTIF_ID, notifId)
                putExtra(EXTRA_DOSE, dose)
                putExtra(EXTRA_DAY, day)
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_BODY, body)
            }
            // Distinct request code per (notification, action).
            val code = notifId * 31 + action.hashCode()
            return PendingIntent.getBroadcast(
                context, code, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }
}
