// ignore_for_file: avoid_web_libraries_in_flutter

// ignore: deprecated_member_use
import 'dart:html' as html;

Future<void> showBrowserNotification({
  required String title,
  required String body,
}) async {
  if (!html.Notification.supported) {
    return;
  }
  var permission = html.Notification.permission;
  if (permission == 'default') {
    permission = await html.Notification.requestPermission();
  }
  if (permission != 'granted') {
    return;
  }
  html.Notification(title, body: body);
}
