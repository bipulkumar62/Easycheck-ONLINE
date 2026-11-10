import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/routes/app_routes.dart';
import '../../core/constants/asset_constants.dart';
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

/// Patient Google Login Screen — "Clinical Clarity" design system.
/// Source: stitch_easycheck_clinic_mobile_ui/google_login_easycheck_online/code.html
/// Shell: mobile_blank (full viewport, no app bar, no bottom nav).
class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  bool _isSigningIn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeContinueSession());
  }

  /// A valid Firebase session already means the patient has signed in. Skip the
  /// Google account picker and go straight to the verification screen.
  Future<void> _maybeContinueSession() async {
    if (!mounted || _isSigningIn) return;
    try {
      if (Firebase.apps.isEmpty) return;
      if (FirebaseAuth.instance.currentUser == null) return;
    } catch (_) {
      return;
    }
    await AuthSessionStore.saveRole(AuthRole.patient);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.authGate,
      arguments: const AuthGateArgs(role: AuthRole.patient),
    );
  }

  // Clinical Clarity color tokens from Stitch tailwind config
  static const Color _surface = Color(0xFFF8F9FF);
  static const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _surfaceContainerHighest = Color(0xFFD3E4FE);
  static const Color _primary = Color(0xFF002553);
  static const Color _primaryContainer = Color(0xFF073B78);
  static const Color _secondary = Color(0xFF006D44);
  static const Color _secondaryContainer = Color(0xFF7DF7B6);
  static const Color _onSurfaceVariant = Color(0xFF434750);
  static const Color _outlineVariant = Color(0xFFC3C6D2);
  static const Color _errorColor = Color(0xFFBA1A1A);
  static const Color _errorContainer = Color(0xFFFFDAD6);
  static const Color _onErrorContainer = Color(0xFF93000A);

  static const String _bgImageUrl = AssetConstants.loginBgConsultation;

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
      await AuthSessionStore.saveRole(AuthRole.patient);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.authGate,
        arguments: const AuthGateArgs(role: AuthRole.patient),
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

  void _openLegal(LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalScreen(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Immersive Full-bleed Background Photograph
          Image.asset(
            _bgImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: _surface),
          ),

          // 2. Soft Glass Gradient Overlay: surface/90 → surface/85 → surface-container-low/95
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xE6F8F9FF), // #f8f9ff at 90%
                  Color(0xD9F8F9FF), // #f8f9ff at 85%
                  Color(0xF2EFF4FF), // surface-container-low at 95%
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // 3. Ambient Micro-Glow Accents
          // Top-right ambient orb (static, no runtime blur)
          Positioned(
            top: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  color: _secondaryContainer.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _secondaryContainer.withValues(alpha: 0.30),
                      blurRadius: 80,
                      spreadRadius: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom-left ambient orb (static, no runtime blur)
          Positioned(
            bottom: size.height * 0.18,
            left: -50,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: _surfaceContainerHighest.withValues(alpha: 0.40),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _surfaceContainerHighest.withValues(alpha: 0.45),
                      blurRadius: 70,
                      spreadRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Core Content Stack
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: _surfaceContainerLowest.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: l10n.t('backToRoleSelection'),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: _primary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _surfaceContainerLowest.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const LanguageToggle(compact: true),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── HEADER: Pill + Brand ──
                        Column(
                          children: [
                            const SizedBox(height: 12),

                            // Live Sync Status Chip
                            _buildLivePill(),

                            const SizedBox(height: 20),

                            // Canonical square brand mark.
                            const BrandMark(
                              size: 58,
                              padding: 7,
                              radius: 16,
                            ),

                            const SizedBox(height: 10),

                            // Brand Wordmark: "EasyCheck Online"
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'EasyCheck',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _primary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Online',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: _secondary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Subtitle: OFFICIAL PATIENT PORTAL
                            Text(
                              l10n.t('officialPatientPortal'),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _onSurfaceVariant.withValues(alpha: 0.80),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── CENTER: Value Proposition Card (glass) ──
                        _buildValueCard(),

                        const SizedBox(height: 24),

                        // ── BOTTOM: Google Button + Security + Legal ──
                        Column(
                          children: [
                            if (_error != null) ...[
                              _buildErrorBanner(),
                              const SizedBox(height: 12),
                            ],
                            _buildGoogleButton(),
                            if (_hasSignedInAccount) ...[
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed:
                                    _isSigningIn ? null : _useDifferentAccount,
                                child: Text(
                                  l10n.t('useDifferentAccount'),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _secondary,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            _buildSecurityBadge(),
                            const SizedBox(height: 14),
                            _buildLegalFooter(),
                            const SizedBox(height: 8),
                          ],
                        ),
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

  Widget _buildLivePill() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceContainerLowest.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LiveDot(
            size: 7,
            color: _secondary,
            semanticsLabel: 'Real-time clinic updates',
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              l10n.t('realTimeClinicUpdates'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF007147), // on-secondary-container
                letterSpacing: 0.33,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainerLowest.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Feature Header: verified icon + label
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_rounded, color: _secondary, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.t('opdParchiTracker'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _secondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // H1: Your doctor, closer than ever.
              Text(
                l10n.t('patientLoginHeadline'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _primaryContainer,
                  height: 1.3,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 8),

              // Body description
              Text(
                l10n.t('patientLoginSubtitle'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: _onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildGoogleButton() {
    final l10n = AppLocalizations.of(context);
    return GoogleSignInButton(
      onPressed: _handleGoogleSignIn,
      isLoading: _isSigningIn,
      subtitle: l10n.t('securePatientSignIn'),
      accentColor: _secondary,
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _errorContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _onErrorContainer.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: _errorColor, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: _onErrorContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadge() {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_rounded, color: _secondary, size: 15),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            l10n.t('securityBadge'),
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _onSurfaceVariant.withValues(alpha: 0.90),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegalFooter() {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      children: [
        _LegalLink(
          label: l10n.t('privacyPolicy'),
          onTap: () => _openLegal(LegalDocument.privacy),
        ),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: _outlineVariant,
            shape: BoxShape.circle,
          ),
        ),
        _LegalLink(
          label: l10n.t('termsOfUse'),
          onTap: () => _openLegal(LegalDocument.terms),
        ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LegalLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF434750),
            decoration: TextDecoration.underline,
            decorationColor: Color(0x66434750),
          ),
        ),
      ),
    );
  }
}
