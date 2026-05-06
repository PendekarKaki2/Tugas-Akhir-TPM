# Data Persistence Architecture - Complete Integration Guide

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                              │
│  (Screens: Login, Register, Home, Profile, Debug)                      │
│  (Providers: AuthProvider, UserProvider)                                │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                       BUSINESS LOGIC LAYER                              │
│  (Providers, Repositories, Use Cases)                                   │
│  - AuthProvider → Register, Login, Logout, CheckStatus                 │
│  - UserRepository → CRUD operations                                     │
│  - DataPersistenceService → Verification & Management                  │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                       DATA ACCESS LAYER                                 │
│  - UserLocalDataSource (SQL + SharedPreferences)                        │
│  - UserRemoteDataSource (API calls - future)                            │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ↓                    ↓                    ↓
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   SQLite     │    │   Shared     │    │   Memory     │
│  (Primary)   │    │ Preferences  │    │   Cache      │
│              │    │  (Session)   │    │  (Fallback)  │
│  edufun.db   │    │              │    │              │
└──────────────┘    └──────────────┘    └──────────────┘
```

---

## 📊 Data Flow Diagram

### **Registration Flow**
```
User Input (username, password)
         ↓
  RegisterScreen
         ↓
  AuthProvider.register()
         ↓
  UserRepository.registerUser()
         ↓
  UserLocalDataSource.createUser()
         ↓
    ┌────┴────┐
    ↓         ↓
  SQLite    SharedPreferences
  (Store)    (Cache)
    ↓         ↓
    └────┬────┘
         ↓
  AuthProvider.login() [auto]
         ↓
  Save session to SharedPreferences
    (user_id, username, is_logged_in)
         ↓
  Navigate to Home Screen
```

### **App Restart Flow**
```
App Opened
    ↓
SplashScreen._checkLoginStatus()
    ↓
AuthProvider.checkLoginStatus()
    ↓
Read SharedPreferences (user_id)
    ↓
    ├─ If user_id exists:
    │      ↓
    │   Query SQLite for user data
    │      ↓
    │   Restore UserModel
    │      ↓
    │   Navigate to Home (logged in)
    │
    └─ If user_id NOT exists:
         ↓
      Navigate to Login Screen
```

### **Logout Flow**
```
User clicks Logout
    ↓
AuthProvider.logout()
    ↓
DataPersistenceService.clearUserSession()
    ↓
Clear SharedPreferences
  (remove: user_id, username, is_logged_in)
    ↓
SQLite data remains (untuk future login)
    ↓
Navigate to Login Screen
```

---

## 🔑 Key Components

### **1. DatabaseService** ✅
**Location:** `lib/core/services/database_service.dart`

**Responsibility:**
- Initialize SQLite database
- Create/manage tables
- Provide database instance

**Key Method:**
```dart
Future<Database> get database async {
  if (_database != null) return _database!;
  _database = await _initializeDatabase();
  return _database!;
}
```

**Tables Created:**
```
users (id, username, password, photo, createdAt, level, xp)
questions (id, userId, question, answer, category, timestamp)
scores (id, userId, score, totalQuestions, category, timestamp)
badges (id, userId, badgeName, badgeIcon, unlockedAt)
user_locations (id, userId, latitude, longitude, timestamp)
```

---

### **2. UserLocalDataSource** ✅
**Location:** `lib/data/sources/local/user_local_data_source.dart`

**Responsibility:**
- Implement dual-storage strategy
- Handle SQLite operations
- Manage SharedPreferences cache

**Storage Strategy:**
```
Native Platform (Android/iOS):
  Primary: SQLite (edufun.db)
  Secondary: SharedPreferences (cache)
  Fallback: Memory map
  
Web Platform:
  Primary: SharedPreferences
  Secondary: Memory map
  SQLite: Not available on web
```

**Key Methods:**
```dart
Future<UserModel> createUser(UserModel user)
  → Insert to SQLite
  → Update SharedPreferences cache
  
Future<UserModel?> getUserById(int id)
  → Query SQLite (fresh data)
  → Update memory cache
  
Future<List<UserModel>> getAllUsers()
  → Query SQLite
  → Return all users
```

---

### **3. UserRepository** ✅
**Location:** `lib/data/repositories/user_repository.dart`

**Responsibility:**
- Business logic untuk user operations
- Validation & error handling
- Call UserLocalDataSource

**Key Methods:**
```dart
Future<UserModel> registerUser(String username, String password)
  → Check username exists
  → Hash password
  → Call createUser
  
Future<UserModel?> loginUser(String username, String password)
  → Get user by username
  → Verify password hash
  → Return user if valid
  
Future<UserModel?> getUserById(int id)
  → Call UserLocalDataSource.getUserById
```

---

### **4. AuthProvider** ✅
**Location:** `lib/presentation/providers/auth_provider.dart`

**Responsibility:**
- Manage authentication state
- Handle session persistence
- Provide UI with auth status

**Key Methods:**
```dart
Future<void> register(String username, String password)
  → Call UserRepository.registerUser
  → Auto login after register
  → Save session to SharedPreferences
  
Future<void> login(String username, String password)
  → Call UserRepository.loginUser
  → Save user_id, username to SharedPreferences
  → Set isLoggedIn = true
  → Notify listeners
  
Future<void> checkLoginStatus()
  → Read SharedPreferences
  → Get user_id
  → Restore user from database
  → Update isLoggedIn state
  
Future<void> logout()
  → Clear SharedPreferences session
  → Set isLoggedIn = false
  → Clear currentUser
  → Notify listeners
```

**State Variables:**
```dart
UserModel? _currentUser;
bool _isLoggedIn = false;
String? _error;
```

---

### **5. DataPersistenceService** ✅
**Location:** `lib/core/services/data_persistence_service.dart`

**Responsibility:**
- Verify data consistency
- Provide persistence management
- Logging & debugging

**Key Methods:**
```dart
Future<Map<String, dynamic>> verifyDataConsistency()
  → Check SQLite user count
  → Check SharedPreferences cache
  → Check session variables
  → Return consistency report
  
Future<bool> persistUserData(UserModel user)
  → Save to SQLite
  → Save to SharedPreferences
  → Verify both saved successfully
  → Return result
  
Future<UserModel?> restoreUserSession()
  → Read user_id from SharedPreferences
  → Query SQLite for user
  → Return UserModel
  
Future<bool> clearUserSession()
  → Remove SharedPreferences keys
  → Return success
  
Future<Map<String, int>> getDatabaseStats()
  → Count users, scores, questions, badges
  → Return statistics
```

---

### **6. SplashScreen** ✅
**Location:** `lib/presentation/screens/splash/splash_screen.dart`

**Responsibility:**
- Entry point untuk app
- Restore session automatically
- Route ke appropriate screen

**Flow:**
```dart
@override
void initState() {
  super.initState();
  _checkLoginStatus(); // ← Critical
}

Future<void> _checkLoginStatus() async {
  await Future.delayed(const Duration(seconds: 2));
  
  if (mounted) {
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkLoginStatus(); // ← Restore session
    
    if (mounted) {
      if (authProvider.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}
```

---

## 🔄 Complete User Journey

### **Journey 1: New User Registration → First Login**

```
1. User opens app
   └─ SplashScreen loads
   └─ checkLoginStatus() finds no session
   └─ Navigate to Login Screen

2. User clicks Register button
   └─ Navigate to RegisterScreen

3. User enters credentials
   └─ Username: "john_doe"
   └─ Password: "Pass123!"

4. User clicks Register button
   └─ AuthProvider.register() called
   └─ UserRepository.registerUser() called
   └─ Password hashed: "pass_hash_xyz"
   └─ UserLocalDataSource.createUser() called
   
5. Data saved (DUAL STORAGE):
   
   SQLite:
   ┌─────────────────────────────────┐
   │ INSERT INTO users VALUES        │
   │ (1, "john_doe", "pass_hash_xyz" │
   │  "https://...", "2024-05-06",   │
   │  1, 0)                          │
   └─────────────────────────────────┘
   
   SharedPreferences:
   ┌─────────────────────────────────┐
   │ cached_users_v1 = [{...user}]   │
   │ cached_users_id_counter = 1     │
   └─────────────────────────────────┘

6. Auto login triggered
   └─ AuthProvider.login() called
   └─ User object set in _currentUser
   └─ SharedPreferences updated:
      • user_id = 1
      • username = "john_doe"
      • is_logged_in = true

7. Navigate to Home Screen
   └─ User sees welcome message
   └─ Profile shows user data
```

### **Journey 2: User Closes & Reopens App**

```
1. User closes app completely
   └─ SQLite: Data persists in file
   └─ SharedPreferences: Session saved

2. User reopens app (30 mins later)
   └─ main() runs
   └─ SplashScreen built
   └─ initState() → _checkLoginStatus()

3. AuthProvider.checkLoginStatus() executes
   └─ Read SharedPreferences
   └─ Found: user_id = 1, is_logged_in = true
   └─ Call UserRepository.getUserById(1)
   └─ Query SQLite: SELECT * FROM users WHERE id = 1
   └─ SQLite returns: UserModel(
        id: 1,
        username: "john_doe",
        photo: "https://...",
        createdAt: "2024-05-06",
        level: 1,
        xp: 0
      )

4. AuthProvider state updated
   └─ _currentUser = UserModel(...)
   └─ _isLoggedIn = true
   └─ notifyListeners()

5. SplashScreen checks isLoggedIn
   └─ Found: true
   └─ Navigate to Home Screen

6. User sees Home Screen
   └─ Already logged in! ✓
   └─ Profile shows exact same data ✓
   └─ No login required ✓
```

### **Journey 3: User Logs Out → New User Login**

```
1. User clicks Logout button
   └─ AuthProvider.logout() called
   └─ DataPersistenceService.clearUserSession() called
   └─ SharedPreferences cleared:
      • Remove: user_id
      • Remove: username
      • Remove: is_logged_in
   └─ SQLite: Data REMAINS (not deleted)
   └─ Navigate to Login Screen

2. Different user opens app
   └─ SplashScreen loads
   └─ checkLoginStatus() finds no session
   └─ Navigate to Login Screen

3. New user (alice) enters credentials
   └─ AuthProvider.login("alice", "pass123")
   └─ Query SQLite for user named "alice"
   └─ Verify password hash
   └─ Set session:
      • user_id = 2 (or whatever alice's ID is)
      • username = "alice"
      • is_logged_in = true

4. Navigate to Home
   └─ Show alice's profile
   └─ SQLite has both john and alice data
   └─ SharedPreferences only has alice's session
```

---

## 🛡️ Data Integrity Safeguards

### **1. Primary Key Constraint**
```sql
id INTEGER PRIMARY KEY AUTOINCREMENT
-- Prevents duplicate IDs
-- Ensures each user is unique
```

### **2. Unique Username**
```sql
username TEXT NOT NULL UNIQUE
-- Prevents duplicate usernames
-- Ensures valid login
```

### **3. Foreign Key Relationships**
```sql
CREATE TABLE scores (
  ...
  userId INTEGER NOT NULL,
  FOREIGN KEY(userId) REFERENCES users(id)
  -- Ensures orphaned scores impossible
  -- Maintains referential integrity
)
```

### **4. Password Hashing**
```dart
// Never store plain text
String hashedPassword = PasswordHashing.hashPassword(password);
// Verify with: PasswordHashing.verifyPassword(input, hash)
```

### **5. Transaction Safety**
```dart
// SQLite transactions ensure atomicity
await db.transaction((txn) async {
  await txn.insert('users', userMap);
  // All or nothing - no partial saves
});
```

---

## 📱 Platform-Specific Storage

### **Android**
```
📁 /data/data/com.edufun/
├── 📁 databases/
│  └── 📄 edufun.db (SQLite)
└── 📁 shared_prefs/
   └── 📄 SharedPreferenceDefaults.xml (Encrypted)
```

### **iOS**
```
📁 ~/Library/Containers/com.edufun/Data/
├── 📁 Documents/
│  └── 📄 edufun.db (SQLite)
└── 📁 Library/
   └── 📁 Preferences/
      └── 📄 com.apple.nsuserdefaults.plist (Encrypted)
```

### **Web**
```
🌐 Browser Local Storage
├── SharedPreferences (via sqflite/sqflite_common_ffi_web)
├── IndexedDB (fallback)
└── Session Storage (temporary)

Note: SQLite on web uses virtual file system
```

---

## 🔧 Integration Checklist

- [x] DatabaseService initialized
- [x] SQLite tables auto-created
- [x] UserLocalDataSource dual-storage
- [x] UserRepository validation
- [x] AuthProvider state management
- [x] SplashScreen session restore
- [x] DataPersistenceService verification
- [x] DebugScreen untuk testing
- [ ] Integrate DataPersistenceService into AuthProvider workflow
- [ ] Add persistent logging
- [ ] Production configuration (.env file for secrets)

---

## 🚀 Production Readiness

### **Before Deploy:**
1. Set `debugPrint: false` di DataPersistenceService
2. Move API keys to .env file
3. Enable encryption for sensitive data
4. Set up error tracking (Sentry, Firebase Crashlytics)
5. Implement backup strategy
6. Test on actual devices (not emulator only)
7. Verify database migration strategy

### **Security Recommendations:**
```dart
// 1. Use .env untuk secrets
const String apiKey = String.fromEnvironment('GEMINI_API_KEY');

// 2. Implement key derivation untuk sensitive data
import 'package:encrypt/encrypt.dart' as encrypt;

// 3. Verify password dengan proper algorithm
// Current: Basic hashing
// Recommended: bcrypt, scrypt, or Argon2

// 4. Implement API rate limiting

// 5. Add request signing untuk API calls
```

---

## 📚 Related Documentation

- [DATA_PERSISTENCE_GUIDE.md](DATA_PERSISTENCE_GUIDE.md) - User-facing documentation
- [DATA_PERSISTENCE_TESTING.md](DATA_PERSISTENCE_TESTING.md) - Testing procedures
- [GEMINI_SETUP.md](GEMINI_SETUP.md) - AI service integration
- [OPENAI_SETUP.md](OPENAI_SETUP.md) - Alternative AI provider

---

**✅ Implementation Complete - Ready for Testing**
