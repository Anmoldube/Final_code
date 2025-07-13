# Backend Presence System Integration

## Socket Events to Handle

The Flutter app will send these presence events that the backend needs to handle:

### 1. User Status Updates

```javascript
// Client sends this when status changes
socket.emit("updateUserStatus", "online"); // or 'away', 'offline'

// Server should broadcast to all users
socket.broadcast.emit("userStatusChanged", {
  type: "statusChanged",
  userId: user._id,
  status: "online", // 'online', 'away', 'offline'
  lastSeen: new Date().toISOString(),
  timestamp: new Date().toISOString(),
});
```

### 2. Heartbeat/Presence Ping

```javascript
// Client sends periodic heartbeat
socket.emit("updateUserStatus", "online");

// Server updates lastSeen and broadcasts if needed
```

### 3. Idle Detection

```javascript
// Client goes idle after inactivity
socket.emit("updateUserStatus", "away");

// Client becomes active again
socket.emit("updateUserStatus", "online");
```

### 4. Connection Events

```javascript
// On connect - set user online
io.on("connection", (socket) => {
  // When user authenticates
  socket.on("authenticate", (data) => {
    // Set user as online
    // Broadcast to others
  });

  // On disconnect - set user offline
  socket.on("disconnect", () => {
    // Set user as offline
    // Update lastSeen
    // Broadcast to others
  });
});
```

## Backend Implementation Example

```javascript
// In your socket handler
class PresenceHandler {
  constructor(io) {
    this.io = io;
    this.userPresence = new Map(); // Store user presence in memory
  }

  handleUserStatus(socket, status) {
    const userId = socket.userId; // From authentication
    const now = new Date();

    // Update presence
    this.userPresence.set(userId, {
      status,
      lastSeen: now,
      socketId: socket.id,
    });

    // Broadcast to all connected users
    socket.broadcast.emit("userStatusChanged", {
      type: "statusChanged",
      userId: userId,
      status: status,
      lastSeen: now.toISOString(),
      timestamp: now.toISOString(),
    });

    // Optional: Save to database for persistence
    this.savePresenceToDb(userId, status, now);
  }

  handleDisconnect(socket) {
    const userId = socket.userId;
    const now = new Date();

    // Set as offline
    this.userPresence.set(userId, {
      status: "offline",
      lastSeen: now,
      socketId: null,
    });

    // Broadcast offline status
    socket.broadcast.emit("userStatusChanged", {
      type: "offline",
      userId: userId,
      status: "offline",
      lastSeen: now.toISOString(),
      timestamp: now.toISOString(),
    });

    this.savePresenceToDb(userId, "offline", now);
  }

  async savePresenceToDb(userId, status, lastSeen) {
    try {
      await User.findByIdAndUpdate(userId, {
        status,
        lastSeen,
      });
    } catch (error) {
      console.error("Error saving presence:", error);
    }
  }
}

// Usage in your socket setup
const presenceHandler = new PresenceHandler(io);

io.on("connection", (socket) => {
  socket.on("updateUserStatus", (status) => {
    presenceHandler.handleUserStatus(socket, status);
  });

  socket.on("disconnect", () => {
    presenceHandler.handleDisconnect(socket);
  });
});
```

## Database Schema Update

Add presence fields to your User model:

```javascript
const userSchema = new mongoose.Schema({
  // ... existing fields
  status: {
    type: String,
    enum: ["online", "away", "offline"],
    default: "offline",
  },
  lastSeen: {
    type: Date,
    default: Date.now,
  },
  presenceSettings: {
    showLastSeen: { type: Boolean, default: true },
    enableIdleDetection: { type: Boolean, default: true },
    alwaysShowOnline: { type: Boolean, default: false },
    appearOffline: { type: Boolean, default: false },
  },
});
```

## API Endpoints (Optional)

```javascript
// GET /api/users/presence/:userId
app.get("/api/users/presence/:userId", async (req, res) => {
  const user = await User.findById(req.params.userId).select(
    "status lastSeen presenceSettings"
  );
  res.json(user);
});

// PUT /api/users/presence/settings
app.put("/api/users/presence/settings", async (req, res) => {
  const { userId } = req.user; // from auth middleware
  const settings = req.body;

  await User.findByIdAndUpdate(userId, {
    presenceSettings: settings,
  });

  res.json({ success: true });
});
```

## Testing the Integration

1. **Login with multiple users** in different browser tabs
2. **Check presence indicators** show correctly in chat lists
3. **Test idle detection** by leaving a tab inactive
4. **Test manual status changes** from profile settings
5. **Verify offline status** when closing browser tabs
6. **Check last seen timestamps** are accurate

The Flutter app is now ready to work with any backend that implements these socket events!
