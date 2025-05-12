package com.example.test_athkar_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.androidalarmmanager.AndroidAlarmManagerPlugin

class MainActivity: FlutterActivity() {
    private val DND_CHANNEL = "com.athkar.app/do_not_disturb"
    private val BATTERY_CHANNEL = "com.athkar.app/battery_optimization"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // تسجيل AndroidAlarmManagerPlugin
        if (flutterEngine != null) {
            AndroidAlarmManagerPlugin.registerWith(flutterEngine!!.plugins)
        }
        
        // إنشاء قنوات الإشعارات الافتراضية عند بدء التطبيق
        createNotificationChannels()
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up the method channel for Do Not Disturb
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DND_CHANNEL).setMethodCallHandler(
            DoNotDisturbHandler(applicationContext)
        )
        
        // Set up the method channel for Battery Optimization
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBatteryOptimizationEnabled" -> {
                    result.success(isBatteryOptimizationEnabled())
                }
                "requestBatteryOptimizationDisable" -> {
                    result.success(requestBatteryOptimizationDisable())
                }
                "openManufacturerSpecificSettings" -> {
                    val manufacturer = call.argument<String>("manufacturer")
                    result.success(openManufacturerSpecificSettings(manufacturer))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    // إنشاء قنوات الإشعارات الافتراضية
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // القناة الافتراضية للأذكار
            val defaultChannel = NotificationChannel(
                "athkar_channel_id",
                "إشعارات الأذكار",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "إشعارات تذكير بالأذكار اليومية"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                setBypassDnd(true) // تجاوز وضع عدم الإزعاج
            }
            
            // قناة الإشعارات المجدولة
            val scheduledChannel = NotificationChannel(
                "scheduled_channel",
                "الإشعارات المجدولة",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "إشعارات مجدولة مسبقاً"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                setBypassDnd(true)
            }
            
            // قناة ذات أولوية عالية
            val highPriorityChannel = NotificationChannel(
                "high_priority_channel",
                "إشعارات مهمة",
                NotificationManager.IMPORTANCE_MAX
            ).apply {
                description = "إشعارات ذات أولوية عالية"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                setBypassDnd(true)
            }
            
            // إنشاء القنوات
            notificationManager.createNotificationChannel(defaultChannel)
            notificationManager.createNotificationChannel(scheduledChannel)
            notificationManager.createNotificationChannel(highPriorityChannel)
        }
    }
    
    // Check if battery optimization is enabled for the app
    private fun isBatteryOptimizationEnabled(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            val packageName = packageName
            return !powerManager.isIgnoringBatteryOptimizations(packageName)
        }
        return false
    }
    
    // Request to disable battery optimization
    private fun requestBatteryOptimizationDisable(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent()
                val packageName = packageName
                
                // طلب مباشر لتعطيل تحسين البطارية
                intent.action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                intent.data = Uri.parse("package:$packageName")
                
                startActivity(intent)
                return true
            } catch (e: Exception) {
                // في حالة الفشل، افتح إعدادات البطارية العامة
                try {
                    val settingsIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                    startActivity(settingsIntent)
                    return true
                } catch (e2: Exception) {
                    try {
                        val fallbackIntent = Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS)
                        startActivity(fallbackIntent)
                        return true
                    } catch (e3: Exception) {
                        return false
                    }
                }
            }
        }
        return false
    }
    
    // Open manufacturer-specific settings
    private fun openManufacturerSpecificSettings(manufacturer: String?): Boolean {
        if (manufacturer == null) return false
        
        val intent = Intent()
        
        try {
            when (manufacturer.toLowerCase()) {
                "xiaomi", "redmi", "poco" -> {
                    intent.component = android.content.ComponentName(
                        "com.miui.securitycenter",
                        "com.miui.permcenter.autostart.AutoStartManagementActivity"
                    )
                }
                "samsung" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        intent.component = android.content.ComponentName(
                            "com.samsung.android.lool",
                            "com.samsung.android.sm.ui.battery.BatteryActivity"
                        )
                    }
                }
                "huawei", "honor" -> {
                    // محاولة الأولى
                    intent.component = android.content.ComponentName(
                        "com.huawei.systemmanager",
                        "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                    )
                    try {
                        startActivity(intent)
                        return true
                    } catch (e: Exception) {
                        // المحاولة الثانية
                        intent.component = android.content.ComponentName(
                            "com.huawei.systemmanager",
                            "com.huawei.systemmanager.optimize.process.ProtectActivity"
                        )
                    }
                }
                "oppo", "realme" -> {
                    // محاولة الأولى لـ ColorOS 7+
                    intent.component = android.content.ComponentName(
                        "com.oplus.battery",
                        "com.oplus.battery.BatteryActivity"
                    )
                    try {
                        startActivity(intent)
                        return true
                    } catch (e: Exception) {
                        // المحاولة الثانية للإصدارات الأقدم
                        intent.component = android.content.ComponentName(
                            "com.coloros.safecenter",
                            "com.coloros.safecenter.permission.startup.StartupAppListActivity"
                        )
                    }
                }
                "vivo" -> {
                    // محاولة الأولى
                    intent.component = android.content.ComponentName(
                        "com.vivo.permissionmanager",
                        "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
                    )
                    try {
                        startActivity(intent)
                        return true
                    } catch (e: Exception) {
                        // المحاولة الثانية
                        intent.component = android.content.ComponentName(
                            "com.iqoo.secure",
                            "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"
                        )
                    }
                }
                "oneplus" -> {
                    intent.component = android.content.ComponentName(
                        "com.oneplus.security",
                        "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"
                    )
                }
                "asus" -> {
                    intent.component = android.content.ComponentName(
                        "com.asus.mobilemanager",
                        "com.asus.mobilemanager.autostart.AutoStartActivity"
                    )
                }
                "letv" -> {
                    intent.component = android.content.ComponentName(
                        "com.letv.android.letvsafe",
                        "com.letv.android.letvsafe.AutobootManageActivity"
                    )
                }
                "lenovo" -> {
                    intent.component = android.content.ComponentName(
                        "com.lenovo.security",
                        "com.lenovo.security.purebackground.PureBackgroundActivity"
                    )
                }
                else -> {
                    // Default to battery optimization settings
                    return requestBatteryOptimizationDisable()
                }
            }
            
            startActivity(intent)
            return true
        } catch (e: Exception) {
            // If manufacturer specific settings fail, fall back to general battery settings
            return requestBatteryOptimizationDisable()
        }
    }
}