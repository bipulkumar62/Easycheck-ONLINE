#!/usr/bin/env node
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { cert, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || 'easycheck-online';
const KEY_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS;

function fail(message) {
  console.error(`\nError: ${message}\n`);
  process.exit(1);
}

if (!KEY_PATH) {
  fail(
    'Set GOOGLE_APPLICATION_CREDENTIALS to the service account JSON file path.',
  );
}

let credentials;
try {
  credentials = JSON.parse(readFileSync(resolve(KEY_PATH), 'utf8'));
} catch (error) {
  fail(`Could not read the service account file: ${error.message}`);
}

initializeApp({ credential: cert(credentials), projectId: PROJECT_ID });

const db = getFirestore();
const auth = getAuth();

const args = process.argv.slice(2);
const command = args[0];

function flag(name, fallback = null) {
  const index = args.indexOf(`--${name}`);
  return index >= 0 && args[index + 1] ? args[index + 1] : fallback;
}

function hasFlag(name) {
  return args.includes(`--${name}`);
}

function required(name) {
  const value = flag(name);
  if (!value) fail(`Missing --${name}`);
  return value;
}

function list(value) {
  return value
    ? value
        .split(',')
        .map((item) => item.trim())
        .filter(Boolean)
    : [];
}

function timestamp(value) {
  return value?.toDate ? value.toDate().toISOString() : null;
}

const ALL_PERMISSIONS = [
  'update_tally',
  'update_status',
  'reset_tally',
  'manage_staff',
  'view_queue',
];

const ROLE_PERMISSIONS = {
  clinic_admin: ALL_PERMISSIONS,
  front_desk_lead: ['update_tally', 'update_status', 'reset_tally', 'view_queue'],
  triage_coordinator: ['update_status', 'view_queue'],
};

function permissionsFor(role, raw) {
  if (raw) return list(raw);
  if (!ROLE_PERMISSIONS[role]) fail(`Unknown role: ${role}`);
  return ROLE_PERMISSIONS[role];
}

function membershipId(uid, clinicId) {
  return `${uid}_${clinicId}`;
}

function writeAudit(transaction, entry) {
  const ref = db.collection('admin_audit_log').doc();
  transaction.set(ref, {
    ...entry,
    createdAt: FieldValue.serverTimestamp(),
  });
}

async function requireActor() {
  const actor = required('by');
  try {
    await auth.getUser(actor);
  } catch {
    fail(`Actor ${actor} is not a valid account.`);
  }
  return actor;
}

async function requireActiveClinic(clinicId) {
  const snapshot = await db.collection('clinics').doc(clinicId).get();
  if (!snapshot.exists) fail(`Clinic ${clinicId} was not found.`);
  if (snapshot.data().isActive !== true) fail(`Clinic ${clinicId} is inactive.`);
  return snapshot.data();
}

function printHelp() {
  console.log(`
EasyCheck trusted operations CLI

Required environment:
  GOOGLE_APPLICATION_CREDENTIALS   Path to the service account JSON
  FIREBASE_PROJECT_ID              Optional, defaults to easycheck-online

Commands:
  list-requests [--status pending|approved|rejected] [--limit 100]
  approve <requestId> --by <uid> [--role clinic_admin] [--permissions a,b] [--reason "..."]
  reject <requestId> --by <uid> --reason "..."
  add-member --uid <uid> --clinic <clinicId> --by <uid> [--role ...] [--permissions a,b] [--force]
  remove-member --uid <uid> --clinic <clinicId> --by <uid> --reason "..."
  list-members --clinic <clinicId>
  create-clinic --id <CLN-xxxxx> --name "..." --city "..." --region "..." --phone "..." --email "..." --admin-uid <uid> --by <uid> [--doctor-name "..."] [--doctor-timing "..."]
  deactivate-clinic <clinicId> --by <uid> --reason "..."
  list-clinics
  list-users [--limit 100]
  cleanup-admin-uid

Safety:
  - Self-approval is rejected.
  - The last active clinic admin cannot be removed.
  - Every mutation writes an append-only audit entry.
  - No command runs from the mobile app.
`);
}

async function main() {
  switch (command) {
    case 'list-requests': {
      const status = flag('status');
      let query = db.collection('admin_access_requests');
      if (status) query = query.where('status', '==', status);
      const snapshot = await query.limit(Number(flag('limit', '100'))).get();
      const rows = snapshot.docs
        .map((doc) => ({
          id: doc.id,
          ...doc.data(),
          createdAt: timestamp(doc.data().createdAt),
        }))
        .sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
      if (rows.length === 0) {
        console.log('No access requests found.');
        return;
      }
      for (const row of rows) {
        console.log(
          `${row.id} | ${row.status} | ${row.displayName || ''} <${row.email || ''}> | ${row.requestedClinicId} | ${row.createdAt || ''}`,
        );
      }
      return;
    }

    case 'approve': {
      const requestId = args[1];
      if (!requestId) {
        fail(
          'Usage: approve <requestId> --by <uid> [--role clinic_admin] [--permissions a,b] [--reason "..."]',
        );
      }
      const actor = await requireActor();
      const role = flag('role', 'clinic_admin');
      const permissions = permissionsFor(role, flag('permissions'));
      const reason = flag('reason', '');

      await db.runTransaction(async (transaction) => {
        const requestRef = db
          .collection('admin_access_requests')
          .doc(requestId);
        const requestSnapshot = await transaction.get(requestRef);
        if (!requestSnapshot.exists) fail('Access request not found.');

        const request = requestSnapshot.data();
        if (request.status !== 'pending') {
          fail(`Request is already ${request.status}.`);
        }
        if (request.uid === actor) {
          fail('Self-approval is not allowed.');
        }

        const clinicRef = db.collection('clinics').doc(request.requestedClinicId);
        const clinicSnapshot = await transaction.get(clinicRef);
        if (!clinicSnapshot.exists) fail('Clinic not found.');
        if (clinicSnapshot.data().isActive !== true) {
          fail('Clinic is inactive.');
        }

        const memberRef = db
          .collection('clinic_members')
          .doc(membershipId(request.uid, request.requestedClinicId));
        const memberSnapshot = await transaction.get(memberRef);

        transaction.update(requestRef, {
          status: 'approved',
          reviewedBy: actor,
          reviewedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          rejectionReason: null,
        });

        const membership = {
          userId: request.uid,
          clinicId: request.requestedClinicId,
          role,
          permissions,
          isActive: true,
          assignedBy: actor,
        };
        if (!memberSnapshot.exists) {
          membership.joinedAt = FieldValue.serverTimestamp();
        }
        transaction.set(memberRef, membership, { merge: true });

        writeAudit(transaction, {
          actor,
          action: 'access_request.approved',
          entityType: 'request',
          entityId: requestId,
          clinicId: request.requestedClinicId,
          before: { status: request.status },
          after: { status: 'approved', role, permissions },
          reason,
        });
      });

      console.log(`Approved ${requestId}. Clinic membership is now active.`);
      return;
    }

    case 'reject': {
      const requestId = args[1];
      if (!requestId) {
        fail('Usage: reject <requestId> --by <uid> --reason "..."');
      }
      const actor = await requireActor();
      const reason = required('reason');
      if (reason.trim().length < 10) {
        fail('Rejection reason must be at least 10 characters.');
      }

      await db.runTransaction(async (transaction) => {
        const requestRef = db
          .collection('admin_access_requests')
          .doc(requestId);
        const requestSnapshot = await transaction.get(requestRef);
        if (!requestSnapshot.exists) fail('Access request not found.');

        const request = requestSnapshot.data();
        if (request.status !== 'pending') {
          fail(`Request is already ${request.status}.`);
        }
        if (request.uid === actor) {
          fail('Self-review is not allowed.');
        }

        transaction.update(requestRef, {
          status: 'rejected',
          reviewedBy: actor,
          reviewedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          rejectionReason: reason.trim(),
        });

        writeAudit(transaction, {
          actor,
          action: 'access_request.rejected',
          entityType: 'request',
          entityId: requestId,
          clinicId: request.requestedClinicId,
          before: { status: request.status },
          after: { status: 'rejected', reason: reason.trim() },
          reason: reason.trim(),
        });
      });

      console.log(`Rejected ${requestId}.`);
      return;
    }

    case 'add-member': {
      const uid = required('uid');
      const clinicId = required('clinic');
      const actor = await requireActor();
      const role = flag('role', 'clinic_admin');
      const permissions = permissionsFor(role, flag('permissions'));
      const reason = flag('reason', '');
      await requireActiveClinic(clinicId);

      try {
        await auth.getUser(uid);
      } catch {
        fail(`Account ${uid} was not found. The person must sign in once.`);
      }

      await db.runTransaction(async (transaction) => {
        const memberRef = db
          .collection('clinic_members')
          .doc(membershipId(uid, clinicId));
        const memberSnapshot = await transaction.get(memberRef);
        if (
          memberSnapshot.exists &&
          memberSnapshot.data().isActive === true &&
          !hasFlag('force')
        ) {
          fail('An active membership already exists. Use --force to update it.');
        }

        const membership = {
          userId: uid,
          clinicId,
          role,
          permissions,
          isActive: true,
          assignedBy: actor,
        };
        if (!memberSnapshot.exists) {
          membership.joinedAt = FieldValue.serverTimestamp();
        }
        transaction.set(memberRef, membership, { merge: true });

        writeAudit(transaction, {
          actor,
          action: 'membership.upserted',
          entityType: 'membership',
          entityId: membershipId(uid, clinicId),
          clinicId,
          before: memberSnapshot.exists ? memberSnapshot.data() : null,
          after: { role, permissions, isActive: true },
          reason,
        });
      });

      console.log(`Membership ${membershipId(uid, clinicId)} is active.`);
      return;
    }

    case 'remove-member': {
      const uid = required('uid');
      const clinicId = required('clinic');
      const actor = await requireActor();
      const reason = required('reason');

      await db.runTransaction(async (transaction) => {
        const memberRef = db
          .collection('clinic_members')
          .doc(membershipId(uid, clinicId));
        const memberSnapshot = await transaction.get(memberRef);
        if (!memberSnapshot.exists || memberSnapshot.data().isActive !== true) {
          fail('Active membership not found.');
        }

        const member = memberSnapshot.data();
        if (member.role === 'clinic_admin') {
          const admins = await transaction.get(
            db
              .collection('clinic_members')
              .where('clinicId', '==', clinicId)
              .where('role', '==', 'clinic_admin')
              .where('isActive', '==', true),
          );
          if (admins.size <= 1) {
            fail(
              'Cannot remove the last active clinic admin. Add another admin first.',
            );
          }
        }

        transaction.update(memberRef, {
          isActive: false,
          updatedAt: FieldValue.serverTimestamp(),
        });

        writeAudit(transaction, {
          actor,
          action: 'membership.deactivated',
          entityType: 'membership',
          entityId: membershipId(uid, clinicId),
          clinicId,
          before: { role: member.role, isActive: true },
          after: { isActive: false },
          reason,
        });
      });

      console.log(`Membership ${membershipId(uid, clinicId)} is inactive.`);
      return;
    }

    case 'list-members': {
      const clinicId = required('clinic');
      const snapshot = await db
        .collection('clinic_members')
        .where('clinicId', '==', clinicId)
        .where('isActive', '==', true)
        .get();
      if (snapshot.empty) {
        console.log('No active members found.');
        return;
      }
      for (const doc of snapshot.docs) {
        const data = doc.data();
        console.log(
          `${data.userId} | ${data.role} | ${(data.permissions || []).join(',')} | joined ${timestamp(data.joinedAt) || ''}`,
        );
      }
      return;
    }

    case 'create-clinic': {
      const clinicId = required('id');
      if (!/^CLN-[0-9]{5}$/.test(clinicId)) {
        fail('Clinic ID must match CLN- followed by exactly five digits.');
      }
      const name = required('name');
      const city = required('city');
      const region = required('region');
      const phone = required('phone');
      const email = required('email');
      const adminUid = required('admin-uid');
      const actor = await requireActor();
      const reason = flag('reason', 'Clinic onboarding');

      try {
        await auth.getUser(adminUid);
      } catch {
        fail(`Admin account ${adminUid} was not found. The person must sign in once.`);
      }

      await db.runTransaction(async (transaction) => {
        const clinicRef = db.collection('clinics').doc(clinicId);
        const clinicSnapshot = await transaction.get(clinicRef);
        if (clinicSnapshot.exists) fail(`Clinic ${clinicId} already exists.`);

        transaction.set(clinicRef, {
          name,
          address: flag('address', ''),
          city,
          region,
          phone,
          email,
          description: flag('description', ''),
          isActive: true,
          isOnline: false,
          doctorName: flag('doctor-name', ''),
          doctorCredentials: flag('doctor-credentials', ''),
          doctorSpecialty: flag('doctor-specialty', ''),
          doctorPhotoUrl: '',
          doctorStatus: 'offDuty',
          doctorTiming: flag('doctor-timing', ''),
          todayParchiCount: 0,
          yesterdayParchiCount: 0,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });

        const memberRef = db
          .collection('clinic_members')
          .doc(membershipId(adminUid, clinicId));
        transaction.set(memberRef, {
          userId: adminUid,
          clinicId,
          role: 'clinic_admin',
          permissions: ALL_PERMISSIONS,
          isActive: true,
          joinedAt: FieldValue.serverTimestamp(),
          assignedBy: actor,
        });

        writeAudit(transaction, {
          actor,
          action: 'clinic.created',
          entityType: 'clinic',
          entityId: clinicId,
          clinicId,
          before: null,
          after: { name, city, region, primaryAdmin: adminUid },
          reason,
        });
      });

      console.log(`Clinic ${clinicId} created and ${adminUid} is its admin.`);
      return;
    }

    case 'deactivate-clinic': {
      const clinicId = args[1];
      if (!clinicId) {
        fail('Usage: deactivate-clinic <clinicId> --by <uid> --reason "..."');
      }
      const actor = await requireActor();
      const reason = required('reason');

      await db.runTransaction(async (transaction) => {
        const clinicRef = db.collection('clinics').doc(clinicId);
        const clinicSnapshot = await transaction.get(clinicRef);
        if (!clinicSnapshot.exists) fail('Clinic not found.');

        transaction.update(clinicRef, {
          isActive: false,
          isOnline: false,
          updatedAt: FieldValue.serverTimestamp(),
        });

        writeAudit(transaction, {
          actor,
          action: 'clinic.deactivated',
          entityType: 'clinic',
          entityId: clinicId,
          clinicId,
          before: { isActive: clinicSnapshot.data().isActive },
          after: { isActive: false },
          reason,
        });
      });

      console.log(`Clinic ${clinicId} is now inactive and hidden from patients.`);
      return;
    }

    case 'list-clinics': {
      const snapshot = await db.collection('clinics').get();
      if (snapshot.empty) {
        console.log('No clinics found.');
        return;
      }
      for (const doc of snapshot.docs) {
        const data = doc.data();
        console.log(
          `${doc.id} | ${data.name} | ${data.city || ''} | active=${data.isActive} | online=${data.isOnline}`,
        );
      }
      return;
    }

    case 'list-users': {
      const result = await auth.listUsers(Number(flag('limit', '100')));
      if (result.users.length === 0) {
        console.log('No accounts found.');
        return;
      }
      for (const user of result.users) {
        console.log(
          `${user.uid} | ${user.email || ''} | ${user.displayName || ''} | disabled=${user.disabled}`,
        );
      }
      return;
    }

    case 'cleanup-admin-uid': {
      const actor = await requireActor();
      const snapshot = await db.collection('clinics').get();
      let removed = 0;
      for (const doc of snapshot.docs) {
        if (!Object.prototype.hasOwnProperty.call(doc.data(), 'adminUid')) {
          continue;
        }
        await doc.ref.update({
          adminUid: FieldValue.delete(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        await db.collection('admin_audit_log').add({
          actor,
          action: 'clinic.admin_uid_removed',
          entityType: 'clinic',
          entityId: doc.id,
          clinicId: doc.id,
          before: { adminUid: 'present' },
          after: { adminUid: 'removed' },
          reason: 'Remove staff identifier from a patient-readable document',
          createdAt: FieldValue.serverTimestamp(),
        });
        removed += 1;
      }
      console.log(`Removed the adminUid field from ${removed} clinic document(s).`);
      return;
    }

    case 'help':
    case '--help':
    case undefined:
      printHelp();
      return;

    default:
      fail(`Unknown command: ${command}. Run with --help for usage.`);
  }
}

main().catch((error) => {
  console.error(`\nOperation failed: ${error.message}\n`);
  process.exit(1);
});
