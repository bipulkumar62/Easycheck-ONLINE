/// Supabase is used only for public doctor photos.
///
/// Authentication, Firestore, Hosting, Crashlytics and App Check stay on
/// Firebase. The app never holds a Supabase service key: the Edge Function
/// verifies the Firebase ID token and the Firestore clinic membership before
/// it writes to the photo bucket.
class SupabaseConfig {
  const SupabaseConfig._();

  static const String projectUrl = 'https://oeyetcapghqibcqkcued.supabase.co';

  static Uri get clinicPhotoEndpoint =>
      Uri.parse('$projectUrl/functions/v1/clinic-photo');
}
