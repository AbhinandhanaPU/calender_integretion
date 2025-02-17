import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  Set<DateTime> selectedDays = {};
  final Set<DateTime> _bookedDates = {};
  Set<DateTime> _availableDates = {};
  bool _isLoading = false;

  // Define the cutoff time for today's selection
  final TimeOfDay _cutoffTime = const TimeOfDay(hour: 22, minute: 0);

  @override
  void initState() {
    super.initState();
    _fetchBookedDates();
  }

  /// Asynchronous function to fetch booked dates from the backend
  Future<void> _fetchBookedDates() async {
    setState(() {
      _bookedDates.addAll({
        DateTime(2025, 2, 10),
        DateTime(2025, 2, 15),
        DateTime(2025, 2, 16),
        DateTime(2025, 3, 1),
        DateTime(2025, 3, 16),
        DateTime(2025, 4, 16),
        DateTime(2025, 5, 18),
        DateTime(2025, 6, 25),
      });
      _computeAvailableDates();
      _isLoading = false;
    });
  }

  /// Computes available dates based on booked dates
  void _computeAvailableDates() {
    Set<DateTime> availableDates = {};
    DateTime firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    DateTime lastDay = DateTime(_focusedDay.year, _focusedDay.month + 5, 0);

    for (DateTime day = firstDay;
        day.isBefore(lastDay.add(const Duration(days: 1)));
        day = day.add(const Duration(days: 1))) {
      if (!_bookedDates.any((bookedDate) => isSameDay(day, bookedDate))) {
        availableDates.add(day);
      }
    }

    setState(() {
      _availableDates = availableDates;
    });
  }

  /// Checks if a given date is today
  bool _isToday(DateTime day) {
    return day.year == DateTime.now().year &&
        day.month == DateTime.now().month &&
        day.day == DateTime.now().day;
  }

  // Handles the logic for date selection
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // Prevent selection of booked dates
    if (_bookedDates.any((bookedDate) => isSameDay(selectedDay, bookedDate))) {
      log("Day is booked, preventing selection");
      return;
    }

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    // Create DateTime object representing the cutoff time *today*
    DateTime cutoffDateTime = DateTime(
      today.year,
      today.month,
      today.day,
      _cutoffTime.hour,
      _cutoffTime.minute,
    );

    // If the selected day is before today, prevent selection.
    if (selectedDay.isBefore(today)) {
      log("Selected day is BEFORE today, preventing selection");
      return;
    }

    // If the selected day is today and the current time is after the cutoff time, prevent selection
    if (isSameDay(selectedDay, today) && now.isAfter(cutoffDateTime)) {
      log("Today after cutoff, preventing selection");
      return;
    }

    // Range selection logic
    if (_rangeStart == null) {
      _rangeStart = selectedDay;
      _rangeEnd = null;
    } else if (_rangeEnd == null && selectedDay.isAfter(_rangeStart!) ||
        isSameDay(selectedDay, _rangeStart!)) {
      // It is necessary to check any booked dates fall within the potential selection
      DateTime rangeStartDate = _rangeStart!;
      DateTime rangeEndDate = selectedDay;

      // Ensure startDate is before endDate
      if (rangeStartDate.isAfter(rangeEndDate)) {
        rangeStartDate = selectedDay;
        rangeEndDate = _rangeStart!;
      }

      // Check if any booked dates fall within the selected range
      for (DateTime bookedDate in _bookedDates) {
        if ((bookedDate.isAtSameMomentAs(rangeStartDate) ||
                bookedDate.isAfter(rangeStartDate)) &&
            (bookedDate.isBefore(rangeEndDate.add(const Duration(days: 0))) ||
                bookedDate.isAtSameMomentAs(
                    rangeEndDate.add(const Duration(days: 0))))) {
          log("Selected range includes a booked date, preventing selection");
          _rangeStart = null; // Reset range selection
          _rangeEnd = null; // Reset range selection
          return;
        }
      }

      _rangeEnd = selectedDay; // Set end date if no conflicts
    } else {
      _rangeStart = selectedDay; // Reset start date
      _rangeEnd = null; // Reset end date
    }

    setState(() {
      _focusedDay = focusedDay;
    });
  }

  /// Clears the date range
  void _clearDateRange() {
    setState(() {
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  /// Builds the UI for the selected range
  Widget _buildRangeStart(DateTime day, DateTime focusedDay) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff00B5CC),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(5),
      ),
      margin: const EdgeInsets.all(4.0),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Builds the UI for the selected range
  Widget _buildRangeEnd(DateTime day, DateTime focusedDay) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff00B5CC),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(5),
      ),
      margin: const EdgeInsets.all(4.0),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds the UI for the selected range
  Widget _buildRangeMiddle(DateTime day, DateTime focusedDay) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1B2230),
      appBar: AppBar(
        backgroundColor: const Color(0xff1B2230),
        foregroundColor: Colors.white,
        title: const Text("Custom Calendar"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBookedDates,
          ),
          GestureDetector(
            onTap: _rangeStart != null ? _clearDateRange : null,
            child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: _rangeStart != null ? Colors.blue : Colors.grey,
                ),
                child: const Text('Clear Range')),
          ),
          const SizedBox(
            width: 10,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              color: Color(0xff252E41),
            ),
            margin: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator()) // Loading indicator
                    : TableCalendar(
                        firstDay: DateTime(
                            DateTime.now().year, DateTime.now().month, 1),
                        lastDay: DateTime(
                            DateTime.now().year, DateTime.now().month + 5, 0),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        rangeStartDay: _rangeStart,
                        rangeEndDay: _rangeEnd,
                        rangeSelectionMode: RangeSelectionMode.toggledOn,
                        onDaySelected: _onDaySelected,
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: true,
                          rangeHighlightColor:
                              const Color(0xff00B5CC).withAlpha(128),
                          defaultTextStyle:
                              const TextStyle(color: Colors.white),
                          weekendTextStyle:
                              const TextStyle(color: Colors.white),
                          todayDecoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          weekendStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronIcon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                          rightChevronIcon: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                          titleTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          rangeStartBuilder: (context, day, focusedDay) =>
                              _buildRangeStart(day, focusedDay),
                          rangeEndBuilder: (context, day, focusedDay) =>
                              _buildRangeEnd(day, focusedDay),
                          withinRangeBuilder: (context, day, focusedDay) =>
                              _buildRangeMiddle(day, focusedDay),
                          defaultBuilder: (context, day, _) {
                            if (_bookedDates.any(
                                (bookedDate) => isSameDay(day, bookedDate))) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      day.day.toString(),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      "Booked",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else if (_isToday(day)) {
                              return Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.rectangle,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Center(
                                  child: Text(
                                    day.day.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            } else if (_availableDates.any((availableDate) =>
                                isSameDay(day, availableDate))) {
                              return Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.rectangle,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Center(
                                  child: Text(
                                    day.day.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Selected Range: ${DateFormat('dd-MM-yyyy').format(_rangeStart ?? DateTime.now())} - ${DateFormat('dd-MM-yyyy').format(_rangeEnd ?? DateTime.now())}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
