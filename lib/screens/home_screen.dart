import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'logSampah_screen.dart';
import '../widgets/bottom_navbar.dart';
import 'location_screen.dart' as loc;
import 'profile_screen.dart'; // Make sure this file exists and contains 'class ProfileScreen extends StatelessWidget' or StatefulWidget

class HomeScreen extends StatefulWidget {
  final String name;
  final String email;

  const HomeScreen({super.key, required this.name, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int ecoPoints = 0;
void updateEcoPoints(int newPoints) {
    setState(() {
      ecoPoints = newPoints;
    });
  }
  late final ticker;
  List<String> notifications = [
    "Reminder: Buang sampah organik hari ini",
    "Event: Bersih-bersih lingkungan Minggu depan",
  ];

  @override
  void initState() {
    super.initState();

    // Update UI every second for the real-time clock
    ticker = Stream.periodic(Duration(seconds: 1)).listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    ticker.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTimeInZone(String timeZone) {
    final now = DateTime.now().toUtc();
    DateTime timeInZone;

    switch (timeZone) {
      case 'WIB':
        timeInZone = now.add(Duration(hours: 7));
        break;
      case 'WITA':
        timeInZone = now.add(Duration(hours: 8));
        break;
      case 'WIT':
        timeInZone = now.add(Duration(hours: 9));
        break;
      case 'London':
        timeInZone = now.add(Duration(hours: 0));
        break;
      default:
        timeInZone = now;
    }

    return TimeOfDay.fromDateTime(timeInZone).format(context);
  }

  // Updated Home Dashboard Widget
  Widget _buildHomeDashboard() {
    final articles = [
      {
        'title': 'Masalah Sampah di Indonesia Belum Terkendali, Hasilkan 6,9 Juta Ton Setiap Tahun',
        'source': 'Liputan6.com',
        'date': '3 Juni 2025',
        'url': 'https://www.liputan6.com/hot/read/5704909/masalah-sampah-di-indonesia-belum-terkendali-hasilkan-69-juta-ton-setiap-tahun',
      },
      {
        'title': '7,2 Juta Ton Sampah di Indonesia Belum Terkelola dengan Baik',
        'source': 'Kemenkop MK',
        'date': '2023',
        'url': 'https://www.kemenkopmk.go.id/72-juta-ton-sampah-di-indonesia-belum-terkelola-dengan-baik',
      },
      {
        'title': 'Darurat Pengelolaan Sampah di Indonesia',
        'source': 'Kompas.id',
        'date': '28 Juli 2023',
        'url': 'https://www.kompas.id/baca/riset/2023/07/28/darurat-pengelolaan-sampah-di-indonesia',
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🌱 Selamat Datang di EcoWaste Manager',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Mari kelola sampah dengan bijak dan ramah lingkungan',
            style: TextStyle(fontSize: 16, color: Colors.green.shade900),
          ),
          SizedBox(height: 28),

          // EcoPoints Card
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            shadowColor: Colors.green.shade200,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
              child: Column(
                children: [
                  Text(
                    ecoPoints.toString(),
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.green.shade800,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'EcoPoints Anda',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 30),

          // Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                icon: Icon(Icons.recycling_outlined, size: 24, color: Colors.green.shade700),
                label: Text('Log Sampah Baru'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                  side: BorderSide(color: Colors.green.shade700, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  foregroundColor: Colors.green.shade700,
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: () async {
                  final result = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LogSampahScreen(
                        onEcoPointsUpdate: (int newPoints) {
                          setState(() {
                            ecoPoints += newPoints;
                          });
                        },
                      ),
                    ),
                  );

                  if (result != null && result > 0) {
                    setState(() {
                      ecoPoints += result;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('EcoPoints bertambah sebanyak $result points!')),
                    );
                  }
                },
              ),
            ],
          ),

          SizedBox(height: 32),

          // Notifications Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔔 Notifikasi Terbaru:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 14),
                  if (notifications.isEmpty)
                    Text('Belum ada notifikasi', style: TextStyle(fontSize: 16))
                  else
                    ...notifications.map(
                      (note) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 10, color: Colors.green.shade400),
                            SizedBox(width: 10),
                            Expanded(child: Text(note, style: TextStyle(fontSize: 16))),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 36),

          // Time Display Row
          Wrap(
            spacing: 20,
            runSpacing: 14,
            children: ['WIB', 'WITA', 'WIT', 'London']
                .map((zone) => _buildTimeBox(zone))
                .toList(),
          ),

          SizedBox(height: 40),

          // Artikel Berita Sampah
          Text(
            '📰 Berita Terkini tentang Sampah',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade700),
          ),
          SizedBox(height: 18),

          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: articles.length,
            separatorBuilder: (context, index) => Divider(height: 20, color: Colors.grey.shade300),
            itemBuilder: (context, index) {
              final article = articles[index];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final url = Uri.parse(article['url'] ?? '');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tidak dapat membuka link')),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green.shade50,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(article['title'] ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.green.shade900)),
                      SizedBox(height: 6),
                      Text('${article['source']} • ${article['date']}', style: TextStyle(color: Colors.green.shade700.withOpacity(0.7))),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.chevron_right, color: Colors.green.shade700),
                      )
                    ],
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String zone) {
    return Container(
      width: 160,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.shade400),
        borderRadius: BorderRadius.circular(14),
        color: Colors.green.shade50,
      ),
      child: Column(
        children: [
          Text(
            zone == 'London'
                ? zone
                : '$zone (Waktu Indonesia ${zone == 'WIB' ? 'Barat' : zone == 'WITA' ? 'Tengah' : 'Timur'})',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            _getTimeInZone(zone),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.green.shade900),
          ),
        ],
      ),
    );
  }

  List<Widget> get _pages => [
        _buildHomeDashboard(),
        loc.LocationScreen(),
        ProfileScreen(
          ecoPoints: ecoPoints,
          onEcoPointsUpdate: (int newPoints) {
            setState(() {
              ecoPoints = newPoints;
            });
          },
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EcoWaste Manager'),
        backgroundColor: Color(0xFF4CAF50),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
