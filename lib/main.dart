import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart'; // For iOS-style alerts
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

void main() {
  runApp(const CircleScreenApp());
}

class CircleScreenApp extends StatelessWidget {
  const CircleScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CircleScreen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF29434e),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF102027),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
          ),
          bodyLarge: TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF455a64),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            elevation: 8,
            shadowColor: Colors.black45,
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// Shared server URL — we'll store it in memory (you can add shared_preferences later for persistence)
String serverUrl = 'http://108.254.1.184:9026'; // Default to your public IP

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const GalleryScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'Upload'),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.white60,
        backgroundColor: const Color(0xFF102027),
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewScreen(imageFile: _selectedImage!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CircleScreen')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle_outlined, size: 140, color: Colors.white38),
              const SizedBox(height: 40),
              const Text(
                'CircleScreen',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Share photos to your circular display',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white60),
              ),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate, size: 32),
                label: const Text(
                  'Select & Upload Photo',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PreviewScreen extends StatelessWidget {
  final File imageFile;

  const PreviewScreen({super.key, required this.imageFile});

  Future<void> _upload(BuildContext context) async {
    var request = http.MultipartRequest('POST', Uri.parse('$serverUrl/upload'));
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    try {
      var response = await request.send();
      if (context.mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploaded successfully! 🎉')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload failed — check server')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: () => _upload(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'How it will look on your device',
                style: TextStyle(fontSize: 20, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              ClipOval(
                child: Image.file(
                  imageFile,
                  width: 320,
                  height: 320,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Choose Different Photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  Future<List<String>>? _imagesFuture;

  @override
  void initState() {
    super.initState();
    _refreshImages();
  }

  Future<void> _refreshImages() async {
    setState(() {
      _imagesFuture = _fetchImages();
    });
  }

  Future<List<String>> _fetchImages() async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/list'));
      if (response.statusCode == 200) {
        return List<String>.from(json.decode(response.body));
      }
    } catch (e) {
      // Silent — will show empty state
    }
    return [];
  }

  Future<void> _deleteImage(String filename) async {
    await http.delete(Uri.parse('$serverUrl/delete/$filename'));
    _refreshImages();
  }

  Future<void> _setAsCurrent(String filename) async {
    // Copy the selected image to current.jpg
    try {
      final imgResponse = await http.get(
        Uri.parse('$serverUrl/images/$filename'),
      );
      if (imgResponse.statusCode == 200) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$serverUrl/upload'),
        );
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imgResponse.bodyBytes,
            filename: 'temp.jpg',
          ),
        );
        await request.send();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$filename is now on display!')),
          );
          _refreshImages();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to set as current')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: RefreshIndicator(
        onRefresh: _refreshImages,
        child: FutureBuilder<List<String>>(
          future: _imagesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No photos yet — upload some!',
                  style: TextStyle(color: Colors.white60),
                ),
              );
            }

            final images = snapshot.data!;

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final filename = images[index];
                final imageUrl = '$serverUrl/images/$filename';
                final isCurrent = filename == 'current.jpg';

                return GestureDetector(
                  onTap: () => showCupertinoModalPopup(
                    context: context,
                    builder: (context) => CupertinoActionSheet(
                      title: Text(filename),
                      message: isCurrent
                          ? const Text('This is currently displayed')
                          : null,
                      actions: [
                        if (!isCurrent)
                          CupertinoActionSheetAction(
                            child: const Text('Set as Current Display'),
                            onPressed: () {
                              Navigator.pop(context);
                              _setAsCurrent(filename);
                            },
                          ),
                        CupertinoActionSheetAction(
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                          isDestructiveAction: true,
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteImage(filename);
                          },
                        ),
                      ],
                      cancelButton: CupertinoActionSheetAction(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) => const Icon(Icons.error),
                        ),
                        if (isCurrent)
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.visibility,
                                color: Colors.cyanAccent,
                                size: 28,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _controller = TextEditingController(
    text: serverUrl,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Server Address',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'e.g. http://your-ip:9026',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.white10,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  serverUrl = _controller.text.trim();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Server set to: $serverUrl')),
                );
              },
              child: const Text('Save Server URL'),
            ),
            const SizedBox(height: 40),
            Text(
              'Current: $serverUrl',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
