import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/avatar_service.dart';
import '../../../../core/services/simple_presence_service.dart';
import '../../../../core/widgets/simple_presence_indicator.dart';
import 'status_indicator.dart';

class UserAvatar extends StatefulWidget {
  final UserModel? user;
  final String? avatarUrl;
  final String? name;
  final double size;
  final bool showStatus;
  final bool showPresence;
  final String? status;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.user,
    this.avatarUrl,
    this.name,
    this.size = 40,
    this.showStatus = false,
    this.showPresence = true,
    this.status,
    this.onTap,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  late Stream<Map<String, dynamic>> _presenceStream;

  @override
  void initState() {
    super.initState();
    _presenceStream = SimplePresenceService.instance.presenceStream.map(
      (presences) => {'presences': presences},
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user?.displayName ?? widget.name ?? 'User';
    final displayAvatar = widget.user?.avatar ?? widget.avatarUrl;
    final userStatus = widget.user?.status.value ?? widget.status ?? 'offline';
    final userId = widget.user?.id;

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          // Avatar
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: ClipOval(
              child: displayAvatar != null && displayAvatar.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: displayAvatar,
                      width: widget.size,
                      height: widget.size,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          _buildPlaceholder(displayName),
                      errorWidget: (context, url, error) =>
                          _buildPlaceholder(displayName),
                    )
                  : _buildPlaceholder(displayName),
            ),
          ),

          // Status indicator
          if (widget.showStatus) ...[
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: widget.size * 0.3,
                height: widget.size * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: StatusIndicator(
                  status: userStatus,
                  size: widget.size * 0.15,
                ),
              ),
            ),
          ],

          // Presence indicator
          if (widget.showPresence && userId != null) ...[
            StreamBuilder<Map<String, dynamic>>(
              stream: _presenceStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final presences =
                    snapshot.data!['presences'] as Map<String, dynamic>;
                final userPresence = presences[userId];

                if (userPresence == null) {
                  return const SizedBox.shrink();
                }

                return Positioned(
                  bottom: widget.showStatus ? widget.size * 0.15 : 0,
                  right: widget.showStatus ? widget.size * 0.15 : 0,
                  child: SimplePresenceIndicator(
                    state: userPresence.state,
                    size: widget.size * 0.25,
                    showBorder: true,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String displayName) {
    // Create avatar data using the user ID or name as identifier
    final identifier = widget.user?.id ?? displayName;
    final avatarData = AvatarService.createAvatarData(
      identifier: identifier,
      displayName: displayName,
    );

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [avatarData.backgroundColor, avatarData.gradientColor],
        ),
      ),
      child: Center(
        child: Text(
          avatarData.initials,
          style: TextStyle(
            color: avatarData.textColor,
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.w600,
            letterSpacing:
                widget.size *
                0.02, // Add slight letter spacing for better appearance
          ),
        ),
      ),
    );
  }
}

// Group avatar for showing multiple users
class GroupAvatar extends StatelessWidget {
  final List<UserModel> users;
  final String? groupAvatarUrl;
  final double size;
  final VoidCallback? onTap;

  const GroupAvatar({
    super.key,
    required this.users,
    this.groupAvatarUrl,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: ClipOval(
          child: groupAvatarUrl != null && groupAvatarUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: groupAvatarUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildGroupPlaceholder(),
                  errorWidget: (context, url, error) =>
                      _buildGroupPlaceholder(),
                )
              : _buildGroupPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildGroupPlaceholder() {
    if (users.isEmpty) {
      // Use a deterministic color for empty groups
      final avatarData = AvatarService.createAvatarData(
        identifier: 'empty_group',
        displayName: 'Group',
      );

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [avatarData.backgroundColor, avatarData.gradientColor],
          ),
        ),
        child: Icon(Icons.group, size: size * 0.5, color: avatarData.textColor),
      );
    }

    if (users.length == 1) {
      return UserAvatar(user: users.first, size: size);
    }

    // Show multiple user avatars in a grid
    return _buildMultiUserAvatar();
  }

  Widget _buildMultiUserAvatar() {
    final displayUsers = users.take(4).toList();

    if (displayUsers.length == 2) {
      return Row(
        children: [
          Expanded(
            child: UserAvatar(user: displayUsers[0], size: size * 0.9),
          ),
          Expanded(
            child: UserAvatar(user: displayUsers[1], size: size * 0.9),
          ),
        ],
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: displayUsers.length,
      itemBuilder: (context, index) {
        return UserAvatar(user: displayUsers[index], size: size * 0.45);
      },
    );
  }
}

// Avatar with custom content
class CustomAvatar extends StatelessWidget {
  final Widget child;
  final double size;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const CustomAvatar({
    super.key,
    required this.child,
    this.size = 40,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? AppTheme.primaryColor.withOpacity(0.1),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: ClipOval(child: child),
      ),
    );
  }
}
