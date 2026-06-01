import 'package:flutter/material.dart';

/// Notification toggle widget for managing push notification preferences
class NotificationToggleWidget extends StatefulWidget {
  final String type;

  const NotificationToggleWidget({super.key, required this.type});

  @override
  State<NotificationToggleWidget> createState() =>
      _NotificationToggleWidgetState();
}

class _NotificationToggleWidgetState extends State<NotificationToggleWidget> {
  bool _isEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Switch(
      value: _isEnabled,
      onChanged: (value) {
        setState(() {
          _isEnabled = value;
        });
        // Notification preference logic would be implemented here
      },
      activeThumbColor: theme.colorScheme.primary,
    );
  }
}
