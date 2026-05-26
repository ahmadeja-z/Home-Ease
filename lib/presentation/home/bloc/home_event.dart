import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class FetchBannersEvent extends HomeEvent {
  final String? search;
  final bool isRefresh;
  final int? page;

  const FetchBannersEvent({this.search, this.isRefresh = false, this.page});

  @override
  List<Object?> get props => [page, search, isRefresh];
}

class FetchServicesCategories extends HomeEvent {
  final String? search;
  final bool isRefresh;
  final int? page;

  const FetchServicesCategories({
    this.search,
    this.isRefresh = false,
    this.page,
  });

  @override
  List<Object?> get props => [search, isRefresh, page];
}

class FetchAllServices extends HomeEvent {
  final String? search;
  final String? categoryId;
  final bool isRefresh;
  final int? page;

  const FetchAllServices({
    this.search,
    this.categoryId,
    this.isRefresh = false,
    this.page,
  });

  @override
  List<Object?> get props => [search, categoryId, isRefresh, page];
}

class UpdateBannerIndexEvent extends HomeEvent {
  final int index;

  const UpdateBannerIndexEvent(this.index);

  @override
  List<Object?> get props => [index];
}
