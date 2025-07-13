import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class TypingIndicator extends StatefulWidget {
  final List<String> typingUsers;
  final double? height;
  final Color? backgroundColor;
  final Color? dotColor;

  const TypingIndicator({
    super.key,
    this.typingUsers = const [],
    this.height,
    this.backgroundColor,
    this.dotColor,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late List<AnimationController> _dotControllers;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();

    // Main fade animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Dot bounce animations
    _dotControllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _dotAnimations = _dotControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _startAnimations();
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.typingUsers.isNotEmpty && oldWidget.typingUsers.isEmpty) {
      // Start showing
      _animationController.forward();
      _startDotAnimations();
    } else if (widget.typingUsers.isEmpty && oldWidget.typingUsers.isNotEmpty) {
      // Start hiding
      _animationController.reverse();
      _stopDotAnimations();
    }
  }

  void _startAnimations() {
    if (widget.typingUsers.isNotEmpty) {
      _animationController.forward();
      _startDotAnimations();
    }
  }

  void _startDotAnimations() {
    for (int i = 0; i < _dotControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _dotControllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopDotAnimations() {
    for (final controller in _dotControllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: widget.height ?? 50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              widget.backgroundColor ??
              (isDark ? AppTheme.darkSurface : Colors.grey[100]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Typing dots animation
            _buildTypingDots(),
            const SizedBox(width: 12),

            // Typing text
            Expanded(
              child: Text(
                _buildTypingText(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDots() {
    return Container(
      width: 40,
      height: 20,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _dotAnimations[index],
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.translate(
                  offset: Offset(0, -6 * _dotAnimations[index].value),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.dotColor ?? AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  String _buildTypingText() {
    if (widget.typingUsers.isEmpty) {
      return '';
    } else if (widget.typingUsers.length == 1) {
      return '${widget.typingUsers.first} is typing...';
    } else if (widget.typingUsers.length == 2) {
      return '${widget.typingUsers.first} and ${widget.typingUsers.last} are typing...';
    } else {
      return '${widget.typingUsers.first} and ${widget.typingUsers.length - 1} others are typing...';
    }
  }
}

// Simple typing indicator without user names
class SimpleTypingIndicator extends StatefulWidget {
  final Color? dotColor;
  final double dotSize;
  final Duration animationDuration;

  const SimpleTypingIndicator({
    super.key,
    this.dotColor,
    this.dotSize = 6,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  @override
  State<SimpleTypingIndicator> createState() => _SimpleTypingIndicatorState();
}

class _SimpleTypingIndicatorState extends State<SimpleTypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: 0.5 + (_animations[index].value * 0.5),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: widget.dotColor ?? AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// Typing indicator for message bubbles
class MessageTypingIndicator extends StatelessWidget {
  final bool isMe;
  final String? userName;

  const MessageTypingIndicator({super.key, this.isMe = false, this.userName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(
        left: isMe ? 60 : 0,
        right: isMe ? 0 : 60,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe
                  ? AppTheme.primaryColor
                  : (isDark ? AppTheme.darkSurface : Colors.grey[200]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMe && userName != null) ...[
                  Text(
                    userName!,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                SimpleTypingIndicator(
                  dotColor: isMe
                      ? Colors.white
                      : (isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary),
                  dotSize: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
