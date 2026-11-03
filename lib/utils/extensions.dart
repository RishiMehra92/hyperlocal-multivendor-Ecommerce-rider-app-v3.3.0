import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/config/theme/theme_bloc/theme_bloc.dart';

extension ContextSize on BuildContext {
  double get height => MediaQuery.of(this).size.height;
  double get width => MediaQuery.of(this).size.width;

  Size get size => MediaQuery.of(this).size;
}

extension ThemeContext on BuildContext {
  bool get isDarkMode => select((ThemeBloc bloc) => bloc.isDarkMode);
}
