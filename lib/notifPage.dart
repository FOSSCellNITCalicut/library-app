import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Notifpage extends StatelessWidget {
  const Notifpage({super.key});



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Notifications"),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back)
        ),
      ),
      body: Padding (
        padding: EdgeInsets.all(12),
        child: NotifScreen()
      )
    );
  }
}

class NotifScreen extends StatefulWidget {
  const NotifScreen({super.key});

  @override
  State<NotifScreen> createState() => _NotifScreenState();
}

enum NotifFilter {all, unread, read}

class _NotifScreenState extends State<NotifScreen> {



  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.start,
          spacing: 5.0,
          children: [
            ChoiceChip(
              label: Text("All"),
              selected: notifProvider.selectedFilter == NotifFilter.all,
              onSelected: (bool selected) {
                setState(() {
                  notifProvider.selectedFilter = NotifFilter.all;
                });
              },
            ),
            ChoiceChip(
              label: Text("Unread"),
              selected: notifProvider.selectedFilter == NotifFilter.unread,
              onSelected: (bool selected) {
                setState(() {
                  notifProvider.selectedFilter = NotifFilter.unread;
                });
              },
            ),
            ChoiceChip(
              label: Text("Read"),
              selected: notifProvider.selectedFilter == NotifFilter.read,
              onSelected: (bool selected) {
                setState(() {
                  notifProvider.selectedFilter = NotifFilter.read;
                });
              },
            ),
            FilledButton.tonalIcon( //! for Debugging purposes, could be implemented in the future maybe
              onPressed: () {
                notifProvider.clearNotifications();
              },
              icon: Icon(Icons.clear),
              label: const Text("Clear all notifications"),
            ),
            FilledButton.tonalIcon( //! for Debugging purposes
              onPressed: () {
                notifProvider.addNotification(Notification(id: Random().nextInt(20).toString(), message: "belo", text: 'blah blah blaj'));
              },
              icon: Icon(Icons.add),
              label: const Text("Add new notif"),
            ),
          ],
        ),
        SizedBox(height: 12,),
        Expanded(
          child: notifProvider.isLoading
          ? const Center(child: CircularProgressIndicator(),)
          : notifProvider.filteredNotifs.isEmpty
            ? const Center(
              child: Text('nothing bob'), //!
            )
            : ListView.builder(
              itemCount: notifProvider.filteredNotifs.length,
              itemBuilder: (context, index) {
                final notification = notifProvider.filteredNotifs[index];
                return NotifItem(notification: notification);
              },
            )
        )
      ],
    );
  }
}

class NotifItem extends StatelessWidget {
  final Notification notification;

  const NotifItem({required this.notification,super.key});

  String truncate(int cutoff, String text) {
    return (text.length <= cutoff) 
      ? text
      : '${text.substring(0,cutoff)}...';
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.read<NotificationProvider>();


    return ListTile(
      title: Text(notification.message),
      subtitle: Text(truncate(20 ,notification.text)), // TODO change cutoff according to requirements
      tileColor: notification.read ? Colors.black12 : Colors.deepPurple.shade50,
      onTap: () {
        if(!notification.read){
          notificationProvider.toggleReadStatus(notification.id);
        }
        pushScreenWithoutNavBar(context, NotifDetailsPage(notification: notification));
      },
    );
  }
}

class Notification {
  final String id;
  final String message;
  final String text;
  bool read;

  Notification({required this.id, required this.message, required this.text, this.read = false});

  // Factory constructor to create a Notification object from a JSON map
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      message: json['message'] as String,
      text: json['text'] as String,
      read: json['read'] as bool,
    );
  }

  // Method to convert a Notification object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'text': text,
      'read': read,
    };
  }
}

class NotificationProvider extends ChangeNotifier {

  NotifFilter _selectedFilter = NotifFilter.all;

  NotifFilter get selectedFilter => _selectedFilter;

  set selectedFilter(NotifFilter newValue) {
    _selectedFilter = newValue;
    notifyListeners();
  }

  List<Notification> get filteredNotifs {
    switch(_selectedFilter) {
      case NotifFilter.all:
        return _notifications;
      case NotifFilter.read:
        return _notifications.where((n) => n.read).toList();
      case NotifFilter.unread:
        return _notifications.where((n) => !n.read).toList();
    }
  }

  int get unreadCount {
    return filteredNotifs.where((n) => !n.read).length;
  }

  List<Notification> _notifications = [];
  bool _isLoading = true;

  NotificationProvider() {
    _loadNotifications();
  }
  // Public getters to access the state
  bool get isLoading => _isLoading;
  List<Notification> get notifications => _notifications;



  Future<void> _loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String? notifsJson = prefs.getString('notifications_data');

    if(notifsJson != null){
      final List<dynamic> decodedList = json.decode(notifsJson);
      _notifications = decodedList.map((item) => Notification.fromJson(item)).toList();
    } else {
      _notifications = [
        Notification(id: "1", message: "helo", text: 'blah blah blaj'),
        Notification(id: "2", message: "helo", text: 'blah blah blaj'),
        Notification(id: "3", message: "helo", text: 'blah blah blaj'),
      ];
    }
    _isLoading = false;
    notifyListeners();

  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    final List<Map<String,dynamic>> jsonList = _notifications.map((n) => n.toJson()).toList();
    await prefs.setString('notifications_data', jsonEncode(jsonList));
  }

  void toggleReadStatus(String id) {
    int index = _notifications.indexWhere((n) => n.id == id);
    if(index != -1) {
      _notifications[index].read = !_notifications[index].read; 
      notifyListeners();
      _saveNotifications();
    }
  }

  void addNotification(Notification newNotif){
    _notifications.add(newNotif);
    notifyListeners();
    _saveNotifications();
  }

  Future<void> clearNotifications() async {
    _notifications.clear();
    notifyListeners();
    await _saveNotifications();
  }
}

class NotifDetailsPage extends StatelessWidget {
  final Notification notification;
  const NotifDetailsPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    NotificationProvider provider = context.read<NotificationProvider>();

    final currentNotif = provider.notifications.firstWhere((n) => n.id == notification.id); // some cs geek could optimize this maybe (i think this is O(n))

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () {
              provider.toggleReadStatus(currentNotif.id);
              print("Notif status changed");
            },
            icon: Icon(notification.read ? Icons.mark_as_unread : Icons.mark_email_read_rounded),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                Text(notification.message, style: TextStyle(fontSize: 22),),
              ],
            ),
            Wrap(children: [
              Text(notification.text)
            ],)
          ],
        ),
      ),
    );
  }
}
