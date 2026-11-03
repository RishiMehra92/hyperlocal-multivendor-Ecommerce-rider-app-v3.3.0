import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/global.dart';
import '../../../l10n/default_en_labels.dart';
import '../../../model/language_model/language_list_model.dart';
import '../../../repo/language_repo.dart';

part 'language_list_event.dart';
part 'language_list_state.dart';

class LanguageListBloc extends Bloc<LanguageListEvent, LanguageListState> {
  final LanguageRepo languageRepo;

  LanguageListBloc({LanguageRepo? languageRepo})
      : languageRepo = languageRepo ?? LanguageRepo(),
        super(_resolveInitialState(languageRepo ?? LanguageRepo())) {
    on<FetchLanguageList>(_onFetchLanguageList);
  }

  static LanguageListState _resolveInitialState(LanguageRepo repo) {
    final currentLang = Global.currentLanguage;
    final cached = LanguageRepo.getCachedLanguageLabelsSync(currentLang);
    if (cached != null &&
        cached.data != null &&
        cached.data!.labels != null &&
        cached.data!.labels!.isNotEmpty) {
      LanguageRepo.activeLabels = Map<String, dynamic>.from(cached.data!.labels!);
      LanguageRepo.activeLocale = currentLang;
      return LanguageListLoaded(
        languageLabelsModel: cached,
        labels: cached.data!.labels!,
        locale: cached.data?.locale ?? currentLang,
        direction: cached.data?.direction ?? 'ltr',
      );
    }
    if (currentLang == 'en' || currentLang.isEmpty) {
      LanguageRepo.activeLabels = Map<String, dynamic>.from(defaultEnglishLabels);
      LanguageRepo.activeLocale = 'en';
      return LanguageListLoaded(
        languageLabelsModel: LanguageLabelsModel(
          success: true,
          data: LanguageLabels(
            locale: 'en',
            direction: 'ltr',
            labels: Map<String, String>.from(defaultEnglishLabels),
          ),
        ),
        labels: Map<String, String>.from(defaultEnglishLabels),
        locale: 'en',
        direction: 'ltr',
      );
    }
    return LanguageListInitial();
  }

  Future<void> _onFetchLanguageList(
    FetchLanguageList event,
    Emitter<LanguageListState> emit,
  ) async {
    if (state is! LanguageListLoaded || (state as LanguageListLoaded).locale != event.locale) {
      final cached = LanguageRepo.getCachedLanguageLabelsSync(event.locale) ??
          await languageRepo.getCachedLanguageLabels(event.locale);
      if (cached != null && cached.data != null && cached.data!.labels != null) {
        final cachedLabels = cached.data!.labels!;
        LanguageRepo.activeLabels = Map<String, dynamic>.from(cachedLabels);
        LanguageRepo.activeLocale = event.locale;
        emit(LanguageListLoaded(
          languageLabelsModel: cached,
          labels: cachedLabels,
          locale: cached.data?.locale ?? event.locale,
          direction: cached.data?.direction ?? 'ltr',
        ));
      } else if (state is! LanguageListLoaded) {
        emit(LanguageListLoading());
      }
    }

    try {
      final response = await languageRepo.fetchLanguageLabels(event.locale);
      if (response.success == true && response.data != null) {
        final freshLabels = response.data?.labels ?? {};
        final freshDirection = response.data?.direction ?? 'ltr';
        final freshLocale = response.data?.locale ?? event.locale;

        if (state is LanguageListLoaded) {
          final current = state as LanguageListLoaded;
          final bool isSameLocale = current.locale == freshLocale;
          final bool isSameDirection = current.direction == freshDirection;
          final bool areLabelsEqual = mapEquals(current.labels, freshLabels);

          if (isSameLocale && isSameDirection && areLabelsEqual) {
            return;
          }
        }

        LanguageRepo.activeLabels = Map<String, dynamic>.from(freshLabels);
        LanguageRepo.activeLocale = freshLocale;
        emit(LanguageListLoaded(
          languageLabelsModel: response,
          labels: freshLabels,
          locale: freshLocale,
          direction: freshDirection,
        ));
      } else if (state is! LanguageListLoaded) {
        emit(LanguageListFailed(
          error: response.message ?? 'Failed to load language labels',
        ));
      }
    } catch (e) {
      if (state is! LanguageListLoaded) {
        emit(LanguageListFailed(error: e.toString()));
      }
    }
  }
}
