# 📍 Employee Tracking Guide

## How to Track Employees in Real-Time

### **Setup (One-time)**

1. **Grant Location Permissions**
   - Employee must allow location permissions when prompted
   - On Android: "Allow all the time" for background tracking
   - On iOS: "Always" for background tracking

### **For Employees (Tracked Device)**

✅ **Automatic Tracking** - No manual steps needed!

When an employee logs in:
- Location tracking **starts automatically** in the background
- Updates sent every **30 seconds**
- Works even when app is minimized
- Stops automatically on logout

**Visual Indicators:**
- Dashboard shows "Location Tracking: Active ✅"
- Green dot on Live Map tab

### **For Admins (Tracking Device)**

To view live employee locations:

1. **Login as Admin**
2. **Navigate to "Live Map" tab** (bottom navigation, 2nd icon)
3. **View real-time employee markers** on the map

**Live Map Features:**
- 🟢 Green marker = Employee online (updated <5 min ago)
- 🟠 Orange marker = Employee offline (no recent update)
- 📍 Tap any marker to see employee details
- 🔄 Auto-refreshes every time employees move
- 🗺️ Switch map styles: Streets, Satellite, Terrain, Hybrid
- 📊 Employee list on the right side (tap to zoom to employee)
- 🎯 Geofence circles shown in blue/green/orange

### **Troubleshooting**

**Employee not showing on map?**

1. ✅ **Check Employee Device:**
   - Location permissions granted?
   - Location services (GPS) enabled?
   - Internet connection active?
   - App running (can be in background)?
   - Dashboard shows "Location Tracking: Active"?

2. ✅ **Check Admin Device:**
   - Internet connection active?
   - Same company account?
   - Wait 30-60 seconds for first update

3. ✅ **Force Refresh:**
   - Employee: Open app → Go to Dashboard
   - Admin: Pull down on Live Map to refresh

**Location updates delayed?**
- Normal: Updates every 30 seconds
- First update may take up to 60 seconds
- Moving employees update faster

**High battery usage?**
- Normal for location tracking
- Configured for balanced power (30s intervals)
- Employee can logout to stop tracking when not working

### **Technical Details**

**Update Frequency:**
- Interval: 30 seconds (normal)
- Fastest: 15 seconds (when moving)
- Accuracy: High (GPS priority)

**Data Flow:**
1. Employee device → GPS location
2. Location → Firebase Firestore
3. Admin device ← Real-time stream from Firestore

**Background Service:**
- Android: Foreground service with notification
- iOS: Background location updates

### **Privacy & Security**

- Only tracks during work hours (when logged in)
- Admin sees only employees in same company
- Employees can see their own location on "Live Map" tab
- All data encrypted in transit (HTTPS)
- Location history stored in secure Firebase

---

## Quick Start Commands

**Restart Employee Tracking:**
```
Employee: Logout → Login again
```

**View All Active Employees:**
```
Admin: Live Map tab → Check employee list
```

**Test Tracking:**
1. Login as employee on Device 1
2. Login as admin on Device 2
3. Wait 30-60 seconds
4. Check Live Map on admin device
5. Employee marker should appear!

---

**Need Help?** Check the employee's Dashboard for "Location Tracking" status card.
