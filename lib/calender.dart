import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class HalfStaffCalendarScreen extends StatefulWidget {
  const HalfStaffCalendarScreen({super.key});

  @override
  _HalfStaffCalendarScreenState createState() =>
      _HalfStaffCalendarScreenState();
}

class _HalfStaffCalendarScreenState extends State<HalfStaffCalendarScreen> {
  final Map<DateTime, dynamic> _events = {};
  final bool _isLoading = false;
  String? _errorMessage;
  String? _userState;
  String? _userStateName;
  final bool _locationInitialized = false;
  String? userZipcode;
  Position? position;
  final bool _locationAttempted = false;
  final DateTime _currentDate = DateTime.now();
  List<Map<String, dynamic>> _displayedEvents = [];

  // Today's flag status from admin API
  String _todaysFlagStatus = 'Full Staff';
  bool _isLoadingTodaysStatus = false;

  @override
  void initState() {
    super.initState();
    _loadFixedHalfStaffDates();
    _fetchTodaysFlagStatus();
  }

  // Fetch today's flag status from admin API
  Future<void> _fetchTodaysFlagStatus() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoadingTodaysStatus = true;
      });

      final response = await http
          .get(
            Uri.parse(
              'https://service.com.hasthiya.com/api/getAllNotifications/',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        print('Admin API Response: $responseData');
        String todaysStatus = _extractTodaysFlagStatus(responseData);

        if (mounted) {
          setState(() {
            _todaysFlagStatus = todaysStatus;
          });
        }
      } else {
        print('Today\'s Status API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching today\'s flag status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTodaysStatus = false;
        });
      }
    }
  }

  // Extract today's flag status from API response
  String _extractTodaysFlagStatus(dynamic responseData) {
    try {
      List<dynamic> notifications = [];

      if (responseData is List) {
        notifications = responseData;
      } else if (responseData is Map && responseData['data'] is List) {
        notifications = responseData['data'];
      } else if (responseData is Map && responseData['notifications'] is List) {
        notifications = responseData['notifications'];
      }

      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      for (var notification in notifications) {
        String? notificationDate = notification['date']?.toString();
        String? createdAt = notification['created_at']?.toString();
        String title = (notification['title'] ?? '').toString().toLowerCase();
        String description =
            (notification['description'] ?? '').toString().toLowerCase();

        if (notificationDate != null && notificationDate.contains(today)) {
          return _determineFlagStatusFromContent(title, description);
        }

        if (createdAt != null && createdAt.contains(today)) {
          return _determineFlagStatusFromContent(title, description);
        }

        if (title.contains('new') ||
            title.contains('update') ||
            description.contains('new') ||
            description.contains('features')) {
          return _determineFlagStatusFromContent(title, description);
        }
      }
    } catch (e) {
      print('Error extracting today\'s flag status: $e');
    }

    return 'Full Staff';
  }

  // Determine flag status from notification content
  String _determineFlagStatusFromContent(String title, String description) {
    List<String> halfStaffKeywords = [
      'New Update',
      'features',
      'lower flag',
      'mourning',
      'memorial',
      'tragedy',
      'death',
      'passed away',
      'in memory',
      'honor',
      'fallen',
      'victims',
      'solemn',
      'at half',
    ];

    List<String> fullStaffKeywords = [
      'full staff',
      'full-staff',
      'raise flag',
      'normal',
      'regular',
      'back to normal',
    ];

    for (String keyword in halfStaffKeywords) {
      if (title.contains(keyword) || description.contains(keyword)) {
        return 'Half Staff';
      }
    }

    for (String keyword in fullStaffKeywords) {
      if (title.contains(keyword) || description.contains(keyword)) {
        return 'Full Staff';
      }
    }

    return 'Full Staff';
  }

  // Load fixed half-staff dates
  void _loadFixedHalfStaffDates() {
    _events.clear();

    int currentYear = DateTime.now().year;
    List<int> years = [currentYear, currentYear + 1];

    for (int year in years) {
      _addFixedEvent(DateTime(year, 9, 1), 'Labor Day', 'Full Staff');
      _addFixedEvent(DateTime(year, 9, 11), 'Patriot Day', 'Half Staff');
      _addFixedEvent(DateTime(year, 9, 17), 'Constitution Day', 'Full Staff');
      _addFixedEvent(
        DateTime(year, 9, 19),
        'National POW/MIA Recognition',
        'Full Staff',
      );
      _addFixedEvent(DateTime(year, 10, 13), 'Columbus Day', 'Full Staff');
      _addFixedEvent(DateTime(year, 10, 27), 'Navy Day', 'Full Staff');
      _addFixedEvent(
        DateTime(year, 5, 15),
        'Peace Officers Memorial Day',
        'Half Staff',
      );

      DateTime memorialDay = _getLastMonday(year, 5);
      _addFixedEvent(memorialDay, 'Memorial Day', 'Half Staff');

      _addFixedEvent(
        DateTime(year, 7, 27),
        'Korean War Veterans Armistice Day',
        'Half Staff',
      );

      DateTime firefightersDay = _getFirstSunday(year, 10);
      _addFixedEvent(
        firefightersDay,
        'National Firefighters Memorial Day',
        'Half Staff',
      );

      _addFixedEvent(
        DateTime(year, 12, 7),
        'Pearl Harbor Remembrance Day',
        'Half Staff',
      );
    }

    _prepareDisplayEvents();
    if (mounted) {
      setState(() {});
    }
  }

  void _addFixedEvent(DateTime date, String title, String staffType) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    String type =
        staffType == 'Half Staff'
            ? 'Federal Half-Staff Flag Day'
            : 'Federal Full-Staff Flag Day';
    _events[normalizedDate] = {
      'Title': title,
      'StaffType': staffType,
      'Date': normalizedDate,
      'Type': type,
      'IsFixed': true,
    };
  }

  DateTime _getLastMonday(int year, int month) {
    DateTime lastDayOfMonth = DateTime(year, month + 1, 0);
    DateTime lastMonday = lastDayOfMonth;

    while (lastMonday.weekday != DateTime.monday) {
      lastMonday = lastMonday.subtract(Duration(days: 1));
    }

    return lastMonday;
  }

  DateTime _getFirstSunday(int year, int month) {
    DateTime firstDayOfMonth = DateTime(year, month, 1);
    DateTime firstSunday = firstDayOfMonth;

    while (firstSunday.weekday != DateTime.sunday) {
      firstSunday = firstSunday.add(Duration(days: 1));
    }

    return firstSunday;
  }

  void _prepareDisplayEvents() {
    _displayedEvents.clear();

    // DateTime startDate = DateTime.now();
DateTime startDate = DateTime(2025, 9, 1);
DateTime endDate = DateTime(startDate.year + 1, 12, 31);

    _events.forEach((date, event) {
      if (date.isAfter(startDate.subtract(Duration(days: 1))) &&
          date.isBefore(endDate.add(Duration(days: 1)))) {
        _displayedEvents.add(event);
      }
    });

    _displayedEvents.sort((a, b) => a['Date'].compareTo(b['Date']));

    List<Map<String, dynamic>> groupedEvents = [];
    String currentMonth = '';

    for (var event in _displayedEvents) {
      String eventMonth = DateFormat('MMM yyyy').format(event['Date']);
      if (eventMonth != currentMonth) {
        groupedEvents.add({
          'isHeader': true,
          'month': eventMonth,
          'Date': event['Date'],
        });
        currentMonth = eventMonth;
      }
      groupedEvents.add({
        'isHeader': false,
        'Title': event['Title'],
        'Description': event['Description'],
        'StaffType': event['StaffType'],
        'Date': event['Date'],
      });
    }

    _displayedEvents = groupedEvents;
  }

  void _showSimpleEventDialog(DateTime date) {
    if (!mounted) return;

    final event = _events[date];
    if (event != null) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Flag Status Details'),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM d, yyyy').format(date),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Event:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${event['Title']}', style: TextStyle(fontSize: 15)),
                      if (event['Description'] != null &&
                          event['Description'].toString().isNotEmpty) ...[
                        SizedBox(height: 8),
                        Text(
                          'Details:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${event['Description']}',
                          style: TextStyle(fontSize: 14),
                          softWrap: true,
                        ),
                      ],
                      SizedBox(height: 8),
                      Text(
                        'Type: ${event['Type']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    _loadFixedHalfStaffDates();
    await _fetchTodaysFlagStatus();
  }

  String _getTodaysFlagStatus() {
    return _todaysFlagStatus;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          leading: BackButton(color: Colors.black),
          backgroundColor: Colors.grey[200],
          elevation: 0,
          title: Text('Flag Schedule', style: TextStyle(color: Colors.black)),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.black),
              onPressed: _isLoading ? null : _refreshData,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Current date
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  DateFormat('MMMM d, yyyy').format(_currentDate),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              // Today's flag status from admin API
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Flag Status:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    _isLoadingTodaysStatus
                        ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue,
                          ),
                        )
                        : Text(
                          _getTodaysFlagStatus(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                _getTodaysFlagStatus() == 'Half Staff'
                                    ? Colors.red
                                    : Colors.blue,
                          ),
                        ),
                  ],
                ),
              ),

              // Loading indicator
              if (_isLoading)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.blue,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Loading events...',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ],
                  ),
                ),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.black),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Events list
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _displayedEvents.length,
                itemBuilder: (context, index) {
                  final item = _displayedEvents[index];

                  if (item['isHeader'] == true) {
                    return Container(
                      padding: EdgeInsets.all(16),
                      color: Colors.white,
                      child: Text(
                        item['month'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    );
                  } else {
                    return InkWell(
                      onTap: () => _showSimpleEventDialog(item['Date']),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: const Color.fromRGBO(255, 255, 255, 1),
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 50,
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              constraints: BoxConstraints(maxWidth: 200),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('dd').format(item['Date']),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    DateFormat(
                                      'E',
                                    ).format(item['Date']).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                constraints: BoxConstraints(maxWidth: 200),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                    199,
                                    247,
                                    244,
                                    244,
                                  ),

                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: 10,
                                        right: 20,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['Title'],
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            item['StaffType'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  item['StaffType'] ==
                                                          'Half Staff'
                                                      ? Colors.red[800]
                                                      : Colors.blue[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
