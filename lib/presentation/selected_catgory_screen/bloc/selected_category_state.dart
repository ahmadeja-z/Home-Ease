import 'package:equatable/equatable.dart';
import 'package:homeease/models/services_model.dart';

enum FetchCategoryStatus { initial, loading, success, failure }

class SelectedCategoryState extends Equatable {
  final FetchCategoryStatus status;
  final String? errorMessage;
  final List<ServicesModel>? categoryServices;

  const SelectedCategoryState({
    this.status = FetchCategoryStatus.initial,
    this.errorMessage,
    this.categoryServices,
  });

  SelectedCategoryState copyWith({
    FetchCategoryStatus? status,
    String? errorMessage,
    List<ServicesModel>? categoryServices,
  }) {
    return SelectedCategoryState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      categoryServices: categoryServices ?? this.categoryServices,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, categoryServices];
}
