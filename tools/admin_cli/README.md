# EasyCheck Trusted Operations CLI

This is the trusted operator tool for actions the mobile app is not allowed to
perform: approving access requests, provisioning clinic memberships, creating
clinics, offboarding staff, and removing the legacy `adminUid` field from clinic
documents.

It uses the Firebase Admin SDK locally. It is **not** part of the Android app and
is never bundled into the APK or AAB.

## 1. One-time setup

1. Open the Firebase Console for the EasyCheck project.
2. Go to **Project settings → Service accounts**.
3. Click **Generate new private key** and download the JSON file.
4. Keep that file outside source control. Recommended location:

   ```text
   C:\Users\<you>\secrets\easycheck-service-account.json
   ```

5. Install the CLI dependencies:

   ```powershell
   cd "D:\Easycheck ONLINE\tools\admin_cli"
   npm install
   ```

6. Set the environment variable for the current PowerShell session:

   ```powershell
   $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\Users\<you>\secrets\easycheck-service-account.json"
   ```

Never commit the service account JSON. The repository ignores
`tools/admin_cli/service-account*.json` and `node_modules`.

## 2. Commands

```powershell
# See all pending access requests
node index.js list-requests --status pending

# Approve a request (the applicant must not be the actor)
node index.js approve "<requestId>" --by "<operatorUid>" --role clinic_admin --reason "Verified clinic ownership"

# Reject a request (reason must be at least 10 characters)
node index.js reject "<requestId>" --by "<operatorUid>" --reason "Clinic details could not be verified"

# Create a real clinic and its first admin in one step
node index.js create-clinic --id CLN-84923 --name "City Care Clinic" --city "Patna" --region "Bihar" --phone "+91..." --email "clinic@example.com" --admin-uid "<adminUid>" --by "<operatorUid>" --doctor-name "Dr. ..." --doctor-timing "Mon-Sat · 9:00 AM – 5:00 PM"

# Add or update a staff membership
node index.js add-member --uid "<uid>" --clinic CLN-84923 --by "<operatorUid>" --role front_desk_lead

# Offboard a staff member (last-admin protection is enforced)
node index.js remove-member --uid "<uid>" --clinic CLN-84923 --by "<operatorUid>" --reason "Left the clinic"

# Hide a clinic from patients without deleting history
node index.js deactivate-clinic CLN-84920 --by "<operatorUid>" --reason "Demo clinic retired"

# Remove the legacy staff identifier from every clinic document
node index.js cleanup-admin-uid --by "<operatorUid>"

# Inspect data
node index.js list-clinics
node index.js list-members --clinic CLN-84923
node index.js list-users --limit 100
```

## 3. Safety rules enforced by the CLI

- Self-approval and self-review are rejected.
- The last active clinic admin of a clinic cannot be removed.
- A clinic cannot be created with an ID that already exists.
- A clinic is created without the legacy `adminUid` field.
- Every mutation writes an append-only entry to `admin_audit_log`.
- The CLI never runs from the mobile app and never exposes a privileged write to
  the browser.

## 4. First-clinic checklist

1. The clinic owner signs in once with their own Google account in the app
   (Doctor / Staff).
2. Copy their UID from **Authentication → Users**.
3. Run `create-clinic` with that UID.
4. Ask them to sign out and sign in again.
5. Confirm the dashboard opens, doctor timing is visible to patients, and queue
   actions work.
6. Run `cleanup-admin-uid` once to remove the legacy field from existing
   documents.
7. Deactivate the demo clinics before real patients use the app.
