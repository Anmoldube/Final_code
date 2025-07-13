import 'package:flutter/material.dart';
import '../services/simple_presence_service.dart';

class ActivityTracker extends StatefulWidget {
  final Widget child;

  const ActivityTracker({super.key, required this.child});

  @override
  State<ActivityTracker> createState() => _ActivityTrackerState();
}

class _ActivityTrackerState extends State<ActivityTracker> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _trackActivity(),
      onScaleStart: (_) => _trackActivity(),
      onScaleUpdate: (_) => _trackActivity(),
      child: Listener(
        onPointerDown: (_) => _trackActivity(),
        onPointerMove: (_) => _trackActivity(),
        onPointerUp: (_) => _trackActivity(),
        child: widget.child,
      ),
    );
  }

  void _trackActivity() {
    SimplePresenceService.instance.trackActivity();
  }
}
