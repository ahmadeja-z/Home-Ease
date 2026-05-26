import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/utils/app_validators.dart';
import 'package:homeease/core/utils/labels.dart';
import 'package:homeease/core/utils/snackbar_helper.dart';
import 'package:homeease/presentation/auth/bloc/auth_bloc.dart';
import 'package:homeease/presentation/auth/bloc/auth_event.dart';
import 'package:homeease/presentation/auth/bloc/auth_state.dart';
import 'package:homeease/widgets/custom_app_bar.dart';
import 'package:homeease/widgets/custom_elevated_button.dart';
import 'package:homeease/widgets/custom_text_form_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _currentPasswordFocusNode = FocusNode();
  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: Labels.changePassword),
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            // Handle Success
            if (state.changePasswordStatus == ChangePasswordStatus.success) {
              SnackBarHelper.showSuccess(
                context,
                title: Labels.updatePassword,
                subtitle: Labels.yourPasswordHasBeenUpdatedSuccessfully,
              );
              // Clear form and navigate back
              _clearForm();
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(ResetAuthStatusEvent());
            }

            // Handle Error
            if (state.changePasswordStatus == ChangePasswordStatus.error) {
              SnackBarHelper.showError(
                context,
                title: Labels.error,
                subtitle: state.changePasswordError ?? 'An error occurred',
              );
            }
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeader(theme, isDark),

                    const SizedBox(height: 36),

                    // Form Card
                    _buildFormCard(theme, isDark),

                    const SizedBox(height: 32),

                    // Security Tips
                    _buildSecurityTip(theme, isDark),

                    const SizedBox(height: 32),

                    // Submit Button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading =
                            state.changePasswordStatus ==
                            ChangePasswordStatus.loading;

                        return CustomElevatedButton(
                          isLoading: isLoading,
                          text: Labels.updatePassword,
                          onPressed: isLoading
                              ? null
                              : () {
                                  _handleSubmit(context);
                                },
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit(BuildContext context) {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    // Additional validations
    if (newPassword.length < 8) {
      SnackBarHelper.showError(
        context,
        title: Labels.error,
        subtitle: Labels.passwordMustBeAtLeast8CharactersLong,
      );

      return;
    }

    // Dispatch change password event
    context.read<AuthBloc>().add(
      ChangePasswordEvent(
        currentPassword: currentPassword,
        newPassword: newPassword,
        userId: '', // Not used in repository but required by event
      ),
    );
  }

  void _clearForm() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon badge
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),

        const SizedBox(height: 16),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Labels.updatePassword,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: theme.colorScheme.onSurface,
                fontSize: 20,
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: Text(
                Labels.createAStringPasswordToMakeYourAccountSecure,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  height: 1.5,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildFormCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.grey.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(
            theme,
            Labels.currentPassword,
            Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 8),
          CustomTextFormField(
            validator: AppValidators.validateRequired,
            textEditingController: _currentPasswordController,
            hint: Labels.enterCurrentPassword,
            focusNode: _currentPasswordFocusNode,
            nextFocusNode: _newPasswordFocusNode,
          ),

          const SizedBox(height: 20),
          _buildDivider(theme, isDark),
          const SizedBox(height: 20),

          _buildFieldLabel(theme, Labels.newPassword, Icons.lock_open_rounded),
          const SizedBox(height: 8),
          CustomTextFormField(
            validator: AppValidators.validateRequired,
            textEditingController: _newPasswordController,
            hint: Labels.enterNewPassword,
            focusNode: _newPasswordFocusNode,
            nextFocusNode: _confirmPasswordFocusNode,
          ),

          const SizedBox(height: 20),
          _buildDivider(theme, isDark),
          const SizedBox(height: 20),

          _buildFieldLabel(
            theme,
            Labels.confirmPassword,
            Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 8),
          CustomTextFormField(
            validator: (value) => AppValidators.validateConfirmPassword(
              _newPasswordController.text,
              value!,
            ),
            textEditingController: _confirmPasswordController,
            hint: Labels.reEnterNewPassword,
            focusNode: _confirmPasswordFocusNode,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(ThemeData theme, String label, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: theme.colorScheme.primary.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(ThemeData theme, bool isDark) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTip(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(
          alpha: isDark ? 0.12 : 0.06,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              Labels.usePlusCharacters,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
