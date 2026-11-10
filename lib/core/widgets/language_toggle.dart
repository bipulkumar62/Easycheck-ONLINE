import 'package:flutter/material.dart';

import '../../app/localization/locale_controller.dart';

/// Compact Hindi/English switch used across the patient and clinic surfaces.
///
/// One tap changes the whole app language and the choice is persisted. The
/// [onDark] variant is for navy panels; the default variant follows the active
/// Material theme so it also works inside the clinic-admin experience.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, this.compact = false, this.onDark = false});

  final bool compact;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LocaleController.instance,
      builder: (context, _) {
        final isHindi = LocaleController.instance.isHindi;
        final scheme = Theme.of(context).colorScheme;
        final selectedBackground = onDark
            ? Colors.white.withValues(alpha: 0.92)
            : scheme.primary;
        final selectedForeground = onDark
            ? const Color(0xFF002553)
            : scheme.onPrimary;
        final idleForeground = onDark
            ? Colors.white.withValues(alpha: 0.78)
            : scheme.onSurfaceVariant;
        final track = onDark
            ? Colors.white.withValues(alpha: 0.10)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.72);
        final border = onDark
            ? Colors.white.withValues(alpha: 0.16)
            : scheme.outlineVariant.withValues(alpha: 0.55);

        Widget option(String code, String label) {
          final selected =
              (code == 'hi' && isHindi) || (code == 'en' && !isHindi);
          return Semantics(
            button: true,
            selected: selected,
            label: code == 'hi' ? 'हिंदी' : 'English',
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => LocaleController.instance.setLocale(Locale(code)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 11,
                  vertical: compact ? 5 : 6,
                ),
                decoration: BoxDecoration(
                  color: selected ? selectedBackground : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: compact ? 10 : 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? selectedForeground : idleForeground,
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: track,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              option('hi', compact ? 'हिं' : 'हिंदी'),
              option('en', 'EN'),
            ],
          ),
        );
      },
    );
  }
}
