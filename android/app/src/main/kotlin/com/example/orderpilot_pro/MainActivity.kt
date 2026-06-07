package com.example.orderpilot_pro

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createOrderNotificationChannel()
    }

    private fun createOrderNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java)

        val channel = NotificationChannel(
            ORDER_CHANNEL_ID,
            "New order notifications",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "New WooCommerce order alerts"
            enableVibration(false)
            setSound(Settings.System.DEFAULT_NOTIFICATION_URI, null)
            setShowBadge(true)
        }

        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val ORDER_CHANNEL_ID = "orderpilot_default_v4"
    }
}
