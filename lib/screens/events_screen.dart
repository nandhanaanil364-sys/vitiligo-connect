import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_model.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import 'event_registration_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({
    super.key,
  });

  @override
  State<EventsScreen> createState() =>
      _EventsScreenState();
}

class _EventsScreenState
    extends State<EventsScreen> {
  final EventService eventService =
      EventService.instance;

  int? userAge;
  bool isLoadingAge = true;

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadUserAge();
  }

  // ------------------------------------------------------------
  // CURRENT USER
  // ------------------------------------------------------------

  User? get currentUser =>
      FirebaseAuth.instance.currentUser;

  // ------------------------------------------------------------
  // LOAD USER AGE
  // ------------------------------------------------------------

  Future<void> _loadUserAge() async {
    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          isLoadingAge = false;
        });

        return;
      }

      final document =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!mounted) return;

      if (document.exists) {
        final data =
            document.data() ?? {};

        final storedAge =
            data['age'];

        int? parsedAge;

        if (storedAge is int) {
          parsedAge = storedAge;
        } else if (storedAge != null) {
          parsedAge =
              int.tryParse(
            storedAge.toString(),
          );
        }

        setState(() {
          userAge = parsedAge;
          isLoadingAge = false;
        });
      } else {
        setState(() {
          userAge = null;
          isLoadingAge = false;
        });
      }
    } catch (e) {
      debugPrint(
        'EVENT AGE LOAD ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        userAge = null;
        isLoadingAge = false;
      });
    }
  }

  // ------------------------------------------------------------
  // AGE FILTER
  // ------------------------------------------------------------

  List<Event> _filterEventsByAge(
    List<Event> events,
  ) {
    // If user has not added an age,
    // show only All Ages events.
    if (userAge == null) {
      return events.where((event) {
        return event.targetAgeGroup ==
            'All Ages';
      }).toList();
    }

    return events.where((event) {
      return userAge! >= event.minAge &&
          userAge! <= event.maxAge;
    }).toList();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppTheme.background,

      appBar: AppBar(
        backgroundColor:
            AppTheme.background,
        elevation: 0,
        automaticallyImplyLeading:
            false,
        title: const Text(
          'Events',
          style: TextStyle(
            fontSize: 21,
            fontWeight:
                FontWeight.bold,
            color:
                AppTheme.textDark,
          ),
        ),
      ),

      body: isLoadingAge
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    AppTheme.primaryDark,
              ),
            )
          : StreamBuilder<List<Event>>(
              stream:
                  eventService
                      .approvedEventsStream(),

              builder:
                  (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          AppTheme
                              .primaryDark,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildError(
                    snapshot.error
                        .toString(),
                  );
                }

                final allEvents =
                    snapshot.data ?? [];

                final events =
                    _filterEventsByAge(
                  allEvents,
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    await _loadUserAge();

                    await Future.delayed(
                      const Duration(
                        milliseconds: 300,
                      ),
                    );
                  },

                  child:
                      SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),

                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      30,
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        _buildHeader(),

                        const SizedBox(
                          height: 25,
                        ),

                        const Text(
                          'Upcoming Events',
                          style:
                              TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight
                                    .bold,
                            color:
                                AppTheme
                                    .textDark,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          userAge == null
                              ? 'Add your age in Profile to see events for your age group.'
                              : 'Events recommended for your age group.',
                          style:
                              const TextStyle(
                            fontSize: 13,
                            color:
                                AppTheme
                                    .textGrey,
                          ),
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        if (events.isEmpty)
                          _buildEmptyState()
                        else
                          ...events.map(
                            (event) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(
                                  bottom: 15,
                                ),
                                child:
                                    _buildEventCard(
                                  event,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color:
            AppTheme.pastelGreen,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 55,
            height: 55,
            child: CircleAvatar(
              backgroundColor:
                  Colors.white,
              child: Icon(
                Icons
                    .event_available_rounded,
                color:
                    AppTheme
                        .primaryDark,
                size: 30,
              ),
            ),
          ),

          SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  'Connect & Participate',
                  style:
                      TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppTheme
                            .textDark,
                  ),
                ),

                SizedBox(
                  height: 5,
                ),

                Text(
                  'Discover events created by verified experts.',
                  style:
                      TextStyle(
                    fontSize: 13,
                    color:
                        AppTheme
                            .textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // EVENT CARD
  // ------------------------------------------------------------

  Widget _buildEventCard(
    Event event,
  ) {
    final user = currentUser;

    if (user == null) {
      return _buildEventCardContent(
        event,
        false,
      );
    }

    return StreamBuilder<bool>(
      stream:
          eventService
              .registrationStatusStream(
        eventId: event.id,
        userId: user.uid,
      ),

      builder:
          (context, snapshot) {
        final joined =
            snapshot.data ?? false;

        return _buildEventCardContent(
          event,
          joined,
        );
      },
    );
  }

  // ------------------------------------------------------------
  // EVENT CARD CONTENT
  // ------------------------------------------------------------

  Widget _buildEventCardContent(
    Event event,
    bool joined,
  ) {
    final seatsLeft =
        event.maxSeats > 0
            ? event.maxSeats -
                event.participants
            : 0;

    final isFull =
        event.maxSeats > 0 &&
            seatsLeft <= 0;

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(17),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border:
            Border.all(
          color:
              const Color(
            0xFFE8ECE9,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration:
                    BoxDecoration(
                  color:
                      event.color,
                  shape:
                      BoxShape.circle,
                ),
                child: Icon(
                  event.icon,
                  color:
                      AppTheme
                          .primaryDark,
                  size: 27,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      event.eventType
                          .toUpperCase(),
                      style:
                          const TextStyle(
                        fontSize: 10,
                        fontWeight:
                            FontWeight
                                .bold,
                        color:
                            AppTheme
                                .primaryDark,
                        letterSpacing:
                            0.6,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      event.title,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight
                                .bold,
                        color:
                            AppTheme
                                .textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            event.description,
            maxLines: 3,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 13,
              color:
                  AppTheme.textGrey,
              height: 1.4,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          _infoRow(
            Icons.calendar_today_outlined,
            '${event.date} • ${event.time}',
          ),

          const SizedBox(
            height: 8,
          ),

          _infoRow(
            Icons.location_on_outlined,
            event.mode == 'Online'
                ? 'Online event'
                : event.mode == 'Hybrid'
                    ? 'Hybrid event'
                    : event.venue,
          ),

          const SizedBox(
            height: 8,
          ),

          _infoRow(
            Icons.people_outline,
            event.maxSeats > 0
                ? '${event.participants}/${event.maxSeats} participants'
                : '${event.participants} participants',
          ),

          if (event.maxSeats > 0) ...[
            const SizedBox(
              height: 8,
            ),

            _infoRow(
              Icons.event_seat_outlined,
              isFull
                  ? 'Event is full'
                  : '$seatsLeft seats remaining',
            ),
          ],

          const SizedBox(
            height: 15,
          ),

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton(
                  onPressed: () {
                    _showEventDetails(
                      event,
                    );
                  },

                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        AppTheme
                            .primaryDark,
                    side:
                        const BorderSide(
                      color:
                          Color(
                        0xFFD5DED8,
                      ),
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        11,
                      ),
                    ),
                  ),

                  child:
                      const Text(
                    'Details',
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                    ElevatedButton(
                  onPressed:
                      isFull && !joined
                          ? null
                          : () {
                              if (joined) {
                                _leaveEvent(
                                  event,
                                );
                              } else {
                                _openRegistration(
                                  event,
                                );
                              }
                            },

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        joined
                            ? Colors.white
                            : AppTheme
                                .primaryDark,
                    foregroundColor:
                        joined
                            ? AppTheme
                                .primaryDark
                            : Colors.white,
                    side: joined
                        ? const BorderSide(
                            color:
                                AppTheme
                                    .primaryDark,
                          )
                        : null,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        11,
                      ),
                    ),
                  ),

                  child:
                      Text(
                    joined
                        ? 'Joined ✓'
                        : isFull
                            ? 'Full'
                            : 'Participate',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // INFO ROW
  // ------------------------------------------------------------

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color:
              AppTheme.textGrey,
        ),

        const SizedBox(
          width: 7,
        ),

        Expanded(
          child: Text(
            text,
            style:
                const TextStyle(
              fontSize: 12,
              color:
                  AppTheme.textGrey,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // DETAILS
  // ------------------------------------------------------------

  void _showEventDetails(
    Event event,
  ) {
    final user = currentUser;

    if (user == null) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.white,
      isScrollControlled:
          true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(
            25,
          ),
        ),
      ),

      builder: (context) {
        return StreamBuilder<bool>(
          stream:
              eventService
                  .registrationStatusStream(
            eventId: event.id,
            userId: user.uid,
          ),

          builder:
              (context, snapshot) {
            final joined =
                snapshot.data ?? false;

            return _buildDetailsContent(
              event,
              joined,
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // DETAILS CONTENT
  // ------------------------------------------------------------

  Widget _buildDetailsContent(
    Event event,
    bool joined,
  ) {
    final isFull =
        event.maxSeats > 0 &&
            event.participants >=
                event.maxSeats;

    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          24,
          24,
          24,
          20,
        ),

        child:
            SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration:
                        BoxDecoration(
                      color:
                          event.color,
                      shape:
                          BoxShape.circle,
                    ),
                    child: Icon(
                      event.icon,
                      color:
                          AppTheme
                              .primaryDark,
                      size: 27,
                    ),
                  ),

                  const SizedBox(
                    width: 14,
                  ),

                  Expanded(
                    child: Text(
                      event.title,
                      style:
                          const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppTheme
                                .textDark,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),

              Text(
                event.eventType,
                style:
                    const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppTheme
                          .primaryDark,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                event.description,
                style:
                    const TextStyle(
                  fontSize: 14,
                  color:
                      AppTheme.textGrey,
                  height: 1.5,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              _detailRow(
                Icons
                    .calendar_today_outlined,
                '${event.date} • ${event.time}',
              ),

              const SizedBox(
                height: 10,
              ),

              _detailRow(
                Icons.location_on_outlined,
                event.mode == 'Online'
                    ? 'Online'
                    : event.mode ==
                            'Hybrid'
                        ? 'Hybrid • ${event.venue}'
                        : event.venue,
              ),

              const SizedBox(
                height: 10,
              ),

              _detailRow(
                Icons.people_outline,
                event.maxSeats > 0
                    ? '${event.participants} / ${event.maxSeats} participants'
                    : '${event.participants} participants',
              ),

              if (event.maxSeats > 0) ...[
                const SizedBox(
                  height: 10,
                ),

                _detailRow(
                  Icons
                      .event_seat_outlined,
                  isFull
                      ? 'Event is full'
                      : '${event.maxSeats - event.participants} seats remaining',
                ),
              ],

              const SizedBox(
                height: 10,
              ),

              _detailRow(
                Icons.groups_outlined,
                'For: ${event.targetAgeGroup}',
              ),

              const SizedBox(
                height: 10,
              ),

              _detailRow(
                Icons
                    .contact_phone_outlined,
                event.contact,
              ),

              const SizedBox(
                height: 22,
              ),

              SizedBox(
                width:
                    double.infinity,
                height: 48,

                child:
                    ElevatedButton(
                  onPressed:
                      !joined &&
                              isFull
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                              );

                              if (joined) {
                                _leaveEvent(
                                  event,
                                );
                              } else {
                                _openRegistration(
                                  event,
                                );
                              }
                            },

                  child:
                      Text(
                    joined
                        ? 'Leave Event'
                        : isFull
                            ? 'Event Full'
                            : 'Register for Event',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DETAIL ROW
  // ------------------------------------------------------------

  Widget _detailRow(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color:
              AppTheme.primaryDark,
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: Text(
            text,
            style:
                const TextStyle(
              fontSize: 13,
              color:
                  AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // REGISTRATION
  // ------------------------------------------------------------

  Future<void> _openRegistration(
    Event event,
  ) async {
    final user = currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please log in to participate in an event.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // Check Firebase first.
    try {
      final alreadyRegistered =
          await eventService
              .isUserRegistered(
        eventId: event.id,
        userId: user.uid,
      );

      if (alreadyRegistered) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'You are already registered for this event.',
            ),
            behavior:
                SnackBarBehavior.floating,
          ),
        );

        return;
      }
    } catch (e) {
      debugPrint(
        'REGISTRATION STATUS ERROR: $e',
      );
    }

    if (!mounted) return;

    final registered =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EventRegistrationScreen(
          event: event,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (registered == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Registered for "${event.title}"',
          ),
          behavior:
              SnackBarBehavior
                  .floating,
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // LEAVE EVENT
  // ------------------------------------------------------------

  Future<void> _leaveEvent(
    Event event,
  ) async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    final confirm =
        await showDialog<bool>(
      context: context,

      builder:
          (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Leave Event?',
          ),

          content: Text(
            'Are you sure you want to leave "${event.title}"?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },

              child:
                  const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },

              child:
                  const Text(
                'Leave',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await eventService
          .cancelRegistration(
        eventId: event.id,
        userId: user.uid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'You left "${event.title}".',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint(
        'LEAVE EVENT ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to leave the event: $e',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // EMPTY
  // ------------------------------------------------------------

  Widget _buildEmptyState() {
    final message = userAge == null
        ? 'Add your age in Profile to see events recommended for you.'
        : 'There are no approved events available for your age group right now.';

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(25),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border:
            Border.all(
          color:
              const Color(
            0xFFE8ECE9,
          ),
        ),
      ),

      child: Column(
        children: [
          const Icon(
            Icons.event_busy_outlined,
            size: 48,
            color:
                AppTheme.primaryDark,
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            'No events available',
            style:
                TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppTheme.textDark,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            message,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 13,
              color:
                  AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ERROR
  // ------------------------------------------------------------

  Widget _buildError(
    String error,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(25),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color:
                  Colors.redAccent,
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              'Unable to load events',
              style:
                  TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppTheme.textDark,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              error,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 12,
                color:
                    AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}