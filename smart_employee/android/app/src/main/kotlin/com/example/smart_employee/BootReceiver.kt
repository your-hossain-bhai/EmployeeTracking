// BootReceiver.kt
// Boot Completed Receiver for Smart Employee
//
// This receiver restarts the location service after device reboot
// if the user was tracking before the reboot.

package com.example.smart_employee

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    
    companion object {
        const val PREFS_NAME = "location_service_prefs"
        const val KEY_WAS_RUNNING = "was_running"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val wasRunning = prefs.getBoolean(KEY_WAS_RUNNING, false)
            
            if (wasRunning) {
                // Restart location service
                val serviceIntent = Intent(context, LocationService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        }
    }
}
