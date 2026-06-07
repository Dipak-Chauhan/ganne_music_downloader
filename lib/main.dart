import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable gesture resampling for buttery-smooth scrolling on
  // high refresh rate displays (90Hz, 120Hz, 144Hz).
  GestureBinding.instance.resamplingEnabled = true;

  runApp(const ProviderScope(child: GanneApp()));
}
