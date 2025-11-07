import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDb.open();
  runApp(const ProviderScope(child: FastDownApp()));
}
