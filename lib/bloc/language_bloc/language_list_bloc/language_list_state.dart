part of 'language_list_bloc.dart';

abstract class LanguageListState extends Equatable {
  const LanguageListState();
  @override
  List<Object?> get props => [];
}

class LanguageListInitial extends LanguageListState {}

class LanguageListLoading extends LanguageListState {}

class LanguageListLoaded extends LanguageListState {
  final LanguageLabelsModel? languageLabelsModel;
  final Map<String, String> labels;
  final String locale;
  final String direction;

  const LanguageListLoaded({
    this.languageLabelsModel,
    required this.labels,
    required this.locale,
    required this.direction,
  });

  @override
  List<Object?> get props => [languageLabelsModel, labels, locale, direction];
}

class LanguageListFailed extends LanguageListState {
  final String error;

  const LanguageListFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
