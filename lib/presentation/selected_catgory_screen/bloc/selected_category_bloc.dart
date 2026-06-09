import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/network/network_failure.dart';
import 'package:homeease/presentation/selected_catgory_screen/bloc/selected_category_event.dart';
import 'package:homeease/presentation/selected_catgory_screen/bloc/selected_category_state.dart';
import 'package:homeease/repositories/selected_category_repository.dart';

class SelectedCategoryBloc
    extends Bloc<SelectedCategoryEvent, SelectedCategoryState> {
  final SelectedCategoryRepository repository;

  SelectedCategoryBloc({required this.repository})
      : super(SelectedCategoryState()) {
    on<FetchCategoryEvent>(_onFetchCategoryServices);
  }

  Future<void> _onFetchCategoryServices(
    FetchCategoryEvent event,
    Emitter<SelectedCategoryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FetchCategoryStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      final services = await repository.getServicesByCategory(event.categoryId);

      emit(
        state.copyWith(
          status: FetchCategoryStatus.success,
          categoryServices: services,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FetchCategoryStatus.failure,
          errorMessage: mapCustomerErrorMessage(e),
        ),
      );
    }
  }
}
