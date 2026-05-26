import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

abstract class LanguageEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChangeLanguage extends LanguageEvent {
  final BuildContext context;
  final Locale locale;

  ChangeLanguage(this.context, this.locale);

  @override
  List<Object?> get props => [locale];
}

class LoadLanguage extends LanguageEvent {
  final BuildContext context;

  LoadLanguage(this.context);

  @override
  List<Object?> get props => [];
}
