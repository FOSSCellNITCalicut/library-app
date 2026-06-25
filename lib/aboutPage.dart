import 'package:flutter/material.dart';
import 'package:library_nitc/models/book_arrangement.dart';
import 'package:library_nitc/models/business_hours.dart';
import 'package:library_nitc/services/opac_home_service.dart';

int _dayIndex(String abbr) {
  const map = {'sun': 7, 'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 'fri': 5, 'sat': 6};
  return map[abbr.toLowerCase().substring(0, 3)] ?? 0;
}

bool _inDayRange(int now, int start, int end) {
  if (start <= end) return now >= start && now <= end;
  return now >= start || now <= end;
}

int _parseTime(String s) {
  s = s.trim();
  if (s.contains('Midnight')) return 24 * 60;
  if (s.contains('Noon')) return 12 * 60;
  final isPM = s.contains('PM');
  final isAM = s.contains('AM');
  final digits = s.replaceAll(RegExp(r'(AM|PM)'), '').trim();
  int h = int.tryParse(digits) ?? 0;
  if (isPM && h != 12) h += 12;
  if (isAM && h == 12) h = 0;
  return h * 60;
}

bool _isOpenNow(List<HourEntry> entries) {
  final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  final wd = now.weekday;

  for (final e in entries) {
    for (final part in _splitSchedule(e.schedule)) {
      final d = RegExp(r'\((\w+)-(\w+)\)').firstMatch(part);
      final t = RegExp(r'(\S+)-(\S+)').firstMatch(part);
      if (d == null || t == null) continue;
      final sd = _dayIndex(d.group(1)!);
      final ed = _dayIndex(d.group(2)!);
      if (!_inDayRange(wd, sd, ed)) continue;
      final st = _parseTime(t.group(1)!);
      final et = _parseTime(t.group(2)!);
      final cur = now.hour * 60 + now.minute;
      if (cur >= st && cur < et) return true;
    }
  }
  return false;
}

String _subjectLabel(String callRange) {
  const labels = [
    'Computer Science, Information & General Works',
    'Philosophy & Psychology',
    'Religion',
    'Social Sciences',
    'Language',
    'Science',
    'Technology',
    'Arts & Recreation',
    'Literature',
    'History & Geography',
  ];
  final start = callRange.split('-').first.trim();
  final h = int.tryParse(start.isNotEmpty ? start[0] : '') ?? 0;
  if (h >= 0 && h < labels.length) return labels[h];
  return '';
}

class AboutPage extends StatefulWidget {
  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final _opacService = OpacHomeService();
  List<StackEntry> _bookArrangement = [];
  List<HourEntry> _businessHours = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _opacService.fetchHomeData();
      if (mounted) {
        setState(() {
          _bookArrangement = data.bookArrangement;
          _businessHours = data.businessHours;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Text("About Us",
                  style:
                      TextStyle(fontSize: 40, fontWeight: FontWeight.w700)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                "Since 1961, the Central Library at NIT Calicut has been a cornerstone of academic excellence — housing over 1.35 lakh books and serving a community of 8,000+ users.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
            ),
            if (_loading)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: 0,
                  color: Colors.deepPurple.shade50,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(width: 22, height: 22, decoration: BoxDecoration(color: Colors.deepPurple.shade200, borderRadius: BorderRadius.circular(4))),
                        SizedBox(width: 12),
                        Container(height: 14, width: 160, decoration: BoxDecoration(color: Colors.deepPurple.shade200, borderRadius: BorderRadius.circular(4))),
                      ],
                    ),
                  ),
                ),
              ),
            if (!_loading && _businessHours.isNotEmpty)
              _BusinessHoursSection(entries: _businessHours),
            AboutImage(id: 1),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCard(icon: Icons.menu_book, value: "1,35,000+", label: "Books"),
                  _StatCard(icon: Icons.people, value: "8,000+", label: "Users"),
                  _StatCard(icon: Icons.square_foot, value: "11,340", label: "Sq. Meters"),
                ],
              ),
            ),
            AboutImage(id: 2),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                "Fully automated with a modern digital infrastructure:",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCard(icon: Icons.computer, value: "KOHA", label: "Library System"),
                  _StatCard(icon: Icons.wifi, value: "RFID", label: "Technology"),
                  _StatCard(icon: Icons.event_seat, value: "500", label: "Seating"),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                "Open daily 8 AM – 12 Midnight  •  Since 1961",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            AboutImage(id: 3),

            if (!_loading && _bookArrangement.isNotEmpty)
              _BookArrangementSection(entries: _bookArrangement),

            _DDCReferenceTable(),

            _ContactSection(),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _BookArrangementSection extends StatelessWidget {
  final List<StackEntry> entries;
  const _BookArrangementSection({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, color: Colors.deepPurple, size: 22),
              SizedBox(width: 8),
              Text(
                "Book Arrangement",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...entries.map((e) => Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.deepPurple.shade200),
                  ),
                  child: Text(
                    e.stack,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.callRange,
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      if (_subjectLabel(e.callRange).isNotEmpty)
                        Text(
                          _subjectLabel(e.callRange),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _BusinessHoursSection extends StatelessWidget {
  final List<HourEntry> entries;
  const _BusinessHoursSection({required this.entries});

  @override
  Widget build(BuildContext context) {
    final open = _isOpenNow(entries);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.deepPurple, size: 22),
              SizedBox(width: 8),
              Text(
                "Library Business Hours",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: open ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: open ? Colors.green : Colors.red, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      open ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: open ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: 4),
                    Text(
                      open ? "Open Now" : "Closed",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: open ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...entries.map((e) => Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    e.area,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _splitSchedule(e.schedule).map((line) => Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Text(
                        line,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          )),
          SizedBox(height: 4),
        ],
      ),
    );
  }
}

List<String> _splitSchedule(String schedule) {
  return schedule
      .split(RegExp(r'(?<=\))\s*'))
      .where((s) => s.isNotEmpty)
      .toList();
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.deepPurple.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 100,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.deepPurple, size: 24),
              SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.deepPurple.shade800,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DDCReferenceTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const rows = [
      ('0xx', 'Computer Science, Information & General Works'),
      ('1xx', 'Philosophy & Psychology'),
      ('2xx', 'Religion'),
      ('3xx', 'Social Sciences'),
      ('4xx', 'Language'),
      ('5xx', 'Science'),
      ('6xx', 'Technology'),
      ('7xx', 'Arts & Recreation'),
      ('8xx', 'Literature'),
      ('9xx', 'History & Geography'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.deepPurple, size: 22),
              SizedBox(width: 8),
              Text(
                "DDC Classification Reference",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple.shade200),
            ),
            child: Column(
              children: rows.map((r) => Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: r != rows.last
                      ? Border(bottom: BorderSide(color: Colors.deepPurple.shade200))
                      : null,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        r.$1,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        r.$2,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_enabled, color: Colors.deepPurple, size: 22),
              SizedBox(width: 8),
              Text(
                "Reach Us",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple.shade200),
            ),
            child: Column(
              children: [
                _ContactRow(icon: Icons.mail, text: "library@nitc.ac.in"),
                SizedBox(height: 14),
                _ContactRow(icon: Icons.phone, text: "0495-2286063"),
                SizedBox(height: 14),
                _ContactRow(
                  icon: Icons.location_on_sharp,
                  text: "NIT Calicut, NIT Campus P.O\nKozhikode, Kerala, India 673601",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 20),
        SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.black87))),
      ],
    );
  }
}

class AboutImage extends StatelessWidget {
  final int id;

  const AboutImage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 201,
        width: 370,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FittedBox(
              fit: BoxFit.fill,
              child: Image.asset("assets/about_img_$id.png"),
            )));
  }
}
