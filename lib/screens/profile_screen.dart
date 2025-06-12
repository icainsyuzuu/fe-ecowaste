import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int ecoPoints;
  final Function(int) onEcoPointsUpdate;
  

  const ProfileScreen({
    Key? key,
    required this.ecoPoints,
    required this.onEcoPointsUpdate,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  bool showFeedbackForm = false;
  bool showWasteLogHistory = false;
  bool showAllFeedback = false; 
  bool showCompass = false;
  bool isLoadingWasteLogs = false;
  bool isLoadingFeedback = false; 
  bool showProfileUpdateForm = false;
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _appFeedbackController = TextEditingController();
  int? _selectedRating;
  final _usernameController = TextEditingController();

  late int currentEcoPoints;
  late List<Map<String, dynamic>> wasteLogData;

  List<Map<String, dynamic>> _feedbackList = [];

  // Profile image variables
  File? _profileImageFile;
  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();

  // User data variables
  String _username = '';
  String _email = '';
  int? _userId;

// Compass variables
  late AnimationController _compassAnimationController;
  double _currentHeading = 0.0;
  bool _isCompassActive = false;

  @override
  void initState() {
    super.initState();
    currentEcoPoints = widget.ecoPoints;
    wasteLogData = [];
    _loadUserData();
    // Initialize compass animation controller
    _compassAnimationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _startCompassSimulation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _appFeedbackController.dispose();
    _compassAnimationController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
 // Simulate compass heading changes (in real app, you'd use flutter_compass plugin)
  void _startCompassSimulation() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted && _isCompassActive) {
        setState(() {
          // Simulate random heading changes
          _currentHeading = (_currentHeading + (math.Random().nextDouble() * 10 - 5)) % 360;
          if (_currentHeading < 0) _currentHeading += 360;
        });
        _startCompassSimulation();
      }
    });
  }

  void _toggleCompass() {
    setState(() {
      _isCompassActive = !_isCompassActive;
      if (_isCompassActive) {
        _startCompassSimulation();
      }
    });
  }

  Widget _buildCompass() {
    return Container(
      key: ValueKey('compass'),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    showCompass = false;
                    _isCompassActive = false;
                  });
                },
                icon: Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  'Kompas Digital',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              Switch(
                value: _isCompassActive,
                onChanged: (value) => _toggleCompass(),
                activeColor: Colors.green,
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Compass Display
          Center(
            child: Column(
              children: [
                // Compass Rose
                Container(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Compass Background
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.grey[100]!,
                              Colors.grey[300]!,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                      
                      // Compass Markings
                      ...List.generate(12, (index) {
                        final angle = index * 30.0;
                        final isCardinal = index % 3 == 0;
                        
                        return Transform.rotate(
                          angle: angle * math.pi / 180,
                          child: Container(
                            width: 240,
                            height: 240,
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 10,
                                  left: 117,
                                  child: Container(
                                    width: 6,
                                    height: isCardinal ? 25 : 15,
                                    decoration: BoxDecoration(
                                      color: isCardinal ? Colors.red : Colors.grey[600],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                                if (isCardinal)
                                  Positioned(
                                    top: 40,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Text(
                                        _getCardinalDirection(angle),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      
                      // Compass Needle
                      Transform.rotate(
                        angle: _currentHeading * math.pi / 180,
                        child: Container(
                          width: 4,
                          height: 120,
                          child: Column(
                            children: [
                              // North pointer (red)
                              Container(
                                width: 4,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(2),
                                  ),
                                ),
                              ),
                              // South pointer (white/gray)
                              Container(
                                width: 4,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Center dot
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Heading Information
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                'Arah',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${_currentHeading.toStringAsFixed(0)}°',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Mata Angin',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _getDirectionName(_currentHeading),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isCompassActive ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isCompassActive ? Icons.sensors : Icons.sensors_off,
                              color: _isCompassActive ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              _isCompassActive ? 'Kompas Aktif' : 'Kompas Tidak Aktif',
                              style: TextStyle(
                                color: _isCompassActive ? Colors.green[700] : Colors.red[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Compass Features
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🧭 Fitur Kompas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Menunjukkan arah mata angin\n'
                        '• Membantu navigasi ke lokasi TPS\n'
                        '• Berguna saat melakukan aktivitas daur ulang\n'
                        '• Compass digital real-time',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCardinalDirection(double angle) {
    switch (angle.toInt()) {
      case 0:
        return 'N';
      case 90:
        return 'E';
      case 180:
        return 'S';
      case 270:
        return 'W';
      default:
        return '';
    }
  }

  String _getDirectionName(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'Utara';
    if (heading >= 22.5 && heading < 67.5) return 'Timur Laut';
    if (heading >= 67.5 && heading < 112.5) return 'Timur';
    if (heading >= 112.5 && heading < 157.5) return 'Tenggara';
    if (heading >= 157.5 && heading < 202.5) return 'Selatan';
    if (heading >= 202.5 && heading < 247.5) return 'Barat Daya';
    if (heading >= 247.5 && heading < 292.5) return 'Barat';
    if (heading >= 292.5 && heading < 337.5) return 'Barat Laut';
    return 'Unknown';
  }


  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('name') ?? 'Username tidak ditemukan';
      _email = prefs.getString('email') ?? 'Email tidak ditemukan';
      _userId = prefs.getInt('id'); // Store user ID

      // Set the controllers' text to the current user data
    _usernameController.text = _username;
    });

    // Fetch waste logs after loading user data
    if (_userId != null) {
      await _fetchWasteLogs();
      await _fetchUserFeedback();
      await _loadAllFeedback(); // Load all feedback on init
    }
  }

Future<void> _updateProfile(int id) async {
  final requestBody = {
    'username': _usernameController.text.trim(),
  };

  final response = await http.put(
    Uri.parse('hhttps://ecowaste-1013759214686.us-central1.run.app/api/profile/$id/username'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode(requestBody),
  );

  if (response.statusCode == 200) {
    final result = json.decode(response.body);
    print('Profile updated successfully: ${result['data']}');
    // Handle success (refresh profile or UI)

    // After updating the profile, refresh the profile data
    await _refreshProfileData(id);

  } else {
    print('Failed to update profile: ${response.body}');
    // Handle failure (show error message)
  }
}

// Method to refresh the profile data from the backend
Future<void> _refreshProfileData(int id) async {
  final response = await http.get(
    Uri.parse('https://ecowaste-1013759214686.us-central1.run.app/api/profile/$id'),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final result = json.decode(response.body);
    print('Profile refreshed successfully: ${result['data']}');

    setState(() {
      // Update the state with the latest profile information
      _username = result['data']['username'];
      _email = result['data']['email'];
    });

    // Optionally, show a success message or perform other UI updates
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  } else {
    print('Failed to fetch profile data: ${response.body}');
    // Handle failure (show error message)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to refresh profile data. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  // Fetch waste logs from API
  Future<void> _fetchWasteLogs() async {
    if (_userId == null) {
      print('User ID not found');
      return;
    }

    setState(() {
      isLoadingWasteLogs = true;
    });

    try {
      // Fixed: Use actual user ID in the URL instead of placeholder
      final response = await http.get(
        Uri.parse(
          'https://ecowaste-1013759214686.us-central1.run.app/api/waste-logs/$_userId',
        ), // Changed from :user_id to $_userId
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        List<Map<String, dynamic>> logs = [];
        if (data is Map && data.containsKey('data')) {
          logs = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          logs = List<Map<String, dynamic>>.from(data);
        }

        setState(() {
          wasteLogData = logs;
          isLoadingWasteLogs = false;
        });

        print(
          'Successfully loaded ${wasteLogData.length} waste logs for user $_userId',
        );
      } else {
        print('Failed to load waste logs: ${response.statusCode}');
        print('Response body: ${response.body}');
        setState(() {
          isLoadingWasteLogs = false;
        });

        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat riwayat log sampah'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error fetching waste logs: $e');
      setState(() {
        isLoadingWasteLogs = false;
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add refresh function
  Future<void> _refreshWasteLogs() async {
    await _fetchWasteLogs();
  }

  void nextStep() {
    if (currentEcoPoints < 10) {
      setState(() {
        currentEcoPoints++;
      });
    }
  }

  void backStep() {
    if (currentEcoPoints > 0) {
      setState(() {
        currentEcoPoints--;
      });
    }
  }

  Widget _buildWasteLogItem(Map<String, dynamic> logData, int index) {
    // Get category name - handle both direct string and nested object
    String category = 'Tidak diketahui';
    if (logData['category'] != null) {
      if (logData['category'] is Map) {
        category = logData['category']['name'] ?? 'Tidak diketahui';
      } else {
        category = logData['category'].toString();
      }
    } else if (logData['category_id'] != null) {
      // Map category_id to category names based on your database
      final categoryMap = {
        1: 'Plastik',
        2: 'Kertas',
        3: 'Logam',
        4: 'Kaca',
        5: 'Organik',
        6: 'Elektronik',
      };
      category =
          categoryMap[logData['category_id']] ??
          'Kategori ${logData['category_id']}';
    }

    // Get other data with proper defaults
    final description =
        logData['description']?.toString() ?? 'Tidak ada deskripsi';
    final weight = double.tryParse(logData['weight']?.toString() ?? '0') ?? 0.0;
    final pickupTime = logData['pickup_time']?.toString() ?? '00:00:00';
    final timezone = logData['timezone']?.toString() ?? 'WIB';
    final currency = logData['currency']?.toString() ?? 'IDR';
    final price = double.tryParse(logData['price']?.toString() ?? '0') ?? 0.0;
    final ecoPoints =
        int.tryParse(logData['eco_points']?.toString() ?? '0') ?? 0;

    // Get location name - handle both direct and nested
    String location = 'Lokasi tidak diketahui';
    if (logData['location'] != null) {
      if (logData['location'] is Map) {
        location = logData['location']['name'] ?? 'Lokasi tidak diketahui';
      } else {
        location = logData['location'].toString();
      }
    } else if (logData['location_id'] != null) {
      // You might want to map location_id to actual location names
      location = 'Lokasi ${logData['location_id']}';
    }

    // Set emoji based on category
    String emoji = '🗑️';
    switch (category.toLowerCase()) {
      case 'plastik':
        emoji = '♻️';
        break;
      case 'kertas':
        emoji = '📄';
        break;
      case 'logam':
        emoji = '🔩';
        break;
      case 'kaca':
        emoji = '🍶';
        break;
      case 'organik':
        emoji = '🍃';
        break;
      case 'elektronik':
        emoji = '📱';
        break;
    }

    // Handle date parsing
    DateTime submittedAt;
    try {
      if (logData['created_at'] != null) {
        submittedAt = DateTime.parse(logData['created_at'].toString());
      } else {
        submittedAt = DateTime.now();
      }
    } catch (e) {
      submittedAt = DateTime.now();
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Log #${index + 1} • ${_formatDate(submittedAt)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$ecoPoints pts',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('📝 Deskripsi', description),
                  _buildDetailRow(
                    '⚖️ Berat',
                    '${weight.toStringAsFixed(1)} kg',
                  ),
                  _buildDetailRow('📍 Lokasi', location),
                  _buildDetailRow('⏰ Waktu', '$pickupTime $timezone'),
                  _buildDetailRow(
                    '💰 Harga',
                    '${price.toStringAsFixed(0)} $currency',
                  ),
                ],
              ),
            ),
            // Edit and Delete buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // Call the delete function
                    _deleteWasteLog(logData['id']);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteWasteLog(int id) async {
    try {
      final response = await http.delete(
        Uri.parse(
          'https://ecowaste-1013759214686.us-central1.run.app/api/waste-log/$id',
        ), // Ensure $id is being correctly replaced
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('Successfully deleted waste log: $result');
        // Refresh the UI or any other necessary actions after deleting the log
      } else if (response.statusCode == 404) {
        print('Error: Waste log with ID $id not found.');
      } else {
        print(
          'Failed to delete waste log: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('An error occurred: $e');
    }
  }

  Future<void> _showImageSourceActionSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Pilih Foto Profil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (!kIsWeb)
                ListTile(
                  leading: Icon(Icons.photo_camera, color: Colors.green),
                  title: Text('Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.green),
                title: Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profileImageBytes != null || _profileImageFile != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Hapus Foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
              ListTile(
                leading: Icon(Icons.cancel),
                title: Text('Batal'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _profileImageBytes = bytes;
            _profileImageFile = null;
          });
        } else {
          final file = File(pickedFile.path);
          setState(() {
            _profileImageFile = file;
            _profileImageBytes = null;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Foto profil berhasil diubah!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeProfileImage() {
    setState(() {
      _profileImageFile = null;
      _profileImageBytes = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Foto profil dihapus'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _fetchUserFeedback() async {
    if (_userId == null) {
      print('User ID not found');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://ecowaste-1013759214686.us-central1.run.app/api/feedback/user/$_userId',
        ), // Lebih spesifik endpoint
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Fetched feedback data: $data'); // Debug log

        // Handle different response formats
        if (data is Map && data.containsKey('data')) {
          final feedback = data['data'];

          // Cek apakah feedback adalah array atau single object
          if (feedback is List && feedback.isNotEmpty) {
            // Ambil feedback terbaru jika ada multiple feedback
            final latestFeedback = feedback.first;
            setState(() {
              _messageController.text = latestFeedback['message'] ?? '';
              _selectedRating = latestFeedback['rating'] ?? 0;
              _appFeedbackController.text =
                  latestFeedback['app_feedback'] ?? '';
            });
          } else if (feedback is Map) {
            // Single feedback object
            setState(() {
              _messageController.text = feedback['message'] ?? '';
              _selectedRating = feedback['rating'] ?? 0;
              _appFeedbackController.text = feedback['app_feedback'] ?? '';
            });
          }
        } else if (data is List && data.isNotEmpty) {
          // Response langsung berupa array
          final latestFeedback = data.first;
          setState(() {
            _messageController.text = latestFeedback['message'] ?? '';
            _selectedRating = latestFeedback['rating'] ?? 0;
            _appFeedbackController.text = latestFeedback['app_feedback'] ?? '';
          });
        } else {
          print('No feedback found for user');
        }
      } else {
        print('Failed to load feedback: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching feedback: $e');
    }
  }

 Widget _buildFeedbackDisplay() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📝 Saran dan Kesan Anda:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        Text(
          _messageController.text.isNotEmpty
              ? _messageController.text
              : 'Belum ada saran dan kesan.',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 16),
        Text(
          '⭐ Rating: ${_selectedRating ?? 0}',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 16),
        Text(
          'Feedback Aplikasi: ${_appFeedbackController.text.isNotEmpty ? _appFeedbackController.text : 'Belum ada feedback aplikasi.'}',
          style: TextStyle(fontSize: 14),
        ),
      ],
    ),
  );
}

Future<void> _submitFeedback() async {
  if (!_formKey.currentState!.validate()) return;

  // Prepare data untuk dikirim ke backend
  final requestBody = {
    'user_id': _userId, // Pastikan _userId tidak null
    'user_name': _username.isNotEmpty ? _username : 'Anonymous',
    'message': _messageController.text.trim(),
    'rating': _selectedRating ?? 0,
    'app_feedback': _appFeedbackController.text.trim(),
  };

  try {
    // Kirim data ke backend
    final response = await http.post(
      Uri.parse('https://ecowaste-1013759214686.us-central1.run.app/api/feedback'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final result = json.decode(response.body);
      print('Feedback berhasil disimpan: ${result['data']}');

      // Update UI setelah berhasil simpan
      setState(() {
        final newFeedback = {
          'user_name': requestBody['user_name'],
          'message': requestBody['message'],
          'rating': requestBody['rating'],
          'appFeedback': requestBody['app_feedback'],
          'created_at': DateTime.now(),
        };

        _feedbackList.insert(0, newFeedback);
        _messageController.clear();
        _appFeedbackController.clear();
        _selectedRating = null;
        showFeedbackForm = false;

        currentEcoPoints += 50;
        widget.onEcoPointsUpdate(currentEcoPoints);
      });

      // Refresh all feedback after submitting
      await _loadAllFeedback();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Feedback berhasil dikirim. EcoPoints bertambah 50!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      print('Failed to submit feedback: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim feedback. Coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    print('Error submitting feedback: $e');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan. Periksa koneksi internet.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Widget _buildRatingDropdown() {
  return DropdownButtonFormField<int>(
    value: _selectedRating,
    decoration: InputDecoration(
      labelText: 'Rating Aplikasi',
      border: OutlineInputBorder(),
    ),
    items: List.generate(5, (index) {
      final starCount = index + 1;
      return DropdownMenuItem(value: starCount, child: Text('⭐' * starCount));
    }),
    onChanged: (val) => setState(() => _selectedRating = val),
    validator: (val) {
      if (val == null) return 'Pilih rating';
      return null;
    },
  );
}


// Method untuk menampilkan semua feedback
Future<void> _loadAllFeedback() async {
  setState(() {
    isLoadingFeedback = true;
  });

  try {
    final response = await http.get(
      Uri.parse('https://ecowaste-1013759214686.us-central1.run.app/api/feedbacks'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      setState(() {
        if (result is Map && result.containsKey('data')) {
          _feedbackList = List<Map<String, dynamic>>.from(result['data']);
        } else if (result is List) {
          _feedbackList = List<Map<String, dynamic>>.from(result);
        } else {
          _feedbackList = [];
        }
        isLoadingFeedback = false;
      });
      print('Successfully loaded ${_feedbackList.length} feedback entries');
    } else {
      print('Failed to load feedback: ${response.statusCode}');
      print('Response body: ${response.body}');
      setState(() {
        isLoadingFeedback = false;
      });
    }
  } catch (e) {
    print('Error loading feedback: $e');
    setState(() {
      isLoadingFeedback = false;
    });
  }
}

// Widget untuk menampilkan daftar semua feedback
Widget _buildFeedbackList() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  showAllFeedback = false;
                });
              },
              icon: Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                'Data Semua Feedback',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            IconButton(
              onPressed: _loadAllFeedback,
              icon: Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
        SizedBox(height: 16),

        // Show loading indicator
        if (isLoadingFeedback)
          Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: Colors.green),
                SizedBox(height: 16),
                Text('Memuat data feedback...'),
              ],
            ),
          )
        else if (_feedbackList.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.feedback_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Belum ada feedback yang tersedia.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'Jadilah yang pertama memberikan feedback!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadAllFeedback,
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _feedbackList.length,
            itemBuilder: (context, index) {
              final feedback = _feedbackList[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              feedback['user_name'] ?? 'Anonymous',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '⭐ ${feedback['rating'] ?? 0}',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saran & Kesan:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              feedback['message'] ?? 'Tidak ada pesan',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Feedback Aplikasi:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              feedback['app_feedback'] ?? feedback['appFeedback'] ?? 'Tidak ada feedback aplikasi',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _formatDate(DateTime.tryParse(feedback['created_at']?.toString() ?? '') ?? DateTime.now()),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    ),
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) {
    return 'Hari ini';
  } else if (difference.inDays == 1) {
    return 'Kemarin';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} hari lalu';
  } else {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Logout function
Future<void> _logout() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  } catch (e) {
    print('Error during logout: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

@override
Widget build(BuildContext context) {
  if (showCompass) {
    return Scaffold(
      body: SafeArea(
        child: _buildCompass(),
      ),
    );
  }

  return Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: AppBar(
      title: Text('Profil Saya'),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: _logout,
          tooltip: 'Logout',
        ),
      ],
    ),
    body: SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green, Colors.green[300]!],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Image
                  GestureDetector(
                    onTap: _showImageSourceActionSheet,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _getProfileImage(),
                            child: _getProfileImage() == null
                                ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // User Info
                  Text(
                    _username,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Eco Points Display
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.eco, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          '${widget.ecoPoints} Eco Points',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Button to toggle showing the update profile form
          _buildUpdateProfileButton(),
          // Conditional Profile Update Form Display
          if (showProfileUpdateForm) _buildProfileUpdateForm(),
          // Menu Options
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Compass Feature
                _buildMenuOption(
                  icon: Icons.explore,
                  title: 'Kompas Digital',
                  subtitle: 'Navigasi dan arah mata angin',
                  onTap: () {
                    setState(() {
                      showCompass = true;
                    });
                  },
                ),
                
                // Waste Log History
                _buildMenuOption(
                  icon: Icons.history,
                  title: 'Riwayat Log Sampah',
                  subtitle: 'Lihat semua aktivitas daur ulang Anda',
                  onTap: () {
                    setState(() {
                      showWasteLogHistory = !showWasteLogHistory;
                      if (showWasteLogHistory && wasteLogData.isEmpty) {
                        _fetchWasteLogs();
                      }
                    });
                  },
                ),
                
                // Feedback Option
                _buildMenuOption(
                  icon: Icons.feedback,
                  title: 'Berikan Feedback',
                  subtitle: 'Bagikan saran dan kesan Anda',
                  onTap: () {
                    setState(() {
                      showFeedbackForm = !showFeedbackForm;
                    });
                  },
                ),
                
                // View All Feedback
                _buildMenuOption(
                  icon: Icons.reviews,
                  title: 'Lihat Semua Feedback',
                  subtitle: 'Feedback dari pengguna lain',
                  onTap: () {
                    setState(() {
                      showAllFeedback = !showAllFeedback;
                      if (showAllFeedback && _feedbackList.isEmpty) {
                        _loadAllFeedback();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Conditional Content
          if (showWasteLogHistory) _buildWasteLogHistory(),
          if (showFeedbackForm) _buildFeedbackForm(),
          if (showAllFeedback) _buildAllFeedbackList(),
          
          SizedBox(height: 20),
        ],
      ),
    ),
  );
}

ImageProvider? _getProfileImage() {
  if (kIsWeb && _profileImageBytes != null) {
    return MemoryImage(_profileImageBytes!);
  } else if (!kIsWeb && _profileImageFile != null) {
    return FileImage(_profileImageFile!);
  }
  return null;
}

Widget _buildMenuOption({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return Card(
    margin: EdgeInsets.only(bottom: 12),
    elevation: 2,
    child: ListTile(
      leading: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.green, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    ),
  );
}

Widget _buildWasteLogHistory() {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 16),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Riwayat Log Sampah',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            IconButton(
              onPressed: _refreshWasteLogs,
              icon: Icon(Icons.refresh),
            ),
          ],
        ),
        SizedBox(height: 16),
        
        if (isLoadingWasteLogs)
          Center(child: CircularProgressIndicator())
        else if (wasteLogData.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'Belum ada riwayat log sampah',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              ...wasteLogData.asMap().entries.map(
                (entry) => _buildWasteLogItem(entry.value, entry.key),
              ),
            ],
          ),
      ],
    ),
  );
}

Widget _buildFeedbackForm() {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 16),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.feedback, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Berikan Feedback',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Existing feedback display
          if (_messageController.text.isNotEmpty || _selectedRating != null)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feedback Anda Sebelumnya:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _buildFeedbackDisplay(),
                ],
              ),
            ),
          
          SizedBox(height: 16),
          
          // Message Field
          TextFormField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: 'Saran dan Kesan',
              hintText: 'Bagikan pengalaman Anda menggunakan aplikasi ini...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.message),
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Mohon berikan saran dan kesan Anda';
              }
              return null;
            },
          ),
          
          SizedBox(height: 16),
          
          // Rating Field
          Text(
            'Rating Aplikasi:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = index + 1;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.star,
                    size: 30,
                    color: (_selectedRating != null && index < _selectedRating!)
                        ? Colors.amber
                        : Colors.grey[300],
                  ),
                ),
              );
            }),
          ),
          
          SizedBox(height: 16),
          
          // App Feedback Field
          TextFormField(
            controller: _appFeedbackController,
            decoration: InputDecoration(
              labelText: 'Feedback Aplikasi',
              hintText: 'Apa yang bisa diperbaiki dari aplikasi ini?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.rate_review),
            ),
            maxLines: 3,
          ),
          
          SizedBox(height: 20),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Kirim Feedback',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
// Button to toggle showing the update profile form
Widget _buildUpdateProfileButton() {
  return ElevatedButton(
    onPressed: () {
      setState(() {
        showProfileUpdateForm = !showProfileUpdateForm;
      });
    },
    child: Text(showProfileUpdateForm ? 'Cancel Update' : 'Update Profile'),
  );
}

Widget _buildProfileUpdateForm() {
  return Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        TextField(
          controller: _usernameController, // Using the controller for username
          decoration: InputDecoration(labelText: 'Username'),
        ),
        
        ElevatedButton(
          onPressed: () {
            _updateProfile(_userId!); // Ensure userId is passed correctly
          },
          child: Text('Update Profile'),
        ),
      ],
    ),
  );
}



Widget _buildAllFeedbackList() {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 16),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.reviews, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Semua Feedback Pengguna',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            IconButton(
              onPressed: _loadAllFeedback,
              icon: Icon(Icons.refresh),
            ),
          ],
        ),
        SizedBox(height: 16),
        
        if (isLoadingFeedback)
          Center(child: CircularProgressIndicator())
        else if (_feedbackList.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'Belum ada feedback dari pengguna',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else
          Column(
            children: _feedbackList.map((feedback) {
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Text(
                              (feedback['user_name'] ?? 'U')[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feedback['user_name'] ?? 'Anonymous',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      Icons.star,
                                      size: 16,
                                      color: index < (feedback['rating'] ?? 0)
                                          ? Colors.amber
                                          : Colors.grey[300],
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      if (feedback['message'] != null && feedback['message'].isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(feedback['message']),
                        ),
                      if (feedback['app_feedback'] != null && feedback['app_feedback'].isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(top: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Feedback Aplikasi:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(feedback['app_feedback']),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    ),
  );
}
}