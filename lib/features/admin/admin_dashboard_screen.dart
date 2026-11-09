import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/errors/app_failure.dart';
import '../../core/widgets/live_dot.dart';
import '../authentication/admin_access_request_model.dart';
import '../authentication/admin_access_service.dart';
import '../clinics/clinic_membership_model.dart';
import '../clinics/clinic_membership_repository.dart';
import '../clinics/clinic_model.dart';
import '../clinics/clinic_photo_service.dart';
import '../clinics/clinic_repository.dart';
import '../clinics/queue_repository.dart';
import '../clinics/queue_session_model.dart';

/// Clinic Admin Dashboard — "Clinical Precision" design system.
/// Live queue counter, doctor availability, intake history, staff and clinic
/// profile tabs. All values are backed by Firestore.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const double _contentMaxWidth = 720.0;

  final ClinicRepository _clinicRepository = ClinicRepository();
  final ClinicMembershipRepository _membershipRepository =
      ClinicMembershipRepository();
  final QueueRepository _queueRepository = QueueRepository();
  final AdminAccessService _adminAccessService = AdminAccessService();
  final ClinicPhotoService _photoService = ClinicPhotoService();
  final ImagePicker _imagePicker = ImagePicker();

  int _tab = 0;
  bool _loading = true;
  bool _busy = false;
  bool _isUploadingPhoto = false;
  bool _isUploadingClinicPhoto = false;
  String? _error;

  ClinicModel? _clinic;
  ClinicMembershipModel? _membership;
  StreamSubscription<ClinicModel?>? _clinicSubscription;
  StreamSubscription<QueueSessionModel?>? _sessionSubscription;
  QueueSessionModel? _session;
  int _count = 0;
  Future<List<ClinicMembershipModel>>? _membersFuture;

  DateTime get _now => DateTime.now();

  String get _dateKey {
    final now = _now;
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  User? get _user {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get _isActive => (_session?.status ?? 'active') == 'active';

  @override
  void initState() {
    super.initState();
    _loadClinic();
  }

  @override
  void dispose() {
    _clinicSubscription?.cancel();
    _sessionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadClinic() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (Firebase.apps.isEmpty) {
        throw StateError('Firebase is not configured on this device.');
      }
      final user = _user;
      if (user == null) {
        throw StateError('Please sign in with an authorised clinic account.');
      }

      ClinicModel? clinic;
      ClinicMembershipModel? membership;

      final resolution = await _adminAccessService.resolve(user);
      if (!mounted) return;

      if (resolution.state != AdminAccessState.approved) {
        _routeForAccessState(resolution);
        return;
      }

      clinic = resolution.clinic;
      membership = resolution.membership;
      if (clinic == null) {
        throw StateError('No active clinic was found for this account.');
      }

      await _sessionSubscription?.cancel();
      _sessionSubscription = null;
      await _clinicSubscription?.cancel();
      _clinicSubscription = null;
      _session = null;
      _count = 0;

      final loadedClinic = clinic;
      _membersFuture = _membershipRepository.getClinicMembers(
        loadedClinic.clinicId,
      );

      _sessionSubscription = _queueRepository
          .sessionStream(loadedClinic.clinicId, _dateKey)
          .listen(
            (session) {
              if (!mounted) return;
              setState(() {
                _session = session;
                _count =
                    session?.currentParchaNumber ??
                    loadedClinic.todayParchiCount;
              });
            },
            onError: (_) {
              // Keep the last known counter value.
            },
          );

      setState(() {
        _clinic = loadedClinic;
        _membership = membership;
        _loading = false;
      });

      // If the network administrator disables this clinic while the dashboard
      // is open, pause the controls immediately and show the subscription
      // notice instead of letting the clinic keep writing to a disabled queue.
      _clinicSubscription = _clinicRepository
          .clinicStream(loadedClinic.clinicId)
          .listen(
            (clinic) {
              if (!mounted || clinic == null) return;
              if (!clinic.isActive) {
                _clinicSubscription?.cancel();
                Navigator.of(context).pushReplacementNamed(
                  AppRoutes.adminInactive,
                  arguments: clinic,
                );
                return;
              }
              setState(() => _clinic = clinic);
            },
            onError: (_) {
              // Keep the last known clinic profile when the live feed drops.
            },
          );

      // Make sure today's session document exists so the counter is live.
      try {
        await _queueRepository.getOrCreateTodaySession(
          loadedClinic.clinicId,
          _dateKey,
        );
      } catch (_) {
        // The stream above will surface any data that is available.
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  void _routeForAccessState(AdminAccessResolution resolution) {
    switch (resolution.state) {
      case AdminAccessState.pending:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.adminPendingApproval,
          arguments: AdminAccessFlowArgs(
            request: resolution.request!,
            clinic: resolution.clinic,
          ),
        );
        return;
      case AdminAccessState.rejected:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.adminRejected,
          arguments: AdminAccessFlowArgs(
            request: resolution.request!,
            clinic: resolution.clinic,
          ),
        );
        return;
      case AdminAccessState.none:
        Navigator.of(context)
            .pushReplacementNamed(AppRoutes.adminAccessRequest);
        return;
      case AdminAccessState.inactive:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.adminInactive,
          arguments: resolution.clinic,
        );
        return;
      case AdminAccessState.inconsistent:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.adminUnauthorized,
          arguments: resolution.message,
        );
        return;
      case AdminAccessState.approved:
        return;
    }
  }

  Future<void> _increment() async {
    final clinic = _clinic;
    if (clinic == null || _busy) return;
    if (!_isActive) {
      _showMessage('This queue session is not active.');
      return;
    }
    setState(() => _busy = true);
    try {
      final value = await _queueRepository.incrementParcha(
        clinic.clinicId,
        _dateKey,
        _user?.uid ?? 'system',
      );
      if (mounted) setState(() => _count = value);
    } catch (error) {
      _showMessage('Could not update the counter: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decrement() async {
    final clinic = _clinic;
    if (clinic == null || _busy || _count <= 0) return;
    setState(() => _busy = true);
    try {
      final value = await _queueRepository.decrementParcha(
        clinic.clinicId,
        _dateKey,
        _user?.uid ?? 'system',
      );
      if (mounted) setState(() => _count = value);
    } catch (error) {
      _showMessage('Could not update the counter: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset today’s count?'),
        content: const Text(
          'The parchi counter will be set to 0 and the reset will be written '
          'to the audit history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.error,
              foregroundColor: AdminColors.onError,
            ),
            child: const Text('Reset count'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final clinic = _clinic;
    if (clinic == null || _busy) return;

    setState(() => _busy = true);
    try {
      final value = await _queueRepository.resetParcha(
        clinic.clinicId,
        _dateKey,
        _user?.uid ?? 'system',
      );
      if (mounted) setState(() => _count = value);
      _showMessage('Parchi tally reset to 0.');
    } catch (error) {
      _showMessage('Could not reset the counter: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setDoctorStatus(String status) async {
    final clinic = _clinic;
    if (clinic == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _clinicRepository.updateClinic(clinic.clinicId, {
        'doctorStatus': status,
        'isOnline': status == 'available',
      });
      if (!mounted) return;
      setState(() {
        _clinic = clinic.copyWith(
          doctorStatus: status,
          isOnline: status == 'available',
        );
      });
      _showMessage('Doctor availability updated.');
    } catch (error) {
      _showMessage('Could not update availability: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editDoctorTiming(ClinicModel clinic) async {
    final controller = TextEditingController(text: clinic.doctorTiming);
    final timing = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Doctor timing'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Clinic hours',
            hintText: 'Mon–Sat · 9:00 AM – 5:00 PM',
            helperText: 'This text is shown to patients on the clinic screen.',
            prefixIcon: Icon(Icons.schedule_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save timing'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (timing == null) return;
    await _saveDoctorTiming(clinic, timing);
  }

  Future<void> _saveDoctorTiming(ClinicModel clinic, String timing) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _clinicRepository.updateClinic(clinic.clinicId, {
        'doctorTiming': timing,
      });
      if (!mounted) return;
      setState(() {
        _clinic = clinic.copyWith(doctorTiming: timing);
      });
      _showMessage(
        timing.isEmpty
            ? 'Doctor timing cleared.'
            : 'Doctor timing updated for patients.',
      );
    } catch (error) {
      _showMessage('Could not update doctor timing: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editDoctorProfile(ClinicModel clinic) async {
    if (_busy) return;

    final draft = await showDialog<_DoctorProfileDraft>(
      context: context,
      builder: (_) => _DoctorProfileDialog(clinic: clinic),
    );
    if (draft == null) return;
    await _saveDoctorProfile(clinic, draft);
  }

  Future<void> _saveDoctorProfile(
    ClinicModel clinic,
    _DoctorProfileDraft draft,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _clinicRepository.updateClinic(clinic.clinicId, {
        'doctorName': draft.name,
        'doctorCredentials': draft.credentials,
        'doctorSpecialty': draft.specialty,
      });
      if (!mounted) return;
      setState(() {
        _clinic = clinic.copyWith(
          doctorName: draft.name,
          doctorCredentials: draft.credentials,
          doctorSpecialty: draft.specialty,
        );
      });
      _showMessage('Doctor profile updated for patients.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not update the doctor profile. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeDoctorPhoto(ClinicModel clinic) async {
    if (_isUploadingPhoto) return;

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 82,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await _photoService.uploadDoctorPhoto(
        clinicId: clinic.clinicId,
        bytes: bytes,
        fileName: picked.name,
      );
      await _clinicRepository.updateClinic(clinic.clinicId, {
        'doctorPhotoUrl': url,
      });
      if (!mounted) return;
      setState(() {
        _clinic = clinic.copyWith(doctorPhotoUrl: url);
      });
      _showMessage('Doctor photo updated for patients.');
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _showMessage(failure.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not update the doctor photo. Please try again.');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _changeClinicPhoto(ClinicModel clinic) async {
    if (_isUploadingClinicPhoto) return;

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1200,
      imageQuality: 84,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingClinicPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await _photoService.uploadClinicPhoto(
        clinicId: clinic.clinicId,
        bytes: bytes,
        fileName: picked.name,
      );
      await _clinicRepository.updateClinic(clinic.clinicId, {
        'clinicPhotoUrl': url,
      });
      if (!mounted) return;
      setState(() {
        _clinic = clinic.copyWith(clinicPhotoUrl: url);
      });
      _showMessage('Clinic photo updated for patients.');
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _showMessage(failure.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not update the clinic photo. Please try again.');
    } finally {
      if (mounted) setState(() => _isUploadingClinicPhoto = false);
    }
  }

  Widget _buildClinicPhotoCard(ClinicModel clinic) {
    final photo = clinic.clinicPhotoUrl;
    final Widget image;
    if (photo.isEmpty) {
      image = _clinicPhotoPlaceholder();
    } else if (photo.startsWith('http')) {
      image = Image.network(
        photo,
        width: double.infinity,
        height: 108,
        fit: BoxFit.cover,
        cacheWidth: 1000,
        errorBuilder: (_, _, _) => _clinicPhotoPlaceholder(),
      );
    } else {
      image = Image.asset(
        photo,
        width: double.infinity,
        height: 108,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _clinicPhotoPlaceholder(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceLg),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.elevationLevel1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(14), child: image),
          const SizedBox(height: AppSpacing.spaceMd),
          Text(
            'Clinic cover photo',
            style: AppTypography.titleMd.copyWith(
              color: AdminColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This wide image appears on the patient home card above the clinic '
            'name. Use a clear photo of the clinic entrance, reception or '
            'consultation room.',
            style: AppTypography.bodySm.copyWith(
              color: AdminColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUploadingClinicPhoto
                  ? null
                  : () => _changeClinicPhoto(clinic),
              icon: _isUploadingClinicPhoto
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(
                _isUploadingClinicPhoto ? 'Uploading…' : 'Change clinic photo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clinicPhotoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 108,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF073B78), Color(0xFF0A5AA8)],
        ),
      ),
      child: const Icon(
        Icons.local_hospital_rounded,
        color: Colors.white,
        size: 38,
      ),
    );
  }

  Widget _buildDoctorPhotoCard(ClinicModel clinic) {
    final photo = clinic.doctorPhotoUrl;
    final Widget image;
    if (photo.isEmpty) {
      image = _doctorPhotoPlaceholder();
    } else if (photo.startsWith('http')) {
      image = Image.network(
        photo,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        cacheWidth: 216,
        errorBuilder: (_, _, _) => _doctorPhotoPlaceholder(),
      );
    } else {
      image = Image.asset(
        photo,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _doctorPhotoPlaceholder(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceLg),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.elevationLevel1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(16), child: image),
              const SizedBox(width: AppSpacing.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doctor photo',
                      style: AppTypography.titleMd.copyWith(
                        color: AdminColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This photo is shown to patients on the clinic page.',
                      style: AppTypography.bodySm.copyWith(
                        color: AdminColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUploadingPhoto
                  ? null
                  : () => _changeDoctorPhoto(clinic),
              icon: _isUploadingPhoto
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(_isUploadingPhoto ? 'Uploading…' : 'Change photo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doctorPhotoPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      color: AdminColors.surfaceContainer,
      child: const Icon(
        Icons.medical_services_outlined,
        color: AdminColors.primary,
        size: 28,
      ),
    );
  }

  Widget _buildDoctorProfileCard(ClinicModel clinic) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceLg),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.elevationLevel1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.badge_outlined,
                color: AdminColors.primary,
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'DOCTOR PROFILE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm.copyWith(
                    color: AdminColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    fontSize: 10.5,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _busy ? null : () => _editDoctorProfile(clinic),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            clinic.doctorName.trim().isEmpty
                ? 'Add the doctor name, degree and specialty shown to patients.'
                : clinic.doctorName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headlineSm.copyWith(
              color: AdminColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (clinic.doctorCredentials.trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              clinic.doctorCredentials,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm.copyWith(
                color: AdminColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (clinic.doctorSpecialty.trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              clinic.doctorSpecialty,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm.copyWith(
                color: AdminColors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.spaceSm),
          Text(
            'Patients see this on the home card and clinic page. Changes appear '
            'live without reinstalling the app.',
            style: AppTypography.labelSm.copyWith(
              color: AdminColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // UI-only mode.
    }
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.initial, (route) => false);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildShell(
        title: 'Clinic Admin',
        subtitle: 'EASYCHECK ADMIN',
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return _buildShell(
        title: 'Clinic Admin',
        subtitle: 'EASYCHECK ADMIN',
        child: _buildErrorState(),
      );
    }

    if (_clinic == null) {
      return _buildShell(
        title: 'Clinic Admin',
        subtitle: 'EASYCHECK ADMIN',
        child: _buildUnassignedState(),
      );
    }

    return Scaffold(
      backgroundColor: AdminColors.surface,
      body: IndexedStack(
        index: _tab,
        children: [
          _buildQueueTab(),
          _buildIntakeTab(),
          _buildStaffTab(),
          _buildClinicTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Shell / shared chrome
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildShell({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AdminColors.surface,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              topInset + 76.0,
              AppSpacing.gutter,
              bottomInset + 24.0,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                  child: child,
                ),
              ),
            ],
          ),
          _buildTopBar(title: title, subtitle: subtitle),
        ],
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadClinic,
          color: AdminColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              topInset + 76.0,
              AppSpacing.gutter,
              bottomInset + 24.0,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildTopBar(title: title, subtitle: subtitle),
      ],
    );
  }

  Widget _buildTopBar({required String title, required String subtitle}) {
    final topInset = MediaQuery.of(context).padding.top;
    final user = _user;
    final photoUrl = user?.photoURL;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: topInset + 72.0,
        padding: EdgeInsets.only(top: topInset),
        decoration: BoxDecoration(
          color: AdminColors.surface.withValues(alpha: 0.97),
          boxShadow: AppSpacing.elevationLevel1,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              child: Row(
                children: [
                  const BrandMark(size: 40, padding: 4, radius: 10),
                  const SizedBox(width: AppSpacing.spaceMd),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSm.copyWith(
                              color: AdminColors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headlineSm.copyWith(
                              color: AdminColors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spaceSm),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AdminColors.surfaceContainer,
                      shape: BoxShape.circle,
                      image: photoUrl != null && photoUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(photoUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: photoUrl == null || photoUrl.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            color: AdminColors.primary,
                            size: 20,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const items = [
      (Icons.format_list_bulleted_rounded, 'Live Queue'),
      (Icons.how_to_reg_rounded, 'Intake'),
      (Icons.medical_services_rounded, 'Staff'),
      (Icons.manage_accounts_rounded, 'Clinic'),
    ];

    return Container(
      height: 64.0 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: AdminColors.surface.withValues(alpha: 0.97),
        boxShadow: [
          BoxShadow(
            color: AdminColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = _tab == index;
          return Expanded(
            child: Semantics(
              selected: selected,
              button: true,
              label: items[index].$2,
              child: InkWell(
                onTap: () => setState(() => _tab = index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      items[index].$1,
                      size: 23,
                      color: selected
                          ? AdminColors.primary
                          : AdminColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[index].$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected
                            ? AdminColors.primary
                            : AdminColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Live queue tab
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildQueueTab() {
    final clinic = _clinic!;
    return _buildPage(
      title: clinic.name,
      subtitle: 'DOCTOR CONSOLE • EASYCHECK',
      children: [
        _buildClinicHeaderCard(clinic),
        const SizedBox(height: AppSpacing.spaceMd),
        _buildDoctorAvailabilityCard(clinic),
        const SizedBox(height: AppSpacing.spaceMd),
        _buildCounterCard(clinic),
      ],
    );
  }

  String get _doctorGreeting {
    final hour = DateTime.now().hour;
    final part = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final name = _clinic?.doctorName.trim() ?? '';
    return name.isEmpty ? '$part, Doctor' : '$part, $name';
  }

  Widget _buildClinicHeaderCard(ClinicModel clinic) {
    final status = _isActive ? 'LIVE QUEUE' : 'QUEUE PAUSED';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF041A33), Color(0xFF073B78), Color(0xFF0A4A8A)],
          stops: [0.0, 0.58, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AdminColors.primary.withValues(alpha: 0.20),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -72,
            right: -52,
            child: IgnorePointer(
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF62DD9E).withValues(alpha: 0.16),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  LiveStatusPill(
                    label: status,
                    foreground: const Color(0xFFB9F8D7),
                    background: Colors.white.withValues(alpha: 0.10),
                    pulse: _isActive,
                    padding: const EdgeInsets.fromLTRB(9, 4, 10, 4),
                  ),
                  const Text(
                    'DOCTOR CONSOLE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Color(0xFF8CE8BC),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _doctorGreeting,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.4,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                clinic.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: Color(0xE6FFFFFF),
                ),
              ),
              if (clinic.doctorSpecialty.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  clinic.doctorSpecialty,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xB3FFFFFF),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildHeroChip(
                    icon: Icons.schedule_rounded,
                    label: clinic.doctorTiming.trim().isEmpty
                        ? 'Set doctor timing'
                        : clinic.doctorTiming,
                    onTap: _busy ? null : () => _editDoctorTiming(clinic),
                  ),
                  _buildHeroChip(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Today · $_count parchi',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: const Color(0xFF8CE8BC)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE6FFF2),
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.edit_outlined,
                  size: 12,
                  color: Color(0xFFB9F8D7),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorAvailabilityCard(ClinicModel clinic) {
    final status = clinic.doctorStatus;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceLg),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.elevationLevel1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.medical_services_outlined,
                color: AdminColors.primary,
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'DOCTOR AVAILABILITY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm.copyWith(
                    color: AdminColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    fontSize: 10.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: _busy ? null : () => _editDoctorProfile(clinic),
                tooltip: 'Edit doctor profile',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 17),
              ),
              _buildAvailabilityPill(status),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Text(
            clinic.doctorName.isNotEmpty
                ? (clinic.doctorCredentials.isEmpty
                      ? clinic.doctorName
                      : '${clinic.doctorName}, ${clinic.doctorCredentials}')
                : 'Doctor not assigned',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headlineSm.copyWith(
              color: AdminColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            clinic.doctorSpecialty.isNotEmpty
                ? clinic.doctorSpecialty
                : 'Update your clinic profile to show the doctor’s specialty.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm.copyWith(
              color: AdminColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Material(
            color: AdminColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: _busy ? null : () => _editDoctorTiming(clinic),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spaceMd,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: AdminColors.secondary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.spaceSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DOCTOR TIMING',
                            style: AppTypography.labelSm.copyWith(
                              color: AdminColors.onSurfaceVariant,
                              fontSize: 9.5,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            clinic.doctorTiming.trim().isEmpty
                                ? 'Add clinic hours shown to patients'
                                : clinic.doctorTiming,
                            style: AppTypography.bodySm.copyWith(
                              color: clinic.doctorTiming.trim().isEmpty
                                  ? AdminColors.onSurfaceVariant
                                  : AdminColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSm),
                    const Icon(
                      Icons.edit_outlined,
                      color: AdminColors.secondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Row(
            children: [
              _buildStatusButton(
                label: 'Available',
                icon: Icons.check_circle_outline_rounded,
                selected: status == 'available',
                color: AdminColors.primary,
                onTap: () => _setDoctorStatus('available'),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              _buildStatusButton(
                label: 'Delayed',
                icon: Icons.schedule_rounded,
                selected: status == 'delayed',
                color: const Color(0xFFD97706),
                onTap: () => _setDoctorStatus('delayed'),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              _buildStatusButton(
                label: 'Off-Duty',
                icon: Icons.block_rounded,
                selected: status == 'offDuty',
                color: AdminColors.onSurfaceVariant,
                onTap: () => _setDoctorStatus('offDuty'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityPill(String status) {
    final (label, background, foreground) = switch (status) {
      'delayed' => (
        'Delayed',
        const Color(0xFFFEF3C7),
        const Color(0xFFB45309),
      ),
      'offDuty' => (
        'Off-Duty',
        AdminColors.surfaceContainerHigh,
        AdminColors.onSurfaceVariant,
      ),
      _ => (
        'Online',
        AdminColors.secondaryContainer,
        AdminColors.onSecondaryContainer,
      ),
    };

    return LiveStatusPill(
      label: label,
      foreground: foreground,
      background: background,
      pulse: status == 'available',
    );
  }

  Widget _buildStatusButton({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: _busy ? null : onTap,
          borderRadius: AppSpacing.roundedMd,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.12)
                  : AdminColors.surfaceContainerLow,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? color : AdminColors.onSurfaceVariant,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMd.copyWith(
                    fontSize: 11.5,
                    color: selected ? color : AdminColors.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounterCard(ClinicModel clinic) {
    final dateLabel = DateFormat('EEEE, MMMM d').format(_now);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AdminColors.surfaceContainerLowest,
            AdminColors.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.elevationLevel2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Parchi Count",
                      style: AppTypography.headlineMd.copyWith(
                        color: AdminColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: AppTypography.bodySm.copyWith(
                        color: AdminColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSessionPill(),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceLg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spaceMd,
              vertical: AppSpacing.spaceMd,
            ),
            decoration: BoxDecoration(
              color: AdminColors.surfaceContainerLow,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRoundButton(
                  icon: Icons.remove_rounded,
                  enabled: _count > 0 && !_busy,
                  onTap: _decrement,
                  background: AdminColors.surfaceContainerLowest,
                  foreground: AdminColors.onSurface,
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$_count',
                        maxLines: 1,
                        style: AppTypography.displayLg.copyWith(
                          fontSize: 56,
                          color: AdminColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildRoundButton(
                  icon: Icons.add_rounded,
                  enabled: !_busy,
                  onTap: _increment,
                  background: AdminColors.primary,
                  foreground: AdminColors.onPrimary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _busy ? null : _confirmReset,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset count to 0'),
              style: TextButton.styleFrom(
                foregroundColor: AdminColors.error,
                textStyle: AppTypography.labelMd.copyWith(
                  color: AdminColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionPill() {
    final status = _session?.status ?? 'active';
    final (label, color) = switch (status) {
      'paused' => ('Paused', const Color(0xFFD97706)),
      'closed' => ('Closed', AdminColors.onSurfaceVariant),
      _ => ('Live', AdminColors.primary),
    };
    return LiveStatusPill(
      label: label,
      foreground: color,
      background: color.withValues(alpha: 0.10),
      pulse: status == 'active',
      padding: const EdgeInsets.fromLTRB(8, 3, 9, 3),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required Color background,
    required Color foreground,
  }) {
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: enabled ? background : AdminColors.surfaceContainer,
        shape: const CircleBorder(),
        elevation: enabled ? 1 : 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              icon,
              size: 30,
              color: enabled
                  ? foreground
                  : AdminColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Intake history tab
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildIntakeTab() {
    final clinic = _clinic!;
    return _buildPage(
      title: 'Intake History',
      subtitle: 'DOCTOR CONSOLE • EASYCHECK',
      children: [
        StreamBuilder<List<QueueHistoryEntry>>(
          stream: _queueRepository.historyStream(clinic.clinicId, _dateKey),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return _buildInfoCard(
                icon: Icons.cloud_off_rounded,
                title: 'History unavailable',
                body: 'Could not load today’s intake history. Pull down to retry.',
              );
            }
            final entries = snapshot.data ?? const <QueueHistoryEntry>[];
            if (entries.isEmpty) {
              return _buildInfoCard(
                icon: Icons.history_rounded,
                title: 'No activity yet',
                body:
                    'Counter updates and resets for today will appear here '
                    'with a timestamp and audit trail.',
              );
            }
            return Column(
              children: [for (final entry in entries) _buildHistoryTile(entry)],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryTile(QueueHistoryEntry entry) {
    final (icon, color) = switch (entry.action) {
      'reset' => (Icons.restart_alt_rounded, AdminColors.error),
      'correction' => (Icons.edit_rounded, const Color(0xFFD97706)),
      _ => (Icons.add_circle_outline_rounded, AdminColors.primary),
    };
    final time = DateFormat('h:mm a').format(entry.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spaceSm),
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        boxShadow: AppSpacing.elevationLevel1,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: AppSpacing.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_actionLabel(entry.action)} · '
                  '${entry.previousNumber} → ${entry.newNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AdminColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'By ${_shortUid(entry.performedBy)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm.copyWith(
                    color: AdminColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.spaceSm),
          Text(
            time,
            style: AppTypography.labelSm.copyWith(
              color: AdminColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _actionLabel(String action) => switch (action) {
    'reset' => 'Reset',
    'correction' => 'Correction',
    _ => 'Increment',
  };

  String _shortUid(String uid) {
    if (uid.isEmpty) return 'system';
    if (uid.length <= 10) return uid;
    return '${uid.substring(0, 6)}…';
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Staff tab
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildStaffTab() {
    final clinic = _clinic!;
    return _buildPage(
      title: 'Clinic Staff',
      subtitle: 'DOCTOR CONSOLE • EASYCHECK',
      children: [
        FutureBuilder<List<ClinicMembershipModel>>(
          future: _membersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return _buildInfoCard(
                icon: Icons.cloud_off_rounded,
                title: 'Staff list unavailable',
                body: 'Could not load clinic members. Pull down to retry.',
              );
            }
            final members = snapshot.data ?? const <ClinicMembershipModel>[];
            if (members.isEmpty) {
              return _buildInfoCard(
                icon: Icons.group_add_outlined,
                title: 'No staff assigned',
                body:
                    'Members added to ${clinic.name} will appear here with '
                    'their role and permissions.',
              );
            }
            return Column(
              children: [
                for (final member in members) _buildMemberTile(member),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMemberTile(ClinicMembershipModel member) {
    final active = member.isActive;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spaceSm),
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        boxShadow: AppSpacing.elevationLevel1,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AdminColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AdminColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _roleLabel(member.role),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AdminColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.permissions.isEmpty
                      ? 'No permissions assigned'
                      : member.permissions.map(_permissionLabel).join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm.copyWith(
                    color: AdminColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.spaceSm),
          LiveStatusPill(
            label: active ? 'Active' : 'Inactive',
            foreground: active
                ? AdminColors.onSecondaryContainer
                : AdminColors.onSurfaceVariant,
            background: active
                ? AdminColors.secondaryContainer
                : AdminColors.surfaceContainerHigh,
            pulse: active,
            padding: const EdgeInsets.fromLTRB(8, 3, 9, 3),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
    'clinic_admin' => 'Clinic Admin',
    'front_desk_lead' => 'Front Desk Lead',
    'triage_coordinator' => 'Triage Coordinator',
    _ => role.isEmpty ? 'Staff member' : role,
  };

  String _permissionLabel(String permission) => switch (permission) {
    'update_tally' => 'Counter',
    'update_status' => 'Status',
    'reset_tally' => 'Reset',
    'manage_staff' => 'Staff',
    'view_queue' => 'Queue',
    _ => permission,
  };

  // ───────────────────────────────────────────────────────────────────────────
  // Clinic tab
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildClinicTab() {
    final clinic = _clinic!;
    final user = _user;
    final membership = _membership;
    return _buildPage(
      title: 'Clinic Profile',
      subtitle: 'DOCTOR CONSOLE • EASYCHECK',
      children: [
        _buildClinicPhotoCard(clinic),
        const SizedBox(height: AppSpacing.spaceMd),
        _buildDoctorPhotoCard(clinic),
        const SizedBox(height: AppSpacing.spaceMd),
        _buildDoctorProfileCard(clinic),
        const SizedBox(height: AppSpacing.spaceMd),
        Container(
          padding: const EdgeInsets.all(AppSpacing.spaceLg),
          decoration: BoxDecoration(
            color: AdminColors.surfaceContainerLowest,
            borderRadius: AppSpacing.roundedLg,
            boxShadow: AppSpacing.elevationLevel1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clinic.name,
                style: AppTypography.headlineSm.copyWith(
                  color: AdminColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Clinic ID · ${clinic.clinicId}',
                style: AppTypography.labelSm.copyWith(
                  color: AdminColors.onSurfaceVariant,
                ),
              ),
              const Divider(height: AppSpacing.spaceXl),
              _buildInfoRow(
                Icons.location_on_outlined,
                'Address',
                clinic.address.isEmpty
                    ? 'Not listed'
                    : '${clinic.address}${clinic.city.isEmpty ? '' : ', ${clinic.city}'}',
              ),
              _buildInfoRow(
                Icons.call_outlined,
                'Phone',
                clinic.phone.isEmpty ? 'Not listed' : clinic.phone,
              ),
              _buildInfoRow(
                Icons.mail_outline_rounded,
                'Email',
                clinic.email.isEmpty ? 'Not listed' : clinic.email,
              ),
              _buildInfoRow(
                Icons.badge_outlined,
                'Your role',
                membership == null
                    ? 'Clinic administrator'
                    : _roleLabel(membership.role),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.spaceMd),
        Container(
          padding: const EdgeInsets.all(AppSpacing.spaceLg),
          decoration: BoxDecoration(
            color: AdminColors.surfaceContainerLowest,
            borderRadius: AppSpacing.roundedLg,
            boxShadow: AppSpacing.elevationLevel1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Signed-in account',
                style: AppTypography.labelSm.copyWith(
                  color: AdminColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.displayName?.trim().isNotEmpty == true
                    ? user!.displayName!
                    : 'Clinic administrator',
                style: AppTypography.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AdminColors.onSurface,
                ),
              ),
              Text(
                user?.email ?? 'Not available',
                style: AppTypography.bodySm.copyWith(
                  color: AdminColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.spaceLg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.error,
                    side: BorderSide(
                      color: AdminColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.spaceMd),
        Center(
          child: Text(
            'EasyCheck Online · Version 1.0.0 (1)',
            style: AppTypography.labelSm.copyWith(
              color: AdminColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AdminColors.primary),
          const SizedBox(width: AppSpacing.spaceSm),
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: AdminColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySm.copyWith(
                color: AdminColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Empty / error states
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceXl),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.elevationLevel1,
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AdminColors.primary),
          const SizedBox(height: AppSpacing.spaceMd),
          Text(title, style: AppTypography.headlineSm),
          const SizedBox(height: AppSpacing.spaceXs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              color: AdminColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.cloud_off_rounded,
          title: 'Could not open the dashboard',
          body: _error ?? 'Check your connection and try again.',
        ),
        const SizedBox(height: AppSpacing.spaceLg),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _loadClinic,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        TextButton(onPressed: _signOut, child: const Text('Sign out')),
      ],
    );
  }

  Widget _buildUnassignedState() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Clinic access required',
          body:
              'Your Google account is signed in, but no active clinic '
              'membership is available. Submit a clinic access request or ask '
              'your clinic administrator to activate your membership.',
        ),
        const SizedBox(height: AppSpacing.spaceLg),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () =>
                Navigator.of(context)
                    .pushReplacementNamed(AppRoutes.adminAccessRequest),
            icon: const Icon(Icons.add_business_rounded, size: 18),
            label: const Text('Request clinic access'),
          ),
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loadClinic,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Check again'),
          ),
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        TextButton(onPressed: _signOut, child: const Text('Sign out')),
      ],
    );
  }
}

class _DoctorProfileDraft {
  final String name;
  final String credentials;
  final String specialty;

  const _DoctorProfileDraft({
    required this.name,
    required this.credentials,
    required this.specialty,
  });
}

class _DoctorProfileDialog extends StatefulWidget {
  final ClinicModel clinic;

  const _DoctorProfileDialog({required this.clinic});

  @override
  State<_DoctorProfileDialog> createState() => _DoctorProfileDialogState();
}

class _DoctorProfileDialogState extends State<_DoctorProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _credentialsController;
  late final TextEditingController _specialtyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.clinic.doctorName);
    _credentialsController = TextEditingController(
      text: widget.clinic.doctorCredentials,
    );
    _specialtyController = TextEditingController(
      text: widget.clinic.doctorSpecialty,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _credentialsController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _DoctorProfileDraft(
        name: _nameController.text.trim(),
        credentials: _credentialsController.text.trim(),
        specialty: _specialtyController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit doctor profile'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [LengthLimitingTextInputFormatter(80)],
                decoration: const InputDecoration(
                  labelText: 'Doctor name',
                  hintText: 'Dr. Rajesh Kumar',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the doctor name shown to patients.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _credentialsController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
                decoration: const InputDecoration(
                  labelText: 'Degree / qualifications',
                  hintText: 'MBBS, MD (Medicine)',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _specialtyController,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
                decoration: const InputDecoration(
                  labelText: 'Specialty / designation',
                  hintText: 'Consultant Cardiologist',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'These details appear on the patient home card and clinic page, '
                'and update live.',
                style: AppTypography.labelSm.copyWith(
                  color: AdminColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save profile')),
      ],
    );
  }
}
