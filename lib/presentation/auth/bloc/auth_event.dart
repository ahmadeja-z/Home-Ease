import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  LoginEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class ForgotPasswordEvent extends AuthEvent {
  final String email;

  ForgotPasswordEvent({required this.email});

  @override
  List<Object?> get props => [email];
}

class ResetAuthStatusEvent extends AuthEvent {
  @override
  List<Object?> get props => [];
}

// ─── Signup ───────────────────────────────────────────────────────────────────

class SignupEvent extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;

  SignupEvent({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, phone, password];
}

class FetchUserDetailEvent extends AuthEvent {
  final String userId;

  FetchUserDetailEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class ChangePasswordEvent extends AuthEvent {
  final String userId;
  final String currentPassword;
  final String newPassword;

  ChangePasswordEvent({
    required this.userId,
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [userId, currentPassword, newPassword];
}

class AuthLogoutRequestedEvent extends AuthEvent {
  @override
  List<Object?> get props => [];
}
