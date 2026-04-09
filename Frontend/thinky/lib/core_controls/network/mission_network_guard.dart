import 'package:flutter/material.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/network/connectivity_service.dart';
import 'package:thinky/shared_controls/widgets/error_handler_ui.dart';

/// All in-app missions talk to the backend; block entry when there is no network.
class MissionNetworkGuard {
  MissionNetworkGuard._();

  static Future<bool> ensureOnlineForMission(
    BuildContext context,
    String? missionPath,
  ) async {
    if (missionPath == null || missionPath.isEmpty) return true;

    final ok = await ConnectivityService.instance.hasConnection;
    if (!ok && context.mounted) {
      ErrorHandlerUI.showWarning(context, Common.offlineMissionBody);
    }
    return ok;
  }
}
