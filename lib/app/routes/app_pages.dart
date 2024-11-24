import 'package:get/get.dart';

import '../models/user_model.dart';
import '../modules/ceiling/bindings/ceiling_binding.dart';
import '../modules/ceiling/views/ceiling_view.dart';
import '../modules/complete-profile/bindings/complete_profile_binding.dart';
import '../modules/complete-profile/views/complete_profile_view.dart';
import '../modules/deposit/bindings/deposit_binding.dart';
import '../modules/deposit/bindings/deposit_binding.dart';
import '../modules/deposit/views/deposit_view.dart';
import '../modules/deposit/views/deposit_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/register/bindings/register_binding.dart';
import '../modules/register/views/register_view.dart';
import '../modules/transfer/bindings/transfer_binding.dart';
import '../modules/transfer/views/transfer_view.dart';
import '../modules/withdrawal/bindings/withdrawal_binding.dart';
import '../modules/withdrawal/views/withdrawal_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  // Changement de la route initiale vers LOGIN
  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: _Paths.TRANSFER,
      page: () => const TransferView(),
      binding: TransferBinding(),
      arguments: Get.arguments,
    ),
    GetPage(
      name: '/complete-profile',
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final user = args['user'] as User;
        return CompleteProfileView(user: user);
      },
      binding: CompleteProfileBinding(),
    ),
    GetPage(
      name: _Paths.DEPOSIT,
      page: () => const DepositView(),
      binding: DepositBinding(),
      arguments: Get.arguments, // Make sure to pass arguments
    ),
    GetPage(
      name: _Paths.WITHDRAWAL,
      page: () => const WithdrawalView(),
      binding: WithdrawalBinding(),
      arguments: Get.arguments,
    ),
    GetPage(
  name: _Paths.CEILING,
  page: () => const CeilingView(),
  binding: CeilingBinding(),
)
  ];
}
