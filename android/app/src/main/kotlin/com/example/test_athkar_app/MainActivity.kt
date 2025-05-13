package com.example.test_athkar_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val DND_CHANNEL = "com.athkar.app/do_not_disturb"
    private val BATTERY_CHANNEL = "com.athkar.app/battery_optimization"
    
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
                else -> {
                    result.notImplemented()
                }
            }
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
            val intent = Intent()
            val packageName = packageName
            
            intent.action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
            intent.data = Uri.parse("package:$packageName")
            
            try {
                startActivity(intent)
                return true
            } catch (e: Exception) {
                // Fallback to battery settings if direct request fails
                try {
                    val settingsIntent = Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS)
                    startActivity(settingsIntent)
                    return true
                } catch (e2: Exception) {
                    return false
                }
            }
        }
        return false
    }
}