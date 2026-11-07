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

/// Clinic selection and admin access request form.
///
/// The form only collects the applicant's name, the Google account email,
/// the clinic and an optional contact number. The applicant cannot choose a
/// role or permissions, and the request is always written for the current
/// Firebase UID.
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

  bool _loadingClinics = true;
  bool _submitting = false;
  String? _clinicsError;
  String? _submitError;
  List<ClinicModel> _clinics = const [];
  String? _selectedClinicId;

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
    super.dispose();
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

    final clinic = _clinics.firstWhere(
      (item) => item.clinicId == _selectedClinicId,
    );

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final request = await _requestRepository.submitRequest(
        uid: user.uid,
        email: _accountEmail(user),
        displayName: _nameController.text.trim(),
        clinicId: clinic.clinicId,
        contactNumber: _contactController.text.trim(),
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

  Future<void> _signOut() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // Still return to the role selection screen.
    }
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.initial,
      (route) => false,
    );
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
          body: 'Use your Google account so the request can be linked to your '
              'Firebase identity.',
          iconBackground: AdminColors.surfaceContainerHigh,
          iconColor: AdminColors.secondary,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.initial,
              (route) => false,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: AdminColors.onPrimary,
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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
          body: 'Choose your clinic and submit your details. A Super Admin '
              'reviews every request before the clinic dashboard is enabled.',
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
                    helperText: 'Linked automatically from your Google sign-in.',
                  ),
                ),
                const SizedBox(height: 12),
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
                      labelText: 'Clinic',
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Contact number (optional)',
                    prefixIcon: Icon(Icons.call_outlined),
                    helperText: 'Only used if the review team needs to verify '
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
                        (_submitting || _loadingClinics || _clinics.isEmpty)
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
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: AdminColors.secondary, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No active clinics are available right now. Ask your clinic’s '
              'EasyCheck administrator to activate the clinic, then try again.',
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
    );
  }
}
