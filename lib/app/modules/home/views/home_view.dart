import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../controllers/home_controller.dart';
import 'widgets/modal_methods.dart';
import 'widgets/balance_card.dart';
import 'widgets/qr_code_card.dart';
import 'widgets/recent_transactions_list.dart';
import 'widgets/modal_methods.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/ action_buttons_grid.dart';
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeController controller = Get.put(HomeController());
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              title: CustomAppBar(controller: controller),
              backgroundColor: const Color(0xFFE3F2FD),
            ),
            // Page indicator
            SliverToBoxAdapter(
              child: Container(
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 120),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Your existing page indicator code here
                  ],
                ),
              ),
            ),
            // PageView with Balance and QR Code
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: BalanceCard(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: QRCodeCard(),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ActionButtonsGrid(
              controller: controller,
              showScanner: (context, type) =>
                  ModalMethods.showScanner(context, controller, type),
            ),
            const SizedBox(height: 20),
            RecentTransactionsList(
              onCancelTransaction: (context, transaction) {
                controller.cancelTransfer(transaction);
              },
            ),
          ],
        ),
      ),
    );
  }
}