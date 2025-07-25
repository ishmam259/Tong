# Bluetooth Troubleshooting Guide

## Issues Fixed

### 1. Missing Android Permissions
**Problem**: Android requires specific permissions for Bluetooth functionality.
**Fix**: Added all necessary Bluetooth permissions to `android/app/src/main/AndroidManifest.xml`:
- `android.permission.BLUETOOTH`
- `android.permission.BLUETOOTH_ADMIN`
- `android.permission.BLUETOOTH_SCAN`
- `android.permission.BLUETOOTH_CONNECT`
- `android.permission.BLUETOOTH_ADVERTISE`
- `android.permission.ACCESS_FINE_LOCATION`
- `android.permission.ACCESS_COARSE_LOCATION`

### 2. Enhanced Error Handling
**Problem**: Bluetooth failures were silent with no debugging information.
**Fix**: Added comprehensive logging and error handling in `BluetoothService`:
- Detailed permission checking with status logging
- Timeout handling for adapter state checks
- Better initialization flow with fallback attempts
- Enhanced scanning with broader device discovery

### 3. Added Bluetooth Diagnostics
**Problem**: No way to debug Bluetooth issues.
**Fix**: Created a new diagnostics screen accessible from Settings:
- Real-time Bluetooth status checking
- Step-by-step initialization testing
- Device discovery testing with results logging
- Detailed error reporting

## How to Test Bluetooth Features

### Step 1: Check Basic Functionality
1. Open the app
2. Go to Settings
3. Tap "Bluetooth Diagnostics"
4. Watch the diagnostic log for any errors

### Step 2: Test Device Discovery
1. Go to Settings → Network Discovery
2. Wait for the scan to complete
3. Look for Bluetooth devices with purple icons
4. Check if any "Bluetooth Error" messages appear

### Step 3: Test Device Connection
1. Make sure both devices have Bluetooth enabled and discoverable
2. Make sure both devices have the Tong app installed
3. Try connecting to a discovered Bluetooth device
4. Check the connection status messages

## Common Issues and Solutions

### "Bluetooth not supported"
- Your device doesn't have Bluetooth hardware
- No solution available

### "Bluetooth permissions not granted"
- Go to Android Settings → Apps → Tong → Permissions
- Enable all Location and Nearby devices permissions
- Restart the app

### "Bluetooth is turned off"
- Enable Bluetooth in Android settings
- Or allow the app to turn on Bluetooth when prompted

### "No Bluetooth devices found"
- Make sure other devices have Bluetooth enabled
- Make sure other devices are discoverable
- Try scanning multiple times
- Check that location services are enabled

### "Connection failed"
- Make sure both devices have the Tong app installed
- Ensure both devices are running the latest version
- Try restarting Bluetooth on both devices

## Technical Details

### Bluetooth Service Architecture
- Uses `flutter_blue_plus` for Bluetooth Low Energy (BLE)
- Implements custom service UUID: `12345678-1234-1234-1234-123456789abc`
- Uses characteristic UUID: `87654321-4321-4321-4321-cba987654321`
- Supports automatic device discovery and connection

### Permission Flow
1. App checks if Bluetooth is supported
2. Requests all necessary permissions
3. Checks adapter state (on/off)
4. Attempts to enable Bluetooth if needed
5. Initializes scanning and connection services

### Network Discovery Integration
- Bluetooth devices appear alongside WiFi networks
- Purple icons distinguish Bluetooth devices
- Automatic categorization and status checking
- Unified connection interface for all device types

## Testing on Different Platforms

### Android (Primary Target)
- Requires all permissions listed above
- Uses runtime permission requests
- Supports automatic Bluetooth enabling

### iOS (Limited Testing)
- Handles permissions automatically
- Cannot programmatically enable Bluetooth
- User must manually enable Bluetooth in settings

## Next Steps

1. Test the diagnostics screen first
2. Check the diagnostic log for specific error messages
3. Ensure proper permissions are granted
4. Test device discovery with multiple devices
5. Report specific error messages if issues persist
