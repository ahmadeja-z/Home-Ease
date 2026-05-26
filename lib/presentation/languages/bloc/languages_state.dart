import 'dart:ui';

import 'package:equatable/equatable.dart';

class LanguageState extends Equatable {
  final Locale currentLocale;

  const LanguageState(this.currentLocale);

  LanguageState copyWith({Locale? currentLocale}) {
    return LanguageState(currentLocale ?? this.currentLocale);
  }

  @override
  List<Object?> get props => [currentLocale];
}