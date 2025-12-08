// GeofenceService.kt
// Geofencing Service for Smart Employee

package smart.attendance

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingEvent
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject

class GeofenceService private constructor(private val context: Context) {
    
    companion object {
        private var instance: GeofenceService? = null
        
        fun getInstance(context: Context): GeofenceService {
            return instance ?: synchronized(this) {
                instance ?: GeofenceService(context.applicationContext).also { instance = it }
            }
        }
        
        var geofenceEventSink: EventChannel.EventSink? = null
        
        const val PREFS_NAME = "geofence_prefs"
        const val KEY_GEOFENCES = "active_geofences"
    }
    
    private val geofencingClient: GeofencingClient = LocationServices.getGeofencingClient(context)
    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val activeGeofences = mutableMapOf<String, GeofenceData>()
    
    init {
        loadGeofencesFromPrefs()
    }
    
    data class GeofenceData(
        val id: String,
        val latitude: Double,
        val longitude: Double,
        val radius: Float,
        val loiteringDelayMs: Int,
        val expirationMs: Long,
        val transitionTypes: Int
    )
    
    fun addGeofence(
        id: String,
        latitude: Double,
        longitude: Double,
        radius: Float,
        loiteringDelayMs: Int = 30000,
        expirationMs: Long = Geofence.NEVER_EXPIRE,
        transitionTypes: Int = Geofence.GEOFENCE_TRANSITION_ENTER or 
                               Geofence.GEOFENCE_TRANSITION_EXIT or 
                               Geofence.GEOFENCE_TRANSITION_DWELL,
        callback: (Boolean) -> Unit
    ) {
        // Check fine location permission
        if (ActivityCompat.checkSelfPermission(
                context, android.Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            android.util.Log.e("GeofenceService", "Missing ACCESS_FINE_LOCATION permission")
            callback(false)
            return
        }
        
        // Check background location permission (required for Android 10+)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            if (ActivityCompat.checkSelfPermission(
                    context, android.Manifest.permission.ACCESS_BACKGROUND_LOCATION
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                android.util.Log.e("GeofenceService", "Missing ACCESS_BACKGROUND_LOCATION permission - required for geofencing")
                callback(false)
                return
            }
        }
        
        val geofence = Geofence.Builder()
            .setRequestId(id)
            .setCircularRegion(latitude, longitude, radius)
            .setExpirationDuration(expirationMs)
            .setTransitionTypes(transitionTypes)
            .setLoiteringDelay(loiteringDelayMs)
            .build()
        
        val geofencingRequest = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofence(geofence)
            .build()
        
        geofencingClient.addGeofences(geofencingRequest, geofencePendingIntent)
            .addOnSuccessListener {
                android.util.Log.d("GeofenceService", "Geofence added successfully: $id")
                val geofenceData = GeofenceData(
                    id, latitude, longitude, radius,
                    loiteringDelayMs, expirationMs, transitionTypes
                )
                activeGeofences[id] = geofenceData
                saveGeofencesToPrefs()
                callback(true)
            }
            .addOnFailureListener { e ->
                android.util.Log.e("GeofenceService", "Failed to add geofence: ${e.message}", e)
                e.printStackTrace()
                callback(false)
            }
    }
    
    fun removeGeofence(id: String, callback: (Boolean) -> Unit) {
        geofencingClient.removeGeofences(listOf(id))
            .addOnSuccessListener {
                activeGeofences.remove(id)
                saveGeofencesToPrefs()
                callback(true)
            }
            .addOnFailureListener { callback(false) }
    }
    
    fun removeAllGeofences(callback: (Boolean) -> Unit) {
        geofencingClient.removeGeofences(geofencePendingIntent)
            .addOnSuccessListener {
                activeGeofences.clear()
                saveGeofencesToPrefs()
                callback(true)
            }
            .addOnFailureListener { callback(false) }
    }
    
    fun listGeofences(): List<Map<String, Any>> {
        return activeGeofences.values.map { geofence ->
            mapOf(
                "id" to geofence.id,
                "lat" to geofence.latitude,
                "lng" to geofence.longitude,
                "radius" to geofence.radius.toDouble()
            )
        }
    }
    
    private val geofencePendingIntent: PendingIntent by lazy {
        val intent = Intent(context, GeofenceBroadcastReceiver::class.java)
        PendingIntent.getBroadcast(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
    }
    
    private fun saveGeofencesToPrefs() {
        val jsonArray = JSONArray()
        activeGeofences.values.forEach { geofence ->
            val jsonObject = JSONObject().apply {
                put("id", geofence.id)
                put("latitude", geofence.latitude)
                put("longitude", geofence.longitude)
                put("radius", geofence.radius.toDouble())
                put("loiteringDelayMs", geofence.loiteringDelayMs)
                put("expirationMs", geofence.expirationMs)
                put("transitionTypes", geofence.transitionTypes)
            }
            jsonArray.put(jsonObject)
        }
        prefs.edit().putString(KEY_GEOFENCES, jsonArray.toString()).apply()
    }
    
    private fun loadGeofencesFromPrefs() {
        val jsonString = prefs.getString(KEY_GEOFENCES, null) ?: return
        try {
            val jsonArray = JSONArray(jsonString)
            for (i in 0 until jsonArray.length()) {
                val jsonObject = jsonArray.getJSONObject(i)
                val geofence = GeofenceData(
                    id = jsonObject.getString("id"),
                    latitude = jsonObject.getDouble("latitude"),
                    longitude = jsonObject.getDouble("longitude"),
                    radius = jsonObject.getDouble("radius").toFloat(),
                    loiteringDelayMs = jsonObject.getInt("loiteringDelayMs"),
                    expirationMs = jsonObject.getLong("expirationMs"),
                    transitionTypes = jsonObject.getInt("transitionTypes")
                )
                activeGeofences[geofence.id] = geofence
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}

class GeofenceBroadcastReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context, intent: Intent) {
        val geofencingEvent = GeofencingEvent.fromIntent(intent)
        
        if (geofencingEvent == null || geofencingEvent.hasError()) {
            val errorCode = geofencingEvent?.errorCode ?: -1
            GeofenceService.geofenceEventSink?.error("GEOFENCE_ERROR", "Geofence error: $errorCode", null)
            return
        }
        
        val transitionType = when (geofencingEvent.geofenceTransition) {
            Geofence.GEOFENCE_TRANSITION_ENTER -> "enter"
            Geofence.GEOFENCE_TRANSITION_EXIT -> "exit"
            Geofence.GEOFENCE_TRANSITION_DWELL -> "dwell"
            else -> "unknown"
        }
        
        val triggeringLocation = geofencingEvent.triggeringLocation
        
        geofencingEvent.triggeringGeofences?.forEach { geofence ->
            val eventData = mapOf(
                "geofenceId" to geofence.requestId,
                "type" to transitionType,
                "timestamp" to System.currentTimeMillis(),
                "latitude" to (triggeringLocation?.latitude ?: 0.0),
                "longitude" to (triggeringLocation?.longitude ?: 0.0)
            )
            GeofenceService.geofenceEventSink?.success(eventData)
        }
    }
}
