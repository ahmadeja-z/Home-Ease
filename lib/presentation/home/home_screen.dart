import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/network/network_failure.dart';
import 'package:homeease/core/widgets/customer_offline_gate.dart';
import 'package:homeease/core/widgets/customer_reconnect_listener.dart';

import 'package:homeease/presentation/home/bloc/home_bloc.dart';
import 'package:homeease/presentation/home/bloc/home_event.dart';
import 'package:homeease/presentation/home/bloc/home_state.dart';
import 'package:homeease/widgets/image_banner.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:homeease/widgets/service_card.dart';

import '../selected_catgory_screen/selected_catgory_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  void _fetchInitialData() {
    final homeBloc = context.read<HomeBloc>();
    homeBloc.add(FetchBannersEvent());
    homeBloc.add(const FetchServicesCategories());
    homeBloc.add(const FetchAllServices());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<HomeBloc>().add(
      FetchAllServices(search: query.isEmpty ? null : query),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomerReconnectListener(
      onReconnect: _fetchInitialData,
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final hasCachedData = state.banners.isNotEmpty ||
              state.serviceCategories.isNotEmpty ||
              state.services.isNotEmpty;

          return CustomerOfflineGate(
            hasCachedData: hasCachedData,
            onRetry: _fetchInitialData,
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBannersSection(theme),
                            const SizedBox(height: 24),
                            _buildCategoriesSection(theme, isDark),
                            const SizedBox(height: 24),
                            _buildServicesSection(theme, isDark),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBannersSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        BlocBuilder<HomeBloc, HomeState>(
          buildWhen: (previous, current) =>
              previous.fetchBannerStatus != current.fetchBannerStatus,
          builder: (context, state) {
            if (state.fetchBannerStatus == FetchBannerStatus.loading) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: SpinKitThreeInOut(color: Color(0xFF1E3A8A), size: 30),
                ),
              );
            }

            if (state.fetchBannerStatus == FetchBannerStatus.failure) {
              if (isNetworkFailureMessage(state.fetchBannerErrorMessage)) {
                return const SizedBox.shrink();
              }
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade300,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.fetchBannerErrorMessage ??
                            'Failed to load banners',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state.banners.isEmpty) {
              return const SizedBox.shrink();
            }

            final bannerUrls = state.banners.map((b) => b.imageUrl).toList();
            return EcommerceBanner(
              imageUrls: bannerUrls,
              height: 170,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              borderRadius: 16,
              dotSize: 6,
              activeDotColor: Theme.of(context).primaryColor,
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<HomeBloc, HomeState>(
          buildWhen: (previous, current) =>
              previous.fetchServicesCategoriesStatus !=
              current.fetchServicesCategoriesStatus,
          builder: (context, state) {
            if (state.fetchServicesCategoriesStatus ==
                FetchServicesCategoriesStatus.loading) {
              return SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: SpinKitThreeInOut(
                          color: Color(0xFF1E3A8A),
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              );
            }

            if (state.fetchServicesCategoriesStatus ==
                FetchServicesCategoriesStatus.failure) {
              if (isNetworkFailureMessage(
                state.fetchServicesCategoriesErrorMessage,
              )) {
                return const SizedBox.shrink();
              }
              return Container(
                height: 100,
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    state.fetchServicesCategoriesErrorMessage ??
                        'Failed to load categories',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              );
            }

            if (state.serviceCategories.isEmpty) {
              return const SizedBox.shrink();
            }

            return SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.serviceCategories.length,
                itemBuilder: (context, index) {
                  final category = state.serviceCategories[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectedCategoryScreen(
                            category: state.serviceCategories[index],
                          ),
                        ),
                      );
                    },

                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: category.picture != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: category.picture!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          Icon(
                                            Icons.category,
                                            color: Colors.grey.shade400,
                                            size: 24,
                                          ),
                                    ),
                                  )
                                : Icon(
                                    Icons.category,
                                    color: Colors.grey.shade400,
                                    size: 24,
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              category.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServicesSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services',
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<HomeBloc, HomeState>(
          buildWhen: (previous, current) =>
              previous.fetchServicesStatus != current.fetchServicesStatus,
          builder: (context, state) {
            if (state.fetchServicesStatus == FetchServicesStatus.loading) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: SpinKitThreeInOut(
                        color: Color(0xFF1E3A8A),
                        size: 30,
                      ),
                    ),
                  );
                },
              );
            }

            if (state.fetchServicesStatus == FetchServicesStatus.failure) {
              if (isNetworkFailureMessage(state.fetchAllServicesErrorMessage)) {
                return const SizedBox.shrink();
              }
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade300,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.fetchAllServicesErrorMessage ??
                            'Failed to load services',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<HomeBloc>().add(
                            FetchAllServices(
                              search: _searchController.text.isEmpty
                                  ? null
                                  : _searchController.text,
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state.services.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        color: Colors.grey.shade400,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No services found',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filters',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: state.services.length,
              itemBuilder: (context, index) {
                final service = state.services[index];
                return ServiceCard(service: service);
              },
            );
          },
        ),
      ],
    );
  }
}
