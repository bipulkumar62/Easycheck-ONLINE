import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/live_dot.dart';
import '../../core/widgets/status_pill.dart';
import '../authentication/google_auth_service.dart';
import '../authentication/user_profile_model.dart';
import '../authentication/user_profile_repository.dart';
import '../clinics/clinic_model.dart';
import '../legal/about_screen.dart';
import '../legal/legal_screen.dart';
import '../clinics/clinic_repository.dart';
import '../clinics/queue_repository.dart';
import '../clinics/queue_session_model.dart';

/// Patient Home — "Clinical Clarity" design system.
/// Live clinic discovery backed by Firestore with a responsive, single-query
/// parchi counter feed.
class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  static const double _contentMaxWidth = 720.0;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _homeScrollController = ScrollController();
  final GlobalKey _clinicListKey = GlobalKey();
  final ValueNotifier<int> _notificationRevision = ValueNotifier<int>(0);
  final List<_PatientNotification> _notifications = <_PatientNotification>[];
  final ClinicRepository _clinicRepository = ClinicRepository();
  final QueueRepository _queueRepository = QueueRepository();
  final UserProfileRepository _profileRepository = UserProfileRepository();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  StreamSubscription<List<ClinicModel>>? _clinicsSubscription;
  StreamSubscription<List<QueueSessionModel>>? _sessionsSubscription;

  List<ClinicModel> _clinics = const [];
  Map<String, int> _liveCounts = const {};
  Map<String, ClinicModel> _lastClinicState = const {};
  Map<String, int> _lastCounts = const {};
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isDeletingAccount = false;
  bool _notificationBaselineReady = false;
  bool _countBaselineReady = false;
  bool _clinicBaselineEstablished = false;
  bool _countBaselineEstablished = false;
  int _unreadNotificationCount = 0;
  String? _error;
  int _navIndex = 0;

  DateTime get _today => DateTime.now();

  String get _todayKey {
    final now = _today;
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  User? get _currentUser {
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
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _homeScrollController.dispose();
    _notificationRevision.dispose();
    _clinicsSubscription?.cancel();
    _sessionsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _clinicsSubscription?.cancel();
    await _sessionsSubscription?.cancel();

    _clinicsSubscription = _clinicRepository.clinicsStream().listen(
      (clinics) {
        if (!mounted) return;
        _processClinicSnapshot(clinics);
        setState(() {
          _clinics = clinics;
          _isLoading = false;
          _error = null;
        });
      },
      onError: (Object error) {
        // Keep backend details out of the UI. The raw error is only useful in
        // debug logs and must never expose Firestore internals to patients.
        debugPrint('Clinic discovery failed: $error');
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Check your connection and try again.';
        });
      },
    );

    _sessionsSubscription = _queueRepository
        .sessionsForDateStream(_todayKey)
        .listen(
          (sessions) {
            if (!mounted) return;
            final counts = {
              for (final session in sessions)
                session.clinicId: session.currentParchaNumber,
            };
            _processCountSnapshot(counts);
            setState(() {
              _liveCounts = counts;
            });
          },
          onError: (_) {
            // A failed counter feed must never block clinic discovery.
          },
        );
  }

  void _processClinicSnapshot(List<ClinicModel> clinics) {
    final l10n = AppLocalizations.of(context);
    final previous = _lastClinicState;
    final next = <String, ClinicModel>{
      for (final clinic in clinics) clinic.clinicId: clinic,
    };

    if (!_notificationBaselineReady) {
      _lastClinicState = next;
      _notificationBaselineReady = true;
      _clinicBaselineEstablished = next.isNotEmpty;
      return;
    }

    // The first Firestore emission can be an empty cache snapshot before the
    // server data arrives. Treat the first real list as the baseline instead
    // of flooding the bell with every existing clinic.
    if (!_clinicBaselineEstablished) {
      _lastClinicState = next;
      _clinicBaselineEstablished = next.isNotEmpty;
      return;
    }

    for (final clinic in clinics) {
      final old = previous[clinic.clinicId];
      if (old == null) {
        if (clinic.isActive) {
          _addNotification(
            title: l10n.t('newClinicAvailable'),
            message: l10n.newClinicMessage(clinic.name),
            icon: Icons.local_hospital_rounded,
            clinicId: clinic.clinicId,
          );
        }
        continue;
      }

      if (!old.isActive && clinic.isActive) {
        _addNotification(
          title: l10n.t('clinicAvailableAgain'),
          message: l10n.clinicAvailableAgainMessage(clinic.name),
          icon: Icons.local_hospital_rounded,
          clinicId: clinic.clinicId,
        );
      } else if (old.isActive && !clinic.isActive) {
        _addNotification(
          title: l10n.t('clinicTemporarilyUnavailable'),
          message: l10n.clinicUnavailableMessage(clinic.name),
          icon: Icons.info_outline_rounded,
          clinicId: clinic.clinicId,
        );
      } else if (old.isOnline != clinic.isOnline) {
        _addNotification(
          title: clinic.isOnline
              ? l10n.t('clinicIsLive')
              : l10n.t('clinicWentOffline'),
          message: clinic.isOnline
              ? l10n.clinicLiveMessage(clinic.name)
              : l10n.clinicOfflineMessage(clinic.name),
          icon: clinic.isOnline
              ? Icons.campaign_rounded
              : Icons.pause_circle_outline_rounded,
          clinicId: clinic.clinicId,
        );
      } else if (old.doctorStatus != clinic.doctorStatus) {
        final (title, message, icon) = switch (clinic.doctorStatus) {
          'delayed' => (
            l10n.t('doctorRunningLate'),
            l10n.doctorLateMessage(clinic.name),
            Icons.schedule_rounded,
          ),
          'offDuty' => (
            l10n.t('doctorOffDuty'),
            l10n.doctorOffDutyMessage(clinic.name),
            Icons.event_busy_rounded,
          ),
          _ => (
            l10n.t('doctorAvailable'),
            l10n.doctorAvailableMessage(clinic.name),
            Icons.check_circle_outline_rounded,
          ),
        };
        _addNotification(
          title: title,
          message: message,
          icon: icon,
          clinicId: clinic.clinicId,
        );
      }
    }

    _lastClinicState = next;
  }

  void _processCountSnapshot(Map<String, int> counts) {
    final l10n = AppLocalizations.of(context);
    if (!_countBaselineReady) {
      _lastCounts = counts;
      _countBaselineReady = true;
      _countBaselineEstablished = counts.isNotEmpty;
      return;
    }

    // Same cache-vs-server rule as clinics: the first non-empty counter feed
    // becomes the baseline so existing parchi numbers do not all alert at once.
    if (!_countBaselineEstablished) {
      _lastCounts = counts;
      _countBaselineEstablished = counts.isNotEmpty;
      return;
    }

    for (final entry in counts.entries) {
      final previous = _lastCounts[entry.key];
      final current = entry.value;
      if (current <= (previous ?? 0)) continue;
      final clinic = _clinicById(entry.key);
      if (clinic == null || !clinic.isActive) continue;
      _addNotification(
        title: l10n.parchiIssuedTitle(current),
        message: l10n.parchiIssuedMessage(clinic.name, current),
        icon: Icons.confirmation_number_rounded,
        clinicId: entry.key,
      );
    }

    _lastCounts = counts;
  }

  void _addNotification({
    required String title,
    required String message,
    required IconData icon,
    String? clinicId,
  }) {
    final now = DateTime.now();
    _notifications.insert(
      0,
      _PatientNotification(
        title: title,
        message: message,
        icon: icon,
        clinicId: clinicId,
        createdAt: now,
      ),
    );
    if (_notifications.length > 30) {
      _notifications.removeRange(30, _notifications.length);
    }
    _unreadNotificationCount = _notifications
        .where((notification) => !notification.isRead)
        .length;
    _notificationRevision.value++;
  }

  ClinicModel? _clinicById(String clinicId) {
    for (final clinic in _clinics) {
      if (clinic.clinicId == clinicId) return clinic;
    }
    return null;
  }

  void _browseClinics() {
    _searchController.clear();
    setState(() => _navIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _clinicListKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.05,
        );
        return;
      }
      // The section title can be unbuilt if Home was scrolled far down, so
      // fall back to the top where the search and clinic list begin.
      if (_homeScrollController.hasClients) {
        _homeScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  String _relativeTime(DateTime time) {
    final l10n = AppLocalizations.of(context);
    final difference = DateTime.now().difference(time);
    if (difference.inSeconds < 45) return l10n.t('justNow');
    if (difference.inMinutes < 60) return l10n.minutesAgo(difference.inMinutes);
    if (difference.inHours < 24) return l10n.hoursAgo(difference.inHours);
    if (difference.inDays == 1) return l10n.t('yesterdayLabel');
    return l10n.daysAgo(difference.inDays);
  }

  List<ClinicModel> get _filtered {
    if (_searchQuery.isEmpty) return _clinics;
    final query = _searchQuery.toLowerCase();
    return _clinics
        .where((clinic) {
          return clinic.name.toLowerCase().contains(query) ||
              clinic.address.toLowerCase().contains(query) ||
              clinic.city.toLowerCase().contains(query) ||
              clinic.doctorName.toLowerCase().contains(query) ||
              clinic.doctorSpecialty.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  int _parchiCount(ClinicModel clinic) =>
      _liveCounts[clinic.clinicId] ?? clinic.todayParchiCount;

  void _openClinic(ClinicModel clinic) {
    Navigator.of(context)
        .pushNamed(AppRoutes.patientClinicDetails, arguments: clinic);
  }

  Future<void> _signOut() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // UI-only mode: still return to the login screen.
    }
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.initial, (route) => false);
  }

  Future<void> _deleteAccount() async {
    if (_isDeletingAccount) return;
    final user = _currentUser;
    if (user == null) {
      _showMessage('Please sign in again before deleting your account.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).t('deleteAccountQuestion')),
        content: Text(AppLocalizations.of(context).t('deleteAccountBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(context).t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: PatientColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppLocalizations.of(context).t('deleteAccountConfirm')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    UserProfile? profile;
    try {
      profile = await _profileRepository.getProfile(user.uid);
    } catch (_) {
      profile = null;
    }

    // Re-authenticate before deleting anything. If Google confirmation fails,
    // the profile must remain intact so the account is never half-deleted.
    try {
      await _googleAuthService.reauthenticate();
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'Google sign-in could not be confirmed. Your account was not deleted.',
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isDeletingAccount = true);

    var profileDeleted = false;
    try {
      if (profile != null) {
        await _profileRepository.deleteProfile(user.uid);
        profileDeleted = true;
      }
      await user.delete();
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.initial, (route) => false);
    } on FirebaseAuthException catch (e) {
      if (profileDeleted && profile != null) {
        // Restore the profile if sign-in deletion still fails, so the user is
        // not left signed in without a profile.
        try {
          await _profileRepository.createProfile(profile);
        } catch (_) {
          // The next sign-in recreates the patient profile if needed.
        }
      }
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      _showMessage(
        e.code == 'requires-recent-login'
            ? 'For your security, sign out, sign in again, then delete your '
                  'account.'
            : 'Your account could not be deleted. Please try again.',
      );
    } catch (_) {
      if (profileDeleted && profile != null) {
        try {
          await _profileRepository.createProfile(profile);
        } catch (_) {
          // The next sign-in recreates the patient profile if needed.
        }
      }
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      _showMessage(
        'Your account could not be deleted. Check your connection and try '
        'again.',
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    AppSnackBar.showAuto(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientColors.surface,
      body: IndexedStack(
        index: _navIndex,
        children: [_buildHomeTab(), _buildMyClinicsTab(), _buildSettingsTab()],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Home
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildHomeTab() {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadData,
          color: PatientColors.primary,
          child: CustomScrollView(
            controller: _homeScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topInset + 64.0)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _centered(_buildLocationRow()),
                    const SizedBox(height: AppSpacing.spaceMd),
                    _centered(_buildWelcomeCard()),
                    const SizedBox(height: AppSpacing.spaceMd),
                    _centered(_buildSearchBar()),
                    const SizedBox(height: AppSpacing.spaceLg),
                    KeyedSubtree(
                      key: _clinicListKey,
                      child: _centered(_buildSectionTitle()),
                    ),
                    const SizedBox(height: AppSpacing.spaceMd),
                    if (_isLoading)
                      _centered(_buildLoadingState())
                    else if (_error != null)
                      _centered(_buildErrorState())
                    else if (_filtered.isEmpty)
                      _centered(_buildEmptyState()),
                  ]),
                ),
              ),
              if (!_isLoading && _error == null && _filtered.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  sliver: SliverList.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final clinic = _filtered[index];
                      return _centered(
                        _ClinicCard(
                          clinic: clinic,
                          parchiCount: _parchiCount(clinic),
                          onTap: () => _openClinic(clinic),
                        ),
                      );
                    },
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: bottomInset + 24.0)),
            ],
          ),
        ),
        _buildTopAppBar(topInset),
      ],
    );
  }

  Widget _centered(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: child,
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final l10n = AppLocalizations.of(context);
    final user = _currentUser;
    final rawName = user?.displayName?.trim() ?? '';
    final firstName = rawName.isEmpty
        ? ''
        : rawName.split(RegExp(r'\s+')).first;
    final greeting = l10n.greetingForHour(DateTime.now().hour);
    final title = firstName.isEmpty ? greeting : '$greeting, $firstName';
    final quote = l10n.quoteOfDay(DateTime.now().day);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF041A33), Color(0xFF073B78), Color(0xFF0A4A8A)],
          stops: [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: PatientColors.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -20,
              child: IgnorePointer(
                child: Icon(
                  Icons.format_quote_rounded,
                  size: 150,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -36,
              right: 34,
              child: IgnorePointer(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PatientColors.secondaryContainer.withValues(
                      alpha: 0.10,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PatientColors.secondaryContainer.withValues(
                        alpha: 0.16,
                      ),
                      borderRadius: AppSpacing.roundedFull,
                      border: Border.all(
                        color: PatientColors.secondaryContainer.withValues(
                          alpha: 0.28,
                        ),
                      ),
                    ),
                    child: Text(
                      l10n.t('thoughtForToday').toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: Color(0xFFB9F8D7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quote,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.94),
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

  Widget _buildTopAppBar(double topInset) {
    final l10n = AppLocalizations.of(context);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 64.0 + topInset,
        padding: EdgeInsets.only(top: topInset),
        decoration: BoxDecoration(
          color: PatientColors.surface.withValues(alpha: 0.92),
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
                  const BrandMark(size: 36, padding: 4, radius: 10),
                  const SizedBox(width: AppSpacing.spaceSm),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EASYCHECK',
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: PatientColors.secondary,
                              letterSpacing: 0.9,
                            ),
                          ),
                          Text(
                            l10n.t('navHome'),
                            maxLines: 1,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: PatientColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const LanguageToggle(compact: true),
                  const SizedBox(width: 2),
                  _buildNotificationButton(),
                  const SizedBox(width: AppSpacing.spaceXs),
                  _buildAvatarButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    final l10n = AppLocalizations.of(context);
    final unread = _unreadNotificationCount;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: unread == 0
              ? l10n.t('notifications')
              : l10n.unreadNotifications(unread),
          onPressed: _showNotificationsSheet,
          icon: const Icon(
            Icons.notifications_outlined,
            size: 22,
            color: PatientColors.onSurface,
          ),
        ),
        if (unread > 0)
          Positioned(
            top: 3,
            right: 3,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: PatientColors.error,
                  borderRadius: AppSpacing.roundedFull,
                  border: Border.all(color: PatientColors.surface, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      height: 1.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarButton() {
    final user = _currentUser;
    final photoUrl = user?.photoURL;
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).t('openProfileSettings'),
      child: InkWell(
        borderRadius: AppSpacing.roundedFull,
        onTap: () => setState(() => _navIndex = 2),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: PatientColors.primary,
            shape: BoxShape.circle,
            image: photoUrl != null && photoUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(photoUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: photoUrl == null || photoUrl.isEmpty
              ? const Icon(Icons.person_rounded, color: Colors.white, size: 20)
              : null,
        ),
      ),
    );
  }

  Widget _buildLocationRow() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: AppSpacing.spaceSm,
        runSpacing: AppSpacing.spaceSm,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: PatientColors.surfaceContainerLow,
              borderRadius: AppSpacing.roundedFull,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: PatientColors.primary,
                ),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    AppConstants.defaultCity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: PatientColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: PatientColors.outline,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: PatientColors.surfaceContainerLowest,
              borderRadius: AppSpacing.roundedFull,
              boxShadow: AppSpacing.elevationLevel1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LiveDot(
                  size: 6,
                  color: PatientColors.secondary,
                  semanticsLabel: 'Live queue',
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    l10n.t('liveQueue'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: PatientColors.secondary,
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

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      style: AppTypography.bodyMd.copyWith(color: PatientColors.onSurface),
      decoration: InputDecoration(
        hintText: l10n.t('searchPlaceholder'),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 21,
          color: PatientColors.outline,
        ),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: l10n.t('clearSearch'),
                icon: const Icon(Icons.close_rounded, size: 19),
                onPressed: () => _searchController.clear(),
              ),
        filled: true,
        fillColor: PatientColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(
            color: PatientColors.secondary.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    final l10n = AppLocalizations.of(context);
    final showLiveSync = MediaQuery.sizeOf(context).width >= 390;
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  l10n.t('registeredClinics'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headlineSm.copyWith(
                    color: PatientColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: const BoxDecoration(
                  color: PatientColors.surfaceContainer,
                  borderRadius: AppSpacing.roundedFull,
                ),
                child: Text(
                  l10n.activeCount(_filtered.length),
                  maxLines: 1,
                  style: AppTypography.labelSm.copyWith(
                    color: PatientColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showLiveSync) ...[
          const SizedBox(width: AppSpacing.spaceSm),
          Text(
            l10n.t('liveSync'),
            maxLines: 1,
            style: AppTypography.labelSm.copyWith(
              color: PatientColors.outline,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: PatientColors.error,
            size: 44,
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Text(l10n.t('couldNotLoadClinics'), style: AppTypography.titleMd),
          const SizedBox(height: AppSpacing.spaceXs),
          Text(
            _error ?? l10n.t('checkConnection'),
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              color: PatientColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceLg),
          FilledButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.t('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    final hasSearch = _searchQuery.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            hasSearch
                ? Icons.search_off_rounded
                : Icons.local_hospital_outlined,
            color: PatientColors.outline,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Text(
            hasSearch ? l10n.t('noClinicsMatch') : l10n.t('noClinicsAvailable'),
            textAlign: TextAlign.center,
            style: AppTypography.titleMd,
          ),
          const SizedBox(height: AppSpacing.spaceXs),
          Text(
            hasSearch ? l10n.t('tryDifferentSearch') : l10n.t('pullToRefresh'),
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              color: PatientColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // My Clinics
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildMyClinicsTab() {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        children: [
          _buildSimpleHeader(
            l10n.t('navMyClinics'),
            Icons.local_hospital_rounded,
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.spaceXl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: PatientColors.surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bookmark_add_outlined,
                          size: 32,
                          color: PatientColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spaceLg),
                      Text(
                        l10n.t('noSavedClinics'),
                        style: AppTypography.headlineSm,
                      ),
                      const SizedBox(height: AppSpacing.spaceSm),
                      Text(
                        l10n.t('noSavedClinicsBody'),
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMd.copyWith(
                          color: PatientColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spaceXl),
                      FilledButton.icon(
                        onPressed: _browseClinics,
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: Text(l10n.t('browseClinics')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Settings
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildSettingsTab() {
    final l10n = AppLocalizations.of(context);
    final user = _currentUser;
    return SafeArea(
      child: Column(
        children: [
          _buildSimpleHeader(l10n.t('navSettings'), Icons.settings_rounded),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _contentMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.spaceLg),
                          decoration: BoxDecoration(
                            color: PatientColors.surfaceContainerLowest,
                            borderRadius: AppSpacing.roundedLg,
                            boxShadow: AppSpacing.elevationLevel1,
                          ),
                          child: Row(
                            children: [
                              _buildAvatarButton(),
                              const SizedBox(width: AppSpacing.spaceMd),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.displayName?.trim().isNotEmpty ==
                                              true
                                          ? user!.displayName!
                                          : l10n.t('patientAccount'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.titleMd,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user?.email ?? l10n.t('notSignedIn'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySm.copyWith(
                                        color: PatientColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spaceLg),
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                          decoration: BoxDecoration(
                            color: PatientColors.surfaceContainerLowest,
                            borderRadius: AppSpacing.roundedMd,
                            boxShadow: AppSpacing.elevationLevel1,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: PatientColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.translate_rounded,
                                  color: PatientColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.spaceMd),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.t('languageSection'),
                                      style: AppTypography.bodyMd.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.t('languageDescription'),
                                      style: AppTypography.labelSm,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const LanguageToggle(compact: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spaceSm),
                        _buildSettingsTile(
                          icon: Icons.shield_outlined,
                          title: l10n.t('privacyPolicy'),
                          onTap: () => _openLegal(LegalDocument.privacy),
                        ),
                        _buildSettingsTile(
                          icon: Icons.description_outlined,
                          title: l10n.t('termsOfUse'),
                          onTap: () => _openLegal(LegalDocument.terms),
                        ),
                        _buildSettingsTile(
                          icon: Icons.info_outline_rounded,
                          title: l10n.t('aboutEasyCheck'),
                          subtitle: l10n.t('aboutEasyCheckSubtitle'),
                          onTap: _openAbout,
                        ),
                        _buildSettingsTile(
                          icon: Icons.delete_forever_outlined,
                          title: _isDeletingAccount
                              ? l10n.t('deletingAccount')
                              : l10n.t('deleteAccount'),
                          subtitle: l10n.t('deleteAccountSubtitle'),
                          iconColor: PatientColors.error,
                          trailing: _isDeletingAccount
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: PatientColors.error,
                                  ),
                                )
                              : const Icon(
                                  Icons.chevron_right_rounded,
                                  color: PatientColors.outline,
                                ),
                          onTap: _deleteAccount,
                        ),
                        const SizedBox(height: AppSpacing.spaceLg),
                        if (user != null)
                          OutlinedButton.icon(
                            onPressed: _signOut,
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: Text(l10n.t('signOut')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: PatientColors.error,
                              side: BorderSide(
                                color: PatientColors.error.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildSimpleHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.spaceMd,
        AppSpacing.gutter,
        AppSpacing.spaceSm,
      ),
      child: Row(
        children: [
          Icon(icon, color: PatientColors.primary, size: 22),
          const SizedBox(width: AppSpacing.spaceSm),
          Text(title, style: AppTypography.headlineSm),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceSm),
      child: Material(
        color: PatientColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        elevation: 1,
        shadowColor: PatientColors.primary.withValues(alpha: 0.10),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
          leading: Icon(
            icon,
            color: iconColor ?? PatientColors.primary,
            size: 21,
          ),
          title: Text(
            title,
            style: iconColor == null
                ? AppTypography.bodyMd
                : AppTypography.bodyMd.copyWith(color: iconColor),
          ),
          subtitle: subtitle == null
              ? null
              : Text(subtitle, style: AppTypography.labelSm),
          trailing:
              trailing ??
              const Icon(
                Icons.chevron_right_rounded,
                color: PatientColors.outline,
              ),
          onTap: onTap,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Bottom navigation
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final items = [
      (Icons.home_rounded, l10n.t('navHome')),
      (Icons.local_hospital_rounded, l10n.t('navMyClinics')),
      (Icons.settings_rounded, l10n.t('navSettings')),
    ];

    return Container(
      height: 64.0 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: PatientColors.surface.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: PatientColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final selected = _navIndex == index;
          return Expanded(
            child: Semantics(
              selected: selected,
              button: true,
              label: items[index].$2,
              child: InkWell(
                onTap: () => setState(() => _navIndex = index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? PatientColors.secondaryContainer.withValues(
                                alpha: 0.55,
                              )
                            : Colors.transparent,
                        borderRadius: AppSpacing.roundedFull,
                      ),
                      child: Icon(
                        items[index].$1,
                        size: 23,
                        color: selected
                            ? PatientColors.onSecondaryContainer
                            : PatientColors.onSurfaceVariant,
                      ),
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
                            ? PatientColors.onSecondaryContainer
                            : PatientColors.onSurfaceVariant,
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
  // Sheets
  // ───────────────────────────────────────────────────────────────────────────

  void _showNotificationsSheet() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: PatientColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
            ),
            child: ValueListenableBuilder<int>(
              valueListenable: _notificationRevision,
              builder: (context, _, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.spaceXl,
                        0,
                        AppSpacing.spaceXl,
                        AppSpacing.spaceSm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.t('notifications'),
                              style: AppTypography.headlineSm.copyWith(
                                color: PatientColors.primary,
                              ),
                            ),
                          ),
                          if (_unreadNotificationCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: const BoxDecoration(
                                color: PatientColors.secondaryContainer,
                                borderRadius: AppSpacing.roundedFull,
                              ),
                              child: Text(
                                l10n.unreadNotifications(
                                  _unreadNotificationCount,
                                ),
                                style: AppTypography.labelSm.copyWith(
                                  color: PatientColors.onSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_notifications.isEmpty)
                      _buildNotificationsEmptyState(sheetContext)
                    else
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.spaceMd,
                            0,
                            AppSpacing.spaceMd,
                            AppSpacing.spaceLg,
                          ),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) =>
                              _buildNotificationTile(
                                sheetContext,
                                _notifications[index],
                              ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (!mounted) return;
      setState(() {
        for (final notification in _notifications) {
          notification.isRead = true;
        }
        _unreadNotificationCount = 0;
      });
      _notificationRevision.value++;
    });
  }

  Widget _buildNotificationsEmptyState(BuildContext sheetContext) {
    final l10n = AppLocalizations.of(sheetContext);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spaceXl,
        AppSpacing.spaceMd,
        AppSpacing.spaceXl,
        AppSpacing.spaceXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: PatientColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 32,
              color: PatientColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          Text(l10n.t('allCaughtUp'), style: AppTypography.titleMd),
          const SizedBox(height: AppSpacing.spaceXs),
          Text(
            l10n.t('notificationsEmptyBody'),
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              color: PatientColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceLg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(l10n.t('close')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext sheetContext,
    _PatientNotification notification,
  ) {
    final clinic = notification.clinicId == null
        ? null
        : _clinicById(notification.clinicId!);
    final unread = !notification.isRead;
    return Material(
      color: unread
          ? PatientColors.secondaryContainer.withValues(alpha: 0.22)
          : Colors.transparent,
      child: InkWell(
        onTap: clinic == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                _openClinic(clinic);
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spaceSm,
            vertical: AppSpacing.spaceMd,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: PatientColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.icon,
                  size: 19,
                  color: PatientColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMd.copyWith(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: PatientColors.onSurface,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: AppSpacing.spaceXs),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: PatientColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                        color: PatientColors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _relativeTime(notification.createdAt),
                      style: AppTypography.labelSm.copyWith(
                        color: PatientColors.outline,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (clinic != null)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.spaceXs, top: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: PatientColors.outline,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAbout() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const AboutScreen()));
  }

  void _openLegal(LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LegalScreen(document: document)),
    );
  }
}

class _PatientNotification {
  _PatientNotification({
    required this.title,
    required this.message,
    required this.icon,
    required this.createdAt,
    this.clinicId,
  });

  final String title;
  final String message;
  final IconData icon;
  final DateTime createdAt;
  final String? clinicId;
  bool isRead = false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Clinic card
// ─────────────────────────────────────────────────────────────────────────────

class _ClinicCard extends StatelessWidget {
  final ClinicModel clinic;
  final int parchiCount;
  final VoidCallback onTap;

  const _ClinicCard({
    required this.clinic,
    required this.parchiCount,
    required this.onTap,
  });

  ClinicOperationalStatus get _status {
    if (!clinic.isActive || !clinic.isOnline) {
      return ClinicOperationalStatus.unavailable;
    }
    return switch (clinic.doctorStatus) {
      'delayed' => ClinicOperationalStatus.delayed,
      'offDuty' => ClinicOperationalStatus.unavailable,
      _ => ClinicOperationalStatus.available,
    };
  }

  String _statusLabel(AppLocalizations l10n) {
    if (!clinic.isActive) return l10n.t('offline');
    if (!clinic.isOnline) return l10n.t('offline');
    return switch (_status) {
      ClinicOperationalStatus.available => l10n.t('statusAvailable'),
      ClinicOperationalStatus.delayed => l10n.t('statusDelayed'),
      ClinicOperationalStatus.unavailable => l10n.t('statusUnavailable'),
    };
  }

  bool get _isOpen => _status == ClinicOperationalStatus.available;

  String get _locationLine {
    final city = clinic.city.trim();
    final region = clinic.region.trim();
    if (city.isNotEmpty && region.isNotEmpty) return '$city, $region';
    if (city.isNotEmpty) return city;
    if (region.isNotEmpty) return region;
    return clinic.address.trim();
  }

  String get _doctorLine {
    final name = clinic.doctorName.trim();
    final credentials = clinic.doctorCredentials.trim();
    if (name.isEmpty) return '';
    return credentials.isEmpty ? name : '$name, $credentials';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceMd),
      child: Material(
        color: PatientColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedLg,
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shadowColor: PatientColors.primary.withValues(alpha: 0.10),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCover(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineSm.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    if (_doctorLine.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.medical_services_outlined,
                            size: 15,
                            color: PatientColors.secondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _doctorLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySm.copyWith(
                                color: PatientColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_locationLine.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: PatientColors.outline,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _locationLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySm.copyWith(
                                color: PatientColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (clinic.doctorTiming.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: PatientColors.secondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              clinic.doctorTiming,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelMd.copyWith(
                                color: PatientColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: AppSpacing.spaceSm,
                      runSpacing: AppSpacing.spaceSm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusPill(status: _status, label: _statusLabel(l10n)),
                        _buildParchiPill(l10n),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildCoverImage(clinic.coverPhotoUrl),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x22000000)],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _isOpen
                    ? PatientColors.secondaryContainer
                    : PatientColors.outlineVariant,
                shape: BoxShape.circle,
                border: Border.all(
                  color: PatientColors.surfaceContainerLowest,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(String photo) {
    if (photo.isEmpty) return const _ClinicCoverPlaceholder();
    if (photo.startsWith('http')) {
      return Image.network(
        photo,
        fit: BoxFit.cover,
        cacheWidth: 900,
        errorBuilder: (_, _, _) => const _ClinicCoverPlaceholder(),
      );
    }
    return Image.asset(
      photo,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _ClinicCoverPlaceholder(),
    );
  }

  Widget _buildParchiPill(AppLocalizations l10n) {
    if (!clinic.isActive) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: const BoxDecoration(
          color: PatientColors.errorContainer,
          borderRadius: AppSpacing.roundedFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 13,
              color: PatientColors.onErrorContainer,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                l10n.t('subscriptionInactive'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSm.copyWith(
                  color: PatientColors.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isOpen) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: const BoxDecoration(
          color: PatientColors.surfaceContainerLow,
          borderRadius: AppSpacing.roundedFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_rounded,
              size: 13,
              color: PatientColors.outline,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                l10n.t('closedForSession'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSm.copyWith(
                  color: PatientColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        color: PatientColors.secondaryContainer,
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            size: 13,
            color: PatientColors.onSecondaryContainer,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              l10n
                  .t('todaysParchiCountLabel')
                  .replaceAll('{count}', '$parchiCount'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSm.copyWith(
                color: PatientColors.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicCoverPlaceholder extends StatelessWidget {
  const _ClinicCoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF073B78), Color(0xFF0A5AA8)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -18,
            bottom: -30,
            child: Icon(
              Icons.local_hospital_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Center(
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
