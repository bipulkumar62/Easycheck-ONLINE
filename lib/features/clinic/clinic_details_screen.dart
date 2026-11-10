import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/widgets/brand_mark.dart';
import '../../shared/models/clinic_model.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../clinics/clinic_model.dart' as firestore_clinic;
import '../clinics/clinic_repository.dart';
import '../clinics/queue_repository.dart';
import '../clinics/queue_session_model.dart';

/// Clinic Details & Live Parchi Screen — "Clinical Clarity" design system.
/// Shell: mobile_stack (fixed top app bar with back nav, no bottom tab bar).
/// Reference: stitch_easycheck_clinic_mobile_ui/clinic_details_easycheck_online/
class ClinicDetailsScreen extends StatefulWidget {
  final ClinicModel clinic;

  const ClinicDetailsScreen({super.key, required this.clinic});

  @override
  State<ClinicDetailsScreen> createState() => _ClinicDetailsScreenState();
}

class _ClinicDetailsScreenState extends State<ClinicDetailsScreen> {
  static const double _contentMaxWidth = 720.0;

  final QueueRepository _queueRepository = QueueRepository();
  final ClinicRepository _clinicRepository = ClinicRepository();
  StreamSubscription<QueueSessionModel?>? _queueSubscription;
  StreamSubscription<firestore_clinic.ClinicModel?>? _clinicSubscription;
  int? _liveCount;
  DateTime? _lastUpdate;
  ClinicModel? _liveClinic;

  /// Live clinic profile. Falls back to the model passed in by the previous
  /// screen until the Firestore snapshot arrives.
  ClinicModel get _clinic => _liveClinic ?? widget.clinic;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    _queueSubscription = _queueRepository
        .sessionStream(widget.clinic.id, today)
        .listen(
          (session) {
            if (!mounted) return;
            setState(() {
              _liveCount = session?.currentParchaNumber;
              _lastUpdate = DateTime.now();
            });
          },
          onError: (_) {
            // Keep the last known count when the live feed is unavailable.
          },
        );

    // Keep the doctor name, degree, specialty, timing, photo and availability
    // in sync while the patient is on this screen.
    _clinicSubscription = _clinicRepository
        .clinicStream(widget.clinic.id)
        .listen(
          (clinic) {
            if (!mounted || clinic == null) return;
            setState(() {
              _liveClinic = clinic.toDisplayModel(liveParchiCount: _liveCount);
            });
          },
          onError: (_) {
            // Keep the profile from the previous screen if the feed drops.
          },
        );
  }

  @override
  void dispose() {
    _queueSubscription?.cancel();
    _clinicSubscription?.cancel();
    super.dispose();
  }

  int get _displayCount => _liveCount ?? _clinic.todayParchiCount;

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final clinic = _clinic;
    final isAvailable = clinic.status == ClinicStatus.available;

    return Scaffold(
      backgroundColor: PatientColors.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sidePadding = constraints.maxWidth > _contentMaxWidth
              ? (constraints.maxWidth - _contentMaxWidth) / 2 +
                    AppSpacing.gutter
              : AppSpacing.gutter;

          return Stack(
            children: [
              // Scrollable content area
              CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  // Space for fixed header
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).padding.top + 64.0,
                    ),
                  ),

                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: sidePadding,
                      vertical: AppSpacing.spaceSm,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (!clinic.isActive) ...[
                          _buildSubscriptionInactiveBanner(clinic),
                          const SizedBox(height: AppSpacing.spaceLg),
                        ],

                        // 1. Doctor & Clinic Header Card
                        _buildDoctorHeaderCard(clinic, isAvailable),

                        const SizedBox(height: AppSpacing.spaceLg),

                        // 2. Live Parchi Counter Card Section
                        _buildParchiCounterCard(clinic),

                        const SizedBox(height: AppSpacing.spaceLg),

                        // 3. Planning Your Visit Guidance Card
                        _buildPlanningVisitCard(),

                        const SizedBox(height: AppSpacing.spaceLg),

                        // 4. Off-Hours & Doctor Leave Notice Card
                        _buildOffHoursNoticeCard(),

                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 32.0,
                        ),
                      ]),
                    ),
                  ),
                ],
              ),

              // Fixed Top App Bar (Header)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopAppBar(context),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Fixed Top App Bar with back navigation.
  Widget _buildTopAppBar(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(top: topPadding),
      height: topPadding + 64.0,
      decoration: BoxDecoration(
        color: PatientColors.surface.withValues(alpha: 0.97),
        boxShadow: AppSpacing.elevationLevel1,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Row(
              children: [
                // Back Button
                SizedBox(
                  width: 44.0,
                  height: 44.0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: PatientColors.primary,
                      size: 24.0,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    splashRadius: 22.0,
                    tooltip: 'Go back',
                  ),
                ),

                const SizedBox(width: 4.0),

                // EasyCheck Online logo mark
                const BrandMark(size: 34, padding: 4, radius: 10),

                const SizedBox(width: 8.0),

                // Screen Title
                Expanded(
                  child: Text(
                    'Clinic Details',
                    style: PatientTypography.titleMd.copyWith(
                      color: PatientColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // User Avatar
                Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: const BoxDecoration(
                    color: PatientColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 18.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A disabled clinic stays visible so patients get an honest offline state
  /// instead of a clinic that silently disappears from the list.
  Widget _buildSubscriptionInactiveBanner(ClinicModel clinic) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: PatientColors.errorContainer,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: PatientColors.onErrorContainer,
            size: 20.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clinic offline · Subscription inactive',
                  style: PatientTypography.titleMd.copyWith(
                    color: PatientColors.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '${clinic.name} is disabled by the network administrator. The '
                  'live queue is paused, so please check back later.',
                  style: PatientTypography.bodySm.copyWith(
                    color: PatientColors.onErrorContainer,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Doctor & Clinic Header Card
  Widget _buildDoctorHeaderCard(ClinicModel clinic, bool isAvailable) {
    return Container(
      decoration: BoxDecoration(
        color: PatientColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14073B78),
            blurRadius: 12.0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Stack(
          children: [
            // Ambient Decorative Circle (matching code.html line 7)
            Positioned(
              right: -40,
              bottom: -40,
              child: Container(
                width: 180.0,
                height: 180.0,
                decoration: BoxDecoration(
                  color: PatientColors.surfaceContainerLow.withValues(
                    alpha: 0.60,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.spaceLg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 300;
                  final portrait = _buildDoctorPortrait(
                    size: compact ? 108.0 : 132.0,
                  );
                  final info = _buildDoctorInfo(clinic, isAvailable);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (compact) ...[
                        Center(child: portrait),
                        const SizedBox(height: 16.0),
                        info,
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            portrait,
                            const SizedBox(width: 18.0),
                            Expanded(child: info),
                          ],
                        ),
                      const SizedBox(height: 16.0),
                      _buildClinicLocationSection(clinic),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorPortrait({required double size}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: _buildDoctorImage(size: size),
        ),
        // Verified badge circle
        Positioned(
          bottom: -7.0,
          right: -7.0,
          child: Container(
            width: 28.0,
            height: 28.0,
            decoration: BoxDecoration(
              color: PatientColors.secondaryContainer,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: AppSpacing.elevationLevel1,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: PatientColors.onSecondaryContainer,
              size: 16.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorInfo(ClinicModel clinic, bool isAvailable) {
    final doctorName = clinic.doctor.name.isNotEmpty
        ? clinic.doctor.name
        : clinic.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DOCTOR PROFILE',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PatientTypography.labelSm.copyWith(
            color: PatientColors.secondary,
            letterSpacing: 1.0,
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7.0),

        // Doctor Name — the primary heading of this screen.
        Text(
          doctorName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: PatientTypography.headlineMd.copyWith(
            color: PatientColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 24.0,
            height: 1.12,
            letterSpacing: -0.4,
          ),
        ),

        if (clinic.doctor.credentials.trim().isNotEmpty) ...[
          const SizedBox(height: 3.0),
          Text(
            clinic.doctor.credentials,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PatientTypography.bodyMd.copyWith(
              color: PatientColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        if (clinic.doctor.specialty.trim().isNotEmpty) ...[
          const SizedBox(height: 4.0),
          Text(
            clinic.doctor.specialty,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PatientTypography.bodySm.copyWith(
              color: PatientColors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],

        const SizedBox(height: 10.0),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: isAvailable
                ? PatientColors.secondaryContainer
                : PatientColors.surfaceContainerLow,
            borderRadius: AppSpacing.roundedFull,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAvailable) ...[
                const LivePulseDot(color: PatientColors.secondary, size: 6.0),
                const SizedBox(width: 6.0),
              ],
              Flexible(
                child: Text(
                  isAvailable ? 'Currently Available' : 'Not Available',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PatientTypography.labelMd.copyWith(
                    color: isAvailable
                        ? PatientColors.onSecondaryContainer
                        : PatientColors.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (clinic.doctor.timing.trim().isNotEmpty) ...[
          const SizedBox(height: 9.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1.0),
                child: Icon(
                  Icons.schedule_rounded,
                  size: 16.0,
                  color: PatientColors.secondary,
                ),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  clinic.doctor.timing,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PatientTypography.bodySm.copyWith(
                    color: PatientColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildClinicLocationSection(ClinicModel clinic) {
    return Container(
      padding: const EdgeInsets.only(top: 12.0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEFF4FF), width: 1.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_hospital_rounded,
            color: PatientColors.primary,
            size: 20.0,
          ),
          const SizedBox(width: 9.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clinic.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PatientTypography.titleMd.copyWith(
                    color: PatientColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  clinic.address.trim().isEmpty
                      ? 'Address not listed'
                      : clinic.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PatientTypography.bodySm.copyWith(
                    color: PatientColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorImage({required double size}) {
    final photo = _clinic.doctor.photoAssetPath;
    if (photo == null || photo.isEmpty) return _doctorPlaceholder(size: size);

    if (photo.startsWith('http')) {
      return Image.network(
        photo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        errorBuilder: (_, _, _) => _doctorPlaceholder(size: size),
      );
    }

    return Image.asset(
      photo,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _doctorPlaceholder(size: size),
    );
  }

  Widget _doctorPlaceholder({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD7E3FF), Color(0xFFEEF4FF)],
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.46,
        color: PatientColors.primary.withValues(alpha: 0.55),
      ),
    );
  }

  /// 2. Live Parchi Counter Card Section
  Widget _buildParchiCounterCard(ClinicModel clinic) {
    final count = _displayCount;
    final yesterday = clinic.yesterdayParchiCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceLg),
      decoration: BoxDecoration(
        color: PatientColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14073B78),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with live-sync indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        color: PatientColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: PatientColors.primary,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Flexible(
                      child: Text(
                        "Today's Parchi Count",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PatientTypography.titleMd.copyWith(
                          color: PatientColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: clinic.isActive
                      ? PatientColors.secondaryContainer
                      : PatientColors.surfaceContainerLow,
                  borderRadius: AppSpacing.roundedFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (clinic.isActive)
                      const LivePulseDot(
                        color: PatientColors.secondary,
                        size: 6.0,
                      )
                    else
                      const Icon(
                        Icons.pause_circle_outline_rounded,
                        color: PatientColors.outline,
                        size: 13.0,
                      ),
                    const SizedBox(width: 5.0),
                    Text(
                      clinic.isActive ? 'Live' : 'Paused',
                      style: PatientTypography.labelMd.copyWith(
                        color: clinic.isActive
                            ? PatientColors.onSecondaryContainer
                            : PatientColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.spaceLg),

          // Prominent Counter Metric Display Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 12.0,
            ),
            decoration: BoxDecoration(
              color: PatientColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: [
                // Giant Number Display
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$count',
                    maxLines: 1,
                    style: PatientTypography.displayLg.copyWith(
                      color: PatientColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 4.0),

                // Live counter chip. This states only what the data is; it does
                // not claim manual verification by clinic reception.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: PatientColors.surfaceContainerHighest,
                    borderRadius: AppSpacing.roundedFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sensors_rounded,
                        size: 14.0,
                        color: PatientColors.primary,
                      ),
                      const SizedBox(width: 6.0),
                      Flexible(
                        child: Text(
                          'Live clinic counter',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PatientTypography.labelSm.copyWith(
                            color: PatientColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12.0),

                // Realtime Ping Subtitle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const LivePulseDot(
                      color: PatientColors.secondary,
                      size: 6.0,
                    ),
                    const SizedBox(width: 8.0),
                    Flexible(
                      child: Text(
                        _lastUpdate == null
                            ? 'Waiting for the clinic’s live counter'
                            : 'Live · updated ${_formatTime(_lastUpdate!)}',
                        style: PatientTypography.labelMd.copyWith(
                          color: PatientColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.spaceMd),

          // Direct Comparison Grid (Yesterday vs Today)
          Row(
            children: [
              // Yesterday Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: PatientColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yesterday',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PatientTypography.labelMd.copyWith(
                          color: PatientColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$yesterday',
                                maxLines: 1,
                                style: PatientTypography.headlineMd.copyWith(
                                  color: PatientColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            'slips',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PatientTypography.labelSm.copyWith(
                              color: PatientColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'Previous day’s parchi count',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PatientTypography.labelSm.copyWith(
                          color: PatientColors.onSurfaceVariant,
                          fontSize: 10.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8.0),

              // Today Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: PatientColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PatientTypography.labelMd.copyWith(
                          color: PatientColors.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$count',
                                maxLines: 1,
                                style: PatientTypography.headlineMd.copyWith(
                                  color: PatientColors.onSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            'slips',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PatientTypography.labelSm.copyWith(
                              color: PatientColors.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'Current day’s live count',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PatientTypography.labelSm.copyWith(
                          color: PatientColors.onSecondaryContainer,
                          fontSize: 10.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Planning Your Visit Guidance Card
  Widget _buildPlanningVisitCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceLg),
      decoration: BoxDecoration(
        color: PatientColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.0,
            height: 36.0,
            decoration: const BoxDecoration(
              color: PatientColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: PatientColors.primary,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planning Your Visit',
                  style: PatientTypography.titleMd.copyWith(
                    color: PatientColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'A little more clarity before your visit. Check the latest clinic updates and plan your time with greater confidence.',
                  style: PatientTypography.bodyMd.copyWith(
                    color: PatientColors.onSurface,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Off-Hours & Doctor Leave Notice Card (Informative Preview)
  Widget _buildOffHoursNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceLg),
      decoration: BoxDecoration(
        color: PatientColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: AppSpacing.elevationLevel1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_rounded,
                color: PatientColors.onSurfaceVariant,
                size: 18.0,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Off-Hours & Doctor Leave Notice',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PatientTypography.titleMd.copyWith(
                    color: PatientColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: PatientColors.surfaceContainer,
                    borderRadius: AppSpacing.roundedFull,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Standard Protocol',
                      maxLines: 1,
                      style: PatientTypography.labelSm.copyWith(
                        color: PatientColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10.0),

          Text(
            'When clinic session is closed or doctor is unavailable, a calm notice replaces the active count rather than an ambiguous status.',
            style: PatientTypography.bodySm.copyWith(
              color: PatientColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12.0),

          // Visual Sample of Unavailable Badge Row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: PatientColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Container(
                  width: 10.0,
                  height: 10.0,
                  decoration: const BoxDecoration(
                    color: PatientColors.outline,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Session Closed · Offline',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: PatientTypography.bodySm.copyWith(
                      color: PatientColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  '—',
                  style: PatientTypography.labelMd.copyWith(
                    color: PatientColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
