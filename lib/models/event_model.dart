
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String eventType;
  final String mode;
  final String date;
  final String time;
  final String venue;
  final String meetingLink;

  final int maxSeats;
  final int participants;

  final String targetAgeGroup;
  final int minAge;
  final int maxAge;

  final String contact;
  final String expertId;
  final String status;
  final String iconName;
  final int colorValue;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.eventType,
    required this.mode,
    required this.date,
    required this.time,
    required this.venue,
    required this.meetingLink,
    required this.maxSeats,
    required this.participants,
    required this.targetAgeGroup,
    required this.minAge,
    required this.maxAge,
    required this.contact,
    required this.expertId,
    required this.status,
    required this.iconName,
    required this.colorValue,
  });

  // Safely convert Firestore values to strings.
  static String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;

    if (value is Timestamp) {
      return value.toDate().toLocal().toString();
    }

    if (value is DateTime) {
      return value.toLocal().toString();
    }

    return value.toString();
  }

  // Convert a date into a readable date string.
  static String _readDate(dynamic value) {
    if (value == null) return '';

    DateTime? parsedDate;

    if (value is Timestamp) {
      parsedDate = value.toDate().toLocal();
    } else if (value is DateTime) {
      parsedDate = value.toLocal();
    } else if (value is String) {
      parsedDate = DateTime.tryParse(value);
      if (parsedDate == null) return value;
    } else {
      return value.toString();
    }

    final day = parsedDate.day.toString().padLeft(2, '0');
    final month = parsedDate.month.toString().padLeft(2, '0');
    final year = parsedDate.year.toString();

    return '$day/$month/$year';
  }

  // Convert a time into a readable time string.
  static String _readTime(dynamic value) {
    if (value == null) return '';

    if (value is Timestamp || value is DateTime) {
      final dateTime = value is Timestamp
          ? value.toDate().toLocal()
          : (value as DateTime).toLocal();

      final hour = dateTime.hour % 12 == 0
          ? 12
          : dateTime.hour % 12;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    }

    return value.toString();
  }

  static int _readInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  // ICON
  IconData get icon {
    switch (iconName) {
      case 'webinar':
        return Icons.video_camera_front_outlined;
      case 'seminar':
        return Icons.groups_outlined;
      case 'counselling':
        return Icons.psychology_outlined;
      case 'support':
        return Icons.favorite_outline;
      case 'workshop':
        return Icons.handyman_outlined;
      case 'awareness':
        return Icons.campaign_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  // COLOR
  Color get color => Color(colorValue);

  // FIRESTORE -> EVENT
  factory Event.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return Event(
      id: id,
      title: _readString(data['title']),
      description: _readString(data['description']),
      eventType: _readString(
        data['eventType'],
        fallback: 'Other',
      ),
      mode: _readString(
        data['mode'],
        fallback: 'Online',
      ),
      date: _readDate(data['date']),
      time: _readTime(data['time']),
      venue: _readString(data['venue']),
      meetingLink: _readString(data['meetingLink']),

      maxSeats: _readInt(data['maxSeats']),
      participants: _readInt(data['participants']),

      targetAgeGroup: _readString(
        data['targetAgeGroup'],
        fallback: 'All Ages',
      ),
      minAge: _readInt(data['minAge']),
      maxAge: _readInt(
        data['maxAge'],
        fallback: 120,
      ),

      contact: _readString(data['contact']),
      expertId: _readString(data['expertId']),
      status: _readString(
        data['status'],
        fallback: 'pending',
      ),
      iconName: _readString(
        data['iconName'],
        fallback: 'event',
      ),
      colorValue: _readInt(
        data['colorValue'],
        fallback: 0xFFE8F5E9,
      ),
    );
  }

  // EVENT -> FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'eventType': eventType,
      'mode': mode,
      'date': date,
      'time': time,
      'venue': venue,
      'meetingLink': meetingLink,
      'maxSeats': maxSeats,
      'participants': participants,
      'targetAgeGroup': targetAgeGroup,
      'minAge': minAge,
      'maxAge': maxAge,
      'contact': contact,
      'expertId': expertId,
      'status': status,
      'iconName': iconName,
      'colorValue': colorValue,
    };
  }
}
