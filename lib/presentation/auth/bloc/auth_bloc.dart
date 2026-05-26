import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/localStorage/my-local-controller.dart';
import '../../../core/utils/constants.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../../core/services/notification_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@pragma('vm:entry-point')
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc(this.authRepository) : super(const AuthState()) {
    on<LoginEvent>(_loginEvent);
    on<ForgotPasswordEvent>(_forgotPasswordEvent);
    on<ResetAuthStatusEvent>(_resetAuthStatusEvent);
    on<SignupEvent>(_signupEvent);
    on<FetchUserDetailEvent>(_onFetchUserDetail);
    on<ChangePasswordEvent>(_onChangePassword);
    on<AuthLogoutRequestedEvent>(_onLogoutRequestedEvent);
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  void _loginEvent(LoginEvent event, Emitter<AuthState> emit) async {
    debugPrint('🔐 [AuthBloc] LoginEvent fired | email: ${event.email}');
    emit(
      state.copyWith(
        loginStatus: LoginStatus.loading,
        forgotPasswordStatus: ForgotPasswordStatus.initial,
        loginError: null,
      ),
    );

    try {
      debugPrint('🔐 [AuthBloc] Calling authRepository.login...');
      final userModel = await authRepository.login(
        email: event.email,
        password: event.password,
      );

      if (userModel != null) {
        debugPrint(
          '✅ [AuthBloc] Login success | user: ${userModel.name} | role: ${userModel.role}',
        );
        await UserRepository().setUser(userModel);

        // Sync FCM Token on login
        await NotificationService().syncToken();

        await LocalStorage.saveData(
          key: AppKeys.authToken,
          value: userModel.id!,
        );
        await LocalStorage.saveData(key: AppKeys.uRole, value: userModel.role!);
        emit(state.copyWith(loginStatus: LoginStatus.success, user: userModel));
      } else {
        debugPrint('❌ [AuthBloc] Login failed — repository returned null');
        emit(
          state.copyWith(
            loginStatus: LoginStatus.error,
            loginError: 'Login failed. Check your credentials.',
          ),
        );
      }
    } catch (e, st) {
      debugPrint('❌ [AuthBloc] Login exception: $e');
      debugPrint('   StackTrace: $st');
      emit(
        state.copyWith(
          loginStatus: LoginStatus.error,
          loginError: e.toString(),
        ),
      );
    }
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────

  void _forgotPasswordEvent(
    ForgotPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint(
      '📧 [AuthBloc] ForgotPasswordEvent fired | email: ${event.email}',
    );
    emit(
      state.copyWith(
        forgotPasswordStatus: ForgotPasswordStatus.loading,
        loginStatus: LoginStatus.initial,
        forgotPasswordError: null,
      ),
    );

    try {
      debugPrint('📧 [AuthBloc] Calling authRepository.resetPassword...');
      await authRepository.resetPassword(email: event.email);
      debugPrint('✅ [AuthBloc] Password reset email sent to ${event.email}');
      emit(state.copyWith(forgotPasswordStatus: ForgotPasswordStatus.success));
    } catch (e, st) {
      debugPrint('❌ [AuthBloc] ForgotPassword exception: $e');
      debugPrint('   StackTrace: $st');
      emit(
        state.copyWith(
          forgotPasswordStatus: ForgotPasswordStatus.error,
          forgotPasswordError: e.toString(),
        ),
      );
    }
  }

  // ─── Signup ───────────────────────────────────────────────────────────────

  void _signupEvent(SignupEvent event, Emitter<AuthState> emit) async {
    debugPrint('📝 [AuthBloc] SignupEvent fired');
    debugPrint('   name: ${event.name}');
    debugPrint('   email: ${event.email}');
    debugPrint('   phone: ${event.phone}');

    emit(state.copyWith(signupStatus: SignupStatus.loading, signupError: null));

    try {
      debugPrint('📝 [AuthBloc] Calling authRepository.signUp...');
      final userModel = await authRepository.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        phoneNumber: event.phone,
      );

      if (userModel != null) {
        debugPrint('✅ [AuthBloc] Signup success | userId: ${userModel.id}');
        // Note: We don't save the user to local storage here because
        // the user is required to verify their email and then log in.
        emit(
          state.copyWith(signupStatus: SignupStatus.success, user: userModel),
        );
      } else {
        debugPrint('❌ [AuthBloc] Signup failed — repository returned null');
        emit(
          state.copyWith(
            signupStatus: SignupStatus.error,
            signupError: 'Signup failed. Please try again.',
          ),
        );
      }
    } catch (e, st) {
      debugPrint('❌ [AuthBloc] Signup exception: $e');
      debugPrint('   StackTrace: $st');
      emit(
        state.copyWith(
          signupStatus: SignupStatus.error,
          signupError: e.toString(),
        ),
      );
    }
  }

  void _resetAuthStatusEvent(
    ResetAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) {
    debugPrint('🔄 [AuthBloc] ResetAuthStatusEvent — resetting all statuses');
    emit(const AuthState());
  }

  void _onFetchUserDetail(
    FetchUserDetailEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint(
      '🔍 [AuthBloc] FetchUserDetailEvent fired | userId: ${event.userId}',
    );
    emit(
      state.copyWith(
        refreshStatus: RefreshUserStatusStatus.loading,
        refreshError: null,
      ),
    );

    try {
      final userModel = await authRepository.getProfile(event.userId);

      if (userModel != null) {
        debugPrint(
          '✅ [AuthBloc] FetchUserDetail success | status: ${userModel.status}',
        );
        await UserRepository().setUser(userModel);

        // Sync FCM Token on profile refresh
        await NotificationService().syncToken();

        emit(
          state.copyWith(
            refreshStatus: RefreshUserStatusStatus.success,
            user: userModel,
          ),
        );
      } else {
        debugPrint('❌ [AuthBloc] FetchUserDetail failed — user not found');
        emit(
          state.copyWith(
            refreshStatus: RefreshUserStatusStatus.error,
            refreshError: 'User details not found.',
          ),
        );
      }
    } catch (e, st) {
      debugPrint('❌ [AuthBloc] FetchUserDetail exception: $e');
      debugPrint('   StackTrace: $st');
      emit(
        state.copyWith(
          refreshStatus: RefreshUserStatusStatus.error,
          refreshError: e.toString(),
        ),
      );
    }
  }

  // ─── Change Password ────────────────────────────────────────────────────────

  void _onChangePassword(
    ChangePasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🔑 [AuthBloc] ChangePasswordEvent fired');
    emit(
      state.copyWith(
        changePasswordStatus: ChangePasswordStatus.loading,
        changePasswordError: null,
      ),
    );

    try {
      debugPrint('🔑 [AuthBloc] Calling authRepository.changePassword...');

      // Validate passwords
      if (event.currentPassword == event.newPassword) {
        throw Exception('New password must be different from current password');
      }

      if (event.newPassword.length < 8) {
        throw Exception('Password must be at least 8 characters long');
      }

      await authRepository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );

      debugPrint('✅ [AuthBloc] Password changed successfully');
      emit(state.copyWith(changePasswordStatus: ChangePasswordStatus.success));
    } catch (e, st) {
      debugPrint('❌ [AuthBloc] ChangePassword exception: $e');
      debugPrint('   StackTrace: $st');

      String errorMessage = e.toString();
      if (errorMessage.contains('Current password is incorrect')) {
        errorMessage = 'Current password is incorrect';
      } else if (errorMessage.contains('New password must be different')) {
        errorMessage = 'New password must be different from current password';
      } else if (errorMessage.contains('at least 8 characters')) {
        errorMessage = 'Password must be at least 8 characters long';
      }

      emit(
        state.copyWith(
          changePasswordStatus: ChangePasswordStatus.error,
          changePasswordError: errorMessage,
        ),
      );
    }
  }

  void _onLogoutRequestedEvent(
    AuthLogoutRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🚪 [AuthBloc] AuthLogoutRequestedEvent fired');
    emit(state.copyWith(logoutStatus: LogoutStatus.loading));
    try {
      await authRepository.logout();
      debugPrint('✅ [AuthBloc] Logout successful');
      emit(state.copyWith(logoutStatus: LogoutStatus.success));
    } catch (e, st) {
      debugPrint('❌ [AuthBloc] Logout exception: $e');
      debugPrint('   StackTrace: $st');
      emit(
        state.copyWith(
          logoutStatus: LogoutStatus.error,
          logoutError: e.toString(),
        ),
      );
    }
  }
}
