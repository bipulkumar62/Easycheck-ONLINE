import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/language_toggle.dart';
import '../legal/legal_screen.dart';
import 'auth_gate_screen.dart';
import 'auth_session_store.dart';

/// Initial role selection screen — "Clinical Clarity" design system.
///
/// This is the entry route for every user. The selected role is only a UX
/// choice; all privileged access is resolved again from the authenticated
/// Firebase UID after Google sign-in.
///
/// When a Firebase session already exists, the last used experience is resumed
/// automatically so patients and clinic staff are not asked to sign in again.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeResumeSession());
  }

  Future<void> _maybeResumeSession() async {
    if (AuthSessionStore.autoResumeAttempted) return;
    try {
      if (Firebase.apps.isEmpty) return;
      if (FirebaseAuth.instance.currentUser == null) return;
    } catch (_) {
      return;
    }

    AuthSessionStore.markAutoResumeAttempted();
    final role = await AuthSessionStore.loadRole();
    if (!mounted || role == null) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.authGate,
      arguments: AuthGateArgs(role: role),
    );
  }

  void _continueAs(AuthRole role) {
    unawaited(AuthSessionStore.saveRole(role));
    Navigator.of(context).pushNamed(
      role == AuthRole.admin ? AppRoutes.adminLogin : AppRoutes.patientLogin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: PatientColors.surface,
      body: Stack(
        children: [
          // Ambient brand accents, matching the patient login screen.
          Positioned(
            top: -90,
            right: -70,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: PatientColors.secondaryContainer.withValues(
                    alpha: 0.18,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: PatientColors.surfaceContainerHighest.withValues(
                    alpha: 0.55,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: LanguageToggle(compact: true),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBrand(l10n),
                      const SizedBox(height: 32),
                      _buildHeading(l10n),
                      const SizedBox(height: 24),
                      _RoleCard(
                        icon: Icons.person_rounded,
                        iconBackground: PatientColors.primaryFixed,
                        iconColor: PatientColors.primary,
                        title: l10n.t('patientRole'),
                        description: l10n.t('patientRoleDescription'),
                        buttonLabel: l10n.t('patientRoleButton'),
                        buttonColor: PatientColors.primary,
                        buttonKey: const Key('role_patient_button'),
                        onPressed: () => _continueAs(AuthRole.patient),
                      ),
                      const SizedBox(height: 16),
                      _RoleCard(
                        icon: Icons.medical_services_rounded,
                        iconBackground: PatientColors.secondaryFixed,
                        iconColor: PatientColors.secondary,
                        title: l10n.t('staffRole'),
                        description: l10n.t('staffRoleDescription'),
                        buttonLabel: l10n.t('staffRoleButton'),
                        buttonColor: PatientColors.secondary,
                        buttonKey: const Key('role_admin_button'),
                        onPressed: () => _continueAs(AuthRole.admin),
                      ),
                      const SizedBox(height: 24),
                      _buildFooter(context, l10n),
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

  Widget _buildBrand(AppLocalizations l10n) {
    return Column(
      children: [
        const BrandMark(size: 66, padding: 8, radius: 18),
        const SizedBox(height: 14),
        const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'EasyCheck',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: PatientColors.primary,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(width: 5),
              Text(
                'Online',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: PatientColors.secondary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.t('careConnected'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: PatientColors.onSurfaceVariant.withValues(alpha: 0.75),
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildHeading(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.t('roleHeading'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: PatientColors.primaryContainer,
            height: 1.3,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.t('roleSubtitle'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: PatientColors.onSurfaceVariant.withValues(alpha: 0.90),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_rounded,
              color: PatientColors.secondary,
              size: 15,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l10n.t('secureGoogleSignIn'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: PatientColors.onSurfaceVariant.withValues(alpha: 0.90),
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
            _LegalLink(
              label: l10n.t('privacyPolicy'),
              onTap: () => _openLegal(context, LegalDocument.privacy),
            ),
            const Text(
              '·',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: PatientColors.outline,
              ),
            ),
            _LegalLink(
              label: l10n.t('termsOfUse'),
              onTap: () => _openLegal(context, LegalDocument.terms),
            ),
          ],
        ),
      ],
    );
  }

  void _openLegal(BuildContext context, LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LegalScreen(document: document)),
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
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: PatientColors.onSurfaceVariant,
            decoration: TextDecoration.underline,
            decorationColor: Color(0x66434750),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String description;
  final String buttonLabel;
  final Color buttonColor;
  final Key buttonKey;
  final VoidCallback onPressed;

  const _RoleCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.buttonColor,
    required this.buttonKey,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PatientColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PatientColors.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF073B78).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: PatientColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: PatientColors.onSurfaceVariant.withValues(
                          alpha: 0.95,
                        ),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: FilledButton(
              key: buttonKey,
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: PatientColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
