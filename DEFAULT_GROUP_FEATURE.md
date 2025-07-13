# Default Group Feature Implementation

This document describes the implementation of the automatic default group feature for the LAN-based chat application.

## Overview

Every user is automatically added to a default group named "adrdeConnomgpo" upon login or registration. This group serves as a common communication channel for all users.

## Backend Implementation

### 1. Database Schema Updates

**Chat Model** (`backend/src/database/model/Chat.ts`):
- Added `isDefault: boolean` field to identify default groups
- Default value is `false`

### 2. Default Group Service

**File**: `backend/src/services/defaultGroupService.ts`

Key features:
- **Group ID**: `67890abcdef1234567890abc` (fixed ObjectId)
- **Group Name**: `adrdeConnomgpo`
- **Auto-initialization**: Creates the default group on server startup
- **User management**: Adds users to the group automatically
- **Duplicate prevention**: Uses `$addToSet` to avoid duplicate members

**Methods**:
- `initializeDefaultGroup()`: Creates the default group if it doesn't exist
- `addUserToDefaultGroup(userId)`: Adds a user to the default group
- `getDefaultGroup()`: Retrieves the default group
- `isDefaultGroup(groupId)`: Checks if a group is the default group
- `removeUserFromDefaultGroup(userId)`: Removes a user from the default group

### 3. Database Initialization

**File**: `backend/src/database/index.ts`
- Calls `DefaultGroupService.initializeDefaultGroup()` when database connection opens
- Runs after role seeding

### 4. User Registration/Login Integration

**File**: `backend/src/controllers/user.controller.ts`
- Automatically adds users to default group during:
  - Registration (`signUp` function)
  - Login (`signIn` function) - as a fallback

### 5. Socket.IO Integration

**File**: `backend/src/socket/index.ts`

**New Event**: `join_user_groups`
- Automatically joins users to all their groups including the default group
- Emits confirmation with group details
- Logs default group joins separately for debugging

**Event Flow**:
1. User connects to socket
2. Socket emits `join_user_groups` with user ID
3. Server joins user to all their chat rooms
4. Server sends confirmation with group list

### 6. Constants Update

**File**: `backend/src/constants/index.ts`
- Added `JOIN_USER_GROUPS_EVENT = "join_user_groups"`

## Frontend Implementation

### 1. Chat Model Updates

**File**: `lib/core/models/chat_model.dart`
- Added `isDefault: bool` field
- Updated constructors, JSON parsing, and copyWith method
- Default value is `false`

### 2. Socket Service Updates

**File**: `lib/core/services/socket_service.dart`

**New Method**: `joinUserGroups(userId)`
- Emits `join_user_groups` event to server
- Called automatically after successful socket connection

**New Event Listener**: `user_groups_joined`
- Receives confirmation from server
- Logs successful group joins
- Highlights default group joins in debug output

### 3. Chat Provider Updates

**File**: `lib/features/chat/presentation/providers/chat_provider.dart`

**Enhanced Organization**:
- Separates default groups from regular groups
- Places default groups at the top of group chat list
- Maintains sorting within each category

### 4. UI Enhancements

**File**: `lib/features/chat/presentation/widgets/chat_list_item.dart`

**Visual Indicators**:
- "DEFAULT" badge for default groups
- Primary color highlighting for default group names
- Subtle background color and border for default groups
- Bold font weight for default group titles

## API Configuration

**File**: `lib/core/config/api_config.dart`
- No changes required - uses existing socket events and endpoints

## Usage Flow

### Server Startup
1. Database connects
2. Roles are seeded
3. Default group is created/verified
4. Server starts listening

### User Registration
1. User registers
2. User account is created
3. User is automatically added to default group
4. Registration completes

### User Login
1. User logs in
2. Authentication succeeds
3. User is added to default group (if not already present)
4. Socket connection is established
5. User automatically joins all group rooms including default

### Chat List Display
1. User opens chat list
2. Chats are fetched from server
3. Default groups appear at the top with special styling
4. Regular groups appear below, sorted by last message

## Testing

### Backend Test Script
**File**: `backend/test-default-group.js`

Run with: `node test-default-group.js`

Tests:
- Default group initialization
- User addition to default group
- Duplicate prevention
- Group state verification

### Manual Testing Steps

1. **Server Startup**:
   - Start the server
   - Check logs for "Default group created successfully"

2. **User Registration**:
   - Register a new user
   - Check logs for "User added to default group"

3. **Socket Connection**:
   - Login and connect
   - Check logs for "User joined DEFAULT group room"

4. **UI Verification**:
   - Open chat list
   - Verify default group appears at top with "DEFAULT" badge
   - Verify special styling (border, background, bold text)

## Configuration

### Customization Options

To change the default group name or ID, modify:
```typescript
// backend/src/services/defaultGroupService.ts
private static readonly DEFAULT_GROUP_ID = "your-custom-id-here";
private static readonly DEFAULT_GROUP_NAME = "YourCustomName";
```

### Environment Variables
No additional environment variables required - uses existing database configuration.

## Error Handling

- **Database Connection**: Graceful error logging if default group creation fails
- **User Addition**: Silent failure with logging if user addition fails
- **Socket Events**: Error responses sent to client if group joining fails
- **UI Fallbacks**: Default groups render normally if special styling fails

## Performance Considerations

- **Database Queries**: Uses efficient `$addToSet` operations
- **Socket Rooms**: Automatic room joining minimizes manual join operations
- **UI Rendering**: Default group prioritization doesn't impact rendering performance
- **Memory Usage**: Minimal additional memory overhead

## Security Considerations

- **User Verification**: Socket events verify user identity before group operations
- **Group Access**: Users can only join groups they're members of
- **Default Group**: Cannot be deleted or have its default status changed
- **Admin Rights**: Default group admin is set to system user

## Troubleshooting

### Common Issues

1. **Default group not appearing**:
   - Check server logs for initialization errors
   - Verify database connection
   - Run test script to verify creation

2. **Users not auto-joining**:
   - Check user controller logs during login/registration
   - Verify socket connection and event emission
   - Check socket server logs for join events

3. **UI not highlighting default group**:
   - Verify `isDefault` field in chat model
   - Check chat provider organization logic
   - Verify widget styling conditions

### Debug Commands

```bash
# Check default group in database
mongo chat_app --eval "db.chats.findOne({isDefault: true})"

# Monitor server logs
tail -f server.log | grep -i "default"

# Test socket connection
# Use browser dev tools to monitor socket events
```

## Future Enhancements

1. **Multiple Default Groups**: Support for multiple default groups per organization
2. **Default Group Settings**: Allow admins to configure default group behavior
3. **Welcome Messages**: Automatic welcome messages in default groups
4. **Group Templates**: Use default group as template for new groups
5. **Analytics**: Track default group usage and engagement

## Dependencies

### Backend
- `mongoose`: Database operations
- `socket.io`: Real-time communication
- `colors`: Console logging (via colorsUtils)

### Frontend
- `flutter_riverpod`: State management
- `socket_io_client`: Socket communication
- `flutter/material`: UI components

## Conclusion

The default group feature provides a seamless way to connect all users in a common communication channel. The implementation is robust, performant, and provides clear visual indicators in the UI while maintaining backward compatibility with existing chat functionality.