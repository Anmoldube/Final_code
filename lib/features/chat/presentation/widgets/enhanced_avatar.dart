import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/services/avatar_service.dart';
import '../../../../core/models/user_model.dart';
import 'status_indicator.dart';

/// Enhanced avatar widget with better customization and features
class EnhancedAvatar extends StatelessWidget {
  final UserModel? user;
  final String? avatarUrl;
  final String? name;
  final String? userId;
  final double size;
  final bool showStatus;
  final String? status;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final bool isSquare;
  final bool showOnlineIndicator;
  final Widget? customStatusIndicator;
  final bool enableHero;
  final String? heroTag;

  const EnhancedAvatar({
    super.key,
    this.user,
    this.avatarUrl,
    this.name,
    this.userId,
    this.size = 40,
    this.showStatus = false,
    this.status,
    this.onTap,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 1,
    this.isSquare = false,
    this.showOnlineIndicator = false,
    this.customStatusIndicator,
    this.enableHero = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = user?.displayName ?? name ?? 'User';
    final displayAvatar = user?.avatar ?? avatarUrl;
    final userStatus = user?.status.value ?? status ?? 'offline';
    final identifier = user?.id ?? userId ?? displayName;

    Widget avatarWidget = GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Main avatar
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isSquare ? BorderRadius.circular(size * 0.15) : null,
              border: showBorder ? Border.all(
                color: borderColor ?? Theme.of(context).dividerColor,
                width: borderWidth,
              ) : null,
            ),
            child: ClipRRect(
              borderRadius: isSquare 
                  ? BorderRadius.circular(size * 0.15) 
                  : BorderRadius.circular(size / 2),
              child: AvatarService.isValidImageUrl(displayAvatar)
                  ? CachedNetworkImage(
                      imageUrl: displayAvatar!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildPlaceholder(
                        identifier: identifier,
                        displayName: displayName,
                      ),
                      errorWidget: (context, url, error) => _buildPlaceholder(
                        identifier: identifier,
                        displayName: displayName,
                      ),
                    )
                  : _buildPlaceholder(
                      identifier: identifier,
                      displayName: displayName,
                    ),
            ),
          ),

          // Status indicator
          if (showStatus || showOnlineIndicator) ...[
            Positioned(
              bottom: 0,
              right: 0,
              child: customStatusIndicator ?? Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: StatusIndicator(
                  status: userStatus,
                  size: size * 0.15,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    // Wrap with Hero widget if enabled
    if (enableHero && heroTag != null) {
      avatarWidget = Hero(
        tag: heroTag!,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildPlaceholder({
    required String identifier,
    required String displayName,
  }) {
    final avatarData = AvatarService.createAvatarData(
      identifier: identifier,
      displayName: displayName,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isSquare ? BorderRadius.circular(size * 0.15) : null,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            avatarData.backgroundColor,
            avatarData.gradientColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          avatarData.initials,
          style: TextStyle(
            color: avatarData.textColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            letterSpacing: size * 0.02,
          ),
        ),
      ),
    );
  }
}

/// Avatar with typing indicator
class TypingAvatar extends StatefulWidget {
  final UserModel user;
  final double size;
  final bool isTyping;

  const TypingAvatar({
    super.key,
    required this.user,
    this.size = 40,
    required this.isTyping,
  });

  @override
  State<TypingAvatar> createState() => _TypingAvatarState();
}

class _TypingAvatarState extends State<TypingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(TypingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTyping != oldWidget.isTyping) {
      if (widget.isTyping) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isTyping ? _animation.value : 1.0,
          child: EnhancedAvatar(
            user: widget.user,
            size: widget.size,
            showBorder: true,
            borderColor: widget.isTyping ? Colors.green : null,
            borderWidth: widget.isTyping ? 2 : 1,
          ),
        );
      },
    );
  }
}

/// Stack of avatars for group display
class AvatarStack extends StatelessWidget {
  final List<UserModel> users;
  final double size;
  final int maxVisible;
  final double overlap;
  final VoidCallback? onTap;

  const AvatarStack({
    super.key,
    required this.users,
    this.size = 32,
    this.maxVisible = 3,
    this.overlap = 0.6,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleUsers = users.take(maxVisible).toList();
    final extraCount = users.length - maxVisible;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + (visibleUsers.length - 1) * (size * overlap),
        height: size,
        child: Stack(
          children: [
            // User avatars
            ...visibleUsers.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              return Positioned(
                left: index * (size * overlap),
                child: EnhancedAvatar(
                  user: user,
                  size: size,
                  showBorder: true,
                  borderColor: Theme.of(context).scaffoldBackgroundColor,
                  borderWidth: 2,
                ),
              );
            }),
            
            // Extra count indicator
            if (extraCount > 0)
              Positioned(
                left: visibleUsers.length * (size * overlap),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '+$extraCount',
                      style: TextStyle(
                        fontSize: size * 0.3,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}