import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/errors/app_failure.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/live_dot.dart';
import '../../core/widgets/photo_crop_dialog.dart';
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
  int _lastServerCount = 0;
  int _pendingCounterDelta = 0;
  bool _counterSyncing = false;
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
              final serverCount =
                  session?.currentParchaNumber ?? loadedClinic.todayParchiCount;
              setState(() {
                _session = session;
                _lastServerCount = serverCount;
                // Do not let a live snapshot overwrite a value the user just
                // changed optimistically while the write is still in flight.
                if (_pendingCounterDelta == 0 && !_counterSyncing) {
                  _count = serverCount;
                }
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
    if (clinic == null) return;
    if (!_isActive) {
      _showMessage(AppLocalizations.of(context).t('thisQueueNotActive'));
      return;
    }

    // Update the visible number immediately. Firestore is reconciled in the
    // background so a fast tap never waits for the network round-trip.
    setState(() {
      _count += 1;
      _pendingCounterDelta += 1;
    });
    unawaited(_drainCounterQueue());
  }

  Future<void> _decrement() async {
    final clinic = _clinic;
    if (clinic == null || _count <= 0) return;

    setState(() {
      _count -= 1;
      _pendingCounterDelta -= 1;
    });
    unawaited(_drainCounterQueue());
  }

  Future<void> _drainCounterQueue() async {
    if (_counterSyncing) return;
    _counterSyncing = true;
    final clinic = _clinic;
    if (clinic == null) {
      _counterSyncing = false;
      return;
    }

    try {
      while (_pendingCounterDelta != 0) {
        final delta = _pendingCounterDelta;
        final value = delta > 0
            ? await _queueRepository.incrementParcha(
                clinic.clinicId,
                _dateKey,
                _user?.uid ?? 'system',
              )
            : await _queueRepository.decrementParcha(
                clinic.clinicId,
                _dateKey,
                _user?.uid ?? 'system',
              );

        _lastServerCount = value;
        _pendingCounterDelta += delta > 0 ? -1 : 1;
        if (!mounted) return;
        setState(() {
          _count = value + _pendingCounterDelta;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pendingCounterDelta = 0;
        _count = _lastServerCount;
      });
      _showMessage(AppLocalizations.of(context).t('couldNotUpdateCounter'));
    } finally {
      _counterSyncing = false;
    }
  }

  Future<void> _confirmReset() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('resetCountQuestion')),
        content: Text(l10n.t('resetCountBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.error,
              foregroundColor: AdminColors.onError,
            ),
            child: Text(l10n.t('resetCountConfirm')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final clinic = _clinic;
    if (clinic == null || _busy) return;
    if (_pendingCounterDelta != 0 || _counterSyncing) {
      _showMessage(l10n.t('couldNotUpdateCounter'));
      return;
    }

    setState(() => _busy = true);
    try {
      final value = await _queueRepository.resetParcha(
        clinic.clinicId,
        _dateKey,
        _user?.uid ?? 'system',
      );
      if (mounted) {
        setState(() {
          _count = value;
          _lastServerCount = value;
          _pendingCounterDelta = 0;
        });
      }
      _showMessage(l10n.t('parchiReset'));
    } catch (error) {
      _showMessage(l10n.t('couldNotResetCounter'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editYesterdayCount(ClinicModel clinic) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: '${clinic.yesterdayParchiCount}',
    );
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        String? error;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void submit() {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null || parsed < 0 || parsed > 99999) {
                setDialogState(() {
                  error = l10n.t('enterValidCount');
                });
                return;
              }
              Navigator.of(dialogContext).pop(parsed);
            }

            return AlertDialog(
              title: Text(l10n.t('editYesterdayCount')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('editYesterdayBody'),
                    style: AppTypography.bodySm.copyWith(
                      color: AdminColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spaceMd),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      labelText: l10n.t('yesterdayParchiCountLabel'),
                      errorText: error,
                      prefixIcon: const Icon(Icons.history_rounded),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.t('cancel')),
                ),
                FilledButton(onPressed: submit, child: Text(l10n.t('save'))),
              ],
            );
          },
        );
      },
    );
    controller.dispose();

    if (value == null || !mounted) return;
    if (value == clinic.yesterdayParchiCount) {
      _showMessage(
        l10n.t('yesterdayCountAlready').replaceAll('{count}', '$value'),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final updated = await _queueRepository.updateYesterdayParchiCount(
        clinic.clinicId,
        value,
        _user?.uid ?? 'system',
      );
      if (!mounted) return;
      setState(() {
        _clinic = _clinic?.copyWith(yesterdayParchiCount: updated);
      });
      _showMessage(l10n.t('yesterdayUpdated'));
    } catch (_) {
      _showMessage(l10n.t('couldNotUpdateYesterdayCount'));
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
      _showMessage(AppLocalizations.of(context).t('doctorAvailabilityUpdated'));
    } catch (_) {
      _showMessage(
        AppLocalizations.of(context).t('couldNotUpdateAvailability'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editDoctorTiming(ClinicModel clinic) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: clinic.doctorTiming);
    final timing = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.t('doctorTimingTitle')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.t('clinicHoursLabel'),
            hintText: l10n.t('clinicHoursHint'),
            helperText: l10n.t('clinicHoursHelper'),
            prefixIcon: const Icon(Icons.schedule_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.t('saveTiming')),
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
            ? AppLocalizations.of(context).t('doctorTimingCleared')
            : AppLocalizations.of(context).t('doctorTimingUpdated'),
      );
    } catch (_) {
      _showMessage(
        AppLocalizations.of(context).t('couldNotUpdateDoctorTiming'),
      );
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
      _showMessage(AppLocalizations.of(context).t('doctorProfileUpdated'));
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        AppLocalizations.of(context).t('couldNotUpdateDoctorProfile'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeDoctorPhoto(ClinicModel clinic) async {
    if (_isUploadingPhoto) return;

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 92,
    );
    if (picked == null || !mounted) return;

    final originalBytes = await picked.readAsBytes();
    if (!mounted) return;
    final bytes = await showPhotoCropDialog(
      context,
      bytes: originalBytes,
      aspectRatio: 1,
      title: AppLocalizations.of(context).t('cropDoctorPhoto'),
    );
    if (bytes == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final url = await _photoService.uploadDoctorPhoto(
        clinicId: clinic.clinicId,
        bytes: bytes,
        fileName: '${picked.name}.png',
      );
      await _clinicRepository.updateClinic(clinic.clinicId, {
        'doctorPhotoUrl': url,
      });
      if (!mounted) return;
      setState(() {
        _clinic = clinic.copyWith(doctorPhotoUrl: url);
      });
      _showMessage(AppLocalizations.of(context).t('doctorPhotoUpdated'));
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _showMessage(failure.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage(AppLocalizations.of(context).t('couldNotUpdateDoctorPhoto'));
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _changeClinicPhoto(ClinicModel clinic) async {
    if (_isUploadingClinicPhoto) return;

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2600,
      maxHeight: 2600,
      imageQuality: 92,
    );
    if (picked == null || !mounted) return;

    final originalBytes = await picked.readAsBytes();
    if (!mounted) return;
    final bytes = await showPhotoCropDialog(
      context,
      bytes: originalBytes,
      aspectRatio: 16 / 9,
      title: AppLocalizations.of(context).t('cropClinicPhoto'),
    );
    if (bytes == null || !mounted) return;

    setState(() => _isUploadingClinicPhoto = true);
    try {
      final url = await _photoService.uploadClinicPhoto(
        clinicId: clinic.clinicId,
        bytes: bytes,
        fileName: '${picked.name}.png',
      );
      await _clinicRepository.updateClinic(clinic.clinicId, {
        'clinicPhotoUrl': url,
      });
      if (!mounted) return;
      setState(() {
        _clinic = clinic.copyWith(clinicPhotoUrl: url);
      });
      _showMessage(AppLocalizations.of(context).t('clinicPhotoUpdated'));
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _showMessage(failure.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage(AppLocalizations.of(context).t('couldNotUpdateClinicPhoto'));
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
    AppSnackBar.showAuto(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return _buildShell(
        title: l10n.t('clinicAdminTitle'),
        subtitle: l10n.t('easycheckAdmin'),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return _buildShell(
        title: l10n.t('clinicAdminTitle'),
        subtitle: l10n.t('easycheckAdmin'),
        child: _buildErrorState(),
      );
    }

    if (_clinic == null) {
      return _buildShell(
        title: l10n.t('clinicAdminTitle'),
        subtitle: l10n.t('easycheckAdmin'),
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
    final l10n = AppLocalizations.of(context);

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
                  const LanguageToggle(compact: true),
                  const SizedBox(width: AppSpacing.spaceXs),
                  Tooltip(
                    message: l10n.t('signedInAccountLabel'),
                    child: Container(
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
    final l10n = AppLocalizations.of(context);
    final items = [
      (Icons.format_list_bulleted_rounded, l10n.t('liveQueueTab')),
      (Icons.how_to_reg_rounded, l10n.t('intakeTab')),
      (Icons.medical_services_rounded, l10n.t('staffTab')),
      (Icons.manage_accounts_rounded, l10n.t('clinicTab')),
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
    final l10n = AppLocalizations.of(context);
    return _buildPage(
      title: clinic.name,
      subtitle: '${l10n.t('doctorConsole')} • EASYCHECK',
      children: [
        _buildClinicHeaderCard(clinic),
        const SizedBox(height: AppSpacing.spaceMd),
        _buildDoctorAvailabilityCard(clinic),
        const SizedBox(height: AppSpacing.spaceMd),
        _buildCounterCard(clinic),
      ],
    );
  }

  String _doctorGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    final part = l10n.greetingForHour(hour);
    final name = _clinic?.doctorName.trim() ?? '';
    return name.isEmpty ? '$part, Doctor' : '$part, $name';
  }

  Widget _buildClinicHeaderCard(ClinicModel clinic) {
    final l10n = AppLocalizations.of(context);
    final status = _isActive
        ? l10n.t('liveQueueStatus')
        : l10n.t('queuePausedStatus');
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
                  Text(
                    l10n.t('doctorConsole'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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
                _doctorGreeting(l10n),
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
                        ? l10n.t('setDoctorTiming')
                        : clinic.doctorTiming,
                    onTap: _busy ? null : () => _editDoctorTiming(clinic),
                  ),
                  _buildHeroChip(
                    icon: Icons.confirmation_number_outlined,
                    label: l10n
                        .t('todaysParchiChip')
                        .replaceAll('{count}', '$_count'),
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
    final l10n = AppLocalizations.of(context);
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
                  l10n.t('doctorAvailability'),
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
                tooltip: l10n.t('editDoctorProfile'),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 17),
              ),
              _buildAvailabilityPill(status, l10n),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Text(
            clinic.doctorName.isNotEmpty
                ? (clinic.doctorCredentials.isEmpty
                      ? clinic.doctorName
                      : '${clinic.doctorName}, ${clinic.doctorCredentials}')
                : l10n.t('doctorNotAssigned'),
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
                : l10n.t('updateSpecialty'),
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
                            l10n.t('doctorTiming'),
                            style: AppTypography.labelSm.copyWith(
                              color: AdminColors.onSurfaceVariant,
                              fontSize: 9.5,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            clinic.doctorTiming.trim().isEmpty
                                ? l10n.t('addClinicHours')
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
                label: l10n.t('statusAvailable'),
                icon: Icons.check_circle_outline_rounded,
                selected: status == 'available',
                color: AdminColors.primary,
                onTap: () => _setDoctorStatus('available'),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              _buildStatusButton(
                label: l10n.t('statusDelayed'),
                icon: Icons.schedule_rounded,
                selected: status == 'delayed',
                color: const Color(0xFFD97706),
                onTap: () => _setDoctorStatus('delayed'),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              _buildStatusButton(
                label: l10n.t('statusOffDuty'),
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

  Widget _buildAvailabilityPill(String status, AppLocalizations l10n) {
    final (label, background, foreground) = switch (status) {
      'delayed' => (
        l10n.t('statusDelayed'),
        const Color(0xFFFEF3C7),
        const Color(0xFFB45309),
      ),
      'offDuty' => (
        l10n.t('statusOffDuty'),
        AdminColors.surfaceContainerHigh,
        AdminColors.onSurfaceVariant,
      ),
      _ => (
        l10n.t('online'),
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
    final l10n = AppLocalizations.of(context);
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
                      l10n.t('todaysParchiCount'),
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
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.92,
                                end: 1,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          '$_count',
                          key: ValueKey<int>(_count),
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
              onPressed: _busy || _counterSyncing || _pendingCounterDelta != 0
                  ? null
                  : _confirmReset,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: Text(l10n.t('resetCountToZero')),
              style: TextButton.styleFrom(
                foregroundColor: AdminColors.error,
                textStyle: AppTypography.labelMd.copyWith(
                  color: AdminColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSm),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spaceMd,
              10,
              AppSpacing.spaceSm,
              10,
            ),
            decoration: BoxDecoration(
              color: AdminColors.surfaceContainerLow,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: AdminColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('yesterdayParchi'),
                        style: AppTypography.labelSm.copyWith(
                          color: AdminColors.onSurfaceVariant,
                          fontSize: 9.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${clinic.yesterdayParchiCount} ${l10n.t('slips')} · '
                        '${DateFormat('MMM d').format(_now.subtract(const Duration(days: 1)))}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMd.copyWith(
                          color: AdminColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : () => _editYesterdayCount(clinic),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(l10n.t('edit')),
                  style: TextButton.styleFrom(
                    foregroundColor: AdminColors.primary,
                    textStyle: AppTypography.labelMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionPill() {
    final l10n = AppLocalizations.of(context);
    final status = _session?.status ?? 'active';
    final (label, color) = switch (status) {
      'paused' => (l10n.t('paused'), const Color(0xFFD97706)),
      'closed' => (l10n.t('offline'), AdminColors.onSurfaceVariant),
      _ => (l10n.t('live'), AdminColors.primary),
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
    final l10n = AppLocalizations.of(context);
    return _buildPage(
      title: l10n.t('intakeHistoryTitle'),
      subtitle: '${l10n.t('doctorConsole')} • EASYCHECK',
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
                title: l10n.t('historyUnavailable'),
                body: l10n.t('couldNotLoadHistory'),
              );
            }
            final entries = snapshot.data ?? const <QueueHistoryEntry>[];
            if (entries.isEmpty) {
              return _buildInfoCard(
                icon: Icons.history_rounded,
                title: l10n.t('noCounterActivity'),
                body: l10n.t('noCounterActivityBody'),
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
    final l10n = AppLocalizations.of(context);
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
                  '${_actionLabel(entry.action, l10n)} · '
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
                  l10n
                      .t('byUser')
                      .replaceAll('{user}', _shortUid(entry.performedBy)),
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

  String _actionLabel(String action, AppLocalizations l10n) => switch (action) {
    'reset' => l10n.t('resetAction'),
    'correction' => l10n.t('correctionAction'),
    _ => l10n.t('incrementAction'),
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
    final l10n = AppLocalizations.of(context);
    return _buildPage(
      title: l10n.t('staffManagementTitle'),
      subtitle: '${l10n.t('doctorConsole')} • EASYCHECK',
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
                title: l10n.t('staffListUnavailable'),
                body: l10n.t('couldNotLoadMembers'),
              );
            }
            final members = snapshot.data ?? const <ClinicMembershipModel>[];
            if (members.isEmpty) {
              return _buildInfoCard(
                icon: Icons.group_add_outlined,
                title: l10n.t('noStaffAssigned'),
                body: l10n
                    .t('noTeamMembersBody')
                    .replaceAll('{clinic}', clinic.name),
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
    final l10n = AppLocalizations.of(context);
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
                  _roleLabel(member.role, l10n),
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
                      ? l10n.t('noPermissionsAssigned')
                      : member.permissions
                            .map(
                              (permission) =>
                                  _permissionLabel(permission, l10n),
                            )
                            .join(' · '),
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
            label: active ? l10n.t('active') : l10n.t('inactive'),
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

  String _roleLabel(String role, AppLocalizations l10n) => switch (role) {
    'clinic_admin' => l10n.t('roleClinicAdmin'),
    'front_desk_lead' => l10n.t('roleFrontDeskLead'),
    'triage_coordinator' => l10n.t('roleTriageCoordinator'),
    _ => role.isEmpty ? l10n.t('staffMember') : role,
  };

  String _permissionLabel(String permission, AppLocalizations l10n) =>
      switch (permission) {
        'update_tally' => l10n.t('permissionCounter'),
        'update_status' => l10n.t('permissionStatus'),
        'reset_tally' => l10n.t('reset'),
        'manage_staff' => l10n.t('staffTab'),
        'view_queue' => l10n.t('permissionQueue'),
        _ => permission,
      };

  // ───────────────────────────────────────────────────────────────────────────
  // Clinic tab
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildClinicTab() {
    final clinic = _clinic!;
    final user = _user;
    final membership = _membership;
    final l10n = AppLocalizations.of(context);
    return _buildPage(
      title: l10n.t('clinicProfileTitle'),
      subtitle: '${l10n.t('doctorConsole')} • EASYCHECK',
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
                '${l10n.t('clinicIdLabel')} · ${clinic.clinicId}',
                style: AppTypography.labelSm.copyWith(
                  color: AdminColors.onSurfaceVariant,
                ),
              ),
              const Divider(height: AppSpacing.spaceXl),
              _buildInfoRow(
                Icons.location_on_outlined,
                l10n.t('addressLabel'),
                clinic.address.isEmpty
                    ? l10n.t('notListed')
                    : '${clinic.address}${clinic.city.isEmpty ? '' : ', ${clinic.city}'}',
              ),
              _buildInfoRow(
                Icons.call_outlined,
                l10n.t('phoneLabel'),
                clinic.phone.isEmpty ? l10n.t('notListed') : clinic.phone,
              ),
              _buildInfoRow(
                Icons.mail_outline_rounded,
                l10n.t('emailLabel'),
                clinic.email.isEmpty ? l10n.t('notListed') : clinic.email,
              ),
              _buildInfoRow(
                Icons.badge_outlined,
                l10n.t('yourRoleLabel'),
                membership == null
                    ? l10n.t('roleClinicAdmin')
                    : _roleLabel(membership.role, l10n),
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
                l10n.t('signedInAccountLabel'),
                style: AppTypography.labelSm.copyWith(
                  color: AdminColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.displayName?.trim().isNotEmpty == true
                    ? user!.displayName!
                    : l10n.t('roleClinicAdmin'),
                style: AppTypography.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AdminColors.onSurface,
                ),
              ),
              Text(
                user?.email ?? l10n.t('notAvailable'),
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
                  label: Text(l10n.t('signOut')),
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
            l10n.t('versionLabel'),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.cloud_off_rounded,
          title: l10n.t('couldNotOpenDashboard'),
          body: _error ?? l10n.t('checkConnection'),
        ),
        const SizedBox(height: AppSpacing.spaceLg),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _loadClinic,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.t('retry')),
          ),
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        TextButton(onPressed: _signOut, child: Text(l10n.t('signOut'))),
      ],
    );
  }

  Widget _buildUnassignedState() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.admin_panel_settings_outlined,
          title: l10n.t('unassignedTitle'),
          body: l10n.t('unassignedBody'),
        ),
        const SizedBox(height: AppSpacing.spaceLg),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () =>
                Navigator.of(context)
                    .pushReplacementNamed(AppRoutes.adminAccessRequest),
            icon: const Icon(Icons.add_business_rounded, size: 18),
            label: Text(l10n.t('requestClinicAccess')),
          ),
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loadClinic,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.t('checkAgain')),
          ),
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        TextButton(onPressed: _signOut, child: Text(l10n.t('signOut'))),
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
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.t('editDoctorProfile')),
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
                decoration: InputDecoration(
                  labelText: l10n.t('doctorNameLabel'),
                  hintText: l10n.t('doctorNameHint'),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.t('doctorNameRequired');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _credentialsController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
                decoration: InputDecoration(
                  labelText: l10n.t('credentialsLabel'),
                  hintText: l10n.t('credentialsHint'),
                  prefixIcon: const Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _specialtyController,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
                decoration: InputDecoration(
                  labelText: l10n.t('specialtyLabel'),
                  hintText: l10n.t('specialtyHint'),
                  prefixIcon: const Icon(Icons.medical_services_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.t('patientVisibilityNote'),
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
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.t('saveProfile'))),
      ],
    );
  }
}
