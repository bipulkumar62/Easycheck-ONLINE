import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/constants/asset_constants.dart';

/// Reset Confirmation & Account State Studio — "Clinical Precision" design system.
/// Shell: mobile_tab (fixed top app bar + fixed bottom 4-tab nav).
/// Source: stitch_easycheck_clinic_admin/reset_confirmation_account_state/
class AdminResetStudioScreen extends StatefulWidget {
  const AdminResetStudioScreen({super.key});

  @override
  State<AdminResetStudioScreen> createState() => _AdminResetStudioScreenState();
}

enum _StudioScenario { resetModal, feedback, staffDrawer }

class _AdminResetStudioScreenState extends State<AdminResetStudioScreen> {
  _StudioScenario _currentScenario = _StudioScenario.resetModal;
  int _parchiCount = 12;
  bool _showToast = false;
  String _toastTitle = '';
  String _toastSubtitle = '';
  int _selectedTab = 3; // 'Clinic' tab active in Stitch prototype

  void _selectScenario(_StudioScenario scenario) {
    setState(() {
      _currentScenario = scenario;
      if (scenario == _StudioScenario.feedback) {
        _triggerFeedbackToast(
          title: 'Parchi counter incremented to $_parchiCount',
          subtitle: 'Sync confirmed with Apex Cloud Ledger',
        );
      }
    });
  }

  void _triggerFeedbackToast({
    required String title,
    required String subtitle,
  }) {
    setState(() {
      _toastTitle = title;
      _toastSubtitle = subtitle;
      _showToast = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showToast = false);
    });
  }

  void _handleConfirmReset() {
    setState(() {
      _parchiCount = 0;
      _currentScenario = _StudioScenario.feedback;
    });
    _triggerFeedbackToast(
      title: 'Parchi tally reset to 0',
      subtitle: 'Audit logged: reception.apex@easycheck.med',
    );
  }

  void _handleQuickIncrement() {
    setState(() => _parchiCount++);
    _triggerFeedbackToast(
      title: 'Parchi counter incremented to $_parchiCount',
      subtitle: 'Sync confirmed with Apex Cloud Ledger',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.surface,
      body: Stack(
        children: [
          // Base scrollable dashboard underlay
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + 64.0,
                ),
              ),

              // Scenario selector toolbar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.spaceSm,
                    AppSpacing.gutter,
                    AppSpacing.spaceXs,
                  ),
                  child: _buildScenarioToolbar(),
                ),
              ),

              // Underlay dashboard view
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.spaceSm,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Quick Status Pill Banner
                    _buildQuickStatusBanner(),

                    const SizedBox(height: AppSpacing.spaceMd),

                    // Parchi Live Counter Card
                    _buildParchiCounterCard(),

                    const SizedBox(height: AppSpacing.spaceMd),

                    // Waiting Area Queue Preview
                    _buildWaitingAreaPreview(),

                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 64.0 + 16.0,
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // Fixed Top App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopAppBar(context),
          ),

          // Fixed Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNav(context),
          ),

          // Modal backdrop and dialog for Reset confirmation
          if (_currentScenario == _StudioScenario.resetModal)
            _buildResetModalBackdrop(),

          // Slide-up drawer for Staff Audit
          if (_currentScenario == _StudioScenario.staffDrawer)
            _buildStaffAuditDrawer(),

          // Feedback toast overlay
          if (_showToast) _buildFeedbackToast(context),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      height: MediaQuery.of(context).padding.top + 64.0,
      decoration: BoxDecoration(
        color: AdminColors.surface.withValues(alpha: 0.90),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A073B78),
            blurRadius: 8.0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Row(
          children: [
            Image.asset(
              AssetConstants.logoAdmin,
              height: 32.0,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10.0),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'CLINIC ADMIN',
                      style: AdminTypography.labelSm.copyWith(
                        color: AdminColors.primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AdminColors.outline,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      'EASYCHECK ADMIN',
                      style: AdminTypography.labelSm.copyWith(
                        color: AdminColors.secondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Apex Care Polyclinic',
                  style: AdminTypography.headlineSm.copyWith(
                    color: AdminColors.onSurface,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Profile avatar button
            GestureDetector(
              onTap: () => _selectScenario(_StudioScenario.staffDrawer),
              child: Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F073B78),
                      blurRadius: 4.0,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    AssetConstants.avatarReceptionApex,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AdminColors.secondary,
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 18.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioToolbar() {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerHigh,
        borderRadius: AppSpacing.roundedFull,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A073B78),
            blurRadius: 4.0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildScenarioTab(
            scenario: _StudioScenario.resetModal,
            icon: Icons.restart_alt_rounded,
            iconColor: AdminColors.error,
            label: 'Reset Dialog',
          ),
          _buildScenarioTab(
            scenario: _StudioScenario.feedback,
            icon: Icons.notifications_active_rounded,
            iconColor: AdminColors.primary,
            label: 'Feedback',
          ),
          _buildScenarioTab(
            scenario: _StudioScenario.staffDrawer,
            icon: Icons.badge_rounded,
            iconColor: AdminColors.secondary,
            label: 'Staff Audit',
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioTab({
    required _StudioScenario scenario,
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    final isSelected = _currentScenario == scenario;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectScenario(scenario),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected
                ? AdminColors.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: AppSpacing.roundedFull,
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0D073B78),
                      blurRadius: 4.0,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16.0, color: iconColor),
              const SizedBox(width: 4.0),
              Flexible(
                child: Text(
                  label,
                  style: AdminTypography.labelMd.copyWith(
                    color: isSelected
                        ? AdminColors.onSurface
                        : AdminColors.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A073B78),
            blurRadius: 4.0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: AdminColors.secondaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'RS',
                    style: AdminTypography.headlineSm.copyWith(
                      color: AdminColors.onSecondaryFixed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12.0,
                  height: 12.0,
                  decoration: BoxDecoration(
                    color: AdminColors.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AdminColors.surfaceContainerLowest,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. Rajesh Sharma',
                  style: AdminTypography.headlineSm.copyWith(
                    color: AdminColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'General OPD • Room 04',
                  style: AdminTypography.bodySm.copyWith(
                    color: AdminColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AdminColors.surfaceContainerLow,
              borderRadius: AppSpacing.roundedFull,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.0,
                  height: 6.0,
                  decoration: const BoxDecoration(
                    color: AdminColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4.0),
                Text(
                  'AVAILABLE',
                  style: AdminTypography.labelSm.copyWith(
                    color: AdminColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParchiCounterCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceLg),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A073B78),
            blurRadius: 4.0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.confirmation_number_rounded,
                    color: AdminColors.primary,
                    size: 20.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    "Today's Token Tally",
                    style: AdminTypography.labelLg.copyWith(
                      color: AdminColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: AdminColors.surfaceContainerHigh,
                  borderRadius: AppSpacing.roundedFull,
                ),
                child: Text(
                  'Session Active',
                  style: AdminTypography.labelSm.copyWith(
                    color: AdminColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12.0),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$_parchiCount',
                style: AdminTypography.headlineXl.copyWith(
                  color: AdminColors.onSurface,
                  fontSize: 40.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                'parchis issued',
                style: AdminTypography.bodyMd.copyWith(
                  color: AdminColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: AdminColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: AdminColors.primary,
                      size: 16.0,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      '+3 / hr',
                      style: AdminTypography.labelMd.copyWith(
                        color: AdminColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.spaceMd),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48.0,
                  child: ElevatedButton.icon(
                    onPressed: _handleQuickIncrement,
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        size: 18.0),
                    label: Text('Issue Next (${_parchiCount + 1})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.primary,
                      foregroundColor: AdminColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      textStyle: AdminTypography.labelLg,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: SizedBox(
                  height: 48.0,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _selectScenario(_StudioScenario.resetModal),
                    icon: const Icon(
                      Icons.restart_alt_rounded,
                      color: AdminColors.error,
                      size: 18.0,
                    ),
                    label: Text(
                      'Reset Tally',
                      style: AdminTypography.labelLg.copyWith(
                        color: AdminColors.onSurface,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AdminColors.surfaceContainerHigh,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.spaceSm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: AdminColors.outline,
                    size: 14.0,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'Last parchi issued: 10:38 AM (#012)',
                    style: AdminTypography.labelSm.copyWith(
                      color: AdminColors.outline,
                    ),
                  ),
                ],
              ),
              Text(
                'Auto-Sync ON',
                style: AdminTypography.labelSm.copyWith(
                  color: AdminColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingAreaPreview() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A073B78),
            blurRadius: 4.0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'In Waiting Area (3)',
                style: AdminTypography.labelLg.copyWith(
                  color: AdminColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Est. 18m wait',
                style: AdminTypography.labelSm.copyWith(
                  color: AdminColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          _buildPatientSnippet(
            tokenNumber: '10',
            name: 'Meera Patel',
            subtitle: 'Follow-up BP Check • Dr. Rajesh',
            statusTag: 'With Doctor',
            tagBg: AdminColors.surfaceContainerHighest,
            tagColor: AdminColors.onSurfaceVariant,
          ),
          const SizedBox(height: 8.0),
          _buildPatientSnippet(
            tokenNumber: '11',
            name: 'Harshavardhan Rao',
            subtitle: 'General Viral Consult • Waiting 8m',
            statusTag: 'Next Up',
            tagBg: AdminColors.secondaryFixed,
            tagColor: AdminColors.onSecondaryFixedVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSnippet({
    required String tokenNumber,
    required String name,
    required String subtitle,
    required String statusTag,
    required Color tagBg,
    required Color tagColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AdminColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Container(
            width: 32.0,
            height: 32.0,
            decoration: BoxDecoration(
              color: AdminColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
              child: Text(
                tokenNumber,
                style: AdminTypography.headlineSm.copyWith(
                  color: AdminColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AdminTypography.headlineSm.copyWith(
                    color: AdminColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AdminTypography.bodySm.copyWith(
                    color: AdminColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: AppSpacing.roundedFull,
            ),
            child: Text(
              statusTag,
              style: AdminTypography.labelSm.copyWith(
                color: tagColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetModalBackdrop() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _currentScenario = _StudioScenario.feedback),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: AdminColors.onSurface.withValues(alpha: 0.40),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent tap from bubbling to backdrop
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.gutter),
                constraints: const BoxConstraints(maxWidth: 384.0),
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AdminColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(32.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 32.0,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56.0,
                      height: 56.0,
                      decoration: BoxDecoration(
                        color: AdminColors.errorContainer.withValues(alpha: 0.60),
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: const Icon(
                        Icons.restart_alt_rounded,
                        color: AdminColors.error,
                        size: 32.0,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Reset today’s count?',
                      style: AdminTypography.headlineMd.copyWith(
                        color: AdminColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8.0),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AdminTypography.bodyMd.copyWith(
                          color: AdminColors.onSurfaceVariant,
                        ),
                        children: const [
                          TextSpan(
                            text: 'This will reset the parchi tally for ',
                          ),
                          TextSpan(
                            text: 'Apex Care Polyclinic',
                            style: TextStyle(
                              color: AdminColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: ' back to 0.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: AdminColors.errorContainer,
                        borderRadius: AppSpacing.roundedFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.confirmation_number_rounded,
                            color: AdminColors.onErrorContainer,
                            size: 16.0,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            '$_parchiCount issued today',
                            style: AdminTypography.labelMd.copyWith(
                              color: AdminColors.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    SizedBox(
                      width: double.infinity,
                      height: 52.0,
                      child: ElevatedButton.icon(
                        onPressed: _handleConfirmReset,
                        icon: const Icon(Icons.check_circle_rounded,
                            size: 20.0),
                        label: const Text('Confirm Reset to 0'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.error,
                          foregroundColor: AdminColors.onError,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          textStyle: AdminTypography.labelLg,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    SizedBox(
                      width: double.infinity,
                      height: 48.0,
                      child: OutlinedButton(
                        onPressed: () => setState(
                          () => _currentScenario = _StudioScenario.feedback,
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide.none,
                          backgroundColor: AdminColors.surfaceContainerHigh,
                          foregroundColor: AdminColors.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          textStyle: AdminTypography.labelLg,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildStaffAuditDrawer() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _currentScenario = _StudioScenario.feedback),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: AdminColors.onSurface.withValues(alpha: 0.40),
          alignment: Alignment.bottomCenter,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: GestureDetector(
                onTap: () {}, // Prevent bubbling
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 448.0),
                  padding: const EdgeInsets.all(AppSpacing.spaceLg),
              decoration: const BoxDecoration(
                color: AdminColors.surfaceContainerLowest,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.0)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 32.0,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 48.0,
                      height: 5.0,
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceVariant,
                        borderRadius: AppSpacing.roundedFull,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Staff Identity
                  Row(
                    children: [
                      Container(
                        width: 56.0,
                        height: 56.0,
                        decoration: BoxDecoration(
                          color: AdminColors.secondaryFixed,
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: AdminColors.onSecondaryFixed,
                          size: 32.0,
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Front Desk Lead',
                                  style: AdminTypography.headlineSm.copyWith(
                                    color: AdminColors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 2.0),
                                  decoration: BoxDecoration(
                                    color: AdminColors.primaryFixed,
                                    borderRadius: AppSpacing.roundedFull,
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: AdminTypography.labelSm.copyWith(
                                      color: AdminColors.onPrimaryFixed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'reception.apex@easycheck.med',
                              style: AdminTypography.bodySm.copyWith(
                                color: AdminColors.secondary,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              'Assigned to: Apex Care Polyclinic',
                              style: AdminTypography.labelSm.copyWith(
                                color: AdminColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // Audit summary card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.spaceMd),
                    decoration: BoxDecoration(
                      color: AdminColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Column(
                      children: [
                        _buildAuditMetaRow(
                          label: 'Session Auth Protocol',
                          value: 'Google OAuth 2.0',
                          valueIcon: Icons.verified_user_rounded,
                          iconColor: AdminColors.primary,
                        ),
                        const SizedBox(height: 8.0),
                        _buildAuditMetaRow(
                          label: 'Daily Reset Permissions',
                          value: 'Granted (Lead Tier)',
                          valueColor: AdminColors.primary,
                          isBold: true,
                        ),
                        const SizedBox(height: 8.0),
                        _buildAuditMetaRow(
                          label: 'Last Audit Checkpoint',
                          value: 'Today, 08:30 AM IST',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12.0),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: AdminColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.receipt_long_rounded,
                                      size: 16.0),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    'Audit Activity',
                                    style: AdminTypography.labelMd.copyWith(
                                      color: AdminColors.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                'View 18 shift actions',
                                style: AdminTypography.bodySm.copyWith(
                                  color: AdminColors.onSurfaceVariant,
                                  fontSize: 11.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: AdminColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.print_rounded, size: 16.0),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    'Reprint Slip',
                                    style: AdminTypography.labelMd.copyWith(
                                      color: AdminColors.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                'Bluetooth Desk Printer',
                                style: AdminTypography.bodySm.copyWith(
                                  color: AdminColors.onSurfaceVariant,
                                  fontSize: 11.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    height: 52.0,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          if (Firebase.apps.isNotEmpty) {
                            await FirebaseAuth.instance.signOut();
                          }
                        } catch (_) {
                          // Returning to role selection is still safe.
                        }
                        if (!mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.initial,
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, size: 20.0),
                      label: const Text('Log out of Apex Terminal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.errorContainer,
                        foregroundColor: AdminColors.onErrorContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        textStyle: AdminTypography.labelLg,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8.0),

                  // Close panel button
                  SizedBox(
                    width: double.infinity,
                    height: 44.0,
                    child: TextButton(
                      onPressed: () => setState(
                        () => _currentScenario = _StudioScenario.feedback,
                      ),
                      child: Text(
                        'Close Panel',
                        style: AdminTypography.labelMd.copyWith(
                          color: AdminColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildAuditMetaRow({
    required String label,
    required String value,
    IconData? valueIcon,
    Color? iconColor,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AdminTypography.labelMd.copyWith(
            color: AdminColors.onSurfaceVariant,
          ),
        ),
        Row(
          children: [
            if (valueIcon != null) ...[
              Icon(valueIcon, size: 16.0, color: iconColor),
              const SizedBox(width: 4.0),
            ],
            Text(
              value,
              style: AdminTypography.labelMd.copyWith(
                color: valueColor ?? AdminColors.onSurface,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackToast(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 72.0,
      left: AppSpacing.gutter,
      right: AppSpacing.gutter,
      child: AnimatedOpacity(
        opacity: _showToast ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: AdminColors.inverseSurface,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12.0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF62DD9E),
                size: 20.0,
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _toastTitle,
                      style: AdminTypography.labelMd.copyWith(
                        color: AdminColors.inverseOnSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _toastSubtitle,
                      style: AdminTypography.bodySm.copyWith(
                        color: AdminColors.inverseOnSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showToast = false),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white70,
                  size: 16.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    const tabs = [
      _AdminTabItem(icon: Icons.format_list_bulleted_rounded, label: 'Live Queue'),
      _AdminTabItem(icon: Icons.how_to_reg_rounded, label: 'Intake'),
      _AdminTabItem(icon: Icons.medical_services_rounded, label: 'Staff'),
      _AdminTabItem(icon: Icons.manage_accounts_rounded, label: 'Clinic'),
    ];

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      height: MediaQuery.of(context).padding.bottom + 64.0,
      decoration: BoxDecoration(
        color: AdminColors.surface.withValues(alpha: 0.90),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A073B78),
            blurRadius: 8.0,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(tabs.length, (i) {
          final isActive = i == _selectedTab;
          return GestureDetector(
            onTap: () {
              if (i == 0) {
                Navigator.of(context).pushReplacementNamed(
                  AppRoutes.adminDashboard,
                );
              } else {
                setState(() => _selectedTab = i);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 72.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tabs[i].icon,
                    size: 22.0,
                    color: isActive ? AdminColors.primary : AdminColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    tabs[i].label,
                    style: AdminTypography.labelSm.copyWith(
                      color: isActive ? AdminColors.primary : AdminColors.onSurfaceVariant,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AdminTabItem {
  final IconData icon;
  final String label;

  const _AdminTabItem({required this.icon, required this.label});
}
