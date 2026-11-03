import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/bloc/language_bloc/language_bloc.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import '../../../config/colors.dart';
import '../../../utils/widgets/custom_appbar_without_navbar.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../utils/widgets/toast_message.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: CustomAppBar(
        title: context.tr('languageSelection', fallback: 'Language Selection'),
        showRefreshButton: false,
        showThemeToggle: false,
      ),
      body: BlocBuilder<LanguageBloc, LanguageState>(
        builder: (context, langState) {
          final currentCode = langState is LanguageLoaded
              ? langState.currentLanguage
              : Global.currentLanguage;

          final dynamicLanguages = langState is LanguageLoaded
              ? (langState.languageModel.data?.languages ?? [])
              : [];
          final hasDynamic = dynamicLanguages.isNotEmpty;

          final List<Map<String, String>> languagesToShow = hasDynamic
              ? dynamicLanguages
                  .map<Map<String, String>>((l) => <String, String>{
                        'code': l.code ?? '',
                        'name': l.name ?? '',
                        'nativeName': (l.nativeName != null &&
                                l.nativeName!.isNotEmpty)
                            ? l.nativeName!
                            : (l.name ?? ''),
                      })
                  .toList()
              : Global.supportedLanguages;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: languagesToShow.length,
            itemBuilder: (context, index) {
              final language = languagesToShow[index];
              final code = language['code'] ?? 'en';
              final isSelected = code == currentCode;

              return Card(
                margin: EdgeInsets.only(bottom: 12.h),
                elevation: isSelected ? 4 : 1,
                color: isSelected
                    ? AppColors.primaryColor.withValues(alpha: 0.1)
                    : Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primaryColor
                        : Colors.transparent,
                    width: 2.w,
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  leading: Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: CustomText(
                        text: code.toUpperCase(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  title: CustomText(
                    text: (language['nativeName'] ?? language['name'] ?? ''),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primaryColor
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  subtitle: CustomText(
                    text: (language['name'] ?? ''),
                    color: isSelected
                        ? AppColors.primaryColor.withValues(alpha: 0.7)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: AppColors.primaryColor,
                          size: 24.sp,
                        )
                      : null,
                  onTap: () {
                    if (!isSelected) {
                      context.read<LanguageBloc>().add(ChangeLanguage(code));
                      context
                          .read<LanguageListBloc>()
                          .add(FetchLanguageList(locale: code));


                      ToastManager.show(
                        context: context,
                        message: 'Language changed to ${language['name'] ?? code}',
                        type: ToastType.success,
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
