# Debugging Guide: User Registration Data Persistence

## Problem Summary
Data user saat registrasi tidak tersimpan ke SQLite database, hanya tersimpan di SharedPreferences (memory).

## Root Causes Fixed
1. **Silent Exception Handling**: Database insert errors ditangkap tanpa log
2. **No Error Visibility**: App tidak tahu jika save ke database gagal
3. **Fallback Masking**: Fallback ke memory storage menyembunyikan real errors
4. **No Logging**: Sulit untuk debug flow registrasi

## Solutions Implemented

### 1. Enhanced Database Operation Logging
**File**: `lib/core/services/database_service.dart`
- Database initialization sekarang log di console dengan path file
- Setiap table creation di `_onCreate` di-log
- Table existence verification setelah database terbuka
- Database upgrade steps di-log

### 2. User Data Source Error Handling
**File**: `lib/data/sources/local/user_local_data_source.dart`
- Method `createUser()`: Exceptions sekarang di-throw, bukan di-silent
- Method `getUserByUsername()`: Query attempts di-log
- Method `getUserById()`: Query results di-log

### 3. User Repository Detailed Logging
**File**: `lib/data/repositories/user_repository.dart` (NEW)
- `registerUser()`: Logs registration status
- `loginUser()`: Logs login attempts, user lookup, password verification

**Login Logging Detail**:
```
[UserRepository] Attempting login for user: Dicky
[UserRepository] Password hash length: 64
[UserRepository] ✓ User found: Dicky (id=1)
[UserRepository] Password verified for user: Dicky
```

### 4. Auth Provider Registration Flow Logging
**File**: `lib/presentation/providers/auth_provider.dart`
- Registration steps di-track
- Auto-login success/failure di-log
- Session save di-log

## How to Test the Fixes

### WINDOWS PREREQUISITE: Enable Developer Mode
If you get "symlink support" error, you must enable Developer Mode:
```powershell
start ms-settings:developers
```
Then enable "Developer Mode" toggle.

### Step 1: Clean Build
```bash
cd "d:\Tugas Kelompok TPM\Tugas Akhir TPM\tugas_akhir_mobile"
flutter clean
flutter pub get
```

### Step 2: Run App dengan Verbose Logging
**Option A - Android/iOS Device:**
```bash
flutter run -v
```

**Option B - Windows (after enabling Developer Mode):**
```bash
flutter run -d windows -v
```

**Option C - Chrome (web):**
```bash
flutter run -d chrome -v
```

### Step 3: Capture Full Logs
Di terminal, cari logs dengan filter:
```
[DatabaseService]
[UserLocalDataSource]
[UserRepository]
[AuthProvider]
```

### Step 4: Test Registration
1. Go to Register screen
2. Enter username: `testuser_$(date +%s)` (unique setiap kali)
3. Enter password: `TestPassword123!`
4. Tap Register button

**Expected Full Log Flow:**
```
[DatabaseService] Opening database (attempt 1/3)...
[DatabaseService] ✓ Database opened successfully
[DatabaseService] ✓ Users table verified

[UserLocalDataSource] Inserting user to SQLite: {username: testuser_..., ...}
[UserLocalDataSource] ✓ User successfully created in SQLite: id=1, username=testuser_...

[UserRepository] ✓ User registered and saved to database: testuser_...
[AuthProvider] ✓ User registered successfully: testuser_...

[AuthProvider] Starting login for user: testuser_...
[UserRepository] Attempting login for user: testuser_...
[UserLocalDataSource] Querying SQLite for user: testuser_...
[UserLocalDataSource] ✓ User found in SQLite: testuser_... (id=1)
[UserRepository] ✓ User found: testuser_... (id=1)
[UserRepository] ✓ Password verified for user: testuser_...
[AuthProvider] ✓ Login successful: testuser_... (id=1)
[AuthProvider] ✓ Session saved to SharedPreferences

↓ Redirected to home screen ✓
```

### Step 5: Test Login After Restart
1. Close app completely
2. Kill the Flutter process
3. Reopen app
4. Try to login dengan credentials tadi
5. Should see successful login logs (without registration logs)

## If You See "User not found" Error

### Check These Logs in Order:

**1. Database Initialization:**
```
[DatabaseService] ✓ Database opened successfully
[DatabaseService] ✓ Users table verified
```
- If NOT present → Database failed to open

**2. Registration Insert:**
```
[UserLocalDataSource] ✓ User successfully created in SQLite: id=...
```
- If NOT present or shows "ERROR" → Database insert failed

**3. Login Query:**
```
[UserLocalDataSource] ✓ User found in SQLite: username (id=...)
```
- If shows "✗ User NOT found in SQLite" → Query didn't find the user
- If shows "User found in memory" → Data only in SharedPrefs, NOT in SQLite

### Common Issues & Solutions:

| Error | Cause | Solution |
|-------|-------|----------|
| `[DatabaseService] ✗ Max attempts reached` | DB file locked/corrupted | Stop all Flutter processes, delete `edufun.db`, restart |
| `[UserLocalDataSource] ✗ ERROR creating user` | Database insert failed | Check storage permissions, available space |
| `✗ User NOT found in SQLite` | User not actually saved | See logs above during registration |
| `User found in memory` | Only in SharedPrefs | Database save failed silently (check SQLite error logs) |
| `ERROR querying SQLite` | Database error | Check database file exists and is valid |

## Debug Commands

### Android: View Database File
```bash
adb shell ls -la /data/data/com.example.tugas_akhir_mobile/app_flutter/
adb pull /data/data/com.example.tugas_akhir_mobile/app_flutter/edufun.db ./
```

### Windows: View Database File Location
```powershell
# Database is usually in:
$env:APPDATA + "\Local\tugas_akhir_mobile\"
# Or in:
$env:LOCALAPPDATA + "\Flutter\plugins\..."
```

### SQLite Browser (Optional)
Download DB Browser for SQLite and open `edufun.db` to visually inspect users table:
- https://sqlitebrowser.org/

## Full Debug Checklist

- [ ] Developer Mode enabled (Windows)
- [ ] `flutter clean && flutter pub get` completed
- [ ] Running with `-v` (verbose) flag
- [ ] Unique username used for each test
- [ ] All [DatabaseService], [UserLocalDataSource], [UserRepository], [AuthProvider] logs captured
- [ ] Registration showed "successfully created in SQLite"
- [ ] Login showed "User found in SQLite"
- [ ] Successfully redirected to home screen
- [ ] Tested persistence (close/reopen app)

## Next Steps

1. **Run test** dengan steps di atas
2. **Capture full console output** dari registration hingga login
3. **Share the logs** jika masih ada error
4. **Share specific section** yang bermasalah dari logs

## Important Notes

- Debug logs HANYA tampil saat `flutter run -v` (verbose)
- Logs otomatis hidden di production build
- Database file tersimpan di aplikasi documents directory
- Password terenkripsi sebelum tersimpan di database
