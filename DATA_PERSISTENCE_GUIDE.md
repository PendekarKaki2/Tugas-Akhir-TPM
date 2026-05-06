# Data Persistence & User Data Storage - Panduan Lengkap

## ✅ Bagaimana Data User Tersimpan

### 🗄️ **Dual Storage System**

Data user disimpan di **2 tempat** untuk reliability maksimal:

#### **1. SQLite Database** (Primary Storage)
- **File**: `edufun.db` di Documents directory
- **Lokasi**: `/data/data/com.edufun/documents/edufun.db` (Android)
- **Keandalan**: ⭐⭐⭐⭐⭐ (Persistent, crash-safe)
- **Data yang disimpan**: 
  - User credentials (username, hashed password)
  - User profile (photo, level, XP)
  - Timestamps
  - Foreign key relationships

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  photo TEXT,
  createdAt TEXT NOT NULL,
  level INTEGER DEFAULT 1,
  xp INTEGER DEFAULT 0
)
```

#### **2. SharedPreferences** (Session Cache)
- **Tipe**: Encrypted key-value store
- **Keandalan**: ⭐⭐⭐⭐ (Fast access, session persistence)
- **Data yang disimpan**:
  - `user_id`: User ID untuk quick restore
  - `username`: Username saat ini login
  - `is_logged_in`: Flag login status
  - `cached_users_v1`: Cache semua users (JSON)

---

## 🔄 **Data Flow: Register → Login → Persistence**

```
┌─────────────────────────────────────────────────────────────────┐
│ USER REGISTRASI                                                 │
└─────────────────────────────────────────────────────────────────┘
   ↓
┌─────────────────────────────────────────────────────────────────┐
│ RegisterScreen                                                  │
│ - Collect username & password                                  │
│ - Hash password dengan PasswordHashing.hashPassword()          │
└─────────────────────────────────────────────────────────────────┘
   ↓
┌─────────────────────────────────────────────────────────────────┐
│ AuthProvider.register()                                         │
│ - Call UserRepository.registerUser()                            │
│ - Hash password                                                │
│ - Auto login setelah register                                  │
└─────────────────────────────────────────────────────────────────┘
   ↓
┌─────────────────────────────────────────────────────────────────┐
│ UserRepository.registerUser()                                  │
│ - Check if username exists                                     │
│ - Create UserModel                                             │
│ - Call UserLocalDataSource.createUser()                        │
└─────────────────────────────────────────────────────────────────┘
   ↓
┌─────────────────────────────────────────────────────────────────┐
│ UserLocalDataSource.createUser()                               │
│ - Insert ke SQLite Database ✓                                 │
│ - Save ke SharedPreferences cache ✓                            │
│ - Return UserModel with generated ID                           │
└─────────────────────────────────────────────────────────────────┘
   ↓
┌─────────────────────────────────────────────────────────────────┐
│ AuthProvider.login() - Auto setelah register                   │
│ - Fetch user dari database                                     │
│ - Save session ke SharedPreferences:                           │
│   • user_id                                                     │
│   • username                                                    │
│   • is_logged_in = true                                        │
└─────────────────────────────────────────────────────────────────┘
   ↓
┌─────────────────────────────────────────────────────────────────┐
│ DATA PERSISTED SAFELY ✓                                         │
│ - SQLite memastikan persistence                                │
│ - SharedPreferences memastikan quick session restore            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔐 **Saat App Ditutup & Dibuka Lagi**

```
┌──────────────────────────────────────────────────────────┐
│ APP DITUTUP                                              │
│ - SQLite data tetap aman di storage                     │
│ - SharedPreferences cache tetap aman                    │
└──────────────────────────────────────────────────────────┘
   ↓
┌──────────────────────────────────────────────────────────┐
│ APP DIBUKA LAGI                                          │
│ - SplashScreen._checkLoginStatus() dipanggil            │
└──────────────────────────────────────────────────────────┘
   ↓
┌──────────────────────────────────────────────────────────┐
│ AuthProvider.checkLoginStatus()                          │
│ - Read SharedPreferences                                 │
│ - Get user_id dari cache                                │
│ - If user_id exists → call getUserById(id)              │
└──────────────────────────────────────────────────────────┘
   ↓
┌──────────────────────────────────────────────────────────┐
│ UserLocalDataSource.getUserById()                        │
│ - Query SQLite untuk get fresh user data ✓              │
│ - Return UserModel dengan data terbaru                  │
└──────────────────────────────────────────────────────────┘
   ↓
┌──────────────────────────────────────────────────────────┐
│ HASIL:                                                   │
│ - User sudah login otomatis ✓                           │
│ - Data user tetap lengkap ✓                             │
│ - Navigasi ke Home Screen ✓                             │
└──────────────────────────────────────────────────────────┘
```

---

## 📊 **Data Structure Lengkap**

### **User Table (SQLite)**
```
users
├── id (INTEGER PRIMARY KEY) - Auto-increment
├── username (TEXT UNIQUE) - Login identifier
├── password (TEXT) - Hashed password
├── photo (TEXT) - Profile photo URL/path
├── createdAt (TEXT ISO8601) - Waktu registrasi
├── level (INTEGER) - User level (default: 1)
└── xp (INTEGER) - User XP points (default: 0)
```

### **Related Tables**
```
scores
├── id (INTEGER PRIMARY KEY)
├── userId (FOREIGN KEY) → users.id ✓
├── score (INTEGER)
├── totalQuestions (INTEGER)
├── category (TEXT)
└── timestamp (TEXT)

badges
├── id (INTEGER PRIMARY KEY)
├── userId (FOREIGN KEY) → users.id ✓
├── badgeName (TEXT)
├── badgeIcon (TEXT)
└── unlockedAt (TEXT)

user_locations
├── id (INTEGER PRIMARY KEY)
├── userId (FOREIGN KEY) → users.id ✓
├── latitude (REAL)
├── longitude (REAL)
└── timestamp (TEXT)
```

---

## 🛡️ **Security Features**

✅ **Password Hashing**
```dart
// Passwords di-hash sebelum disimpan
String hashedPassword = PasswordHashing.hashPassword(password);
// Not: SELECT * WHERE password = 'plaintext'
// But: SELECT * WHERE password = 'hashed_value'
```

✅ **Unique Username Constraint**
```sql
username TEXT NOT NULL UNIQUE
-- Mencegah duplikat username
```

✅ **Foreign Key Relationships**
```sql
FOREIGN KEY (userId) REFERENCES users(id)
-- Ensures data integrity
```

---

## 🧪 **Testing Data Persistence**

### **Menggunakan DataPersistenceService**

```dart
// In main.dart atau di provider:
import 'core/services/data_persistence_service.dart';

final persistenceService = DataPersistenceService(databaseService);

// 1. Verify data consistency
final consistency = await persistenceService.verifyDataConsistency();
print(consistency);
// Output:
// {
//   'status': 'success',
//   'sqliteUserCount': 5,
//   'cachedUsersExist': true,
//   'currentSessionUserId': 1,
//   'currentSessionUsername': 'john_doe',
//   'isLoggedIn': true,
//   'timestamp': '2024-05-06T10:30:00.000Z'
// }

// 2. Get database statistics
final stats = await persistenceService.getDatabaseStats();
print(stats);
// Output:
// {
//   'users': 5,
//   'scores': 42,
//   'questions': 200,
//   'badges': 15
// }

// 3. Get all users
final allUsers = await persistenceService.getAllUsers();
for (var user in allUsers) {
  print('User: ${user.username}, ID: ${user.id}');
}

// 4. Restore user session
final sessionUser = await persistenceService.restoreUserSession();
if (sessionUser != null) {
  print('Session restored: ${sessionUser.username}');
}
```

---

## 🔍 **Manual Testing Steps**

### **Test 1: Register & Check Persistence**
```
1. Buka app → SplashScreen
2. Klik "Register"
3. Input username: "test_user_123"
4. Input password: "password123"
5. Confirm password: "password123"
6. Klik "Register"
7. ✓ Automatic login should happen
8. Home screen appears
9. CLOSE APP COMPLETELY (kill dari memory)
10. Open app again
11. ✓ Should auto-login tanpa input username/password
12. ✓ User data tetap ada (check profile)
```

### **Test 2: Verify Database**
```
1. Install Android Studio
2. Tools → Device File Explorer
3. Navigate: /data/data/com.edufun/documents/
4. ✓ edufun.db file exists
5. Pull file ke desktop
6. Open dengan SQLite viewer (e.g., DB Browser for SQLite)
7. Check 'users' table
8. ✓ User data ada dengan lengkap
```

### **Test 3: Multiple Users**
```
1. Register user 1: "alice"
2. Logout
3. Register user 2: "bob"
4. Logout
5. Login dengan "alice"
6. ✓ Should load alice's data (not bob's)
7. Logout
8. Login dengan "bob"
9. ✓ Should load bob's data
```

### **Test 4: Data Integrity After Crash Simulation**
```
1. Login sebagai user
2. Open adb shell: adb shell
3. Kill app: am force-stop com.edufun
4. Open app lagi
5. ✓ Data tetap ada, user still logged in
6. Profile data intact ✓
```

---

## 📚 **Database Files Lokasi**

### **Android**
```
Internal Storage:
/data/data/com.edufun/documents/edufun.db

SharedPreferences:
/data/data/com.edufun/shared_prefs/
```

### **iOS**
```
Documents directory:
/Library/Preferences/com.edufun/documents/edufun.db
```

### **Development (Desktop)**
```
Windows:
%APPDATA%\edufun\edufun.db

macOS:
~/Library/Application Support/edufun/edufun.db

Linux:
~/.local/share/edufun/edufun.db
```

---

## 🚨 **Troubleshooting**

### **Problem: Data hilang setelah close app**

**Kemungkinan Penyebab:**
- SharedPreferences tidak initialized
- Database transaction tidak completed
- App killed sebelum data written

**Solusi:**
```dart
// Ensure all database operations completed
await persistenceService.verifyDataConsistency();

// Check if data actually saved
final user = await persistenceService.getUserFromDatabase(userId);
if (user == null) {
  print('WARNING: Data not saved!');
}
```

### **Problem: User login tidak auto-restore**

**Kemungkinan Penyebab:**
- `checkLoginStatus()` tidak dipanggil di splash screen
- SharedPreferences cache corrupted
- user_id tidak tersimpan

**Solusi:**
```dart
// In AuthProvider.checkLoginStatus():
// Ensure properly awaited
await prefs.getInt('user_id');

// Add error handling
try {
  final user = await _userRepository.getUserById(userId);
  if (user != null) {
    _currentUser = user;
    notifyListeners();
  }
} catch (e) {
  _error = 'Failed to restore session: $e';
  notifyListeners();
}
```

---

## ✨ **Best Practices**

1. **Always use DataPersistenceService untuk critical operations**
   ```dart
   await persistenceService.persistUserData(user);
   ```

2. **Enable logging during development**
   ```dart
   persistenceService.setLoggingEnabled(true);
   ```

3. **Verify data setelah major operations**
   ```dart
   final consistency = await persistenceService.verifyDataConsistency();
   if (consistency['status'] == 'error') {
     // Handle error
   }
   ```

4. **Handle failures gracefully**
   ```dart
   try {
     // Database operation
   } catch (e) {
     // Fallback atau user notification
     showErrorDialog(context, 'Data save failed. Please try again.');
   }
   ```

---

## 🎯 **Summary**

✅ **Data PASTI tersimpan dengan baik karena:**
- Dual storage (SQLite + SharedPreferences)
- ACID compliance dalam SQLite
- Automatic session restoration
- Foreign key constraints
- Error handling & fallbacks

✅ **Data TIDAK akan hilang karena:**
- SQLite persist ke filesystem
- SharedPreferences encrypted by OS
- Multi-layer redundancy
- Transaction safety

✅ **Session AKAN auto-restore karena:**
- SplashScreen check login status
- AuthProvider restore dari database
- SharedPreferences cache for speed

---

**Data user Anda aman! 🔒**
