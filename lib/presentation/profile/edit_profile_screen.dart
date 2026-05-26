import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/utils/app_validators.dart';
import 'package:homeease/core/utils/labels.dart';
import 'package:homeease/core/utils/snackbar_helper.dart';
import 'package:homeease/presentation/profile/bloc/profile_bloc.dart';
import 'package:homeease/presentation/profile/bloc/profile_event.dart';
import 'package:homeease/presentation/profile/bloc/profile_state.dart';
import 'package:homeease/widgets/custom_app_bar.dart';
import 'package:homeease/widgets/custom_elevated_button.dart';
import 'package:homeease/widgets/custom_text_form_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load current profile data
    context.read<ProfileBloc>().add(LoadProfile());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  Labels.chooseFromGallery,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  Labels.takePhoto,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickImageFromGallery() {
    if (!mounted) return;
    context.read<ProfileBloc>().add(PickImage());
  }

  void _pickImageFromCamera() {
    if (!mounted) return;
    context.read<ProfileBloc>().add(PickImageFromCamera());
  }

  void _saveProfile() {
    context.read<ProfileBloc>().add(SaveProfile());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: Labels.updateProfile),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          // Handle success
          if (state.status == ProfileStatus.success && state.message != null) {
            SnackBarHelper.showSuccess(
              context,
              title: Labels.done,
              subtitle: state.message!,
            );
            // Navigate back after successful save
            if (state.message == 'Profile updated successfully!') {
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) Navigator.of(context).pop();
              });
            }
          }

          // Handle failure
          if (state.status == ProfileStatus.failure && state.error != null) {
            SnackBarHelper.showError(
              context,
              title: Labels.error,
              subtitle: state.error!,
            );
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state.status == ProfileStatus.loading && state.user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Form(
                key: state.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image Section
                    _buildProfileImageSection(state, isDark),

                    const SizedBox(height: 32),

                    // Name Field
                    _buildSectionLabel(Labels.fullName),
                    const SizedBox(height: 8),
                    CustomTextFormField(
                      textEditingController: state.nameController,
                      hint: Labels.fullName,
                      validator: AppValidators.validateName,
                    ),

                    const SizedBox(height: 20),

                    // Email Field (Read-only)
                    _buildSectionLabel(Labels.email),
                    const SizedBox(height: 8),
                    CustomTextFormField(
                      textEditingController: state.emailController,
                      hint: Labels.emailAddress,
                      isEnabled: false,
                      validator: AppValidators.noValidation,
                    ),

                    const SizedBox(height: 20),

                    // Phone Field
                    _buildSectionLabel(Labels.phoneNumber),
                    const SizedBox(height: 8),
                    CustomTextFormField(
                      textEditingController: state.phoneController,
                      hint: Labels.enterANumber,
                      validator: AppValidators.validatePhone,
                      textInputType: TextInputType.phone,
                    ),

                    const SizedBox(height: 20),

                    // Address Field
                    _buildSectionLabel(Labels.address),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        CustomTextFormField(
                          textEditingController: state.addressController,
                          hint: Labels.enterYourCompleteAddress,
                          maxLineLength: 3,
                          validator: AppValidators.noValidation,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    CustomElevatedButton(
                      isLoading: state.status == ProfileStatus.updating,
                      text: Labels.updateProfile,
                      onPressed: _saveProfile,
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(ProfileState state, bool isDark) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              // Profile Image
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: state.selectedImageBytes != null
                          ? Image.memory(
                              state.selectedImageBytes!,
                              fit: BoxFit.cover,
                              width: 114,
                              height: 114,
                            )
                          : state.user?.profileImage != null &&
                                state.user!.profileImage!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: state.user!.profileImage!,
                              fit: BoxFit.cover,
                              width: 114,
                              height: 114,
                              placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (_, __, ___) =>
                                  _buildDefaultAvatar(),
                            )
                          : _buildDefaultAvatar(),
                    ),
                  ),
                ),
              ),

              // Edit Button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Labels.tapToUpload,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[100],
      child: const Icon(Icons.person_rounded, size: 60, color: Colors.grey),
    );
  }

  Widget _buildSectionLabel(String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
