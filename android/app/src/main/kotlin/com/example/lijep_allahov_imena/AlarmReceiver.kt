package com.example.lijep_allahov_imena

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        android.util.Log.d("AlarmReceiver", "Alarm primljen!")
        createNotificationChannel(context)
        showNotification(context)
        
        // Zakaži sledeći alarm za sutra u isto vrijeme
        rescheduleAlarm(context)
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Dnevne Poruke"
            val descriptionText = "Dnevne poruke sa Allahovim imenima"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel("daily_messages", name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showNotification(context: Context) {
        // Učitaj trenutni dan iz SharedPreferences
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val startDateStr = prefs.getString("flutter.notification_start_date", null)
        val currentDay = if (startDateStr != null) {
            val startDate = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.getDefault()).parse(startDateStr)
            val now = java.util.Date()
            val diff = now.time - startDate.time
            val days = (diff / (1000 * 60 * 60 * 24)).toInt()
            days % 30 //循環 kroz 30 poruka
        } else {
            0
        }
        
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("day_index", currentDay)
        }
        val pendingIntent: PendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, "daily_messages")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Allahovo ime")
            .setContentText("Kliknite da vidite današnju poruku - Dan ${currentDay + 1}")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        try {
            with(NotificationManagerCompat.from(context)) {
                // Provjeri da li imamo permisiju
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU || 
                    context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    notify(1001, builder.build())
                    android.util.Log.d("AlarmReceiver", "Notifikacija poslata za dan: $currentDay")
                } else {
                    android.util.Log.e("AlarmReceiver", "Nema permisije za notifikacije")
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("AlarmReceiver", "Greška pri slanju notifikacije: ${e.message}")
        }
    }
    
    private fun rescheduleAlarm(context: Context) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val hour = prefs.getInt("flutter.notification_hour", 9)
        val minute = prefs.getInt("flutter.notification_minute", 0)
        
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java)
        val pendingIntent = android.app.PendingIntent.getBroadcast(
            context, 0, intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        
        val calendar = java.util.Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            add(java.util.Calendar.DAY_OF_MONTH, 1) // Sutra
            set(java.util.Calendar.HOUR_OF_DAY, hour)
            set(java.util.Calendar.MINUTE, minute)
            set(java.util.Calendar.SECOND, 0)
        }
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExact(
                        android.app.AlarmManager.RTC_WAKEUP,
                        calendar.timeInMillis,
                        pendingIntent
                    )
                    android.util.Log.d("AlarmReceiver", "Novi alarm zakazan za: ${calendar.time}")
                }
            } else {
                alarmManager.setExact(
                    android.app.AlarmManager.RTC_WAKEUP,
                    calendar.timeInMillis,
                    pendingIntent
                )
                android.util.Log.d("AlarmReceiver", "Novi alarm zakazan za: ${calendar.time}")
            }
        } catch (e: Exception) {
            android.util.Log.e("AlarmReceiver", "Greška pri zakazivanju novog alarma: ${e.message}")
        }
    }
}
