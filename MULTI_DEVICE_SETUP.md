# Tong Messenger - Multi-Device Chat Setup

## Features Added

### 1. Settings Screen
- Accessible via the settings button (gear icon) in the messaging screen
- Profile management (nickname editing)
- Connection type selection (WiFi, Bluetooth, Internet)
- Network discovery screen
- Notifications and appearance settings
- Help and support information

### 2. Multi-Device Networking
- TCP-based local network communication
- Automatic server hosting
- Device discovery and connection
- Real-time message synchronization
- Connection status indicator

## How to Test Multi-Device Chat

### Option 1: Two Devices on Same WiFi Network

1. **On Device 1 (Host):**
   - Open Tong Messenger
   - Tap "Start Messaging"
   - The app automatically starts hosting a server
   - Tap the connection status bar to see your IP address
   - Share this IP address with Device 2

2. **On Device 2 (Client):**
   - Open Tong Messenger
   - Tap "Start Messaging"
   - Tap "Connect" in the connection status bar
   - Enter Device 1's IP address
   - Tap "Connect"

3. **Start Chatting:**
   - Both devices should show "Connected" status
   - Messages sent from either device will appear on both
   - Real-time synchronization

### Option 2: Testing on Simulator + Device

1. **On Simulator (Host):**
   - Run the app
   - Note the IP address from connection dialog
   - Usually shows your computer's local IP

2. **On Physical Device:**
   - Make sure device is on same WiFi as computer
   - Open the app and connect using the computer's IP
   - Start chatting between simulator and device

### Option 3: Two Simulators (Advanced)

1. Run two instances of the app
2. Use 127.0.0.1 (localhost) for connections
3. One acts as server, other as client

## Settings Features

### Profile Settings
- Change your display name
- Appears in chat messages sent to other devices

### Connection Settings
- View current connection type
- Access network discovery
- Scan for nearby devices
- Manual connection options

### Network Discovery
- Automatically finds available devices
- Shows connection strength
- One-tap connection to discovered devices
- Real-time device availability status

### Notifications
- Toggle message notifications
- Sound settings
- Visual notification preferences

## Troubleshooting

### Connection Issues
1. Ensure both devices are on the same WiFi network
2. Check if firewall is blocking connections
3. Try restarting the server (close and reopen app)
4. Use Settings > Connection > Network Discovery to find devices

### Message Not Syncing
1. Check connection status (should show green)
2. Verify both devices show the same number of connected peers
3. Try sending a test message
4. Restart both apps if needed

### IP Address Issues
1. Go to Settings > Connection > Network Discovery
2. Note your device's IP address
3. Share this with other users
4. Common format: 192.168.1.xxx or 10.0.0.xxx

## Technical Details

- **Protocol:** TCP over WiFi
- **Port:** 8080 (default)
- **Message Format:** JSON
- **Real-time:** Yes, instant message delivery
- **Offline Storage:** Messages stored locally
- **Security:** Plain text (encryption can be added later)

## Future Enhancements

- Bluetooth connectivity
- Internet-based messaging
- End-to-end encryption
- File sharing
- Group chat rooms
- User authentication
- Message history synchronization
