import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/errors/app_failure.dart';
import '../clinics/clinic_model.dart';
import '../clinics/clinic_repository.dart';
import 'admin_access_request_model.dart';
import 'admin_access_request_repository.dart';
import 'admin_auth_widgets.dart';
import 'auth_error_mapper.dart';

enum _ClinicRequestMode { existing, newClinic }

/// Clinic selection and admin access request form.
///
/// The form only collects the applicant's name, the Google account email,
/// the clinic and an optional contact number. The applicant cannot choose a
/// role or permissions, and the request is always written for the current
/// Firebase UID. If the clinic is not listed yet, the applicant can enter its
/// name so the Super Admin can onboard it manually.
class AdminAccessRequestScreen extends StatefulWidget {
  const AdminAccessRequestScreen({super.key});

  @override
  State<AdminAccessRequestScreen> createState() =>
      _AdminAccessRequestScreenState();
}

class _AdminAccessRequestScreenState extends State<AdminAccessRequestScreen> {
  final ClinicRepository _clinicRepository = ClinicRepository();
  final AdminAccessRequestRepository _requestRepository =
      AdminAccessRequestRepository();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _clinicNameController = TextEditingController();

  bool _loadingClinics = true;
  bool _submitting = false;
  String? _clinicsError;
  String? _submitError;
  List<ClinicModel> _clinics = const [];
  Set<String> _knownClinicIds = const {};
  String? _selectedClinicId;
  _ClinicRequestMode _mode = _ClinicRequestMode.existing;

  User? get _user {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    final user = _user;
    _nameController.text = user?.displayName?.trim() ?? '';
    _emailController.text = _accountEmail(user);
    _loadClinics();
  }

  /// Resolves the best available contact email for the signed-in account.
  ///
  /// The UID is the authoritative identity. Email is stored only as contact
  /// information, so a provider that omits the email must not block a request.
  String _accountEmail(User? user) {
    if (user == null) return '';
    final direct = user.email?.trim() ?? '';
    if (direct.isNotEmpty) return direct;
    for (final provider in user.providerData) {
      final email = provider.email?.trim() ?? '';
      if (email.isNotEmpty) return email;
    }
    return _emailController.text.trim();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _clinicNameController.dispose();
    super.dispose();
  }

  /// Generates a clinic ID in the same CLN-xxxxx format the Super Admin console
  /// uses. The ID is only a placeholder until the clinic is onboarded; the
  /// applicant cannot create the clinic record itself.
  String _generateClinicId() {
    final random = Random.secure();
    for (var attempt = 0; attempt < 24; attempt += 1) {
      final candidate = 'CLN-${10000 + random.nextInt(90000)}';
      if (!_knownClinicIds.contains(candidate)) return candidate;
    }
    final fallback = 10000 + DateTime.now().microsecondsSinceEpoch % 90000;
    return 'CLN-$fallback';
  }

  Future<void> _loadClinics() async {
    if (mounted) {
      setState(() {
        _loadingClinics = true;
        _clinicsError = null;
      });
    }
    try {
      if (Firebase.apps.isEmpty) {
        throw const ServerFailure(
          'Firebase is not configured on this device. Please install the '
          'latest version of the app and try again.',
        );
      }
      final clinics = await _clinicRepository.getAllClinics();
      final active = clinics.where((clinic) => clinic.isActive).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _clinics = active;
        _knownClinicIds = clinics.map((clinic) => clinic.clinicId).toSet();
        _loadingClinics = false;
        if (_selectedClinicId != null &&
            !active.any((clinic) => clinic.clinicId == _selectedClinicId)) {
          _selectedClinicId = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingClinics = false;
        _clinicsError = AuthErrorMapper.message(error);
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = _user;
    if (user == null) {
      setState(() {
        _submitError =
            'Your sign-in session has expired. Sign in again to continue.';
      });
      return;
    }

    final isNewClinic = _mode == _ClinicRequestMode.newClinic;
    ClinicModel? clinic;
    late final String clinicId;
    late final String clinicName;

    if (isNewClinic) {
      clinicName = _clinicNameController.text.trim();
      clinicId = _generateClinicId();
    } else {
      ClinicModel? selected;
      for (final item in _clinics) {
        if (item.clinicId == _selectedClinicId) {
          selected = item;
          break;
        }
      }
      if (selected == null) {
        setState(() {
          _submitError = 'Select the clinic you work for.';
        });
        return;
      }
      clinic = selected;
      clinicId = selected.clinicId;
      clinicName = selected.name;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final request = await _requestRepository.submitRequest(
        uid: user.uid,
        email: _accountEmail(user),
        displayName: _nameController.text.trim(),
        clinicId: clinicId,
        clinicName: clinicName,
        contactNumber: _contactController.text.trim(),
      );
      if (!mounted) return;
      await _showSubmittedDialog(
        clinicName: clinicName,
        applicantName: _nameController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.adminRequestSubmitted,
        arguments: AdminAccessFlowArgs(request: request, clinic: clinic),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = AuthErrorMapper.message(error);
      });
    }
  }

  Future<void> _showSubmittedDialog({
    required String clinicName,
    required String applicantName,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Application submitted',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (dialogContext, _, _) => _AccessSubmittedDialog(
        clinicName: clinicName,
        applicantName: applicantName,
        onClose: () => Navigator.of(dialogContext).pop(),
      ),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // Still return to the role selection screen.
    }
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.initial, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return AdminAuthShell(
      title: 'Clinic Access',
      onSignOut: _signOut,
      child: user == null ? _buildSignedOutState() : _buildForm(user),
    );
  }

  Widget _buildSignedOutState() {
    return Column(
      children: [
        AdminStatusCard(
          icon: Icons.lock_outline_rounded,
          eyebrow: 'SIGN-IN REQUIRED',
          title: 'Sign in to request access',
          body:
              'Use your Google account so the request can be linked to your '
              'Firebase identity.',
          iconBackground: AdminColors.surfaceContainerHigh,
          iconColor: AdminColors.secondary,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.initial, (route) => false),
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: AdminColors.onPrimary,
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to role selection',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminStatusCard(
          icon: Icons.verified_user_outlined,
          eyebrow: 'ACCESS VERIFICATION',
          title: 'Request clinic access',
          body:
              'Choose your clinic or add a new one, then submit your details. '
              'A Super Admin reviews every application before the clinic '
              'dashboard is enabled.',
          iconBackground: AdminColors.surfaceContainerLow,
          iconColor: AdminColors.primary,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AdminColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14073B78),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Application details',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your request stays pending until it is reviewed. Submitting '
                  'this form does not grant access.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AdminColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) {
                      return 'Enter your full name.';
                    }
                    if ((value?.trim().length ?? 0) < 2) {
                      return 'Enter at least 2 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Google account email',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                    helperText:
                        'Linked automatically from your Google sign-in.',
                  ),
                ),
                const SizedBox(height: 12),
                _buildClinicPicker(),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Contact number (optional)',
                    prefixIcon: Icon(Icons.call_outlined),
                    helperText:
                        'Only used if the review team needs to verify '
                        'your request.',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    if (!RegExp(r'^[0-9+\-\s()]{7,20}$').hasMatch(text)) {
                      return 'Enter a valid contact number.';
                    }
                    return null;
                  },
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 14),
                  AdminErrorBanner(message: _submitError!),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        _submitting ||
                            (_mode == _ClinicRequestMode.existing &&
                                (_loadingClinics ||
                                    _clinicsError != null ||
                                    _clinics.isEmpty))
                        ? null
                        : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AdminColors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _submitting ? 'Submitting…' : 'Submit access request',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminColors.primary,
                      foregroundColor: AdminColors.onPrimary,
                      minimumSize: const Size.fromHeight(50),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Signed in as ${_accountEmail(user).isEmpty ? 'your Google account' : _accountEmail(user)}. '
                  'Requests are linked to this account.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AdminColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClinicPicker() {
    final isNew = _mode == _ClinicRequestMode.newClinic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Clinic',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AdminColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Existing clinic'),
              selected: !isNew,
              onSelected: _submitting
                  ? null
                  : (_) => setState(() => _mode = _ClinicRequestMode.existing),
            ),
            ChoiceChip(
              label: const Text('Add a new clinic'),
              selected: isNew,
              onSelected: _submitting
                  ? null
                  : (_) => setState(() => _mode = _ClinicRequestMode.newClinic),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isNew)
          TextFormField(
            controller: _clinicNameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Clinic name',
              hintText: 'e.g. Sunrise Family Clinic',
              prefixIcon: Icon(Icons.add_business_rounded),
              helperText:
                  'Not listed yet? Enter the clinic name. Our team will '
                  'onboard it manually before enabling access.',
              helperMaxLines: 3,
            ),
            validator: (value) {
              final name = value?.trim() ?? '';
              if (name.isEmpty) return 'Enter your clinic name.';
              if (name.length < 2) return 'Enter at least 2 characters.';
              return null;
            },
          )
        else ...[
          if (_loadingClinics)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else if (_clinicsError != null)
            _buildClinicLoadError()
          else if (_clinics.isEmpty)
            _buildNoClinics()
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedClinicId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Select clinic',
                prefixIcon: Icon(Icons.local_hospital_outlined),
              ),
              hint: const Text('Select your clinic'),
              items: _clinics
                  .map(
                    (clinic) => DropdownMenuItem<String>(
                      value: clinic.clinicId,
                      child: Text(
                        '${clinic.name} (${clinic.clinicId})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _selectedClinicId = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Select the clinic you work for.';
                }
                return null;
              },
            ),
        ],
      ],
    );
  }

  Widget _buildClinicLoadError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminErrorBanner(
          message: _clinicsError ?? 'Could not load the clinic list.',
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _loadClinics,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Retry clinic list'),
        ),
        TextButton.icon(
          onPressed: _submitting
              ? null
              : () => setState(() => _mode = _ClinicRequestMode.newClinic),
          icon: const Icon(Icons.add_business_rounded, size: 18),
          label: const Text('Add your clinic instead'),
        ),
      ],
    );
  }

  Widget _buildNoClinics() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AdminColors.secondary,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No active clinics are listed right now. You can add your '
                  'clinic name and our team will onboard it manually.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AdminColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: _submitting
                ? null
                : () => setState(() => _mode = _ClinicRequestMode.newClinic),
            icon: const Icon(Icons.add_business_rounded, size: 18),
            label: const Text('Add your clinic instead'),
          ),
        ],
      ),
    );
  }
}

class _AccessSubmittedDialog extends StatelessWidget {
  final String clinicName;
  final String applicantName;
  final VoidCallback onClose;

  const _AccessSubmittedDialog({
    required this.clinicName,
    required this.applicantName,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final greeting = applicantName.isEmpty ? '' : ', $applicantName';
    return Dialog(
      backgroundColor: AdminColors.surfaceContainerLowest,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 720),
              curve: Curves.easeOutBack,
              builder: (_, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 86,
                height: 86,
                decoration: const BoxDecoration(
                  color: AdminColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AdminColors.onSecondaryContainer,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (_, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - value)),
                  child: child,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Application submitted',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thank you$greeting. Your clinic access application for '
                    '$clinicName has been received successfully.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      color: AdminColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Our team will review your application and contact you '
                    'within 8–12 hours. Access is enabled only after approval.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: AdminColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AdminColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: AdminColors.secondary,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Review window · 8–12 hours',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onClose,
                      style: FilledButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: AdminColors.onPrimary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Got it',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
