package com.example.orderpilot_pro

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createOrderNotificationChannel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isUnsafeNetwork" -> result.success(isProxyEnabled() || isVpnActive())
                    else -> result.notImplemented()
                }
            }
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
        private const val SECURITY_CHANNEL = "orderpilot/security"
    }

    private fun isProxyEnabled(): Boolean {
        val httpProxy = System.getProperty("http.proxyHost").orEmpty()
        val httpsProxy = System.getProperty("https.proxyHost").orEmpty()
        if (httpProxy.isNotBlank() || httpsProxy.isNotBlank()) return true

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                val proxy = Settings.Global.getString(contentResolver, Settings.Global.HTTP_PROXY)
                !proxy.isNullOrBlank() && proxy != ":0"
            } else {
                false
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun isVpnActive(): Boolean {
        return try {
            val manager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val network = manager.activeNetwork ?: return false
                val caps = manager.getNetworkCapabilities(network) ?: return false
                caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)
            } else {
                @Suppress("DEPRECATION")
                manager.allNetworks.any { network ->
                    val caps = manager.getNetworkCapabilities(network)
                    caps?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
                }
            }
        } catch (_: Exception) {
            false
        }
    }
}
