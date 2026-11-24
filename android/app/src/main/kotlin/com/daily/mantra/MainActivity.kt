package com.daily.mantra

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "habit_alarms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "scheduleExact" -> {
                        // Dart ints > 2^31 arrive as Long; read as Number to avoid
                        // ClassCastException crashes.
                        val id = call.argument<Number>("id")!!.toInt()
                        val epochMillis = call.argument<Number>("epochMillis")!!.toLong()
                        val title = call.argument<String>("title") ?: "Reminder"
                        val body = call.argument<String>("body") ?: ""
                        val daily = call.argument<Boolean>("daily") ?: false
                        val hour = call.argument<Number>("hour")?.toInt() ?: 8
                        val minute = call.argument<Number>("minute")?.toInt() ?: 0
                        val endMillis = call.argument<Number>("endMillis")?.toLong()
                        AlarmScheduler.schedule(this, id, epochMillis, title, body, daily, hour, minute, endMillis)
                        result.success(null)
                    }
                    "cancel" -> {
                        AlarmScheduler.cancel(this, call.argument<Number>("id")!!.toInt())
                        result.success(null)
                    }
                    "enableLegacyCleanup" -> {
                        AlarmScheduler.enableLegacyCleanup(this)
                        result.success(null)
                    }
                    "legacyPluginAlarmIds" -> result.success(AlarmScheduler.legacyPluginAlarmIds(this))
                    "scheduledIds" -> result.success(AlarmScheduler.scheduledIds(this))
                    "canScheduleExact" -> result.success(AlarmScheduler.canScheduleExact(this))
                    "openExactAlarmSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            startActivity(
                                Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                                    .setData(Uri.parse("package:$packageName"))
                            )
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("ALARM_ERROR", e.message, null)
            }
        }
    }
}
