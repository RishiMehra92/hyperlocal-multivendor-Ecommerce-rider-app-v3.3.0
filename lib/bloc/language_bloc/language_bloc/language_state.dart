part of 'language_bloc.dart';

abstract class LanguageState extends Equatable {
  const LanguageState();

  @override
  List<Object?> get props => [];
}

class LanguageInitial extends LanguageState {}

class LanguageLoading extends LanguageState {}

class LanguageLoaded extends LanguageState {
  final LanguageModel languageModel;
  final String defaultLanguage;
  final String currentLanguage;
  final Locale locale;
  final bool isRtl;

  const LanguageLoaded({
    required this.languageModel,
    required this.defaultLanguage,
    required this.currentLanguage,
    required this.locale,
    this.isRtl = false,
  });

  @override
  List<Object?> get props =>
      [languageModel, defaultLanguage, currentLanguage, locale, isRtl];
}

class LanguageError extends LanguageState {
  final String message;

  const LanguageError({required this.message});

  @override
  List<Object?> get props => [message];
}
