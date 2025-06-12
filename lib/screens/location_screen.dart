import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController _searchController = TextEditingController(text: 'bank sampah');
  List<Map<String, dynamic>> _allLocations = [];
  List<Map<String, dynamic>> _filteredLocations = [];
  bool _isLoading = false;
  String? _error;

  String? _selectedProvince;
  String? _selectedCity;

  // Fetch locations
  Future<void> _fetchLocations(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=50',
    );

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'EcoWasteManagerApp/1.0 (email@example.com)',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Cast and store all locations
        _allLocations = data.cast<Map<String, dynamic>>();

        // Set initial filter (all locations)
        _filteredLocations = List.from(_allLocations);

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch location data (status ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error occurred: $e';
        _isLoading = false;
      });
    }
  }

  // Filter locations based on search, province, and city
  void _filterLocations() {
    setState(() {
      _filteredLocations = _allLocations.where((loc) {
        final name = (loc['display_name'] ?? '').toString().toLowerCase();
        final province = loc['address']?['state'] ?? '';
        final city = loc['address']?['city'] ?? loc['address']?['town'] ?? loc['address']?['village'] ?? '';

        final matchesSearch = name.contains(_searchController.text.toLowerCase());
        final matchesProvince = _selectedProvince == null || _selectedProvince!.isEmpty || province == _selectedProvince;
        final matchesCity = _selectedCity == null || _selectedCity!.isEmpty || city == _selectedCity;

        return matchesSearch && matchesProvince && matchesCity;
      }).toList();
    });
  }

  // Open map in external app (Google Maps or OpenStreetMap)
  Future<void> _openMap(String lat, String lon) async {
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    final osmUrl = Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=18/$lat/$lon');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(osmUrl)) {
      await launchUrl(osmUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open map application')),
      );
    }
  }

  // Build location card
  Widget _buildLocationCard(Map<String, dynamic> loc) {
    final lat = loc['lat'] ?? '';
    final lon = loc['lon'] ?? '';
    final displayName = loc['display_name'] ?? 'Name not available';
    final province = loc['address']?['state'] ?? 'Province unknown';
    final city = loc['address']?['city'] ?? loc['address']?['town'] ?? loc['address']?['village'] ?? 'City unknown';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 2,
      child: ListTile(
        leading: Icon(Icons.location_on, color: Colors.green[700]),
        title: Text(displayName),
        subtitle: Text('$city, $province\nLat: $lat, Lon: $lon'),
        isThreeLine: true,
        onTap: () {
          if (lat.isNotEmpty && lon.isNotEmpty) {
            _openMap(lat, lon);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location coordinates not available')),
            );
          }
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchLocations(_searchController.text); // Call to fetch the initial locations
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📍 Locations'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search location...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (_) => _filterLocations(),
                    onSubmitted: (_) => _filterLocations(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _filterLocations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter Dropdowns
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    hint: const Text('Select Province'),
                    items: [''].followedBy(_getProvinces()).map((prov) {
                      return DropdownMenuItem(
                        value: prov.isEmpty ? null : prov,
                        child: Text(prov.isEmpty ? 'All Provinces' : prov),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedProvince = val;
                        _selectedCity = null;
                        _filterLocations();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCity,
                    hint: const Text('Select City'),
                    items: [''].followedBy(_getCities()).map((city) {
                      return DropdownMenuItem(
                        value: city.isEmpty ? null : city,
                        child: Text(city.isEmpty ? 'All Cities' : city),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCity = val;
                        _filterLocations();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // List of locations
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _filteredLocations.isEmpty
                          ? const Center(child: Text('No locations found'))
                          : ListView.builder(
                              itemCount: _filteredLocations.length,
                              itemBuilder: (context, index) {
                                return _buildLocationCard(_filteredLocations[index]);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getProvinces() {
    return _allLocations
        .map((loc) => loc['address']?['state'] ?? 'Unknown')
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList()
        .cast<String>();
  }

  List<String> _getCities() {
    final filteredByProvince = _selectedProvince == null || _selectedProvince!.isEmpty
        ? _allLocations
        : _allLocations.where((loc) => (loc['address']?['state'] ?? '') == _selectedProvince).toList();

    return filteredByProvince
        .map((loc) => loc['address']?['city'] ?? loc['address']?['town'] ?? loc['address']?['village'] ?? 'Unknown')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
        .cast<String>();
  }
}
