import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/brand_mark.dart';
import 'legal_screen.dart';

/// Plain-language product information for patients and clinic teams.
///
/// This screen deliberately describes behaviour, not infrastructure. Vendor
/// names, internal identifiers, keys and server details must never appear here.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _version = '1.0.0 (1)';
  static const String _updated = '8 November 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHero(),
                        const SizedBox(height: 18),
                        for (var i = 0; i < _sections.length; i++) ...[
                          _buildSection(_sections[i]),
                          const SizedBox(height: 12),
                        ],
                        _buildFooter(context),
                      ],
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

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: PatientColors.primary,
            ),
          ),
          const BrandMark(size: 34, padding: 4, radius: 10),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'About EasyCheck',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: PatientColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF002553), Color(0xFF073B78)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: PatientColors.primary.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandMark(size: 48, padding: 6, radius: 14),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EASYCHECK',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xFF8CE8BC),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'EasyCheck Online',
                      maxLines: 2,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: -0.4,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Real-time outpatient and parchi tracking for patients and clinic '
            'teams. See doctor availability, follow the live queue and reach '
            'the right clinic with less uncertainty.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              height: 1.65,
              color: Color(0xE6FFFFFF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(_AboutSection section) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PatientColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: PatientColors.outlineVariant.withValues(alpha: 0.40),
        ),
        boxShadow: [
          BoxShadow(
            color: PatientColors.primary.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PatientColors.secondary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  section.icon,
                  size: 17,
                  color: PatientColors.secondary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: PatientColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (section.paragraphs.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final paragraph in section.paragraphs) ...[
              Text(
                paragraph,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 1.65,
                  color: PatientColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          if (section.bullets.isNotEmpty) ...[
            const SizedBox(height: 2),
            for (final bullet in section.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: PatientColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
                          height: 1.6,
                          color: PatientColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PatientColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: PatientColors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: PatientColors.primary,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'App information',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PatientColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Version $_version. Last updated $_updated.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.6,
              color: PatientColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const LegalScreen(document: LegalDocument.privacy),
                  ),
                ),
                child: const Text('Privacy Policy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const LegalScreen(document: LegalDocument.terms),
                  ),
                ),
                child: const Text('Terms of Use'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'EasyCheck Online is an outpatient queue and clinic-discovery '
            'service. It does not provide medical advice, diagnosis or '
            'treatment. In a medical emergency in India, call 112 or go to the '
            'nearest emergency department.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.6,
              color: PatientColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutSection {
  final IconData icon;
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const _AboutSection({
    required this.icon,
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });
}

const List<_AboutSection> _sections = [
  _AboutSection(
    icon: Icons.medical_services_outlined,
    title: 'What EasyCheck does',
    paragraphs: [
      'EasyCheck Online connects patients with registered clinics through a '
          'live outpatient (OPD) and parchi queue. It is designed for everyday '
          'clinic visits, not for emergency care.',
      'Patients can check a clinic before travelling. Clinic teams can keep '
          'the queue, doctor availability and front-desk work in one place.',
    ],
  ),
  _AboutSection(
    icon: Icons.person_search_rounded,
    title: 'For patients',
    bullets: [
      'Find a registered clinic by clinic name, doctor, specialty or area.',
      'See whether the doctor is available, delayed or off duty before you '
          'leave home.',
      'Follow the live parchi count and the doctor\'s timing for the clinic.',
      'Open clinic details for the address and the current queue state.',
      'Sign in with Google to keep your patient profile and account secure.',
    ],
  ),
  _AboutSection(
    icon: Icons.groups_2_outlined,
    title: 'For clinic teams',
    bullets: [
      'Run the live parchi counter and pause or reset the queue when the '
          'session changes.',
      'Record patient intake and manage front-desk, staff and clinic-admin '
          'roles for the clinic.',
      'Set doctor availability and timing so patients see an honest status.',
      'Add or change the doctor photo through a verified, server-checked '
          'upload.',
      'Keep clinic records separate: staff can only open clinics they are '
          'active members of.',
    ],
  ),
  _AboutSection(
    icon: Icons.verified_user_outlined,
    title: 'Accounts and access',
    paragraphs: [
      'Patients sign in with Google. Clinic staff request access, and a super '
          'administrator reviews the request and assigns the correct clinic.',
      'Clinic data is restricted by server-side security rules. A clinic '
          'cannot read or change another clinic\'s queue, staff list or '
          'profile.',
      'Super-administrator access is controlled by a verified account claim, '
          'not by an email address, phone number or a role written in a '
          'document.',
    ],
  ),
  _AboutSection(
    icon: Icons.lock_outline_rounded,
    title: 'Privacy and your data',
    paragraphs: [
      'EasyCheck collects only the information needed to run the service: '
          'account details from sign-in, clinic access-request details, and '
          'clinic and queue information. We do not sell patient or clinic '
          'data.',
      'You can delete your patient account from Settings. Some clinic audit '
          'records may be retained where required for clinic safety or by law. '
          'The full Privacy Policy and Terms of Use are available from '
          'Settings and from the links below.',
    ],
  ),
  _AboutSection(
    icon: Icons.health_and_safety_outlined,
    title: 'Safety',
    paragraphs: [
      'EasyCheck helps you find a clinic and follow its queue. It does not '
          'provide medical advice, diagnosis or treatment, and a live queue '
          'count is not a promise of a consultation time.',
      'If you have a medical emergency in India, call 112 or go to the '
          'nearest emergency department instead of waiting for an app update.',
    ],
  ),
];
