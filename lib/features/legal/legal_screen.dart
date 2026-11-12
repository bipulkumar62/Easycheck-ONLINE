import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/brand_mark.dart';

enum LegalDocument { privacy, terms }

class LegalSection {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const LegalSection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });
}

/// Full-screen, readable legal document. Content is intentionally written for
/// patients and clinic staff, not for engineers: it explains what is collected,
/// why it is used, and how to exercise rights without naming internal vendors
/// or infrastructure.
class LegalScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalScreen({super.key, required this.document});

  bool get _isPrivacy => document == LegalDocument.privacy;

  String get _title => _isPrivacy ? 'Privacy Policy' : 'Terms of Use';

  String get _eyebrow =>
      _isPrivacy ? 'YOUR INFORMATION, EXPLAINED' : 'THE RULES OF THE SERVICE';

  String get _summary => _isPrivacy
      ? 'This policy explains what information EasyCheck Online collects, why '
            'we need it, who can see it, and the choices you have. We keep the '
            'language plain so you can make an informed decision about using the '
            'service.'
      : 'These terms explain the agreement between you and EasyCheck Online. '
            'They cover acceptable use, clinic-staff access, the limits of the '
            'service, and how disputes are handled. By using the service, you '
            'agree to these terms.';

  List<LegalSection> get _sections =>
      _isPrivacy ? _privacySections : _termsSections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientColors.surface,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: PatientColors.secondaryContainer.withValues(
                    alpha: 0.14,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          SafeArea(
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
                              _buildSection(_sections[i], i + 1),
                              const SizedBox(height: 12),
                            ],
                            _buildContactCard(),
                            const SizedBox(height: 24),
                            Text(
                              'EasyCheck Online · ${_isPrivacy ? 'Privacy Policy' : 'Terms of Use'} · '
                              'Last updated 12 November 2026',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                height: 1.5,
                                color: PatientColors.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
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
          Expanded(
            child: Text(
              _title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
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
          LayoutBuilder(
            builder: (context, constraints) {
              final icon = Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Icon(
                  _isPrivacy
                      ? Icons.shield_outlined
                      : Icons.description_outlined,
                  color: const Color(0xFF8CE8BC),
                  size: 21,
                ),
              );
              final datePill = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Text(
                  '5 NOV 2026',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Color(0xFFD7F8E7),
                  ),
                ),
              );
              final eyebrow = Text(
                _eyebrow,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Color(0xFF8CE8BC),
                ),
              );

              if (constraints.maxWidth < 320) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        icon,
                        const SizedBox(width: 11),
                        Flexible(child: datePill),
                      ],
                    ),
                    const SizedBox(height: 10),
                    eyebrow,
                  ],
                );
              }

              return Row(
                children: [
                  icon,
                  const SizedBox(width: 11),
                  Expanded(child: eyebrow),
                  datePill,
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            _title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: -0.6,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _summary,
            style: const TextStyle(
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

  Widget _buildSection(LegalSection section, int number) {
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
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PatientColors.secondary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: PatientColors.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PatientColors.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: PatientColors.secondary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.support_agent_rounded,
            color: PatientColors.secondary,
            size: 22,
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Questions or requests',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PatientColors.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Contact the EasyCheck support channel shown on the app '
                  'listing, or speak to your clinic administrator. Include the '
                  'email address linked to your account so we can locate your '
                  'record. We aim to respond within 30 days.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 1.6,
                    color: PatientColors.onSurfaceVariant,
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

const List<LegalSection> _privacySections = [
  LegalSection(
    title: 'Who this policy applies to',
    paragraphs: [
      'This policy applies to patients, clinic staff and administrators who '
          'use EasyCheck Online. It covers the patient portal, the clinic '
          'console, and the access-request process.',
      'A clinic may also have its own privacy notice. If a clinic notice and '
          'this policy differ, the clinic notice applies to the clinic\'s own '
          'records and this policy continues to apply to the EasyCheck service.',
    ],
  ),
  LegalSection(
    title: 'Information we collect',
    paragraphs: [
      'We collect only the information needed to run the service. The exact '
          'information depends on how you use EasyCheck.',
    ],
    bullets: [
      'Account details from your sign-in provider, such as your name, email '
          'address and profile photo.',
      'Clinic access-request details, including your name, contact number, '
          'the clinic you selected and the status of your request.',
      'Clinic and queue information, such as the clinic you follow, live '
          'parchi counts, doctor availability and timing.',
      'Technical information needed to keep the service secure and reliable, '
          'such as error logs, approximate device type and browser type.',
    ],
  ),
  LegalSection(
    title: 'How we use information',
    bullets: [
      'To sign you in and keep your session secure.',
      'To show live clinic availability, parchi counts and doctor timing.',
      'To review clinic-staff access requests and connect approved staff to '
          'the correct clinic.',
      'To maintain an audit trail of queue updates and protect against misuse.',
      'To respond to support requests, investigate problems and improve the '
          'clarity of the service.',
      'To meet legal, security and fraud-prevention obligations.',
    ],
  ),
  LegalSection(
    title: 'Why we are allowed to use it',
    paragraphs: [
      'We rely on the information you provide when you choose to use the '
          'service, the agreement between you and EasyCheck, our legitimate '
          'interest in operating a safe service, and legal obligations where '
          'they apply. Where consent is required, you can withdraw it at any '
          'time without affecting earlier lawful use.',
    ],
  ),
  LegalSection(
    title: 'Who can see information',
    paragraphs: [
      'We do not sell personal information. We share it only when there is a '
          'clear operational or legal reason.',
    ],
    bullets: [
      'The clinic you follow or work for, so it can manage its queue and '
          'confirm staff access.',
      'Trusted service providers who help us host, secure and support the '
          'service, under confidentiality and data-protection obligations.',
      'Authorities or other parties when required by law, or when necessary '
          'to protect the safety and rights of users, clinics or the public.',
      'A successor organisation if the service is transferred, subject to '
          'equivalent privacy protections.',
    ],
  ),
  LegalSection(
    title: 'How long we keep information',
    paragraphs: [
      'We keep account and clinic records for as long as your account is '
          'active or as needed to provide the service. Queue audit records are '
          'kept for a limited operational period. When information is no longer '
          'needed, we delete it or remove the details that identify you, unless '
          'a longer period is required by law or for security investigations.',
    ],
  ),
  LegalSection(
    title: 'How we protect information',
    paragraphs: [
      'We use encryption in transit, access controls, least-privilege '
          'authorisation and audit records to protect the service. Clinic '
          'staff can see clinic information only after their membership or '
          'ownership is verified. No system is completely secure, so please use '
          'a strong, unique password for your sign-in account and keep your '
          'device protected.',
    ],
  ),
  LegalSection(
    title: 'Your choices and rights',
    paragraphs: [
      'Depending on where you live, you may have the right to access, correct, '
          'delete, restrict or object to the use of your information, and to '
          'receive a copy of it. You may also have the right to complain to your '
          'local data-protection authority.',
      'To make a request, use the contact details below. We may need to verify '
          'your identity before acting. Deleting your account may remove access '
          'to the patient portal, but clinic audit records may be retained where '
          'the law or security needs require it.',
    ],
  ),
  LegalSection(
    title: 'Children and young patients',
    paragraphs: [
      'EasyCheck is intended for adults and for young patients using the '
          'service with a parent or guardian. We do not knowingly collect '
          'personal information from a child without appropriate involvement '
          'of a parent, guardian or clinic. If you believe a child has provided '
          'information without consent, contact us so we can review it.',
    ],
  ),
  LegalSection(
    title: 'International processing',
    paragraphs: [
      'The service may use providers in different countries. Where information '
          'is transferred across borders, we use appropriate safeguards and '
          'require providers to protect it consistently with this policy.',
    ],
  ),
  LegalSection(
    title: 'Changes to this policy',
    paragraphs: [
      'We may update this policy when the service changes or the law requires '
          'it. The updated version will show a new date at the top. If a change '
          'materially affects your rights, we will provide a clear notice in the '
          'app or by email before it takes effect.',
    ],
  ),
  LegalSection(
    title: 'Contact',
    paragraphs: [
      'For privacy questions or requests, contact the EasyCheck support '
          'channel shown on the app listing or speak to your clinic '
          'administrator. Please include the email address linked to your '
          'account. We aim to respond within 30 days.',
    ],
  ),
];

const List<LegalSection> _termsSections = [
  LegalSection(
    title: 'Acceptance of these terms',
    paragraphs: [
      'These Terms of Use govern your access to and use of EasyCheck Online. '
          'By creating an account, signing in or using the service, you agree '
          'to these terms. If you do not agree, do not use the service.',
    ],
  ),
  LegalSection(
    title: 'What EasyCheck does',
    paragraphs: [
      'EasyCheck helps patients see clinic availability, live parchi counts and '
          'doctor timing, and helps authorised clinic staff manage a queue. '
          'EasyCheck is an operational information tool. It is not a hospital, '
          'a medical practice, an emergency service or a substitute for '
          'professional medical advice, diagnosis or treatment.',
    ],
  ),
  LegalSection(
    title: 'Who may use the service',
    paragraphs: [
      'You must be old enough to form a binding agreement in your jurisdiction, '
          'or use the service with the involvement of a parent or guardian. You '
          'must provide accurate account information and use the service only '
          'for lawful purposes.',
    ],
  ),
  LegalSection(
    title: 'Your account and sign-in',
    paragraphs: [
      'You are responsible for activity carried out through your account and '
          'for keeping access to your sign-in account secure. Do not share your '
          'sign-in credentials or let another person use your session. Tell us '
          'promptly if you believe your account has been compromised.',
    ],
  ),
  LegalSection(
    title: 'Clinic-staff access',
    paragraphs: [
      'Clinic dashboards are available only to staff whose membership or '
          'ownership has been verified. Submitting an access request does not '
          'grant access. A clinic administrator or authorised reviewer must '
          'approve the request before the dashboard opens.',
      'You must request access only for a clinic you genuinely work for. '
          'Providing false details, impersonating another person or attempting '
          'to access another clinic\'s records is a serious breach of these '
          'terms and may result in suspension and legal action.',
    ],
  ),
  LegalSection(
    title: 'Acceptable use',
    bullets: [
      'Do not attempt to access accounts, clinics or records you are not '
          'authorised to use.',
      'Do not interfere with the service, probe its security, or introduce '
          'malicious code.',
      'Do not scrape, copy or resell clinic or patient information.',
      'Do not use the service to harass, discriminate against or endanger '
          'another person.',
      'Do not rely on the service for emergency care. Contact local emergency '
          'services or the clinic directly when urgent help is needed.',
    ],
  ),
  LegalSection(
    title: 'Clinic information and availability',
    paragraphs: [
      'Live counts, doctor availability and timing are supplied by clinics and '
          'may change without notice. We work to keep the information accurate '
          'and current, but we cannot guarantee that every update is immediate '
          'or error-free. Always confirm important details directly with the '
          'clinic before travelling or making a health decision.',
    ],
  ),
  LegalSection(
    title: 'Service changes and downtime',
    paragraphs: [
      'We may add, change, suspend or discontinue parts of the service. We aim '
          'to give reasonable notice of material changes, but maintenance, '
          'network problems or security incidents may cause temporary '
          'unavailability. We do not guarantee uninterrupted access.',
    ],
  ),
  LegalSection(
    title: 'Intellectual property',
    paragraphs: [
      'The EasyCheck name, logo, interface and content are protected by '
          'intellectual-property laws. We grant you a limited, non-exclusive, '
          'non-transferable right to use the service for its intended purpose. '
          'You may not copy, modify, distribute or create derivative works from '
          'the service without written permission, except where the law allows.',
    ],
  ),
  LegalSection(
    title: 'Third-party services',
    paragraphs: [
      'The service uses trusted third-party providers for sign-in, hosting, '
          'security and communications. Their terms and privacy notices may '
          'also apply. We are not responsible for third-party services that we '
          'do not control, but we choose providers with appropriate safeguards.',
    ],
  ),
  LegalSection(
    title: 'Disclaimers',
    paragraphs: [
      'To the maximum extent permitted by law, the service is provided "as is" '
          'and "as available". We disclaim implied warranties of merchantability, '
          'fitness for a particular purpose and non-infringement. Nothing in '
          'these terms excludes a warranty or right that cannot lawfully be '
          'excluded.',
    ],
  ),
  LegalSection(
    title: 'Limitation of liability',
    paragraphs: [
      'To the maximum extent permitted by law, EasyCheck is not liable for '
          'indirect, incidental, special or consequential loss, or for loss of '
          'data, profits or goodwill arising from your use of the service. Our '
          'total liability for a claim relating to the service will not exceed '
          'the amount you paid us for the service in the 12 months before the '
          'claim, or the minimum amount required by law. Nothing in these terms '
          'limits liability for fraud, wilful misconduct or death or personal '
          'injury caused by negligence where the law does not allow it.',
    ],
  ),
  LegalSection(
    title: 'Suspension and termination',
    paragraphs: [
      'We may suspend or terminate access if you breach these terms, if we are '
          'required to do so by law, or if your use creates a security or safety '
          'risk. You may stop using the service at any time. Provisions that by '
          'their nature should survive termination, including ownership, '
          'disclaimers and liability limits, will continue to apply.',
    ],
  ),
  LegalSection(
    title: 'Governing law and disputes',
    paragraphs: [
      'These terms are governed by the laws applicable in the jurisdiction where '
          'the service is provided, without regard to conflict-of-law rules. '
          'Before starting formal proceedings, please contact us so we can try '
          'to resolve the issue informally. Nothing in this section prevents you '
          'from using a mandatory consumer-protection process available in your '
          'country.',
    ],
  ),
  LegalSection(
    title: 'Changes to these terms',
    paragraphs: [
      'We may update these terms to reflect changes to the service or the law. '
          'The updated version will show a new date at the top. If a change '
          'materially affects your rights, we will provide clear notice before '
          'it takes effect. Continued use after the effective date means you '
          'accept the updated terms.',
    ],
  ),
  LegalSection(
    title: 'Contact',
    paragraphs: [
      'For questions about these terms, contact the EasyCheck support channel '
          'shown on the app listing or speak to your clinic administrator.',
    ],
  ),
];
