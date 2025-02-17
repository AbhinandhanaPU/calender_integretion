import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting
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
  final Set<DateTime> selectedDays = {};
  final Set<DateTime> _bookedDates = {};
  Set<DateTime> _availableDates = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBookedDates();
  }

  /// Asynchronous function to fetch booked dates from the backend
  Future<void> _fetchBookedDates() async {
    await Future.delayed(Duration(seconds: 1)); // Simulate API call
    setState(() {
      _bookedDates.addAll({
        DateTime(2025, 2, 10),
        DateTime(2025, 2, 15),
        DateTime(2025, 2, 16),
        DateTime(2025, 2, 17),
        DateTime(2025, 3, 1),
        DateTime(2025, 3, 16),
        DateTime(2025, 4, 16),
        DateTime(2025, 5, 16),
        DateTime(2025, 6, 16),
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
      if (!_bookedDates.contains(day)) {
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

  /// Handles the logic for date selection
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // Prevent selection of booked dates
    if (_bookedDates.any((bookedDate) => isSameDay(selectedDay, bookedDate))) {
      return;
    }

    // Prevent selection of past dates
    if (selectedDay
        .isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return;
    }

    setState(() {
      _focusedDay = focusedDay;

      // Range selection logic
      if (_rangeStart == null) {
        _rangeStart = selectedDay;
        _rangeEnd = null;
      } else if (_rangeEnd == null && selectedDay.isAfter(_rangeStart!) ||
          selectedDay.isAtSameMomentAs(_rangeStart!)) {
        _rangeEnd = selectedDay;
      } else {
        _rangeStart = selectedDay;
        _rangeEnd = null;
      }
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
        color: Color(0xff00B5CC),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(5),
      ),
      margin: const EdgeInsets.all(4.0),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Builds the UI for the selected range
  Widget _buildRangeEnd(DateTime day, DateTime focusedDay) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xff00B5CC),
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
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff1B2230),
      appBar: AppBar(
        backgroundColor: Color(0xff1B2230),
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: _rangeStart != null ? Colors.blue : Colors.grey,
                ),
                child: const Text('Clear Range')),
          ),
          SizedBox(
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
                    ? Center(
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
                          rangeHighlightColor: Color(0xff00B5CC).withAlpha(128),
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
                          leftChevronIcon: Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                          titleTextStyle: TextStyle(
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
