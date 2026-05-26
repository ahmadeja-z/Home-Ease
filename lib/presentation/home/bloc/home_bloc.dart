import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/presentation/home/bloc/home_event.dart';
import 'package:homeease/presentation/home/bloc/home_state.dart';
import 'package:homeease/repositories/home_repository.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _homeRepository;
  HomeBloc(this._homeRepository) : super(const HomeState()) {
    on<FetchBannersEvent>(_onFetchBannersEvent);
    on<FetchServicesCategories>(_onFetchServicesCategories);
    on<FetchAllServices>(_onFetchAllServices);
    on<UpdateBannerIndexEvent>(_onUpdateBannerIndex);
  }
  Future<void> _onFetchBannersEvent(
    FetchBannersEvent event,
    Emitter<HomeState> emit,
  ) async {
    final bool isSearchChanged = event.search != state.bannerSearch;
    int targetPage = event.page ?? state.bannerCurrentPage;

    if (isSearchChanged || event.isRefresh) {
      targetPage = 1;
    }

    emit(
      state.copyWith(
        fetchBannerStatus: FetchBannerStatus.loading,
        bannerSearch: event.search ?? '',
        bannerCurrentPage: targetPage,
      ),
    );

    try {
      const int limit = 10;
      final int offset = (targetPage - 1) * limit;

      final result = await _homeRepository.getBanners(
        limit: limit,
        offset: offset,
        search: event.search,
      );

      emit(
        state.copyWith(
          fetchBannerStatus: FetchBannerStatus.success,
          banners: result.banners,
          bannerTotalCount: result.totalCount,
          bannerCurrentPage: targetPage,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          fetchBannerStatus: FetchBannerStatus.failure,
          fetchBannerErrorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onFetchServicesCategories(
    FetchServicesCategories event,
    Emitter<HomeState> emit,
  ) async {
    final bool isSearchChanged = event.search != state.serviceCategorySearch;
    int targetPage = event.page ?? state.serviceCategoryCurrentPage;

    if (isSearchChanged || event.isRefresh) {
      targetPage = 1;
    }

    emit(
      state.copyWith(
        fetchServicesCategoriesStatus: FetchServicesCategoriesStatus.loading,
        serviceCategorySearch: event.search,
        serviceCategoryCurrentPage: targetPage,
      ),
    );

    try {
      const int limit = 10;
      final int offset = (targetPage - 1) * limit;

      final result = await _homeRepository.getServicesCategories(
        limit: limit,
        offset: offset,
        search: event.search,
      );

      emit(
        state.copyWith(
          fetchServicesCategoriesStatus: FetchServicesCategoriesStatus.success,
          serviceCategories: result.categories,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          fetchServicesCategoriesStatus: FetchServicesCategoriesStatus.failure,
          fetchServicesCategoriesErrorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onFetchAllServices(
    FetchAllServices event,
    Emitter<HomeState> emit,
  ) async {
    final bool isSearchChanged = event.search != state.servicesSearch;
    final bool isCategoryChanged = event.categoryId != state.selectedCategoryId;
    int targetPage = event.page ?? state.servicesCurrentPage;

    if (isSearchChanged || isCategoryChanged || event.isRefresh) {
      targetPage = 1;
    }

    emit(
      state.copyWith(
        fetchServicesStatus: FetchServicesStatus.loading,
        servicesSearch: event.search,
        selectedCategoryId: event.categoryId,
        servicesCurrentPage: targetPage,
      ),
    );

    try {
      const int limit = 10;
      final int offset = (targetPage - 1) * limit;

      final result = await _homeRepository.getServices(
        limit: limit,
        offset: offset,
        search: event.search,
        categoryId: event.categoryId,
      );

      emit(
        state.copyWith(
          fetchServicesStatus: FetchServicesStatus.success,
          services: result.services,
          servicesTotalCount: result.totalCount,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          fetchServicesStatus: FetchServicesStatus.failure,
          fetchAllServicesErrorMessage: e.toString(),
        ),
      );
    }
  }

  void _onUpdateBannerIndex(
    UpdateBannerIndexEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(currentBannerIndex: event.index));
  }
}
