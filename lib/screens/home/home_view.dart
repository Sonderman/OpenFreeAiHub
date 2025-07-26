import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_controller.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_tab_indicator.dart';
import 'library_view.dart';
import 'ai_models_view.dart';

/// HomeView is the main screen of the application that displays AI model categories and their models.
/// It extends [GetView<HomeController>] to utilize GetX for state management.
/// Now uses TabView for navigation between main view and quick actions.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the HomeController using GetX dependency injection
    Get.put(HomeController());

    // Main scaffold with NestedScrollView structure to utilise SliverAppBar and slivers
    return Scaffold(
      // Body contains NestedScrollView which gives us a CustomScrollView with a sliver header.
      body: SafeArea(
        child: GetBuilder<HomeController>(
          builder: (ctrl) {
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // SliverAppBar extracted to its own widget
                  const HomeSliverAppBar(),

                  // Sliver for custom tab indicator (previously at top of Column)
                  SliverToBoxAdapter(child: HomeTabIndicator()),
                ];
              },
              body: TabBarView(
                controller: controller.tabController,
                children: [
                  // First Tab: Library View
                  LibraryView(),
                  // Second Tab: AI Models View
                  AiModelsView(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
