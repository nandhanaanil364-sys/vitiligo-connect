import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_model.dart';

class EventService {
  EventService._privateConstructor();

  static final EventService instance =
      EventService._privateConstructor();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // COLLECTION
  // ------------------------------------------------------------

  CollectionReference<Map<String, dynamic>>
      get _eventsCollection =>
          _firestore.collection('events');

  // ------------------------------------------------------------
  // CREATE EVENT
  // ------------------------------------------------------------

  Future<String> createEvent(
    Event event,
  ) async {
    final document =
        await _eventsCollection.add(
      {
        ...event.toMap(),
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );

    return document.id;
  }

  // ------------------------------------------------------------
  // APPROVED EVENTS
  // ------------------------------------------------------------

  Stream<List<Event>> approvedEventsStream() {
    return _eventsCollection
        .where(
          'status',
          isEqualTo: 'approved',
        )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Event.fromMap(
          doc.id,
          doc.data(),
        );
      }).toList();
    });
  }

  // ------------------------------------------------------------
  // PENDING EVENTS
  // ------------------------------------------------------------

  Stream<List<Event>> pendingEventsStream() {
    return _eventsCollection
        .where(
          'status',
          isEqualTo: 'pending',
        )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Event.fromMap(
          doc.id,
          doc.data(),
        );
      }).toList();
    });
  }

  // ------------------------------------------------------------
  // ALL EVENTS
  // ------------------------------------------------------------

  Stream<List<Event>> allEventsStream() {
    return _eventsCollection
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Event.fromMap(
          doc.id,
          doc.data(),
        );
      }).toList();
    });
  }

  // ------------------------------------------------------------
  // APPROVE EVENT
  // ------------------------------------------------------------

  Future<void> approveEvent(
    String eventId,
    String adminUid,
  ) async {
    await _eventsCollection
        .doc(eventId)
        .update({
      'status': 'approved',
      'approvedBy': adminUid,
      'approvedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // REJECT EVENT
  // ------------------------------------------------------------

  Future<void> rejectEvent(
    String eventId,
    String adminUid,
    String reason,
  ) async {
    await _eventsCollection
        .doc(eventId)
        .update({
      'status': 'rejected',
      'rejectedBy': adminUid,
      'rejectionReason': reason,
      'rejectedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // DELETE EVENT
  // ------------------------------------------------------------

  Future<void> deleteEvent(
    String eventId,
  ) async {
    await _eventsCollection
        .doc(eventId)
        .delete();
  }

  // ------------------------------------------------------------
  // GET SINGLE EVENT
  // ------------------------------------------------------------

  Future<Event?> getEventById(
    String eventId,
  ) async {
    final document =
        await _eventsCollection
            .doc(eventId)
            .get();

    if (!document.exists) {
      return null;
    }

    return Event.fromMap(
      document.id,
      document.data()!,
    );
  }

  // ------------------------------------------------------------
  // REGISTER USER FOR EVENT
  // ------------------------------------------------------------

  Future<void> registerUserForEvent({
    required String eventId,
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String age,
    String message = '',
  }) async {
    final eventReference =
        _eventsCollection.doc(eventId);

    final registrationReference =
        eventReference
            .collection('registrations')
            .doc(userId);

    // ----------------------------------------------------------
    // CONVERT AGE TO INTEGER
    // ----------------------------------------------------------

    final enteredAge =
        int.tryParse(age.trim());

    if (enteredAge == null) {
      throw Exception(
        'Please enter a valid age.',
      );
    }

    await _firestore.runTransaction(
      (transaction) async {
        // ------------------------------------------------------
        // GET EVENT
        // ------------------------------------------------------

        final eventSnapshot =
            await transaction.get(
          eventReference,
        );

        if (!eventSnapshot.exists) {
          throw Exception(
            'Event no longer exists.',
          );
        }

        final eventData =
            eventSnapshot.data() ??
                <String, dynamic>{};

        // ------------------------------------------------------
        // PARTICIPANT COUNT
        // ------------------------------------------------------

        final currentParticipants =
            _toInt(
          eventData['participants'],
        );

        final maxSeats =
            _toInt(
          eventData['maxSeats'],
        );

        // ------------------------------------------------------
        // CHECK EVENT STATUS
        // ------------------------------------------------------

        final eventStatus =
            eventData['status'] ?? '';

        if (eventStatus != 'approved') {
          throw Exception(
            'This event is not available for registration.',
          );
        }

        // ------------------------------------------------------
        // CHECK AGE ELIGIBILITY
        // ------------------------------------------------------

        final minAge =
            _toInt(
          eventData['minAge'],
        );

        final maxAge =
            _toInt(
          eventData['maxAge'],
        );

        if (enteredAge < minAge ||
            enteredAge > maxAge) {
          throw Exception(
            'This event is not available for your age group.',
          );
        }

        // ------------------------------------------------------
        // CHECK AVAILABLE SEATS
        // ------------------------------------------------------

        if (maxSeats > 0 &&
            currentParticipants >= maxSeats) {
          throw Exception(
            'This event is already full.',
          );
        }

        // ------------------------------------------------------
        // CHECK EXISTING REGISTRATION
        // ------------------------------------------------------

        final existingRegistration =
            await transaction.get(
          registrationReference,
        );

        if (existingRegistration.exists) {
          throw Exception(
            'You are already registered for this event.',
          );
        }

        // ------------------------------------------------------
        // CREATE REGISTRATION
        // ------------------------------------------------------

        transaction.set(
          registrationReference,
          {
            'userId': userId,
            'name': name.trim(),
            'email': email.trim(),
            'phone': phone.trim(),

            // Store age as INTEGER.
            'age': enteredAge,

            'message': message.trim(),

            'registeredAt':
                FieldValue.serverTimestamp(),
          },
        );

        // ------------------------------------------------------
        // UPDATE PARTICIPANT COUNT
        // ------------------------------------------------------

        transaction.update(
          eventReference,
          {
            'participants':
                FieldValue.increment(1),
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // CHECK REGISTRATION
  // ------------------------------------------------------------

  Future<bool> isUserRegistered({
    required String eventId,
    required String userId,
  }) async {
    final document =
        await _eventsCollection
            .doc(eventId)
            .collection('registrations')
            .doc(userId)
            .get();

    return document.exists;
  }

  // ------------------------------------------------------------
  // REGISTRATION STATUS STREAM
  // ------------------------------------------------------------

  Stream<bool> registrationStatusStream({
    required String eventId,
    required String userId,
  }) {
    return _eventsCollection
        .doc(eventId)
        .collection('registrations')
        .doc(userId)
        .snapshots()
        .map(
          (document) =>
              document.exists,
        );
  }

  // ------------------------------------------------------------
  // CANCEL REGISTRATION
  // ------------------------------------------------------------

  Future<void> cancelRegistration({
    required String eventId,
    required String userId,
  }) async {
    final eventReference =
        _eventsCollection.doc(eventId);

    final registrationReference =
        eventReference
            .collection('registrations')
            .doc(userId);

    await _firestore.runTransaction(
      (transaction) async {
        // ------------------------------------------------------
        // GET REGISTRATION
        // ------------------------------------------------------

        final registration =
            await transaction.get(
          registrationReference,
        );

        // Nothing to cancel.
        if (!registration.exists) {
          return;
        }

        // ------------------------------------------------------
        // GET EVENT
        // ------------------------------------------------------

        final eventSnapshot =
            await transaction.get(
          eventReference,
        );

        // ------------------------------------------------------
        // DELETE REGISTRATION
        // ------------------------------------------------------

        transaction.delete(
          registrationReference,
        );

        // ------------------------------------------------------
        // DECREASE PARTICIPANT COUNT
        // ------------------------------------------------------

        if (eventSnapshot.exists) {
          final eventData =
              eventSnapshot.data() ??
                  <String, dynamic>{};

          final currentParticipants =
              _toInt(
            eventData['participants'],
          );

          if (currentParticipants > 0) {
            transaction.update(
              eventReference,
              {
                'participants':
                    FieldValue.increment(
                  -1,
                ),
              },
            );
          }
        }
      },
    );
  }

  // ------------------------------------------------------------
  // CONVERT FIRESTORE VALUE TO INT
  // ------------------------------------------------------------

  int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value == null) {
      return 0;
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }
}