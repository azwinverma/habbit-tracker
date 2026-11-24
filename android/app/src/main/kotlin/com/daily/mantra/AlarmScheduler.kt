package com.daily.mantra

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import org.json.JSONObject
import java.util.Calendar

/**
 * Single native scheduler for all DailyMantra reminders.
 *
 * Every armed alarm is also persisted in [PREFS] so that it can be restored
 * after a reboot / app update / clock change (see [BootReceiver]) and so that
 * [AlarmReceiver] can tell real alarms apart from orphans left by older builds.
 */
object AlarmScheduler {
    private const val TAG = "DMAlarm"
    private const val PREFS = "dm_alarm_store"
    private const val KEY_PREFIX = "a_"
    private const val KEY_LEGACY_CLEANUP = "legacy_cleanup"

    // android_alarm_manager_plus persistence (pre-2.0 scheduler)
    private const val PLUGIN_PREFS = "dev.fluttercommunity.plus.android_alarm_manager_plugin"
    private const val PLUGIN_IDS_KEY = "persistent_alarm_ids"

    fun schedule(
        context: Context,
        id: Int,
        atMillis: Long,
        title: String,
        body: String,
        daily: Boolean,
        hour: Int,
        minute: Int,
        endMillis: Long?,
        dose: String? = null,
        doseDay: String? = null
    ) {
        val spec = JSONObject().apply {
            put("id", id)
            put("at", atMillis)
            put("title", title)
            put("body", body)
            put("daily", daily)
            put("hour", hour)
            put("minute", minute)
            if (endMillis != null) put("end", endMillis)
            if (dose != null) put("dose", dose)
            if (doseDay != null) put("doseDay", doseDay)
        }
        prefs(context).edit().putString(KEY_PREFIX + id, spec.toString()).apply()
        arm(context, id, atMillis, title, body, daily, hour, minute)
    }

    fun cancel(context: Context, id: Int) {
        prefs(context).edit().remove(KEY_PREFIX + id).apply()
        val pi = PendingIntent.getBroadcast(
            context, id, Intent(context, AlarmReceiver::class.java),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        ) ?: return
        alarmManager(context).cancel(pi)
        pi.cancel()
    }

    fun get(context: Context, id: Int): JSONObject? =
        prefs(context).getString(KEY_PREFIX + id, null)?.let {
            try { JSONObject(it) } catch (e: Exception) { null }
        }

    fun remove(context: Context, id: Int) {
        prefs(context).edit().remove(KEY_PREFIX + id).apply()
    }

    fun scheduledIds(context: Context): List<Int> =
        prefs(context).all.keys
            .filter { it.startsWith(KEY_PREFIX) }
            .mapNotNull { it.removePrefix(KEY_PREFIX).toIntOrNull() }

    fun isLegacyCleanup(context: Context): Boolean =
        prefs(context).getBoolean(KEY_LEGACY_CLEANUP, false)

    fun enableLegacyCleanup(context: Context) {
        prefs(context).edit().putBoolean(KEY_LEGACY_CLEANUP, true).apply()
    }

    fun legacyPluginAlarmIds(context: Context): List<Int> =
        context.getSharedPreferences(PLUGIN_PREFS, Context.MODE_PRIVATE)
            .getStringSet(PLUGIN_IDS_KEY, emptySet())
            .orEmpty()
            .mapNotNull { it.toIntOrNull() }

    fun canScheduleExact(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager(context).canScheduleExactAlarms()

    /** Re-arms everything in the store. Called after boot, update, time/zone change. */
    fun rescheduleAll(context: Context) {
        val now = System.currentTimeMillis()
        for (id in scheduledIds(context)) {
            val s = get(context, id) ?: continue
            val daily = s.optBoolean("daily", false)
            val title = s.optString("title", "Reminder")
            val body = s.optString("body", "")
            val hour = s.optInt("hour", 8)
            val minute = s.optInt("minute", 0)
            val at = s.optLong("at", 0L)
            if (daily) {
                // Respect a future start (e.g. medicine course not started yet),
                // otherwise recompute from wall-clock time (handles timezone change).
                val next = nextDaily(hour, minute, now, notBefore = maxOf(now, dayStart(at)))
                val end = if (s.has("end")) s.optLong("end") else null
                if (end != null && next > end) { remove(context, id); continue }
                schedule(context, id, next, title, body, true, hour, minute, end, s.optStringOrNull("dose"))
            } else {
                // One-shot that was missed while the device was off: drop it.
                if (at <= now) { remove(context, id); continue }
                // (dose/doseDay stay in the store; the receiver reads them from there.)
                arm(context, id, at, title, body, false, hour, minute)
            }
        }
    }

    /** Next [hour]:[minute] strictly after [now] and on/after the day of [notBefore]. DST-safe. */
    fun nextDaily(hour: Int, minute: Int, now: Long, notBefore: Long = now): Long {
        val cal = Calendar.getInstance().apply {
            timeInMillis = notBefore
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        while (cal.timeInMillis <= now) cal.add(Calendar.DATE, 1)
        return cal.timeInMillis
    }

    /**
     * Arms the OS alarm without touching the store. Uses an exact alarm when
     * permitted; otherwise (Android 12+ with SCHEDULE_EXACT_ALARM denied, the
     * default for new installs on Android 14+) falls back to an inexact
     * allow-while-idle alarm instead of crashing or silently doing nothing.
     */
    fun arm(
        context: Context, id: Int, atMillis: Long, title: String, body: String,
        daily: Boolean, hour: Int, minute: Int
    ) {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("title", title)
            putExtra("body", body)
            putExtra("daily", daily)
            putExtra("hour", hour)
            putExtra("minute", minute)
        }
        val pi = PendingIntent.getBroadcast(
            context, id, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val am = alarmManager(context)
        try {
            if (canScheduleExact(context)) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pi)
            } else {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pi)
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "Exact alarm not permitted, using inexact for $id", e)
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pi)
        }
    }

    // ---- Medicine dose actions (notification buttons) ----

    private const val DOSE_PREFS = "dm_dose_actions"
    private const val DOSE_KEY = "pending"

    /** Queues "<habitId>|YYYY-MM-DD|HH:mm|taken" for the app to import on next open. */
    fun recordDoseAction(context: Context, line: String) {
        val p = context.getSharedPreferences(DOSE_PREFS, Context.MODE_PRIVATE)
        synchronized(this) {
            val arr = try { org.json.JSONArray(p.getString(DOSE_KEY, "[]")) } catch (e: Exception) { org.json.JSONArray() }
            arr.put(line)
            p.edit().putString(DOSE_KEY, arr.toString()).commit()
        }
    }

    /** Returns and clears the queued dose actions. */
    fun drainDoseActions(context: Context): List<String> {
        val p = context.getSharedPreferences(DOSE_PREFS, Context.MODE_PRIVATE)
        synchronized(this) {
            val arr = try { org.json.JSONArray(p.getString(DOSE_KEY, "[]")) } catch (e: Exception) { org.json.JSONArray() }
            p.edit().remove(DOSE_KEY).commit()
            return (0 until arr.length()).map { arr.getString(it) }
        }
    }

    /** Request code for a snoozed copy of alarm [id]; distinct from Dart's ids in practice. */
    fun snoozeId(id: Int): Int = (id xor 0x5A5A5A5A) and 0x7FFFFFFF

    private fun dayStart(millis: Long): Long = Calendar.getInstance().apply {
        timeInMillis = millis
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }.timeInMillis

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun alarmManager(context: Context) =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
}

internal fun JSONObject.optStringOrNull(key: String): String? =
    if (has(key) && !isNull(key)) optString(key) else null
