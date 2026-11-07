/// Common utility helpers for format transformations.
class AppUtils {
  AppUtils._();

  /// Formats sequential token display string (e.g. 12 -> "Seq: P-012").
  static String formatTokenSequence(int tokenNumber) {
    return 'Seq: P-${tokenNumber.toString().padLeft(3, '0')}';
  }
}
