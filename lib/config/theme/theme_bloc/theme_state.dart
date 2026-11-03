import 'package:equatable/equatable.dart';

import '../../constant.dart';

class ThemeState extends Equatable {
  final String currentTheme;

  const ThemeState({this.currentTheme = AppConstant.defaultTheme});

  ThemeState copyWith({String? currentTheme}) {
    return ThemeState(currentTheme: currentTheme ?? this.currentTheme);
  }

  @override
  // TODO: implement props
  List<Object?> get props => [currentTheme];
}
