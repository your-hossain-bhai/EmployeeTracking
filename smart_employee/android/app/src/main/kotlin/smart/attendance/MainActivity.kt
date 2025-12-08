// MainActivity.kt
// Main Activity for Smart Employee Android Application

package smart.attendance

import android.Manifest
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    
    companion object {
        const val LOCATION_CONTROL_CHANNEL = "com.example.smart_employee/location_control"
        const val LOCATION_STREAM_CHANNEL = "com.example.smart_employee/location_stream"
        const val GEOFENCE_CONTROL_CHANNEL = "com.example.smart_employee/geofence_control"
        const val GEOFENCE_STREAM_CHANNEL = "com.example.smart_employee/geofence_stream"
        
        const val REQUEST_LOCATION_PERMISSION = 1001
        const val REQUEST_BACKGROUND_LOCATION_PERMISSION = 1002
    }
    
    private var locationEventSink: EventChannel.EventSink? = null
    private var geofenceEventSink: EventChannel.EventSink? = null
    private var locationService: Intent? = null
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Setup Location Control Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CONTROL_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        val intervalMs = call.argument<Int>("intervalMs") ?: 30000
                        val fastestIntervalMs = call.argument<Int>("fastestIntervalMs") ?: 15000
                        val priority = call.argument<Int>("priority") ?: 100
                        startLocationService(intervalMs.toLong(), fastestIntervalMs.toLong(), priority, result)
                    }
                    "stopService" -> stopLocationService(result)
                    "pauseService" -> pauseLocationService(result)
                    "resumeService" -> resumeLocationService(result)
                    "getPermissionStatus" -> getPermissionStatus(result)
                    "requestPermissions" -> requestLocationPermissions(result)
                    "isServiceRunning" -> result.success(isLocationServiceRunning())
                    "isBatteryOptimizationDisabled" -> result.success(isBatteryOptimizationDisabled())
                    "requestDisableBatteryOptimization" -> {
                        requestDisableBatteryOptimization()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        
        // Setup Location Stream Event Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_STREAM_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    locationEventSink = events
                    LocationService.locationEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    locationEventSink = null
                    LocationService.locationEventSink = null
                }
            })
        
        // Setup Geofence Control Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GEOFENCE_CONTROL_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "addGeofence" -> {
                        val id = call.argument<String>("id") ?: ""
                        val lat = call.argument<Double>("lat") ?: 0.0
                        val lng = call.argument<Double>("lng") ?: 0.0
                        val radius = call.argument<Double>("radius") ?: 100.0
                        val loiteringDelayMs = call.argument<Int>("loiteringDelayMs") ?: 30000
                        val expirationMs = call.argument<Long>("expirationMs") ?: -1L
                        val transitionTypes = call.argument<Int>("transitionTypes") ?: 7
                        
                        GeofenceService.getInstance(this).addGeofence(
                            id, lat, lng, radius.toFloat(),
                            loiteringDelayMs, expirationMs, transitionTypes
                        ) { success -> result.success(success) }
                    }
                    "removeGeofence" -> {
                        val id = call.argument<String>("id") ?: ""
                        GeofenceService.getInstance(this).removeGeofence(id) { success ->
                            result.success(success)
                        }
                    }
                    "removeAllGeofences" -> {
                        GeofenceService.getInstance(this).removeAllGeofences { success ->
                            result.success(success)
                        }
                    }
                    "listGeofences" -> result.success(GeofenceService.getInstance(this).listGeofences())
                    else -> result.notImplemented()
                }
            }
        
        // Setup Geofence Stream Event Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, GEOFENCE_STREAM_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    geofenceEventSink = events
                    GeofenceService.geofenceEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    geofenceEventSink = null
                    GeofenceService.geofenceEventSink = null
                }
            })
    }
    
    private fun startLocationService(
        intervalMs: Long, fastestIntervalMs: Long, priority: Int, result: MethodChannel.Result
    ) {
        if (!hasLocationPermission()) {
            result.success(false)
            return
        }
        
        locationService = Intent(this, LocationService::class.java).apply {
            putExtra("intervalMs", intervalMs)
            putExtra("fastestIntervalMs", fastestIntervalMs)
            putExtra("priority", priority)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(locationService)
        } else {
            startService(locationService)
        }
        result.success(true)
    }
    
    private fun stopLocationService(result: MethodChannel.Result) {
        locationService?.let { stopService(it) }
        result.success(true)
    }
    
    private fun pauseLocationService(result: MethodChannel.Result) {
        val intent = Intent(this, LocationService::class.java).apply {
            action = LocationService.ACTION_PAUSE
        }
        startService(intent)
        result.success(true)
    }
    
    private fun resumeLocationService(result: MethodChannel.Result) {
        val intent = Intent(this, LocationService::class.java).apply {
            action = LocationService.ACTION_RESUME
        }
        startService(intent)
        result.success(true)
    }
    
    private fun isLocationServiceRunning(): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        for (service in manager.getRunningServices(Int.MAX_VALUE)) {
            if (LocationService::class.java.name == service.service.className) {
                return true
            }
        }
        return false
    }
    
    private fun getPermissionStatus(result: MethodChannel.Result) {
        val fineLocation = ContextCompat.checkSelfPermission(
            this, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        
        val coarseLocation = ContextCompat.checkSelfPermission(
            this, Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        
        val backgroundLocation = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        } else true
        
        result.success(mapOf(
            "fineLocation" to fineLocation,
            "coarseLocation" to coarseLocation,
            "backgroundLocation" to backgroundLocation,
            "hasPermission" to (fineLocation && coarseLocation && backgroundLocation)
        ))
    }
    
    private fun requestLocationPermissions(result: MethodChannel.Result) {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
            REQUEST_LOCATION_PERMISSION
        )
        result.success(true)
    }
    
    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    private fun isBatteryOptimizationDisabled(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            return pm.isIgnoringBatteryOptimizations(packageName)
        }
        return true
    }
    
    private fun requestDisableBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent().apply {
                action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        }
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == REQUEST_LOCATION_PERMISSION) {
            if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
                        REQUEST_BACKGROUND_LOCATION_PERMISSION
                    )
                }
            }
        }
    }
}
