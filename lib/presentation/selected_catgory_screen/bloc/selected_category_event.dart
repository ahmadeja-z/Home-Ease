import 'package:equatable/equatable.dart';

class SelectedCategoryEvent extends Equatable{
  @override
  List<Object?> get props => [];

}

class FetchCategoryEvent extends SelectedCategoryEvent{
  final String categoryId;
  FetchCategoryEvent(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}