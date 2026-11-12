import 'package:flutter/material.dart';

/// 화면 아래 짧은 알림. 앞 알림이 남아 있으면 지우고 바로 보여 줘 알림이 줄줄이 쌓이지 않게 한다.
void showAppMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
