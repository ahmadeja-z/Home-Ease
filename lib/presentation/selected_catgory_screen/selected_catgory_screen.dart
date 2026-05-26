import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/models/services_category_model.dart';
import 'package:homeease/models/services_model.dart';
import 'package:homeease/presentation/home/services_details_screen.dart';
import 'package:homeease/presentation/selected_catgory_screen/bloc/selected_category_bloc.dart';
import 'package:homeease/presentation/selected_catgory_screen/bloc/selected_category_event.dart';
import 'package:homeease/presentation/selected_catgory_screen/bloc/selected_category_state.dart';
import 'package:homeease/repositories/selected_category_repository.dart';
import 'package:homeease/widgets/custom_app_bar.dart';

class SelectedCategoryScreen extends StatelessWidget {
  const SelectedCategoryScreen({super.key, required this.category});
  final ServicesCategoriesModel category;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelectedCategoryBloc(
        repository: SelectedCategoryRepository(),
      )..add(FetchCategoryEvent(category.id)),
      child: Scaffold(
        appBar: CustomAppBar(title: category.name),
        body: Column(
          children: [
            _CategoryHeader(category: category),
            Expanded(
              child: _ServicesGrid(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category});

  final ServicesCategoriesModel category;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: .1),
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(category.picture ?? ''),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  category.description ?? '',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectedCategoryBloc, SelectedCategoryState>(
      builder: (context, state) {
        if (state.status == FetchCategoryStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == FetchCategoryStatus.failure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading services',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ?? 'Unknown error occurred',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    final categoryScreen = context
                        .findAncestorWidgetOfExactType<SelectedCategoryScreen>();
                    if (categoryScreen != null) {
                      context.read<SelectedCategoryBloc>().add(
                            FetchCategoryEvent(categoryScreen.category.id),
                          );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state.status == FetchCategoryStatus.success) {
          final services = state.categoryServices ?? [];

          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 60,
                    color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: .5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No services found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'There are no services available in this category yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _ServiceCard(service: service);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final ServicesModel service;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServicesDetailsScreen(service: service),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: .1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: service.mainImage != null
                    ? Image.network(
                        service.mainImage!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: .1),
                            child: Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: .3),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: .1),
                        child: Icon(
                          Icons.image,
                          size: 40,
                          color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: .3),
                        ),
                      ),
              ),
            ),
            // Service Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              service.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: .7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${service.perHourRate.toStringAsFixed(0)}/hr',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
