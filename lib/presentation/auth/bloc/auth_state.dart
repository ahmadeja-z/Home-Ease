import 'package:equatable/equatable.dart';
import '../../../models/user_model.dart';

enum LoginStatus { initial, loading, success, error }

enum ForgotPasswordStatus { initial, loading, success, error }

enum SignupStatus { initial, loading, success, error }

enum RefreshUserStatusStatus { initial, loading, success, error }

enum ChangePasswordStatus { initial, loading, success, error }

enum LogoutStatus { initial, loading, success, error }

class AuthState extends Equatable {
  final LoginStatus loginStatus;
  final ForgotPasswordStatus forgotPasswordStatus;
  final SignupStatus signupStatus;
  final ChangePasswordStatus changePasswordStatus;
  final LogoutStatus logoutStatus;
  final RefreshUserStatusStatus refreshStatus;
  final String? loginError;
  final String? forgotPasswordError;
  final String? signupError;
  final String? changePasswordError;
  final String? logoutError;
  final String? refreshError;
  final UserModel? user;

  const AuthState({
    this.loginStatus = LoginStatus.initial,
    this.forgotPasswordStatus = ForgotPasswordStatus.initial,
    this.signupStatus = SignupStatus.initial,
    this.changePasswordStatus = ChangePasswordStatus.initial,
    this.logoutStatus = LogoutStatus.initial,
    this.refreshStatus = RefreshUserStatusStatus.initial,
    this.loginError,
    this.forgotPasswordError,
    this.signupError,
    this.changePasswordError,
    this.logoutError,

    this.refreshError,
    this.user,
  });

  AuthState copyWith({
    LoginStatus? loginStatus,
    ForgotPasswordStatus? forgotPasswordStatus,
    SignupStatus? signupStatus,
    ChangePasswordStatus? changePasswordStatus,
    LogoutStatus? logoutStatus,
    RefreshUserStatusStatus? refreshStatus,
    String? loginError,
    String? forgotPasswordError,
    String? signupError,
    String? changePasswordError,
    String? logoutError,
    String? refreshError,
    UserModel? user,
  }) {
    return AuthState(
      loginStatus: loginStatus ?? this.loginStatus,
      forgotPasswordStatus: forgotPasswordStatus ?? this.forgotPasswordStatus,
      signupStatus: signupStatus ?? this.signupStatus,
      changePasswordStatus: changePasswordStatus ?? this.changePasswordStatus,
      logoutStatus: logoutStatus ?? this.logoutStatus,
      refreshStatus: refreshStatus ?? this.refreshStatus,
      loginError: loginError ?? this.loginError,
      forgotPasswordError: forgotPasswordError ?? this.forgotPasswordError,
      signupError: signupError ?? this.signupError,
      changePasswordError: changePasswordError ?? this.changePasswordError,
      logoutError: logoutError ?? this.logoutError,
      refreshError: refreshError ?? this.refreshError,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [
    loginStatus,
    forgotPasswordStatus,
    signupStatus,
    changePasswordStatus,
    logoutStatus,
    refreshStatus,
    loginError,
    forgotPasswordError,
    signupError,
    changePasswordError,
    logoutError,
    refreshError,
    user,
  ];
}
