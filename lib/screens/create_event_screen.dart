import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() =>
      _CreateEventScreenState();
}

class _CreateEventScreenState
    extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final venueController = TextEditingController();
  final linkController = TextEditingController();
  final seatsController = TextEditingController();
  final contactController = TextEditingController();

  String eventType = 'Awareness Session';
  String eventMode = 'Online';

  // ------------------------------------------------------------
  // AGE GROUP
  // ------------------------------------------------------------

  String targetAgeGroup = 'All Ages';

  final Map<String, Map<String, int>> ageGroups = {
    'Children': {
      'min': 0,
      'max': 12,
    },
    'Teenagers': {
      'min': 13,
      'max': 17,
    },
    'Young Adults': {
      'min': 18,
      'max': 25,
    },
    'Adults': {
      'min': 26,
      'max': 59,
    },
    'Seniors': {
      'min': 60,
      'max': 120,
    },
    'All Ages': {
      'min': 0,
      'max': 120,
    },
  };

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool isLoading = false;

  final eventTypes = [
    'Awareness Session',
    'Webinar',
    'Seminar',
    'Free Counselling',
    'Support Group',
    'Workshop',
    'Other',
  ];

  final eventModes = [
    'Online',
    'Offline',
    'Hybrid',
  ];

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    venueController.dispose();
    linkController.dispose();
    seatsController.dispose();
    contactController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // DATE
  // ------------------------------------------------------------

  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(
        const Duration(days: 1),
      ),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // ------------------------------------------------------------
  // TIME
  // ------------------------------------------------------------

  Future<void> selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  // ------------------------------------------------------------
  // SUBMIT
  // ------------------------------------------------------------

  Future<void> submitEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedDate == null) {
      showMessage(
        'Please select an event date.',
      );
      return;
    }

    if (selectedTime == null) {
      showMessage(
        'Please select an event time.',
      );
      return;
    }

    if ((eventMode == 'Online' ||
            eventMode == 'Hybrid') &&
        linkController.text.trim().isEmpty) {
      showMessage(
        'Please enter the meeting link.',
      );
      return;
    }

    if ((eventMode == 'Offline' ||
            eventMode == 'Hybrid') &&
        venueController.text.trim().isEmpty) {
      showMessage(
        'Please enter the venue.',
      );
      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(
        'Please login again.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Get age range for selected group
      final selectedAgeRange =
          ageGroups[targetAgeGroup]!;

      final event = Event(
        id: '',
        title: titleController.text.trim(),
        description:
            descriptionController.text.trim(),
        eventType: eventType,
        mode: eventMode,
        date: formatDate(
          selectedDate!,
        ),
        time: formatTime(
          selectedTime!,
        ),
        venue: venueController.text.trim(),
        meetingLink:
            linkController.text.trim(),

        // Capacity
        maxSeats: int.parse(
          seatsController.text.trim(),
        ),
        participants: 0,

        // Age targeting
        targetAgeGroup: targetAgeGroup,
        minAge: selectedAgeRange['min']!,
        maxAge: selectedAgeRange['max']!,

        contact:
            contactController.text.trim(),
        expertId: user.uid,

        // IMPORTANT:
        // Keep pending for admin approval.
        status: 'pending',

        iconName:
            getIconName(eventType),
        colorValue:
            getColor(eventType).value,
      );

      await EventService.instance
          .createEvent(event);

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            title: const Text(
              'Event Submitted',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                color:
                    AppTheme.textDark,
              ),
            ),
            content: const Text(
              'Your event has been submitted successfully. It will appear to users after admin approval.',
              style: TextStyle(
                color:
                    AppTheme.textGrey,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                  Navigator.pop(
                    context,
                  );
                },
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color:
                        AppTheme.primaryDark,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      showMessage(
        'Failed to submit event: $e',
      );
    }
  }

  // ------------------------------------------------------------
  // ICON NAME
  // ------------------------------------------------------------

  String getIconName(
    String type,
  ) {
    switch (type) {
      case 'Webinar':
        return 'webinar';

      case 'Seminar':
        return 'seminar';

      case 'Free Counselling':
        return 'counselling';

      case 'Support Group':
        return 'support';

      case 'Workshop':
        return 'workshop';

      case 'Awareness Session':
        return 'awareness';

      default:
        return 'event';
    }
  }

  // ------------------------------------------------------------
  // COLOR
  // ------------------------------------------------------------

  Color getColor(
    String type,
  ) {
    switch (type) {
      case 'Webinar':
        return AppTheme.pastelBlue;

      case 'Seminar':
        return AppTheme.pastelGreen;

      case 'Free Counselling':
        return AppTheme.pastelPink;

      case 'Support Group':
        return AppTheme.pastelPink;

      case 'Workshop':
        return AppTheme.pastelYellow;

      case 'Awareness Session':
        return AppTheme.pastelBlue;

      default:
        return AppTheme.pastelGreen;
    }
  }

  // ------------------------------------------------------------
  // DATE FORMAT
  // ------------------------------------------------------------

  String formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ------------------------------------------------------------
  // TIME FORMAT
  // ------------------------------------------------------------

  String formatTime(
    TimeOfDay time,
  ) {
    final hour =
        time.hourOfPeriod == 0
            ? 12
            : time.hourOfPeriod;

    final minute = time.minute
        .toString()
        .padLeft(2, '0');

    final period =
        time.period == DayPeriod.am
            ? 'AM'
            : 'PM';

    return '$hour:$minute $period';
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
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
        title: const Text(
          'Create Event',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
            color:
                AppTheme.textDark,
          ),
        ),
        backgroundColor:
            AppTheme.background,
        foregroundColor:
            AppTheme.textDark,
        elevation: 0,
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                buildHeader(),

                const SizedBox(
                  height: 25,
                ),

                buildSectionTitle(
                  'Event Details',
                ),

                const SizedBox(
                  height: 12,
                ),

                buildTextField(
                  controller:
                      titleController,
                  label:
                      'Event Title',
                  hint:
                      'Enter event title',
                  icon:
                      Icons.event_outlined,
                  validator:
                      (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Please enter event title';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 16,
                ),

                buildDropdown(),

                const SizedBox(
                  height: 16,
                ),

                buildTextField(
                  controller:
                      descriptionController,
                  label:
                      'Description',
                  hint:
                      'Describe the event',
                  icon:
                      Icons
                          .description_outlined,
                  maxLines: 5,
                  validator:
                      (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Please enter description';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 25,
                ),

                // ------------------------------------------------
                // TARGET AGE GROUP
                // ------------------------------------------------

                buildSectionTitle(
                  'Who is this event for?',
                ),

                const SizedBox(
                  height: 12,
                ),

                buildAgeGroupDropdown(),

                const SizedBox(
                  height: 8,
                ),

                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  child: Text(
                    'Users will see this event based on their age.',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          AppTheme.textGrey,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                buildSectionTitle(
                  'Date & Time',
                ),

                const SizedBox(
                  height: 12,
                ),

                Row(
                  children: [
                    Expanded(
                      child: buildPicker(
                        icon: Icons
                            .calendar_today_outlined,
                        title:
                            'Event Date',
                        value:
                            selectedDate ==
                                    null
                                ? 'Select date'
                                : formatDate(
                                    selectedDate!,
                                  ),
                        onTap:
                            selectDate,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: buildPicker(
                        icon: Icons
                            .access_time_outlined,
                        title:
                            'Event Time',
                        value:
                            selectedTime ==
                                    null
                                ? 'Select time'
                                : formatTime(
                                    selectedTime!,
                                  ),
                        onTap:
                            selectTime,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 25,
                ),

                buildSectionTitle(
                  'Event Mode',
                ),

                const SizedBox(
                  height: 12,
                ),

                DropdownButtonFormField<
                    String>(
                  initialValue:
                      eventMode,
                  decoration:
                      const InputDecoration(
                    labelText: 'Mode',
                    prefixIcon:
                        Icon(
                      Icons
                          .location_on_outlined,
                      color:
                          AppTheme
                              .primaryDark,
                    ),
                  ),
                  items:
                      eventModes.map(
                    (item) {
                      return DropdownMenuItem(
                        value: item,
                        child:
                            Text(item),
                      );
                    },
                  ).toList(),
                  onChanged:
                      (value) {
                    if (value != null) {
                      setState(() {
                        eventMode =
                            value;
                      });
                    }
                  },
                ),

                const SizedBox(
                  height: 16,
                ),

                if (eventMode ==
                        'Online' ||
                    eventMode ==
                        'Hybrid')
                  buildTextField(
                    controller:
                        linkController,
                    label:
                        'Meeting Link',
                    hint:
                        'Zoom / Google Meet link',
                    icon:
                        Icons.link_outlined,
                  ),

                if (eventMode ==
                        'Online' ||
                    eventMode ==
                        'Hybrid')
                  const SizedBox(
                    height: 16,
                  ),

                if (eventMode ==
                        'Offline' ||
                    eventMode ==
                        'Hybrid')
                  buildTextField(
                    controller:
                        venueController,
                    label:
                        'Venue',
                    hint:
                        'Enter venue',
                    icon:
                        Icons
                            .location_on_outlined,
                  ),

                if (eventMode ==
                        'Offline' ||
                    eventMode ==
                        'Hybrid')
                  const SizedBox(
                    height: 16,
                  ),

                buildTextField(
                  controller:
                      seatsController,
                  label:
                      'Maximum Seats',
                  hint:
                      'Example: 50',
                  icon:
                      Icons.people_outline,
                  keyboardType:
                      TextInputType.number,
                  validator:
                      (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Please enter maximum seats';
                    }

                    final seats =
                        int.tryParse(
                      value.trim(),
                    );

                    if (seats == null ||
                        seats <= 0) {
                      return 'Enter a valid number';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 16,
                ),

                buildTextField(
                  controller:
                      contactController,
                  label:
                      'Contact Information',
                  hint:
                      'Phone number or email',
                  icon: Icons
                      .contact_phone_outlined,
                  validator:
                      (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Please enter contact information';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 25,
                ),

                buildApprovalNotice(),

                const SizedBox(
                  height: 25,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 54,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        isLoading
                            ? null
                            : submitEvent,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons
                                .send_outlined,
                          ),
                    label: Text(
                      isLoading
                          ? 'Submitting...'
                          : 'Submit Event for Approval',
                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // AGE GROUP DROPDOWN
  // ------------------------------------------------------------

  Widget buildAgeGroupDropdown() {
    return DropdownButtonFormField<
        String>(
      initialValue:
          targetAgeGroup,

      decoration:
          const InputDecoration(
        labelText:
            'Target Age Group',
        prefixIcon:
            Icon(
          Icons
              .groups_outlined,
          color:
              AppTheme.primaryDark,
        ),
      ),

      items:
          ageGroups.keys.map(
        (ageGroup) {
          final range =
              ageGroups[ageGroup]!;

          String ageText;

          if (ageGroup ==
              'All Ages') {
            ageText =
                'All Ages (0–120)';
          } else {
            ageText =
                '$ageGroup (${range['min']}–${range['max']})';
          }

          return DropdownMenuItem<
              String>(
            value: ageGroup,
            child: Text(
              ageText,
            ),
          );
        },
      ).toList(),

      onChanged:
          (value) {
        if (value != null) {
          setState(() {
            targetAgeGroup =
                value;
          });
        }
      },
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget buildHeader() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color:
            AppTheme.pastelBlue,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons
                .event_available_outlined,
            size: 38,
            color:
                AppTheme.primaryDark,
          ),
          SizedBox(
            width: 15,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  'Organize an Event',
                  style:
                      TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppTheme.textDark,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  'Create an event for the Vitiligo Connect community.',
                  style:
                      TextStyle(
                    fontSize: 13,
                    color:
                        AppTheme.textGrey,
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
  // SECTION TITLE
  // ------------------------------------------------------------

  Widget buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight:
            FontWeight.bold,
        color:
            AppTheme.textDark,
      ),
    );
  }

  // ------------------------------------------------------------
  // TEXT FIELD
  // ------------------------------------------------------------

  Widget buildTextField({
    required TextEditingController
        controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)?
        validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType:
          keyboardType,
      validator: validator,
      decoration:
          InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon:
            Icon(
          icon,
          color:
              AppTheme.primaryDark,
        ),
        alignLabelWithHint:
            maxLines > 1,
      ),
    );
  }

  // ------------------------------------------------------------
  // EVENT TYPE DROPDOWN
  // ------------------------------------------------------------

  Widget buildDropdown() {
    return DropdownButtonFormField<
        String>(
      initialValue:
          eventType,
      decoration:
          const InputDecoration(
        labelText:
            'Event Type',
        prefixIcon: Icon(
          Icons.category_outlined,
          color:
              AppTheme.primaryDark,
        ),
      ),
      items:
          eventTypes.map(
        (item) {
          return DropdownMenuItem<
              String>(
            value: item,
            child:
                Text(item),
          );
        },
      ).toList(),
      onChanged:
          (value) {
        if (value != null) {
          setState(() {
            eventType =
                value;
          });
        }
      },
    );
  }

  // ------------------------------------------------------------
  // PICKER
  // ------------------------------------------------------------

  Widget buildPicker({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(
        16,
      ),
      child: Container(
        padding:
            const EdgeInsets.all(
          15,
        ),
        decoration:
            BoxDecoration(
          color:
              AppTheme.surface,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          border:
              Border.all(
            color:
                const Color(
              0xFFE2E8E4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color:
                  AppTheme.primaryDark,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              title,
              style:
                  const TextStyle(
                fontSize: 12,
                color:
                    AppTheme.textGrey,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              value,
              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
                color:
                    AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // APPROVAL NOTICE
  // ------------------------------------------------------------

  Widget buildApprovalNotice() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color:
            AppTheme.pastelYellow,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color:
                Colors.orange,
          ),
          SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              'Your event will be reviewed by the admin before it becomes visible to users.',
              style:
                  TextStyle(
                fontSize: 13,
                height: 1.4,
                color:
                    AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}