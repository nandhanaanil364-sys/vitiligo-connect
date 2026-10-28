import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';

class EventRegistrationScreen
    extends StatefulWidget {
  final Event event;

  const EventRegistrationScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventRegistrationScreen>
      createState() =>
          _EventRegistrationScreenState();
}

class _EventRegistrationScreenState
    extends State<EventRegistrationScreen> {
  final formKey =
      GlobalKey<FormState>();

  final nameController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  final ageController =
      TextEditingController();

  final messageController =
      TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    ageController.dispose();
    messageController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // REGISTER
  // ------------------------------------------------------------

  Future<void> register() async {
    if (!formKey.currentState!
        .validate()) {
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
      await EventService.instance
          .registerUserForEvent(
        eventId:
            widget.event.id,
        userId:
            user.uid,
        name:
            nameController.text.trim(),
        email:
            emailController.text.trim(),
        phone:
            phoneController.text.trim(),
        age:
            ageController.text.trim(),
        message:
            messageController.text
                .trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      await showDialog(
        context: context,
        barrierDismissible:
            false,
        builder:
            (dialogContext) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons
                      .check_circle_rounded,
                  color:
                      AppTheme
                          .primaryDark,
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    'Registration Successful',
                    style:
                        TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight
                              .bold,
                      color:
                          AppTheme
                              .textDark,
                    ),
                  ),
                ),
              ],
            ),
            content:
                Text(
              'You have successfully registered for "${widget.event.title}".',
              style:
                  const TextStyle(
                fontSize: 14,
                color:
                    AppTheme
                        .textGrey,
                height: 1.5,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child:
                    const Text(
                  'Done',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
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
        content:
            Text(message),
        behavior:
            SnackBarBehavior
                .floating,
      ),
    );
  }

  // ------------------------------------------------------------
  // INPUT
  // ------------------------------------------------------------

  InputDecoration inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon:
          Icon(
        icon,
        color:
            AppTheme.primaryDark,
      ),
      filled: true,
      fillColor: Colors.white,
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          13,
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          13,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(0xFFE0E6E2),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          13,
        ),
        borderSide:
            const BorderSide(
          color:
              AppTheme.primaryDark,
          width: 1.5,
        ),
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
    final event =
        widget.event;

    return Scaffold(
      backgroundColor:
          AppTheme.background,

      appBar: AppBar(
        backgroundColor:
            AppTheme.background,
        elevation: 0,
        title: const Text(
          'Event Registration',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
            color:
                AppTheme.textDark,
          ),
        ),
      ),

      body:
          SingleChildScrollView(
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
            // EVENT INFORMATION

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                18,
              ),
              decoration:
                  BoxDecoration(
                color:
                    event.color,
                borderRadius:
                    BorderRadius
                        .circular(
                  20,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration:
                        const BoxDecoration(
                      color:
                          Colors.white,
                      shape:
                          BoxShape
                              .circle,
                    ),
                    child:
                        Icon(
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
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          event
                              .eventType
                              .toUpperCase(),
                          style:
                              const TextStyle(
                            fontSize:
                                10,
                            fontWeight:
                                FontWeight
                                    .bold,
                            color:
                                AppTheme
                                    .primaryDark,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          event.title,
                          style:
                              const TextStyle(
                            fontSize:
                                17,
                            fontWeight:
                                FontWeight
                                    .bold,
                            color:
                                AppTheme
                                    .textDark,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          '${event.date} • ${event.time}',
                          style:
                              const TextStyle(
                            fontSize:
                                12,
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
            ),

            const SizedBox(
              height: 25,
            ),

            const Text(
              'Register for this Event',
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

            const SizedBox(
              height: 6,
            ),

            const Text(
              'Enter your details to participate in this event.',
              style:
                  TextStyle(
                fontSize: 13,
                color:
                    AppTheme
                        .textGrey,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Form(
              key: formKey,
              child: Column(
                children: [
                  // NAME

                  TextFormField(
                    controller:
                        nameController,
                    textCapitalization:
                        TextCapitalization
                            .words,
                    decoration:
                        inputDecoration(
                      'Full Name',
                      Icons
                          .person_outline_rounded,
                    ),
                    validator:
                        (value) {
                      if (value ==
                              null ||
                          value
                              .trim()
                              .isEmpty) {
                        return 'Please enter your name';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  // EMAIL

                  TextFormField(
                    controller:
                        emailController,
                    keyboardType:
                        TextInputType
                            .emailAddress,
                    decoration:
                        inputDecoration(
                      'Email',
                      Icons
                          .email_outlined,
                    ),
                    validator:
                        (value) {
                      if (value ==
                              null ||
                          value
                              .trim()
                              .isEmpty) {
                        return 'Please enter your email';
                      }

                      final regex =
                          RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      );

                      if (!regex
                          .hasMatch(
                        value.trim(),
                      )) {
                        return 'Enter a valid email';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  // PHONE

                  TextFormField(
                    controller:
                        phoneController,
                    keyboardType:
                        TextInputType
                            .phone,
                    maxLength: 10,
                    decoration:
                        inputDecoration(
                      'Phone Number',
                      Icons
                          .phone_outlined,
                    ).copyWith(
                      counterText:
                          '',
                    ),
                    validator:
                        (value) {
                      if (value ==
                              null ||
                          value
                              .trim()
                              .isEmpty) {
                        return 'Please enter your phone number';
                      }

                      if (!RegExp(
                        r'^[0-9]{10}$',
                      ).hasMatch(
                        value.trim(),
                      )) {
                        return 'Enter a valid 10-digit number';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  // AGE

                  TextFormField(
                    controller:
                        ageController,
                    keyboardType:
                        TextInputType
                            .number,
                    decoration:
                        inputDecoration(
                      'Age',
                      Icons
                          .cake_outlined,
                    ),
                    validator:
                        (value) {
                      if (value ==
                              null ||
                          value
                              .trim()
                              .isEmpty) {
                        return 'Please enter your age';
                      }

                      final age =
                          int.tryParse(
                        value.trim(),
                      );

                      if (age ==
                              null ||
                          age < 1 ||
                          age > 120) {
                        return 'Enter a valid age';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  // MESSAGE

                  TextFormField(
                    controller:
                        messageController,
                    maxLines: 4,
                    decoration:
                        inputDecoration(
                      'Message (Optional)',
                      Icons
                          .chat_bubble_outline_rounded,
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    height: 50,
                    child:
                        ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : register,
                      child:
                          isLoading
                              ? const SizedBox(
                                  width:
                                      20,
                                  height:
                                      20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Confirm Registration',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        15,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const Text(
                    'Your information will be used only for event registration.',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      fontSize: 11,
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
      ),
    );
  }
}