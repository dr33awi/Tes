package com.example.test_athkar_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.provider.Settings
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Handler for Do Not Disturb related operations on Android
 */
class DoNotDisturbHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isInDoNotDisturbMode" -> {
                result.success(isInDoNotDisturbMode())
            }
            "canBypassDoNotDisturb" -> {
                result.success(canBypassDoNotDisturb())
            }
            "configureNotificationChannelsForDoNotDisturb" -> {
                configureNotificationChannelsForDoNotDisturb()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Check if the device is currently in Do Not Disturb mode
     */
    private fun isInDoNotDisturbMode(): Boolean {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            notificationManager.currentInterruptionFilter != NotificationManager.INTERRUPTION_FILTER_ALL
        } else {
            try {
                val zenMode = Settings.Global.getInt(context.contentResolver, "zen_mode")
                zenMode != 0
            } catch (e: Exception) {
                false
            }
        }
    }

    /**
     * Check if the app has permission to bypass Do Not Disturb
     */
    private fun canBypassDoNotDisturb(): Boolean {
        // For Android O and above, check if any notification channel can bypass DND
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channels = notificationManager.notificationChannels

            for (channel in channels) {
                if (channel.canBypassDnd()) {
                    return true
                }
            }
            return false
        } else {
            // For earlier versions, check if notification policy access is granted
            val notificationManager = NotificationManagerCompat.from(context)
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                notificationManager.areNotificationsEnabled() && 
                        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).isNotificationPolicyAccessGranted
            } else {
                notificationManager.areNotificationsEnabled()
            }
        }
    }

    /**
     * Configure notification channels to bypass Do Not Disturb
     */
    private fun configureNotificationChannelsForDoNotDisturb() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Configure main channel
            configureChannelForDoNotDisturb(
                notificationManager,
                "athkar_channel_id",
                "أذكار",
                "تنبيهات الأذكار",
                NotificationManager.IMPORTANCE_HIGH,
                true
            )
            
            // Configure morning athkar channel
            configureChannelForDoNotDisturb(
                notificationManager,
                "athkar_morning_channel",
                "أذكار الصباح",
                "تنبيهات أذكار الصباح",
                NotificationManager.IMPORTANCE_HIGH,
                true
            )
            
            // Configure evening athkar channel
            configureChannelForDoNotDisturb(
                notificationManager,
                "athkar_evening_channel",
                "أذكار المساء",
                "تنبيهات أذكار المساء",
                NotificationManager.IMPORTANCE_HIGH,
                true
            )
            
            // Configure sleep athkar channel
            configureChannelForDoNotDisturb(
                notificationManager,
                "athkar_sleep_channel",
                "أذكار النوم",
                "تنبيهات أذكار النوم",
                NotificationManager.IMPORTANCE_DEFAULT,
                false // Sleep notifications should respect DND
            )
            
            // Configure prayer athkar channel
            configureChannelForDoNotDisturb(
                notificationManager,
                "athkar_prayer_channel",
                "أذكار الصلاة",
                "تنبيهات أذكار الصلاة",
                NotificationManager.IMPORTANCE_HIGH,
                true
            )
            
            // Configure test channel
            configureChannelForDoNotDisturb(
                notificationManager,
                "athkar_test_channel",
                "اختبار الأذكار",
                "قناة اختبار إشعارات الأذكار",
                NotificationManager.IMPORTANCE_HIGH,
                false
            )
        }
    }
    
    /**
     * Configure a specific notification channel for bypassing Do Not Disturb
     */
    @RequiresApi(Build.VERSION_CODES.O)
    private fun configureChannelForDoNotDisturb(
        notificationManager: NotificationManager,
        channelId: String,
        channelName: String,
        channelDescription: String,
        importance: Int,
        bypassDnd: Boolean
    ) {
        var channel = notificationManager.getNotificationChannel(channelId)
        
        // Create channel if it doesn't exist
        if (channel == null) {
            channel = NotificationChannel(channelId, channelName, importance)
            channel.description = channelDescription
        } else {
            // Update existing channel
            channel.importance = importance
        }
        
        // Configure bypass DND
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            channel.setAllowBubbles(true)
        }
        channel.setBypassDnd(bypassDnd)
        channel.enableVibration(true)
        channel.enableLights(true)
        
        // Save the channel
        notificationManager.createNotificationChannel(channel)
    }
}