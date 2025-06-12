import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LogSampahScreen extends StatefulWidget {
  final void Function(int) onEcoPointsUpdate;

  const LogSampahScreen({
    Key? key,
    required this.onEcoPointsUpdate, // Constructor to accept the callback
  }) : super(key: key);

  @override
  _LogSampahScreenState createState() => _LogSampahScreenState();
}

class _LogSampahScreenState extends State<LogSampahScreen> {
  int currentStep = 0;
  int currentEcoPoints = 0; // Added to track EcoPoints

  // Form fields
  String selectedCategory = 'Plastik';
  TextEditingController descriptionController = TextEditingController(
    text: 'Botol plastik bekas minuman',
  );
  String description = 'Botol plastik bekas minuman';
  double weight = 1.5;
  String schedule = 'Sekarang';

  // Currency conversion fields
  final Map<String, double> currencyRates = {
    'IDR': 1,
    'USD': 0.000067,
    'EUR': 0.000061,
  };
  String selectedCurrency = 'IDR';

  // Harga per kg kategori sampah dalam IDR (contoh)
  final Map<String, int> basePrices = {
    'Plastik': 2500,
    'Kertas': 2000,
    'Logam': 3500,
    'Organik': 700,
    'Elektronik': 15000,
    'B3': 0,
  };

  // Map category names to IDs (adjust these IDs based on your database)
  final Map<String, int> categoryIds = {
    'Plastik': 1,
    'Kertas': 2,
    'Logam': 3,
    'Organik': 4,
    'Elektronik': 5,
    'B3': 6,
  };

  // Lokasi bank sampah dari API
  List<Map<String, dynamic>> locations = [];
  int? selectedLocationIndex;
  int?
  selectedLocationId; // Changed to store location ID instead of name/coords

  bool isLoadingLocations = false;
  String? locationError;

  // Waktu dan zona waktu untuk pembuangan
  TimeOfDay? selectedTime;
  String selectedTimeZone = 'WIB';

  final categories = {
    'Plastik': {
      'emoji': '🥤',
      'info': 'Daur ulang: ✅ Ya\nTips: Cuci bersih sebelum buang',
    },
    'Kertas': {
      'emoji': '📄',
      'info': 'Daur ulang: ✅ Ya\nTips: Pisahkan kertas bersih dan kotor',
    },
    'Logam': {
      'emoji': '🥫',
      'info': 'Daur ulang: ✅ Ya\nTips: Bersihkan sebelum dijual',
    },
    'Organik': {
      'emoji': '🍌',
      'info': 'Daur ulang: ❌ Tidak\nTips: Komposkan sisa makanan',
    },
    'Elektronik': {
      'emoji': '🔋',
      'info': 'Daur ulang: ✅ Ya\nTips: Bawa ke pusat daur ulang khusus',
    },
    'B3': {
      'emoji': '🧪',
      'info': 'Daur ulang: ❌ Tidak\nTips: Tangani dengan aman dan benar',
    },
  };

  void nextStep() {
    if (currentStep < 4) setState(() => currentStep++);
  }

  void backStep() {
    if (currentStep > 0) setState(() => currentStep--);
  }

  double get priceInSelectedCurrency {
    final basePrice = basePrices[selectedCategory] ?? 0;
    final rate = currencyRates[selectedCurrency] ?? 1;
    return basePrice * weight * rate;
  }

  int get totalPoints {
    // Contoh: 1 point per 500 IDR dari harga dasar * berat
    final basePrice = basePrices[selectedCategory] ?? 0;
    return ((basePrice * weight) / 500).round();
  }

  Future<void> fetchLocations() async {
    setState(() {
      isLoadingLocations = true;
      locationError = null;
      locations = [];
      selectedLocationIndex = null;
      selectedLocationId = null;
    });

    try {
      // Data statis bank sampah dengan id untuk setiap lokasi
      final staticLocations = [
        {
          'id': 1, // This ID should match your database
          'lat': '-6.9279',
          'lon': '107.6127',
          'display_name':
              'Bank Sampah, Jalan Lingkar Kencana, Sukaasih, Bojongloa Kaler, Bandung City, West Java',
          'name': 'Bank Sampah Lingkar Kencana',
          'city': 'Bandung City',
          'province': 'West Java',
          'emoji': '♻️',
          'location_type': 'Recycling',
        },
        {
          'id': 2,
          'lat': '-6.9271',
          'lon': '107.613',
          'display_name':
              'Bank Sampah, Jalan Payung Kencana, Sukaasih, Bojongloa Kaler, Bandung City, West Java',
          'name': 'Bank Sampah Payung Kencana',
          'city': 'Bandung City',
          'province': 'West Java',
          'emoji': '♻️',
          'location_type': 'Recycling',
        },
        {
          'id': 3,
          'lat': '-6.928',
          'lon': '107.614',
          'display_name':
              'Bank Sampah, Jalan Luna 4, Jamika, Bojongloa Kaler, Bandung City, West Java',
          'name': 'Bank Sampah Luna 4',
          'city': 'Bandung City',
          'province': 'West Java',
          'emoji': '♻️',
          'location_type': 'Recycling',
        },
        {
          'id': 4,
          'lat': '-7.0035',
          'lon': '110.4207',
          'display_name':
              'Bank Sampah, Jalan Bulustalan III B, RW 03, Bulustalan, Semarang, Central Java',
          'name': 'Bank Sampah Bulustalan',
          'city': 'Semarang',
          'province': 'Central Java',
          'emoji': '♻️',
          'location_type': 'Recycling',
        },
        {
          'id': 5,
          'lat': '-7.547',
          'lon': '110.8267',
          'display_name':
              'Bank Sampah, Kepuh Asri RT 04, Kadipiro, Surakarta, Central Java',
          'name': 'Bank Sampah Kepuh Asri',
          'city': 'Surakarta',
          'province': 'Central Java',
          'emoji': '♻️',
          'location_type': 'Recycling',
        },
        {
          'id': 6,
          'lat': '-0.5037',
          'lon': '101.4464',
          'display_name':
              'Bank Sampah, Jalan Soekarno Hatta, East Sidomulyo, Pekanbaru, Riau',
          'name': 'Bank Sampah Soekarno Hatta',
          'city': 'Pekanbaru',
          'province': 'Riau',
          'emoji': '♻️',
          'location_type': 'Recycling',
        },
        {
          'id': 7,
          'lat': '-6.3287',
          'lon': '106.6556',
          'display_name':
              'Bank Sampah, Parkiran Wisma Tamu Puspiptek, Perum Serpong Damai, South Tangerang, Banten',
          'name': 'Bank Sampah Puspiptek',
          'city': 'South Tangerang',
          'province': 'Banten',
          'emoji': '♻️',
          'location_type': 'Recycling',
        },
      ];

      // Set data ke variabel locations
      locations = staticLocations;
    } catch (e) {
      locationError = 'Kesalahan: $e';
    } finally {
      setState(() {
        isLoadingLocations = false;
      });
    }
  }

  String formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  Future<void> submitLogSampah() async {
    final apiUrl =
        'https://ecowaste-1013759214686.us-central1.run.app/api/eco/add-log'; // Update with your backend API URL

    // Get the user ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(
      'id',
    ); // Retrieve the user_id from SharedPreferences

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('User ID is required')));
      return;
    }

    // Make sure a location has been selected
    if (selectedLocationId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a location')));
      return;
    }

    // Get category ID
    final categoryId = categoryIds[selectedCategory];
    if (categoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid category selected')));
      return;
    }

    // Save values to SharedPreferences
    await prefs.setString('logDescription', descriptionController.text);
    await prefs.setDouble('logWeight', weight);
    await prefs.setString('selectedCategory', selectedCategory);
    await prefs.setString('schedule', schedule);
    // Get current timestamp for created_at and updated_at
    // Try different timestamp formats depending on your backend/database
    final now = DateTime.now().toIso8601String(); // ISO format
    // Alternative formats you can try:
    // final now = DateTime.now().millisecondsSinceEpoch; // Unix timestamp
    // final now = DateTime.now().toString(); // Default Dart format
    // Prepare request body according to backend controller expectations
    final requestBody = {
      'user_id': userId,
      'category_id': categoryId,
      'description': descriptionController.text,
      'weight': weight,
      'schedule': schedule,
      'location_id': selectedLocationId,
      'pickup_time':
          selectedTime != null ? formatTimeOfDay(selectedTime!) : null,
      'timezone': selectedTimeZone,
      'currency': selectedCurrency,
      'price': priceInSelectedCurrency,
      'eco_points': totalPoints,
      'created_at': now,
    };

    // Log the request body to ensure it's being sent correctly
    print('Request Body:');
    print(requestBody);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Log Sampah berhasil dikirim ke backend!'),
            backgroundColor: Colors.green,
          ),
        );
        // Update EcoPoints after successful submission
        setState(() {
          currentEcoPoints += totalPoints;
        });

        widget.onEcoPointsUpdate(
          currentEcoPoints,
        ); // Update EcoPoints after submission
        Navigator.pop(context, totalPoints);
      } else {
        final errorBody = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengirim log sampah: ${errorBody['message'] ?? response.statusCode}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: ValueKey(1),
      children: [
        Text(
          '📋 Step 1: Pilih Kategori Sampah',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              categories.entries.map((entry) {
                final key = entry.key;
                final value = entry.value;
                final isSelected = key == selectedCategory;
                return ChoiceChip(
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value['emoji'] ?? '',
                        style: TextStyle(fontSize: 28),
                      ),
                      Text(key, style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = key;
                    });
                  },
                  selectedColor: Colors.green.shade200,
                  backgroundColor: Colors.grey.shade200,
                );
              }).toList(),
        ),
        SizedBox(height: 20),
        Text('ℹ Info Kategori:', style: TextStyle(fontWeight: FontWeight.bold)),
        Container(
          margin: EdgeInsets.only(top: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Text(categories[selectedCategory]?['info'] ?? ''),
        ),
        SizedBox(height: 20),
        Row(
          children: [
            ElevatedButton(
              onPressed: nextStep,
              child: Text('➡ Lanjut ke Detail'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
              ),
            ),
            SizedBox(width: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('⬅ Kembali'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: ValueKey(2),
      children: [
        Text(
          '⚖ Step 2: Detail & Berat Sampah',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        SizedBox(height: 20),
        TextField(
          decoration: InputDecoration(
            labelText: '📝 Deskripsi Sampah',
            border: OutlineInputBorder(),
            hintText: 'Contoh: Botol air mineral 600ml',
          ),
          controller: descriptionController,
          onChanged: (val) {
            setState(() {
              description = val;
            });
          },
        ),

        SizedBox(height: 20),
        Text(
          '⚖ Berat Sampah (kg): ${weight.toStringAsFixed(1)}',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        Slider(
          value: weight,
          min: 0.1,
          max: 10,
          divisions: 99,
          label: weight.toStringAsFixed(1),
          activeColor: Colors.green.shade700,
          onChanged: (val) {
            setState(() {
              weight = val;
            });
          },
        ),
        SizedBox(height: 20),

        DropdownButtonFormField<String>(
          value: selectedCurrency,
          decoration: InputDecoration(
            labelText: '💰 Pilih Mata Uang',
            border: OutlineInputBorder(),
          ),
          items:
              currencyRates.keys.map((cur) {
                return DropdownMenuItem(value: cur, child: Text(cur));
              }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => selectedCurrency = val);
          },
        ),

        SizedBox(height: 20),
        Text(
          'Harga Sampah: ${priceInSelectedCurrency.toStringAsFixed(2)} $selectedCurrency',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.green.shade700,
          ),
        ),

        SizedBox(height: 20),

        // Pilih waktu penaruhan sampah
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickTime,
                icon: Icon(
                  Icons.access_time_outlined,
                  color: Colors.green.shade700,
                ),
                label: Text(
                  selectedTime == null
                      ? '⏰ Pilih Jam Penaruhan Sampah'
                      : '⏰ Jam Terpilih: ${formatTimeOfDay(selectedTime!)}',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ),
            ),
            SizedBox(width: 12),
            DropdownButton<String>(
              value: selectedTimeZone,
              items:
                  ['WIB', 'WITA', 'WIT', 'London']
                      .map((tz) => DropdownMenuItem(value: tz, child: Text(tz)))
                      .toList(),
              onChanged: (val) {
                if (val != null) setState(() => selectedTimeZone = val);
              },
              underline: Container(height: 2, color: Colors.green.shade700),
              dropdownColor: Colors.green.shade50,
            ),
          ],
        ),

        SizedBox(height: 20),

        Row(
          children: [
            ElevatedButton(
              onPressed: backStep,
              child: Text('⬅ Kembali'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: nextStep,
              child: Text('📍 Pilih Lokasi Bank Sampah'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: ValueKey(3),
      children: [
        Text(
          '📍 Step 3: Pilih Lokasi Bank Sampah',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: isLoadingLocations ? null : fetchLocations,
          child: Text(
            isLoadingLocations ? '🔄 Memuat...' : '🔄 Refresh Lokasi',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
          ),
        ),
        SizedBox(height: 15),
        if (isLoadingLocations)
          Center(child: CircularProgressIndicator())
        else if (locationError != null)
          Center(
            child: Column(
              children: [
                Text(locationError!, style: TextStyle(color: Colors.red)),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: fetchLocations,
                  child: Text('🔄 Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          )
        else if (locations.isEmpty)
          Center(
            child: Column(
              children: [
                Text('Tidak ada lokasi bank sampah ditemukan'),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: fetchLocations,
                  child: Text('🔄 Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          )
        else ...[
          DropdownButtonFormField<int>(
            value: selectedLocationIndex,
            decoration: InputDecoration(
              labelText: 'Pilih Lokasi Bank Sampah',
              border: OutlineInputBorder(),
            ),
            items:
                locations.asMap().entries.map((entry) {
                  final index = entry.key;
                  final location = entry.value;
                  final displayName =
                      location['display_name'] ?? 'Lokasi tidak diketahui';

                  return DropdownMenuItem<int>(
                    value: index,
                    child: Text(
                      displayName.length > 60
                          ? '${displayName.substring(0, 60)}...'
                          : displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
            onChanged: (int? selectedIndex) {
              if (selectedIndex != null && selectedIndex < locations.length) {
                setState(() {
                  selectedLocationIndex = selectedIndex;
                  final selectedLocation = locations[selectedIndex];
                  selectedLocationId =
                      selectedLocation['id']; // Store the location ID
                });
              }
            },
          ),
          SizedBox(height: 20),
          if (selectedLocationIndex != null)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 Lokasi terpilih:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    locations[selectedLocationIndex!]['display_name'] ??
                        'Lokasi tidak diketahui',
                  ),
                  SizedBox(height: 5),
                  Text(
                    '🏪 Nama: ${locations[selectedLocationIndex!]['name']}',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '📐 Koordinat: ${locations[selectedLocationIndex!]['lat']}, ${locations[selectedLocationIndex!]['lon']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                onPressed: backStep,
                child: Text('⬅ Kembali'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: selectedLocationIndex != null ? nextStep : null,
                child: Text('✅ Konfirmasi Log'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedLocationIndex != null
                          ? Colors.green.shade700
                          : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: ValueKey(4),
      children: [
        Text(
          '✅ Step 4: Konfirmasi & Berhasil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.celebration_rounded,
                size: 60,
                color: Colors.green.shade700,
              ),
              SizedBox(height: 10),
              Text(
                'Log Sampah Berhasil!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Terima kasih telah berkontribusi untuk lingkungan',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        Card(
          color: Colors.green.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '📋 Ringkasan Log Sampah:\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        '${categories[selectedCategory]?['emoji']} $selectedCategory (ID: ${categoryIds[selectedCategory]})\n',
                  ),
                  TextSpan(text: 'Deskripsi: $description\n'),
                  TextSpan(text: 'Berat: ${weight.toStringAsFixed(1)} kg\n'),
                  TextSpan(
                    text:
                        'Waktu Penaruhan: ${selectedTime != null ? formatTimeOfDay(selectedTime!) : 'Belum dipilih'} $selectedTimeZone\n',
                  ),
                  TextSpan(
                    text:
                        selectedLocationIndex != null
                            ? 'Lokasi: ${locations[selectedLocationIndex!]['name']} (ID: $selectedLocationId)\n'
                            : 'Lokasi: Tidak dipilih\n',
                  ),
                  TextSpan(text: 'Mata Uang: $selectedCurrency\n'),
                  TextSpan(
                    text:
                        'Harga: ${priceInSelectedCurrency.toStringAsFixed(2)} $selectedCurrency\n',
                  ),
                  TextSpan(text: 'EcoPoints: $totalPoints points\n'),
                ],
              ),
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  // Kirim data ke backend
                  await submitLogSampah();
                },
                child: Text('📤 Kirim ke Backend'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Log sampah berhasil disimpan lokal!'),
                    ),
                  );
                  Navigator.pop(
                    context,
                    totalPoints,
                  ); // Kirim poin kembali ke HomeScreen
                },
                child: Text('🏠 Kembali ke Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget stepContent;
    switch (currentStep) {
      case 0:
        stepContent = buildStep1();
        break;
      case 1:
        stepContent = buildStep2();
        break;
      case 2:
        stepContent = buildStep3();
        break;
      case 3:
        stepContent = buildStep4();
        break;
      default:
        stepContent = buildStep1();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Log Sampah Baru'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          // Wrap the content with SingleChildScrollView
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 400),
            child: stepContent,
            transitionBuilder:
                (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
          ),
        ),
      ),
    );
  }
}
