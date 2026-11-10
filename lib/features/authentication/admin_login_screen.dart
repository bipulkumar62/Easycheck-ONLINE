// ignore_for_file: constant_identifier_names
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/routes/app_routes.dart';
import '../../core/errors/app_failure.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/google_sign_in_button.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/live_dot.dart';
import '../legal/legal_screen.dart';
import 'auth_error_mapper.dart';
import 'auth_gate_screen.dart';
import 'auth_session_store.dart';
import 'google_auth_service.dart';

/// Admin Google Auth Screen — "Clinical Precision" design system.
///
/// The layout is intentionally operational rather than decorative: a deep-navy
/// command panel on wide screens, a calm sign-in surface on the right, and a
/// compact branded hero on mobile. All privileged access is still resolved by
/// [AuthGateScreen] after Google sign-in; nothing on this screen grants access.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

// ── Clinical Precision color tokens ──────────────────────────────────────────
const Color _ap_surface = Color(0xFFF8F9FF);
const Color _ap_surfaceContainerLowest = Color(0xFFFFFFFF);
const Color _ap_primary = Color(0xFF006A42); // emerald — admin primary
const Color _ap_secondary = Color(0xFF375E9D); // navy — admin secondary
const Color _ap_onSurface = Color(0xFF0D1C2E);
const Color _ap_onSurfaceVariant = Color(0xFF3D4A41);
const Color _ap_error = Color(0xFFBA1A1A);
const Color _ap_errorContainer = Color(0xFFFFDAD6);
const Color _ap_onErrorContainer = Color(0xFF93000A);

// Extended operational palette used only by this screen.
const Color _ap_navyDeep = Color(0xFF041A33);
const Color _ap_navy = Color(0xFF073B78);
const Color _ap_navyBright = Color(0xFF0A4A8A);
const Color _ap_emerald = Color(0xFF16A36A);
const Color _ap_emeraldTint = Color(0xFFEAF7EF);
const Color _ap_border = Color(0xFFE2E8F0);
const Color _ap_muted = Color(0xFF64748B);

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  bool _isSigningIn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeContinueSession());
  }

  /// Reuse an existing Firebase session instead of asking clinic staff to pick
  /// their Google account again. Access is still verified by [AuthGateScreen].
  Future<void> _maybeContinueSession() async {
    if (!mounted || _isSigningIn) return;
    try {
      if (Firebase.apps.isEmpty) return;
      if (FirebaseAuth.instance.currentUser == null) return;
    } catch (_) {
      return;
    }
    await AuthSessionStore.saveRole(AuthRole.admin);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.authGate,
      arguments: const AuthGateArgs(role: AuthRole.admin),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isSigningIn) return;
    setState(() {
      _isSigningIn = true;
      _error = null;
    });
    try {
      if (Firebase.apps.isEmpty) {
        throw const ServerFailure(
          'Firebase is not configured on this device. Please install the '
          'latest version of the app and try again.',
        );
      }

      await GoogleAuthService().signIn();
      await AuthSessionStore.saveRole(AuthRole.admin);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.authGate,
        arguments: const AuthGateArgs(role: AuthRole.admin),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSigningIn = false;
        _error = AuthErrorMapper.message(error);
      });
    }
  }

  Future<void> _useDifferentAccount() async {
    await GoogleAuthService().signOut();
    if (!mounted) return;
    setState(() => _error = null);
  }

  bool get _hasSignedInAccount {
    try {
      if (Firebase.apps.isEmpty) return false;
      return FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  void _backToRoleSelection() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.initial,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ap_surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 980;
          return Stack(
            children: [
              if (isDesktop)
                Row(
                  children: [
                    Expanded(flex: 11, child: _buildBrandPanel()),
                    Expanded(flex: 9, child: _buildFormPanel(isDesktop: true)),
                  ],
                )
              else
                _buildMobileLayout(),
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildBackButton(),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LanguageToggle(compact: true),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Desktop brand panel ────────────────────────────────────────────────────

  Widget _buildBrandPanel() {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_ap_navyDeep, _ap_navy, _ap_navyBright],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _AdminGridPainter()),
            ),
          ),
          Positioned(
            top: -140,
            right: -90,
            child: _glow(340, _ap_emerald.withValues(alpha: 0.24)),
          ),
          Positioned(
            bottom: -180,
            left: -140,
            child: _glow(420, const Color(0xFF62DD9E).withValues(alpha: 0.13)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(56, 40, 56, 40),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 80,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBrandRow(),
                        const SizedBox(height: 72),
                        _buildAccessBadge(),
                        const SizedBox(height: 22),
                        Text(
                          l10n.t('runClinicWithPrecision'),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            height: 1.12,
                            letterSpacing: -1.4,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.t('runClinicSubtitle'),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            height: 1.6,
                            color: Color(0xCCFFFFFF),
                          ),
                        ),
                        const SizedBox(height: 42),
                        _buildFeatureRow(
                          icon: Icons.queue_rounded,
                          title: l10n.t('liveQueueControl'),
                          description: l10n.t('liveQueueControlBody'),
                        ),
                        const SizedBox(height: 20),
                        _buildFeatureRow(
                          icon: Icons.insights_rounded,
                          title: l10n.t('patientFlowVisibility'),
                          description: l10n.t('patientFlowVisibilityBody'),
                        ),
                        const SizedBox(height: 20),
                        _buildFeatureRow(
                          icon: Icons.verified_user_rounded,
                          title: l10n.t('roleVerifiedAccess'),
                          description: l10n.t('roleVerifiedAccessBody'),
                        ),
                        const SizedBox(height: 48),
                        _buildBrandFooter(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandRow() {
    return Row(
      children: [
        const BrandMark(size: 54, padding: 7, radius: 16),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EasyCheck',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: const Text(
                  'CLINIC OPERATIONS',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8CE8BC),
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccessBadge() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LiveDot(
            size: 6,
            color: Color(0xFF62DD9E),
            semanticsLabel: 'Secure staff access',
          ),
          const SizedBox(width: 2),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.t('secureStaffAccess'),
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: Color(0xFFD7F8E7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: const Color(0xFF8CE8BC), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  height: 1.45,
                  color: Color(0xB3FFFFFF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrandFooter() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1,
          width: double.infinity,
          color: Colors.white.withValues(alpha: 0.10),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 15,
              color: Color(0xFF8CE8BC),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.t('staffAccessOnly'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  height: 1.45,
                  color: Color(0xB3FFFFFF),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Desktop form panel ─────────────────────────────────────────────────────

  Widget _buildFormPanel({required bool isDesktop}) {
    return Container(
      color: _ap_surface,
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: _glow(280, _ap_secondary.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: _glow(320, _ap_primary.withValues(alpha: 0.07)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFormHeader(),
                      const SizedBox(height: 26),
                      _buildAuthCard(),
                      const SizedBox(height: 22),
                      _buildFormFooter(),
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

  Widget _buildFormHeader() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const BrandMark(size: 42, padding: 5, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.t('clinicAdminTitle').toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: _ap_primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          l10n.t('clinicAdminTitle'),
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: -0.8,
            color: _ap_onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.t('adminSignInSubtitle'),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.5,
            color: _ap_onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ── Mobile layout ──────────────────────────────────────────────────────────

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMobileHero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAuthCard(),
                    const SizedBox(height: 22),
                    _buildFormFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHero() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_ap_navyDeep, _ap_navy, _ap_navyBright],
          stops: [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _AdminGridPainter()),
            ),
          ),
          Positioned(
            top: -90,
            right: -60,
            child: _glow(240, _ap_emerald.withValues(alpha: 0.26)),
          ),
          Positioned(
            bottom: -80,
            left: -70,
            child: _glow(220, const Color(0xFF62DD9E).withValues(alpha: 0.14)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 76, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBrandRow(),
                  const SizedBox(height: 26),
                  _buildAccessBadge(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.t('clinicAdminTitle'),
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      letterSpacing: -0.8,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.t('adminSignInSubtitle'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xCCFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MobileFeatureChip(
                        icon: Icons.queue_rounded,
                        label: l10n.t('liveQueueTab'),
                      ),
                      _MobileFeatureChip(
                        icon: Icons.insights_rounded,
                        label: l10n.t('patientFlowVisibility'),
                      ),
                      _MobileFeatureChip(
                        icon: Icons.verified_user_rounded,
                        label: l10n.t('roleVerifiedAccess'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared form pieces ─────────────────────────────────────────────────────

  Widget _buildAuthCard() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _ap_surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ap_border),
        boxShadow: [
          BoxShadow(
            color: _ap_navy.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: _ap_navy.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _ap_emeraldTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: _ap_primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('secureStaffSignIn'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _ap_onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.t('useClinicGoogleAccount'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: _ap_muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GoogleSignInButton(
            onPressed: _handleGoogleSignIn,
            isLoading: _isSigningIn,
            subtitle: l10n.t('verifiedClinicStaffSignIn'),
            accentColor: _ap_primary,
          ),
          if (_hasSignedInAccount) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: _isSigningIn ? null : _useDifferentAccount,
              child: Text(
                l10n.t('useDifferentAccount'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _ap_secondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: Divider(color: _ap_border, height: 1)),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.t('verifiedAccess'),
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: _ap_muted.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: _ap_border, height: 1)),
            ],
          ),
          const SizedBox(height: 18),
          _buildTrustRow(
            icon: Icons.verified_user_rounded,
            text: l10n.t('clinicMembershipChecked'),
          ),
          const SizedBox(height: 10),
          _buildTrustRow(
            icon: Icons.lock_outline_rounded,
            text: l10n.t('neverStoresPassword'),
          ),
          const SizedBox(height: 10),
          _buildTrustRow(
            icon: Icons.support_agent_rounded,
            text: l10n.t('newStaffRequestAccess'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 18),
            _buildErrorBanner(),
          ],
        ],
      ),
    );
  }

  Widget _buildTrustRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: _ap_primary),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              height: 1.45,
              color: _ap_onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFooter() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 14,
              color: _ap_muted.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l10n.t('authorizedStaffOnly'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _ap_muted.withValues(alpha: 0.95),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            _AdminLegalLink(
              label: l10n.t('privacyPolicy'),
              onTap: () => _openLegal(LegalDocument.privacy),
            ),
            const Text(
              '·',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: _ap_muted,
              ),
            ),
            _AdminLegalLink(
              label: l10n.t('termsOfUse'),
              onTap: () => _openLegal(LegalDocument.terms),
            ),
          ],
        ),
        const SizedBox(height: 2),
        TextButton(
          onPressed: _backToRoleSelection,
          child: Text(
            l10n.t('backToRoleSelection'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _ap_secondary,
            ),
          ),
        ),
      ],
    );
  }

  void _openLegal(LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalScreen(document: document),
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: _ap_surfaceContainerLowest,
      shape: const CircleBorder(
        side: BorderSide(color: _ap_border),
      ),
      elevation: 0,
      child: IconButton(
        tooltip: AppLocalizations.of(context).t('backToRoleSelection'),
        onPressed: _backToRoleSelection,
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: _ap_onSurface,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ap_errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _ap_onErrorContainer.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: _ap_error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: _ap_onErrorContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _AdminLegalLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AdminLegalLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _ap_muted,
            decoration: TextDecoration.underline,
            decorationColor: Color(0x80647A8B),
          ),
        ),
      ),
    );
  }
}

/// Small feature chip used in the mobile hero.
class _MobileFeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MobileFeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF8CE8BC)),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE6FFF2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle operational grid used on the navy brand panel.
class _AdminGridPainter extends CustomPainter {
  const _AdminGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;

    const step = 48.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

