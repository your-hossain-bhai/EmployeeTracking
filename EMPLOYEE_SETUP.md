# ✅ **Employee Management Setup Guide**

## 🐛 **Issue Fixed**

The "No employees found" issue was caused by **a bug in the employee filter**:
- Code was comparing `UserRole.employee` (enum) to string `'employee'`
- This always returned false, so no employees showed up
- ✅ **FIXED** - Now properly filters employees

---

## 👥 **How to Add Employees**

There are **2 ways** to add employees:

### **Option 1: Self-Registration (Recommended)**

Employees register themselves:

1. **Open Smart Employee App**
2. **Tap "Create Account"** at login screen
3. **Fill in the form:**
   - Full Name: `John Doe`
   - Email: `john@company.com`
   - Password: `SecurePass123!`
   - Company Code: `[your-company-id]`
   - ✅ Role automatically set to **Employee**
4. **Tap Register** → Logged in as employee automatically

**To get Company ID (for employees):**
- Admin opens app → Settings or Company page
- Copy the **Company ID/Code**
- Share with employees to use during registration

---

### **Option 2: Direct Add via Firestore (For Testing)**

For quick testing, add employees directly to Firebase:

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/
   - Select your **smart-attendance-96fce** project
   - Go to **Firestore Database**

2. **Add a User Document**
   - Click **+ Add collection**
   - Collection ID: `users`
   - Click **Add document**
   - Document ID: Leave **Auto ID** (will be auto-generated)

3. **Add these fields:**
   ```
   email (string)              → john@company.com
   displayName (string)        → John Doe
   companyId (string)          → [SAME as admin's companyId]
   role (string)               → employee
   isActive (boolean)          → true
   phoneNumber (string)        → 9876543210
   createdAt (timestamp)       → Today's date
   updatedAt (timestamp)       → Today's date
   ```

4. **Click Save** → Employee is now in the system

---

## ✅ **Test It Works**

### **On Employee Device:**
1. Register new employee (Option 1) OR add to Firestore (Option 2)
2. Login with employee credentials
3. Go to **Check In / Out** page
4. ✅ Should show **Location acquired** (if GPS is on)
5. ✅ Tap **Check In** button
6. ✅ Success message appears

### **On Admin Device:**
1. Login as admin
2. Go to **Dashboard** tab
3. Check **Total Employees** button
4. ✅ Should show `1` employee
5. Go to **Live Map** tab
6. ✅ Should show employee marker on map (green dot)

---

## 🎯 **Troubleshooting**

### **Employee still not showing on Live Map?**

1. **Check Firestore:**
   - Make sure `companyId` matches admin's `companyId`
   - Make sure `role` is exactly `employee` (lowercase)
   - Make sure `isActive` is `true`

2. **Check Location Permissions:**
   - Employee device → Settings → Location → **ON**
   - Grant app permission: **"Allow all the time"**
   - Tap "Refresh Location" on Check In page

3. **Check Network:**
   - Both devices connected to internet?
   - Same WiFi network? (Optional but helps)
   - Wait 30-60 seconds for first location sync

4. **Force Refresh:**
   - Admin: Pull down on Live Map
   - Employee: Logout and login again

---

## 📊 **Expected Results**

**After adding 1 employee and checking in:**

| Screen | What You'll See |
|--------|-----------------|
| Admin Dashboard | Total Employees: 1<br>Present Today: 1<br>Absent: 0 |
| Admin Live Map | Green dot marker for employee<br>Employee name shown |
| Employee Dashboard | Location Tracking: Active ✅<br>Today's Status: Checked In |
| Employee Live Map | Blue circle (your geofence)<br>Green dot (your location) |

---

## 🔑 **Important: Company ID**

Make sure both admin and employees use the **SAME** company ID:

- Admin: Created with company ID → `c123abc`
- Employee: Register with company ID → `c123abc` ✅ (MUST MATCH!)

If they don't match, employee won't show up for that admin.

---

## ❓ **FAQ**

**Q: Can I add multiple employees?**
- ✅ Yes! Repeat the process for each employee

**Q: Do employees have to register, or can admin add them?**
- Currently: Employees register themselves
- Future: Admin can add employees directly (coming soon)

**Q: Why does employee show orange (offline) on map?**
- No location update in last 5 minutes
- Wait 30 seconds → marker turns green (online)

**Q: Can employees see each other's locations?**
- ✅ Yes, but only on their own "Live Map" tab
- Shows their own location as blue circle

**Q: How do I remove an employee?**
- Edit employee → Toggle **Active** to OFF
- Or delete from Firestore `users` collection

---

**All set!** 🎉 Your employee tracking system is ready to use!
