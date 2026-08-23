import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';
import 'app.dart';
import 'data/db.dart';
import 'ui/widgets/app_restart_scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDb.open();
  VideoPlayerMediaKit.ensureInitialized(
    macOS: true,
    windows: true,
    linux: true,
  );

  runApp(const AppRestartScope(child: ProviderScope(child: FastDownApp())));
}
