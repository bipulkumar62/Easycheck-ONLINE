import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easycheck_online/features/clinics/queue_session_model.dart';
import 'package:easycheck_online/core/errors/app_failure.dart';

class QueueRepository {
  FirebaseFirestore? _firestore;

  FirebaseFirestore? get _fs {
    if (_firestore == null) {
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (_) {
        // Firebase not initialized (e.g. UI-only mode / tests).
        return null;
      }
    }
    return _firestore;
  }

  CollectionReference<Map<String, dynamic>>? _sessionsCollection() {
    final fs = _fs;
    if (fs == null) return null;
    return fs.collection('queue_sessions');
  }

  CollectionReference<Map<String, dynamic>>? _historyCollection() {
    final fs = _fs;
    if (fs == null) return null;
    return fs.collection('queue_history');
  }

  String _sessionId(String clinicId, String date) => '${clinicId}_$date';

  Future<QueueSessionModel?> getSession(String clinicId, String date) async {
    try {
      final col = _sessionsCollection();
      if (col == null) return null;
      final doc = await col.doc(_sessionId(clinicId, date)).get();
      if (!doc.exists) return null;
      return QueueSessionModel.fromDocument(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to get queue session');
    }
  }

  Future<QueueSessionModel> getOrCreateTodaySession(
      String clinicId, String date) async {
    try {
      final existing = await getSession(clinicId, date);
      if (existing != null) return existing;

      final newSession = QueueSessionModel(
        clinicId: clinicId,
        date: date,
        currentParchaNumber: 0,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final col = _sessionsCollection();
      if (col != null) {
        await col.doc(_sessionId(clinicId, date)).set(newSession.toMap());
      }
      return newSession;
    } on FirebaseException catch (e) {
      throw ServerFailure(
          e.message ?? 'Failed to get or create queue session');
    }
  }

  Future<int> incrementParcha(
      String clinicId, String date, String performedBy) async {
    final fs = _fs;
    if (fs == null) throw const ServerFailure('Firebase is not available');

    return await fs.runTransaction<int>((transaction) async {
      final sessions = _sessionsCollection()!;
      final sessionRef = sessions.doc(_sessionId(clinicId, date));
      final sessionDoc = await transaction.get(sessionRef);

      QueueSessionModel session;
      if (!sessionDoc.exists) {
        session = QueueSessionModel(
          clinicId: clinicId,
          date: date,
          currentParchaNumber: 0,
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        transaction.set(sessionRef, session.toMap());
      } else {
        session =
            QueueSessionModel.fromDocument(sessionDoc.data()!, sessionDoc.id);
      }

      if (session.status != 'active') {
        throw const ServerFailure('Queue session is not active');
      }

      final newNumber = session.currentParchaNumber + 1;

      transaction.update(sessionRef, {
        'currentParchaNumber': newNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final history = _historyCollection();
      if (history != null) {
        transaction.set(history.doc(), {
          'clinicId': clinicId,
          'sessionDate': date,
          'previousNumber': session.currentParchaNumber,
          'newNumber': newNumber,
          'action': 'increment',
          'performedBy': performedBy,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      return newNumber;
    });
  }

  Future<int> decrementParcha(
      String clinicId, String date, String performedBy) async {
    final fs = _fs;
    if (fs == null) throw const ServerFailure('Firebase is not available');

    return await fs.runTransaction<int>((transaction) async {
      final sessions = _sessionsCollection()!;
      final sessionRef = sessions.doc(_sessionId(clinicId, date));
      final sessionDoc = await transaction.get(sessionRef);

      if (!sessionDoc.exists) return 0;
      final session =
          QueueSessionModel.fromDocument(sessionDoc.data()!, sessionDoc.id);
      if (session.currentParchaNumber <= 0) return 0;

      final newNumber = session.currentParchaNumber - 1;
      transaction.update(sessionRef, {
        'currentParchaNumber': newNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final history = _historyCollection();
      if (history != null) {
        transaction.set(history.doc(), {
          'clinicId': clinicId,
          'sessionDate': date,
          'previousNumber': session.currentParchaNumber,
          'newNumber': newNumber,
          'action': 'correction',
          'performedBy': performedBy,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      return newNumber;
    });
  }

  Future<int> resetParcha(
      String clinicId, String date, String performedBy) async {
    final fs = _fs;
    if (fs == null) throw const ServerFailure('Firebase is not available');

    return await fs.runTransaction<int>((transaction) async {
      final sessions = _sessionsCollection()!;
      final sessionRef = sessions.doc(_sessionId(clinicId, date));
      final sessionDoc = await transaction.get(sessionRef);

      int currentNumber = 0;
      if (sessionDoc.exists) {
        final session =
            QueueSessionModel.fromDocument(sessionDoc.data()!, sessionDoc.id);
        currentNumber = session.currentParchaNumber;

        final history = _historyCollection();
        if (history != null) {
          transaction.set(history.doc(), {
            'clinicId': clinicId,
            'sessionDate': date,
            'previousNumber': currentNumber,
            'newNumber': 0,
            'action': 'reset',
            'performedBy': performedBy,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }

      transaction.set(sessionRef, {
        'clinicId': clinicId,
        'date': date,
        'currentParchaNumber': 0,
        'status': 'active',
        'createdAt': sessionDoc.exists
            ? (sessionDoc.data()?['createdAt'] as Timestamp? ?? DateTime.now())
            : DateTime.now(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return 0;
    });
  }

  Future<List<QueueHistoryEntry>> getHistory(
      String clinicId, String date) async {
    try {
      final col = _historyCollection();
      if (col == null) return [];
      final snapshot = await col
          .where('clinicId', isEqualTo: clinicId)
          .where('sessionDate', isEqualTo: date)
          .get();
      final entries = snapshot.docs
          .map((doc) => QueueHistoryEntry.fromDocument(doc.data(), doc.id))
          .toList();
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to get queue history');
    }
  }

  Stream<QueueSessionModel?> sessionStream(String clinicId, String date) {
    final col = _sessionsCollection();
    if (col == null) return Stream.value(null);
    return col.doc(_sessionId(clinicId, date)).snapshots().map((doc) {
      if (!doc.exists) return null;
      return QueueSessionModel.fromDocument(doc.data()!, doc.id);
    });
  }

  Stream<List<QueueSessionModel>> activeSessionsStream() {
    final col = _sessionsCollection();
    if (col == null) return Stream.value(const []);
    return col.where('status', isEqualTo: 'active').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => QueueSessionModel.fromDocument(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream of every session for a calendar day (YYYY-MM-DD).
  /// Used by discovery to render live parchi counts in a single query.
  Stream<List<QueueSessionModel>> sessionsForDateStream(String date) {
    final col = _sessionsCollection();
    if (col == null) return Stream.value(const []);
    return col.where('date', isEqualTo: date).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => QueueSessionModel.fromDocument(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<QueueHistoryEntry>> historyStream(String clinicId, String date) {
    final col = _historyCollection();
    if (col == null) return Stream.value(const []);
    return col
        .where('clinicId', isEqualTo: clinicId)
        .where('sessionDate', isEqualTo: date)
        .snapshots()
        .map((snapshot) {
      final entries = snapshot.docs
          .map((doc) => QueueHistoryEntry.fromDocument(doc.data(), doc.id))
          .toList();
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries.take(50).toList(growable: false);
    });
  }

  Future<void> updateSessionStatus(
      String clinicId, String date, String status) async {
    try {
      if (!QueueSessionModel.validStatuses.contains(status)) {
        throw const ServerFailure('Invalid session status');
      }
      final col = _sessionsCollection();
      if (col == null) return;
      await col.doc(_sessionId(clinicId, date)).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Failed to update session status');
    }
  }
}
