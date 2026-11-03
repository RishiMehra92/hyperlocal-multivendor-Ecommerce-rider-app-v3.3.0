abstract class ThemeEvent {}

class ToggleTheme extends ThemeEvent {}

class LoadTheme extends ThemeEvent {}

class SetTheme extends ThemeEvent {
  final String theme;
  SetTheme(this.theme);
}
