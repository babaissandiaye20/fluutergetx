// app_routes.dart
part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const HOME = _Paths.HOME;
  static const LOGIN = _Paths.LOGIN;
  static const REGISTER = _Paths.REGISTER;
  static const TRANSFER = _Paths.TRANSFER;
  static const COMPLETE_PROFILE = _Paths.COMPLETE_PROFILE;
  static const DEPOSIT = _Paths.DEPOSIT;
  static const WITHDRAWAL = _Paths.WITHDRAWAL;
  static const CEILING = _Paths.CEILING;
  static const SCHEDULED_TRANSFER = _Paths.SCHEDULED_TRANSFER;
}

abstract class _Paths {
  _Paths._();
  static const HOME = '/home';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const TRANSACTION = '/transaction';
  static const TRANSFER = '/transfer';
  static const COMPLETE_PROFILE = '/complete-profile';
  static const DEPOSIT = '/deposit';
  static const WITHDRAWAL = '/withdrawal';
  static const CEILING = '/ceiling-update';
  static const SCHEDULED_TRANSFER = '/scheduled-transfer';
}
