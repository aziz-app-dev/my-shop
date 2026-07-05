import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/items_model.dart';
import '../../res/assets/image_assets.dart';
import '../../res/components/app_icon.dart';
import '../../res/components/product_card.dart';
import '../../res/components/app_bar_widget.dart';
import '../../view_models/providers/home_page_provider.dart';

// Top Selling Products Page
class TopSellingProductsView extends ConsumerWidget {
  const TopSellingProductsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homePageProvider);

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Top Selling Products',
        context: context,
      ),
      body:
          homeState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : homeState.error != null
              ? Center(child: Text('Error: ${homeState.error}'))
              : homeState.topSellingProducts.isEmpty
              ? _buildEmptyState(
                icon: Icons.trending_up,
                win11IconPath: ImageAssets.win11Sales,
                title: 'No Top Selling Products',
                subtitle: 'Products will appear here based on sales',
                color: Colors.orange,
              )
              : _buildProductGrid(context, homeState.topSellingProducts),
    );
  }

  Widget _buildProductGrid(BuildContext context, List<Product> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
          childAspectRatio = 0.75;
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 3;
          childAspectRatio = 0.85;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 0.9;
        }

        return GridView.builder(
          padding: EdgeInsets.all(16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String win11IconPath,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(
            win11IconPath: win11IconPath,
            defaultIcon: icon,
            size: 80,
            color: color.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.spMin,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14.spMin, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Latest Items Page
class LatestItemsView extends ConsumerWidget {
  const LatestItemsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homePageProvider);

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Latest Added Items',
        context: context,
      ),
      body:
          homeState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : homeState.error != null
              ? Center(child: Text('Error: ${homeState.error}'))
              : homeState.latestItems.isEmpty
              ? _buildEmptyState(
                icon: Icons.new_releases,
                win11IconPath: ImageAssets.win11Nuw,
                title: 'No Latest Items',
                subtitle: 'Recently added items will appear here',
                color: Colors.blue,
              )
              : _buildProductGrid(context, homeState.latestItems),
    );
  }

  Widget _buildProductGrid(BuildContext context, List<Product> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
          childAspectRatio = 0.75;
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 3;
          childAspectRatio = 0.85;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 0.9;
        }

        return GridView.builder(
          padding: EdgeInsets.all(16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String win11IconPath,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(
            win11IconPath: win11IconPath,
            defaultIcon: icon,
            size: 80,
            color: color.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.spMin,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14.spMin, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Latest Services Page
class LatestServicesView extends ConsumerWidget {
  const LatestServicesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homePageProvider);

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Latest Services',
        context: context,
      ),
      body:
          homeState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : homeState.error != null
              ? Center(child: Text('Error: ${homeState.error}'))
              : homeState.latestServices.isEmpty
              ? _buildEmptyState(
                icon: Icons.room_service,
                win11IconPath: ImageAssets.win11Services,
                title: 'No Latest Services',
                subtitle: 'Recently added services will appear here',
                color: Colors.green,
              )
              : _buildProductGrid(context, homeState.latestServices),
    );
  }

  Widget _buildProductGrid(BuildContext context, List<Product> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
          childAspectRatio = 0.75;
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 3;
          childAspectRatio = 0.85;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 0.9;
        }

        return GridView.builder(
          padding: EdgeInsets.all(16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String win11IconPath,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(
            win11IconPath: win11IconPath,
            defaultIcon: icon,
            size: 80,
            color: color.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.spMin,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14.spMin, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Low Stock Items Page
class LowStockItemsView extends ConsumerWidget {
  const LowStockItemsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homePageProvider);

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Low Stock Items',
        context: context,
      ),
      body:
          homeState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : homeState.error != null
              ? Center(child: Text('Error: ${homeState.error}'))
              : homeState.lowStockItems.isEmpty
              ? _buildEmptyState(
                icon: Icons.warning_amber_rounded,
                win11IconPath: ImageAssets.win11LowRisk,
                title: 'No Low Stock Items',
                subtitle: 'Items with low stock will appear here',
                color: Colors.red,
              )
              : _buildProductGrid(context, homeState.lowStockItems),
    );
  }

  Widget _buildProductGrid(BuildContext context, List<Product> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
          childAspectRatio = 0.75;
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 3;
          childAspectRatio = 0.85;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 0.9;
        }

        return GridView.builder(
          padding: EdgeInsets.all(16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String win11IconPath,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(
            win11IconPath: win11IconPath,
            defaultIcon: icon,
            size: 80,
            color: color.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.spMin,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14.spMin, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
