# Default Group Troubleshooting Guide

## Issue: Default Group Not Appearing in Group Section

### Quick Diagnosis Steps

#### 1. Check Server Logs
Look for these log messages when server starts:
```
🏗️ Initializing default group...
✅ Default group "adrdeConnomgpo" created successfully
📋 Group ID: 67890abcdef1234567890abc
```

If you don't see these logs, the default group wasn't created.

#### 2. Check Database Directly
```bash
# Connect to MongoDB
mongo your_database_name

# Check if default group exists
db.chats.findOne({name: "adrdeConnomgpo", isDefault: true})

# Expected result:
{
  "_id": ObjectId("67890abcdef1234567890abc"),
  "name": "adrdeConnomgpo",
  "isGroupChat": true,
  "isDefault": true,
  "participants": [...],
  "admin": ObjectId("000000000000000000000001"),
  ...
}
```

#### 3. Check User Membership
```bash
# Replace YOUR_USER_ID with actual user ID
db.chats.findOne({
  name: "adrdeConnomgpo", 
  isDefault: true,
  participants: ObjectId("YOUR_USER_ID")
})
```

#### 4. Use Debug Endpoints
```bash
# Check default group status
GET /api/test/default-group
Authorization: Bearer YOUR_JWT_TOKEN

# Check user's chats
GET /api/test/my-chats
Authorization: Bearer YOUR_JWT_TOKEN

# Force create default group
POST /api/test/create-default-group
Authorization: Bearer YOUR_JWT_TOKEN
```

### Common Issues & Solutions

#### Issue 1: Default Group Not Created
**Symptoms:**
- No default group logs on server start
- Database query returns null
- Debug endpoint shows `defaultGroupExists: false`

**Solutions:**
```bash
# Solution A: Restart server (triggers auto-creation)
npm restart

# Solution B: Use debug endpoint to force creation
curl -X POST http://localhost:5000/api/test/create-default-group \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Solution C: Manual database creation
mongo your_database_name --eval "
db.chats.insertOne({
  _id: ObjectId('67890abcdef1234567890abc'),
  name: 'adrdeConnomgpo',
  isGroupChat: true,
  isDefault: true,
  participants: [],
  admin: ObjectId('000000000000000000000001'),
  createdAt: new Date(),
  updatedAt: new Date(),
  lastMessage: null,
  lastMessageText: null,
  lastMessageTimestamp: null,
  lastMessageSender: null,
  lastMessageType: null,
  unreadCount: {}
})
"
```

#### Issue 2: User Not Added to Default Group
**Symptoms:**
- Default group exists but user not in participants
- Debug endpoint shows `wasUserInDefaultGroup: false`
- Group doesn't appear in user's chat list

**Solutions:**
```bash
# Solution A: Login/logout (triggers auto-add)
# Just login again - the login controller will add user

# Solution B: Use debug endpoint
GET /api/test/default-group  # This will auto-add user

# Solution C: Manual database addition
mongo your_database_name --eval "
db.chats.updateOne(
  {name: 'adrdeConnomgpo', isDefault: true},
  {\$addToSet: {participants: ObjectId('YOUR_USER_ID')}}
)
"
```

#### Issue 3: Frontend Not Showing Default Group
**Symptoms:**
- User is in default group (backend)
- Group doesn't appear in Flutter chat list
- No "DEFAULT" badge visible

**Solutions:**

**Check Flutter Debug Console:**
```
🔗 Socket: Requesting to join user groups for user: USER_ID
🏠 User joined DEFAULT group room: 67890abcdef1234567890abc (adrdeConnomgpo)
✅ Successfully joined X groups
```

**Debug Chat Provider:**
```dart
// Add to chat_provider.dart in loadChats method
print('🔍 All loaded chats:');
for (final chat in chats) {
  print('  - ${chat.name} (isDefault: ${chat.isDefault}, type: ${chat.type})');
}

print('🔍 Group chats after organization:');
for (final chat in state.groupChats) {
  print('  - ${chat.name} (isDefault: ${chat.isDefault})');
}
```

**Check API Response:**
```dart
// Add to chat_repository.dart in getAllChats method
print('🔍 Raw API response:');
print(response.data);
```

#### Issue 4: Socket Room Not Joined
**Symptoms:**
- User in default group
- Group appears in UI
- Messages not received in real-time

**Solutions:**
```bash
# Check socket connection logs
tail -f server.log | grep -i "join_user_groups"

# Expected logs:
# 🔗 User USER_ID requesting to join all their groups
# 🏠 User USER_ID joined DEFAULT group room: 67890abcdef1234567890abc (adrdeConnomgpo)
# ✅ User USER_ID successfully joined X chat rooms
```

**Force Socket Rejoin:**
```javascript
// In browser console (if using web)
socket.emit('join_user_groups', 'YOUR_USER_ID');
```

### Advanced Debugging

#### Enable Verbose Logging
Add to your server startup:
```javascript
// In app.ts or server.ts
process.env.DEBUG_DEFAULT_GROUP = 'true';
```

#### Database Queries for Deep Debugging
```bash
# Check all groups
db.chats.find({isGroupChat: true}).pretty()

# Check user's group memberships
db.chats.find({participants: ObjectId("YOUR_USER_ID")}).pretty()

# Check default group participants
db.chats.findOne({isDefault: true}, {participants: 1, name: 1})

# Count total users in default group
db.chats.aggregate([
  {$match: {isDefault: true}},
  {$project: {participantCount: {$size: "$participants"}}}
])
```

#### Socket.IO Room Debugging
```javascript
// Add to socket service for debugging
socket.on('join_user_groups', async (userId) => {
  console.log('🔍 Debug: User rooms before join:', Array.from(socket.rooms));
  
  // ... existing logic ...
  
  console.log('🔍 Debug: User rooms after join:', Array.from(socket.rooms));
  console.log('🔍 Debug: All server rooms:', Array.from(io.adapter.rooms.keys()));
});
```

### Step-by-Step Resolution Process

#### Step 1: Verify Server Setup
1. Check server logs for default group creation
2. Verify database connection
3. Confirm DefaultGroupService is imported and called

#### Step 2: Verify Database State
1. Check if default group exists in database
2. Verify group has correct structure
3. Check if user is in participants array

#### Step 3: Verify User Addition
1. Check login/registration logs
2. Use debug endpoint to add user
3. Verify user appears in participants

#### Step 4: Verify Frontend Integration
1. Check API response includes default group
2. Verify chat model parsing includes isDefault field
3. Check chat provider organization logic

#### Step 5: Verify Socket Integration
1. Check socket connection logs
2. Verify join_user_groups event emission
3. Check room joining confirmation

#### Step 6: Verify UI Display
1. Check chat list rendering
2. Verify default group styling
3. Check group ordering (default groups first)

### Prevention Measures

#### Server Monitoring
```bash
# Add to your monitoring script
curl -s http://localhost:5000/api/test/default-group \
  -H "Authorization: Bearer $JWT_TOKEN" | \
  jq '.data.defaultGroupExists'
```

#### Health Check Endpoint
Add to your health check:
```javascript
app.get('/health/default-group', async (req, res) => {
  const defaultGroup = await DefaultGroupService.getDefaultGroup();
  res.json({
    status: defaultGroup ? 'healthy' : 'unhealthy',
    defaultGroupExists: !!defaultGroup,
    participantCount: defaultGroup?.participants?.length || 0
  });
});
```

### Contact Support

If none of these solutions work:

1. **Collect Debug Information:**
   ```bash
   # Server logs
   tail -n 100 server.log > debug_server.log
   
   # Database state
   mongo your_db --eval "db.chats.find({isDefault: true}).pretty()" > debug_db.log
   
   # API responses
   curl -H "Authorization: Bearer $JWT" http://localhost:5000/api/test/default-group > debug_api.log
   ```

2. **Provide Information:**
   - Server logs
   - Database query results
   - API response examples
   - Flutter debug console output
   - Steps to reproduce the issue

3. **Temporary Workaround:**
   ```javascript
   // Add to user login success callback
   setTimeout(() => {
     fetch('/api/test/default-group', {
       headers: { 'Authorization': `Bearer ${token}` }
     });
   }, 1000);
   ```

This troubleshooting guide should help identify and resolve why the default group is not appearing in the group section.