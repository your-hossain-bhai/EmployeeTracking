// LocationService.kt
// Background Location Service for Smart Employee
//
// This is a foreground service that tracks employee location in the background.
// It uses FusedLocationProviderClient for efficient, battery-aware location updates.
//
// Features:
// - Foreground service with persistent notification
// - Notification actions: Pause/Resume/Stop
// - Configurable update interval and accuracy
// - Streams location updates to Flutter via EventChannel
// - Battery optimization guidance
//
// NOTE: This service requires POST_NOTIFICATIONS, ACCESS_FINE_LOCATION,
// ACCESS_COARSE_LOCATION, ACCESS_BACKGROUND_LOCATION, and FOREGROUND_SERVICE permissions.

package com.example.smart_employee

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import io.flutter.plugin.common.EventChannel

class LocationService : Service() {
    
    companion object {
        const val NOTIFICATION_ID = 1001
        const val CHANNEL_ID = "location_tracking_channel"
        const val CHANNEL_NAME = "Location Tracking"
        
        const val ACTION_PAUSE = "com.example.smart_employee.PAUSE"
        const val ACTION_RESUME = "com.example.smart_employee.RESUME"
        const val ACTION_STOP = "com.example.smart_employee.STOP"
        
        // Event sink for streaming locations to Flutter
        var locationEventSink: EventChannel.EventSink? = null
    }
    
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback
    private var locationRequest: LocationRequest? = null
    
    private var isPaused = false
    private var intervalMs: Long = 30000
    private var fastestIntervalMs: Long = 15000
    private var priority: Int = Priority.PRIORITY_HIGH_ACCURACY
    
    override fun onCreate() {
        super.onCreate()
        
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        
        // Create notification channel for Android O+
        createNotificationChannel()
        
        // Initialize location callback
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    sendLocationToFlutter(location)
                }
            }
            
            override fun onLocationAvailability(availability: LocationAvailability) {
                if (!availability.isLocationAvailable) {
                    // Location is not available, notify Flutter
                    locationEventSink?.error(
                        "LOCATION_UNAVAILABLE",
                        "Location services are not available",
                        null
                    )
                }
            }
        }
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PAUSE -> {
                pauseLocationUpdates()
                return START_STICKY
            }
            ACTION_RESUME -> {
                resumeLocationUpdates()
                return START_STICKY
            }
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
        }
        
        // Get configuration from intent
        intervalMs = intent?.getLongExtra("intervalMs", 30000) ?: 30000
        fastestIntervalMs = intent?.getLongExtra("fastestIntervalMs", 15000) ?: 15000
        priority = intent?.getIntExtra("priority", Priority.PRIORITY_HIGH_ACCURACY) 
            ?: Priority.PRIORITY_HIGH_ACCURACY
        
        // Start as foreground service
        startForeground(NOTIFICATION_ID, createNotification())
        
        // Start location updates
        startLocationUpdates()
        
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopLocationUpdates()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Used for background location tracking"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        // Intent to open the app
        val contentIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            this, 0, contentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Pause/Resume action
        val pauseResumeIntent = Intent(this, LocationService::class.java).apply {
            action = if (isPaused) ACTION_RESUME else ACTION_PAUSE
        }
        val pauseResumePendingIntent = PendingIntent.getService(
            this, 1, pauseResumeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Stop action
        val stopIntent = Intent(this, LocationService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 2, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val statusText = if (isPaused) "Paused" else "Tracking active"
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Smart Employee")
            .setContentText(statusText)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .setContentIntent(contentPendingIntent)
            .addAction(
                if (isPaused) android.R.drawable.ic_media_play 
                else android.R.drawable.ic_media_pause,
                if (isPaused) "Resume" else "Pause",
                pauseResumePendingIntent
            )
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Stop",
                stopPendingIntent
            )
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
    
    private fun updateNotification() {
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, createNotification())
    }
    
    private fun startLocationUpdates() {
        locationRequest = LocationRequest.Builder(priority, intervalMs)
            .setMinUpdateIntervalMillis(fastestIntervalMs)
            .setWaitForAccurateLocation(false)
            .build()
        
        if (ActivityCompat.checkSelfPermission(
                this,
                android.Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        
        fusedLocationClient.requestLocationUpdates(
            locationRequest!!,
            locationCallback,
            Looper.getMainLooper()
        )
    }
    
    private fun stopLocationUpdates() {
        fusedLocationClient.removeLocationUpdates(locationCallback)
    }
    
    private fun pauseLocationUpdates() {
        isPaused = true
        stopLocationUpdates()
        updateNotification()
    }
    
    private fun resumeLocationUpdates() {
        isPaused = false
        startLocationUpdates()
        updateNotification()
    }
    
    private fun sendLocationToFlutter(location: Location) {
        val locationData = mapOf(
            "lat" to location.latitude,
            "lng" to location.longitude,
            "accuracy" to location.accuracy.toDouble(),
            "altitude" to location.altitude,
            "speed" to (location.speed.toDouble() * 3.6), // Convert to km/h
            "heading" to location.bearing.toDouble(),
            "timestamp" to location.time,
            "isMocked" to location.isFromMockProvider
        )
        
        // Send to Flutter via EventChannel
        locationEventSink?.success(locationData)
    }
}
