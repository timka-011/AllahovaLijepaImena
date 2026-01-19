package com.example.lijep_allahov_imena

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.lijep_allahov_imena/alarm"
    private val NAV_CHANNEL = "com.example.lijep_allahov_imena/navigation"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleDailyAlarm" -> {
                    val hour = call.argument<Int>("hour") ?: 9
                    val minute = call.argument<Int>("minute") ?: 0
                    scheduleDailyAlarm(hour, minute)
                    result.success(true)
                }
                "cancelAlarm" -> {
                    cancelAlarm()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Provjeri da li je aplikacija otvorena iz notifikacije
        val navChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NAV_CHANNEL)
        intent?.extras?.getInt("day_index", -1)?.let { dayIndex ->
            if (dayIndex >= 0) {
                android.util.Log.d("MainActivity", "Otvoreno iz notifikacije za dan: $dayIndex")
                navChannel.invokeMethod("openMessageDetail", dayIndex)
            }
        }
    }

    private fun scheduleDailyAlarm(hour: Int, minute: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        // Provjeri da li imamo permisiju za exact alarms na Android 12+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!alarmManager.canScheduleExactAlarms()) {
                android.util.Log.e("MainActivity", "Nema permisije za exact alarms!")
                // Otvori postavke da korisnik omogući permisiju
                val intent = Intent(android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                startActivity(intent)
                return
            }
        }
        
        val intent = Intent(this, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val calendar = Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            
            // Ako je vrijeme već prošlo danas, zakaži za sutra
            if (timeInMillis <= System.currentTimeMillis()) {
                add(Calendar.DAY_OF_MONTH, 1)
            }
        }

        android.util.Log.d("MainActivity", "Zakazivanje alarma za: ${calendar.time}")

        // Zakaži alarm
        try {
            // Za Android 12+ koristimo setExactAndAllowWhileIdle sa repeating logikom
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    // Koristimo setExact umjesto setRepeating jer je pouzdaniji
                    alarmManager.setExact(
                        AlarmManager.RTC_WAKEUP,
                        calendar.timeInMillis,
                        pendingIntent
                    )
                    android.util.Log.d("MainActivity", "Alarm zakazan sa setExact (Android 12+)")
                } else {
                    android.util.Log.e("MainActivity", "Nema permisije za exact alarms")
                }
            } else {
                alarmManager.setRepeating(
                    AlarmManager.RTC_WAKEUP,
                    calendar.timeInMillis,
                    AlarmManager.INTERVAL_DAY,
                    pendingIntent
                )
                android.util.Log.d("MainActivity", "Alarm uspješno zakazan (stari Android)")
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Greška pri zakazivanju alarma: ${e.message}")
        }
    }

    private fun cancelAlarm() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }
}

