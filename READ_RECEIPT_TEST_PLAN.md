# 📋 Read Receipt Test Plan

## 🎯 **Expected Behavior**
- **Single tick (grey)**: Message sent to server
- **Double tick (grey)**: Message delivered to recipient
- **Double tick (blue)**: Message read by recipient

## 🧪 **Test Steps**

### **1. Basic Read Receipt Test**
1. **Open two browser windows/tabs**
2. **Login with different users** (e.g., test@gmail.com and another user)
3. **Send a message from User A to User B**
4. **Verify status progression**:
   - Message shows single tick initially
   - Message shows double grey tick when delivered
   - Message shows double blue tick when read

### **2. Debug Log Monitoring**
Watch for these debug messages in the console:

#### **Frontend Logs to Watch:**
```
🔍 MessageStatusProvider: markAsRead called for message: [messageId]
📡 Socket: Emitting messageRead event for message: [messageId]
📖 Socket: Message read: [data]
🔍 MessageStatusProvider: Received message read event: [data]
✅ MessageStatusProvider: Updated readBy for [messageId]
🔄 MessageStatusProvider: Updated message status to read for [messageId]
🎯 MessageStatusWidget: Message [messageId] status: MessageStatus.read
```

#### **Backend Logs to Watch:**
```
📖 Marking message as read: [messageId] by user: [userId]
✅ Message marked as read successfully: [messageId]
✅ Message delivery events emitted for: [messageId]
```

### **3. Manual Test Commands**

#### **Test 1: Check Current Status**
Open browser console and run:
```javascript
// Check current message statuses
console.log('Current messages and their statuses');
```

#### **Test 2: Force Read Receipt**
The app should automatically mark visible messages as read when they're viewed.

### **4. Verification Points**

#### **✅ UI Verification:**
- [ ] Messages from other users show appropriate tick status
- [ ] Own messages show status ticks correctly
- [ ] Status updates happen in real-time
- [ ] Blue double ticks appear when messages are read

#### **✅ Socket Event Verification:**
- [ ] `messageRead` events are emitted when messages are read
- [ ] `messageStatusUpdate` events are received by clients
- [ ] Events contain correct data (messageId, readBy, timestamp)

#### **✅ Database Verification:**
- [ ] Message status updated to `READ` in database
- [ ] `readBy` array contains user IDs
- [ ] `readAt` timestamp is set correctly

## 🐛 **Known Issues**

### **1. Time Sync Issue**
- **Problem**: System time is set to 2025 (future date)
- **Impact**: May cause delivery logic problems
- **Solution**: Sync system time (requires admin privileges)
- **Command**: `w32tm /resync` (Windows)

### **2. Already Marked Messages**
- **Issue**: Messages already marked as read in previous sessions
- **Status**: Shows `alreadyMarked=true` in logs
- **Solution**: Implemented, should work for new messages

## 🔧 **Debugging Tips**

### **1. Clear Message Cache**
If messages aren't updating:
1. Clear browser cache
2. Restart the application
3. Check console for error messages

### **2. Check Socket Connection**
Verify socket connection in browser dev tools:
- Go to Network tab
- Look for WebSocket connection
- Check if messages are being sent/received

### **3. Monitor Database Changes**
Use MongoDB compass or similar to check:
- Message status field
- readBy array
- readAt timestamp

## 📝 **Test Results**

After running tests, document:
- [ ] Single tick → Double grey tick working
- [ ] Double grey tick → Double blue tick working
- [ ] Real-time updates working
- [ ] Socket events being emitted/received
- [ ] Database updates working

## 🎉 **Success Criteria**

The read receipt system is working correctly when:
1. **Messages progress through all status stages**
2. **Debug logs show proper event flow**
3. **UI updates in real-time**
4. **Database reflects correct status**
5. **Multiple users can see each other's read receipts**