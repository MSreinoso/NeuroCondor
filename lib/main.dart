import 'package:flutter/material.dart';

import 'app.dart';
import 'data/local_progress_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = LocalProgressRepository();
  await repository.load();
  runApp(NeuroCondorApp(repository: repository));
}
