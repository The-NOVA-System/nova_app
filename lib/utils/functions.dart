import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutterfire_ui/auth.dart';

HeaderBuilder headerImage(String assetName) {
  return (context, constraints, _) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SvgPicture.asset(
          assetName,
          semanticsLabel: 'Nova System logo'
      ),
    );
  };
}

HeaderBuilder headerIcon(IconData icon) {
  return (context, constraints, shrinkOffset) {
    return Padding(
      padding: const EdgeInsets.all(20).copyWith(top: 40),
      child: Icon(
        icon,
        color: Colors.blue,
        size: constraints.maxWidth / 4 * (1 - shrinkOffset),
      ),
    );
  };
}

SideBuilder sideImage(String assetName) {
  return (context, constraints) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(constraints.maxWidth / 4),
        child: SvgPicture.asset(
          assetName,
          semanticsLabel: 'Nova System logo'
      ),
      ),
    );
  };
}

SideBuilder sideIcon(IconData icon) {
  return (context, constraints) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Icon(
        icon,
        color: Colors.blue,
        size: constraints.maxWidth / 3,
      ),
    );
  };
}

String getClientID() {
  if (kIsWeb) {
    return '9939219864-s86mneko4kqcpfn1uqu7ka8eft6b09vr.apps.googleusercontent.com';
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return '9939219864-4u6unhlaebgq3tu8kahenhu64oe4i2dp.apps.googleusercontent.com';
    case TargetPlatform.iOS:
      return '9939219864-r3ekp661b5q5ia69pmrfakvj8ajc1e9d.apps.googleusercontent.com';
    case TargetPlatform.macOS:
      return '9939219864-r3ekp661b5q5ia69pmrfakvj8ajc1e9d.apps.googleusercontent.com';
    default:
      throw UnsupportedError(
        'There is no Sign-In ID for this platform.',
      );
  }
}