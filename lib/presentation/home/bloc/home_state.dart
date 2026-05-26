import 'package:equatable/equatable.dart';
import 'package:homeease/models/banner_model.dart';
import 'package:homeease/models/services_category_model.dart';
import 'package:homeease/models/services_model.dart';

enum FetchBannerStatus { initial, loading, success, failure }

enum FetchServicesCategoriesStatus { initial, loading, success, failure }

enum FetchServicesStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.fetchBannerStatus = FetchBannerStatus.initial,
    this.banners = const [],
    this.fetchServicesCategoriesStatus = FetchServicesCategoriesStatus.initial,
    this.serviceCategories = const [],
    this.fetchServicesStatus = FetchServicesStatus.initial,
    this.services = const [],
    this.serviceCategoryCurrentPage = 1,
    this.serviceCategoryTotalCount = 0,
    this.serviceCategoryHasReachedMax = false,
    this.serviceCategorySearch,

    this.servicesCurrentPage = 1,
    this.servicesTotalCount = 0,
    this.servicesHasReachedMax = false,
    this.servicesSearch,
    this.selectedCategoryId,
    this.fetchAllServicesErrorMessage,
    this.fetchServicesCategoriesErrorMessage,
    this.fetchBannerErrorMessage,

    this.bannerCurrentPage = 1,
    this.bannerTotalCount = 0,
    this.bannerSearch,
    this.currentBannerIndex = 0,
  });

  final FetchBannerStatus fetchBannerStatus;
  final List<BannerModel> banners;
  final FetchServicesCategoriesStatus fetchServicesCategoriesStatus;
  final List<ServicesCategoriesModel> serviceCategories;
  final FetchServicesStatus fetchServicesStatus;
  final List<ServicesModel> services;
  final int serviceCategoryCurrentPage;
  final int serviceCategoryTotalCount;
  final bool serviceCategoryHasReachedMax;
  final String? serviceCategorySearch;

  final int servicesCurrentPage;
  final int servicesTotalCount;
  final bool servicesHasReachedMax;
  final String? servicesSearch;
  final String? selectedCategoryId;
  final String? fetchAllServicesErrorMessage;
  final String? fetchServicesCategoriesErrorMessage;
  final String? fetchBannerErrorMessage;
  final int bannerCurrentPage;
  final int bannerTotalCount;
  final String? bannerSearch;
  final int currentBannerIndex;

  HomeState copyWith({
    FetchBannerStatus? fetchBannerStatus,
    List<BannerModel>? banners,
    FetchServicesCategoriesStatus? fetchServicesCategoriesStatus,
    List<ServicesCategoriesModel>? serviceCategories,
    FetchServicesStatus? fetchServicesStatus,
    List<ServicesModel>? services,
    int? serviceCategoryCurrentPage,
    int? serviceCategoryTotalCount,
    bool? serviceCategoryHasReachedMax,
    String? serviceCategorySearch,
    int? servicesCurrentPage,
    int? servicesTotalCount,
    bool? servicesHasReachedMax,
    String? servicesSearch,
    String? selectedCategoryId,
    String? fetchAllServicesErrorMessage,
    String? fetchServicesCategoriesErrorMessage,
    String? fetchBannerErrorMessage,
    int? bannerCurrentPage,
    int? bannerTotalCount,
    String? bannerSearch,
    int? currentBannerIndex,
  }) {
    return HomeState(
      fetchBannerStatus: fetchBannerStatus ?? this.fetchBannerStatus,
      banners: banners ?? this.banners,
      fetchServicesCategoriesStatus:
          fetchServicesCategoriesStatus ?? this.fetchServicesCategoriesStatus,
      serviceCategories: serviceCategories ?? this.serviceCategories,
      fetchServicesStatus: fetchServicesStatus ?? this.fetchServicesStatus,
      services: services ?? this.services,
      serviceCategoryCurrentPage:
          serviceCategoryCurrentPage ?? this.serviceCategoryCurrentPage,
      serviceCategoryTotalCount:
          serviceCategoryTotalCount ?? this.serviceCategoryTotalCount,
      serviceCategoryHasReachedMax:
          serviceCategoryHasReachedMax ?? this.serviceCategoryHasReachedMax,
      serviceCategorySearch:
          serviceCategorySearch ?? this.serviceCategorySearch,
      servicesCurrentPage: servicesCurrentPage ?? this.servicesCurrentPage,
      servicesTotalCount: servicesTotalCount ?? this.servicesTotalCount,
      servicesHasReachedMax:
          servicesHasReachedMax ?? this.servicesHasReachedMax,
      servicesSearch: servicesSearch ?? this.servicesSearch,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      fetchAllServicesErrorMessage:
          fetchAllServicesErrorMessage ?? this.fetchAllServicesErrorMessage,
      fetchServicesCategoriesErrorMessage:
          fetchServicesCategoriesErrorMessage ??
          this.fetchServicesCategoriesErrorMessage,
      fetchBannerErrorMessage:
          fetchBannerErrorMessage ?? this.fetchBannerErrorMessage,
      bannerCurrentPage: bannerCurrentPage ?? this.bannerCurrentPage,
      bannerTotalCount: bannerTotalCount ?? this.bannerTotalCount,
      bannerSearch: bannerSearch ?? this.bannerSearch,
      currentBannerIndex: currentBannerIndex ?? this.currentBannerIndex,
    );
  }

  @override
  List<Object?> get props => [
    fetchBannerStatus,
    banners,
    fetchServicesCategoriesStatus,
    serviceCategories,
    fetchServicesStatus,
    services,
    serviceCategoryCurrentPage,
    serviceCategoryTotalCount,
    serviceCategoryHasReachedMax,
    serviceCategorySearch,
    servicesCurrentPage,
    servicesTotalCount,
    servicesHasReachedMax,
    servicesSearch,
    selectedCategoryId,
    fetchAllServicesErrorMessage,
    fetchServicesCategoriesErrorMessage,
    fetchBannerErrorMessage,
    bannerCurrentPage,
    bannerTotalCount,
    bannerSearch,
    currentBannerIndex,
  ];
}
