import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/assets/font_family.dart';
import 'package:homeease/core/utils/media_querry_extention.dart';
import 'package:homeease/models/languages_model.dart';
import 'package:homeease/widgets/custom_app_bar.dart';
import '../../core/services/localStorage/my-local-controller.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/labels.dart';
import 'bloc/languages_bloc.dart';
import 'bloc/languages_event.dart';
import 'bloc/languages_state.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen>
    with SingleTickerProviderStateMixin {
  final LanguagesList languagesList = LanguagesList();
  Locale? savedLocale;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: Labels.languages),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.onSecondary.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.translate_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Labels.appLanguage,
                          style: TextStyle(
                            fontSize: context.scaledFont(16),
                            color: theme.colorScheme.onSecondary,
                            fontFamily: FontFamily.fontsPoppinsSemiBold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Labels.selectYourPreferredLanguage,
                          style: TextStyle(
                            fontSize: context.scaledFont(12),
                            color: theme.colorScheme.onSecondary,
                            fontFamily: FontFamily.fontsPoppinsRegular,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Languages List
            Expanded(
              child: BlocBuilder<LanguageBloc, LanguageState>(
                builder: (context, state) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: languagesList.languages.length,
                    itemBuilder: (context, index) {
                      final lang = languagesList.languages[index];

                      final isSelected =
                          state.currentLocale.languageCode ==
                              lang.locale.languageCode &&
                          (state.currentLocale.countryCode ?? '') ==
                              (lang.locale.countryCode ?? '');

                      return _buildLanguageTile(
                        context,
                        lang: lang,
                        isSelected: isSelected,
                        index: index,
                        onTap: () {
                          context.read<LanguageBloc>().add(
                            ChangeLanguage(context, lang.locale),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context, {
    required LanguageModel lang,
    required bool isSelected,
    required int index,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    // Staggered animation
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          (index * 0.1).clamp(0.0, 1.0),
          ((index * 0.1) + 0.3).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.6)
                      : theme.colorScheme.onSecondary.withValues(alpha: 0.2),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: isSelected ? 12 : 6,
                    offset: Offset(0, isSelected ? 4 : 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: theme.colorScheme.primary.withValues(
                    alpha: 0.05,
                  ),
                  highlightColor: theme.colorScheme.primary.withValues(
                    alpha: 0.02,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Flag with subtle border
                        Container(
                          width: 52,
                          height: 52,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.2,
                                    )
                                  : theme.colorScheme.onSecondary.withValues(
                                      alpha: 0.1,
                                    ),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(lang.flag, fit: BoxFit.cover),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Language info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.englishName,
                                style: TextStyle(
                                  fontSize: context.scaledFont(14.5),
                                  color: theme.colorScheme.onSecondary,
                                  fontFamily: FontFamily.fontsPoppinsSemiBold,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                lang.localName,
                                style: TextStyle(
                                  fontSize: context.scaledFont(12),
                                  color: theme.colorScheme.onSecondary
                                      .withValues(alpha: 0.8),
                                  fontFamily: FontFamily.fontsPoppinsRegular,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Selection indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          width: isSelected ? 32 : 32,
                          height: isSelected ? 32 : 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSecondary.withValues(
                                      alpha: 0.3,
                                    ),
                              width: isSelected ? 0 : 1.5,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  color: theme.colorScheme.onPrimary,
                                  size: 18,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadSavedLocale() async {
    final langCode = await LocalStorage.getData(key: AppKeys.languageCode);
    final countryCode = await LocalStorage.getData(key: AppKeys.countryCode);

    if (langCode != null) {
      final locale = (countryCode != null && countryCode.isNotEmpty)
          ? Locale(langCode, countryCode)
          : Locale(langCode);

      savedLocale = locale;

      if (mounted) {
        context.read<LanguageBloc>().add(ChangeLanguage(context, locale));
      }
    }
  }
}

class LanguagesList {
  final List<LanguageModel> _languages = [
    LanguageModel(
      locale: const Locale('en'),
      englishName: "English",
      localName: "English",
      flag: "assets/images/united-states-of-america.png",
    ),
    LanguageModel(
      locale: const Locale('ar'),
      englishName: "Arabic",
      localName: "العربية",
      flag: "assets/images/united-arab-emirates.png",
    ),
    LanguageModel(
      locale: const Locale('es'),
      englishName: "Spanish",
      localName: "Español",
      flag: "assets/images/spain.png",
    ),
    LanguageModel(
      locale: const Locale('fr'),
      englishName: "French (France)",
      localName: "Français - France",
      flag: "assets/images/france.png",
    ),
    LanguageModel(
      locale: const Locale('fr', 'CA'),
      englishName: "French (Canada)",
      localName: "Français - Canadien",
      flag: "assets/images/canada.png",
    ),
    LanguageModel(
      locale: const Locale('pt', 'BR'),
      englishName: "Portuguese (Brazil)",
      localName: "Português - Brasil",
      flag: "assets/images/brazil.png",
    ),
    LanguageModel(
      locale: const Locale('ko'),
      englishName: "Korean",
      localName: "한국어",
      flag: "assets/images/united-states-of-america.png",
    ),
  ];

  List<LanguageModel> get languages => _languages;
}
