import 'package:cloud_firestore/cloud_firestore.dart';

class StudentRepository {
  StudentRepository(this.uid);

  final String uid;

  DocumentReference<Map<String, dynamic>> get _userDocument =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get students =>
      _userDocument.collection('students');

  CollectionReference<Map<String, dynamic>> get _activity =>
      _userDocument.collection('activity');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchStudents() =>
      students.orderBy('fullName').snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchStudent(String id) =>
      students.doc(id).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchActivity(String studentId) =>
      _activity.where('studentId', isEqualTo: studentId).snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile() =>
      _userDocument.snapshots();

  Future<void> saveStudent({
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    final document = documentId == null
        ? students.doc()
        : students.doc(documentId);
    final batch = FirebaseFirestore.instance.batch();
    batch.set(document, {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
      if (documentId == null) 'createdAt': FieldValue.serverTimestamp(),
      if (documentId != null) 'photoUrl': FieldValue.delete(),
      if (documentId != null) 'photoPath': FieldValue.delete(),
    }, SetOptions(merge: true));
    batch.set(_activity.doc(), {
      'studentId': document.id,
      'studentName': data['fullName'],
      'action': documentId == null ? 'created' : 'updated',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> updateStatus({
    required String documentId,
    required String studentName,
    required String status,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(students.doc(documentId), {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_activity.doc(), {
      'studentId': documentId,
      'studentName': studentName,
      'action': 'status_changed',
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> deleteStudent({
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(students.doc(documentId));
    batch.set(_activity.doc(), {
      'studentId': documentId,
      'studentName': data['fullName'],
      'action': 'deleted',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> updateThemeMode(String themeMode) => _userDocument.set({
    'themeMode': themeMode,
    'photoUrl': FieldValue.delete(),
    'photoPath': FieldValue.delete(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
