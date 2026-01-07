import 'dart:io';
import 'dart:typed_data';

import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
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
        primaryColor: Colors.amber[700],
        scaffoldBackgroundColor: const Color(
          0xFF0F1C2E,
        ), // Slightly warmer deep blue
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A2A44),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: TextTheme(
          headlineMedium: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
          ),
          bodyLarge: TextStyle(color: Colors.white.withOpacity(0.95)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[600],
            foregroundColor: Colors.black87, // Dark text on yellow for contrast
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            elevation: 8,
            shadowColor: Colors.amber[900]!.withOpacity(0.5),
          ),
        ),
        colorScheme: ColorScheme.dark(
          primary: Colors.amber[600]!,
          secondary: Colors.orange[400]!,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

String serverUrl = 'http://108.254.1.184:9026';

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
        selectedItemColor: Colors.amber[400],
        unselectedItemColor: Colors.white60,
        backgroundColor: const Color(0xFF1B263B),
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
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 85);

    if (pickedFiles.isNotEmpty && mounted) {
      final imageFiles = pickedFiles.map((f) => File(f.path)).toList();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MultiPreviewScreen(imageFiles: imageFiles),
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
              Icon(Icons.circle_outlined, size: 160, color: Colors.amber[300]),
              const SizedBox(height: 40),
              const Text(
                'CircleScreen',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Share beautiful photos to your circular display',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, color: Colors.white70),
              ),
              const SizedBox(height: 70),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library, size: 34),
                label: const Text(
                  'Select Photos',
                  style: TextStyle(fontSize: 21),
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
            const SnackBar(content: Text('Upload failed — try again')),
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
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Exact appearance on your 240×240 display',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 21, color: Colors.white70),
              ),
              const SizedBox(height: 50),
              // Exact 240x240 circle with subtle shadow
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.file(imageFile, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 70),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Choose Another'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MultiPreviewScreen extends StatefulWidget {
  final List<File> imageFiles;

  const MultiPreviewScreen({super.key, required this.imageFiles});

  @override
  State<MultiPreviewScreen> createState() => _MultiPreviewScreenState();
}

class _MultiPreviewScreenState extends State<MultiPreviewScreen> {
  bool _isUploading = false;
  int _uploadedCount = 0;

  Future<void> _uploadAll() async {
    setState(() {
      _isUploading = true;
      _uploadedCount = 0;
    });

    int successCount = 0;
    int failCount = 0;

    for (var imageFile in widget.imageFiles) {
      try {
        final bytes = await imageFile.readAsBytes();

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$serverUrl/upload'),
        );

        request.files.add(
          http.MultipartFile.fromBytes(
            'image', // Field name — must be 'image'
            bytes,
            filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'), // THIS IS THE KEY FIX
          ),
        );

        var response = await request.send().timeout(
          const Duration(seconds: 60),
        );

        if (response.statusCode == 200) {
          successCount++;
        } else {
          print('Server error: ${response.statusCode}');
          failCount++;
        }
      } catch (e) {
        print('Exception: $e');
        failCount++;
      }

      setState(() {
        _uploadedCount = successCount + failCount;
      });
    }

    if (mounted) {
      String message;
      if (failCount == 0) {
        message =
            'All ${widget.imageFiles.length} photos uploaded successfully! 🎉';
      } else {
        message =
            'Uploaded $successCount of ${widget.imageFiles.length}. $failCount failed.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.imageFiles.length} Photos Selected'),
        actions: [
          if (!_isUploading)
            IconButton(icon: const Icon(Icons.upload), onPressed: _uploadAll),
        ],
      ),
      body: Column(
        children: [
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LinearProgressIndicator(
                value: _uploadedCount / widget.imageFiles.length,
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.imageFiles.length,
              itemBuilder: (context, index) {
                final imageFile = widget.imageFiles[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const Text(
                        'Preview on device',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.file(imageFile, fit: BoxFit.cover),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (!_isUploading)
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: _uploadAll,
                icon: const Icon(Icons.upload),
                label: Text('Upload All ${widget.imageFiles.length} Photos'),
              ),
            ),
        ],
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
  Set<String> selectedFilenames = {};

  @override
  void initState() {
    super.initState();
    _refreshImages();
  }

  Future<void> _refreshImages() async {
    setState(() {
      selectedFilenames.clear();
      _imagesFuture = _fetchImages();
    });
  }

  Future<List<String>> _fetchImages() async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/list'));
      if (response.statusCode == 200) {
        return List<String>.from(json.decode(response.body));
      }
    } catch (e) {}
    return [];
  }

  Future<void> _deleteSelected() async {
    for (var filename in selectedFilenames) {
      await http.delete(Uri.parse('$serverUrl/delete/$filename'));
    }
    _refreshImages();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedFilenames.length} photo(s) deleted')),
      );
    }
  }

  Future<void> _setAsCurrent(String filename) async {
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
          http.MultipartFile.fromBytes('image', imgResponse.bodyBytes),
        );
        await request.send();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$filename is now displayed!')),
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
    final bool isSelecting = selectedFilenames.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSelecting ? '${selectedFilenames.length} selected' : 'Library',
        ),
        actions: isSelecting
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Delete Selected?'),
                      content: Text(
                        'Remove ${selectedFilenames.length} photo(s)?',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          child: const Text('Delete'),
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteSelected();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => selectedFilenames.clear()),
                ),
              ]
            : null,
      ),
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
                final isSelected = selectedFilenames.contains(filename);

                return GestureDetector(
                  onLongPress: () {
                    setState(() {
                      if (selectedFilenames.contains(filename)) {
                        selectedFilenames.remove(filename);
                      } else {
                        selectedFilenames.add(filename);
                      }
                    });
                  },
                  onTap: isSelecting
                      ? () {
                          setState(() {
                            if (isSelected) {
                              selectedFilenames.remove(filename);
                            } else {
                              selectedFilenames.add(filename);
                            }
                          });
                        }
                      : () => showCupertinoModalPopup(
                          context: context,
                          builder: (context) => CupertinoActionSheet(
                            title: Text(filename),
                            actions: [
                              CupertinoActionSheetAction(
                                child: const Text('Save to Device'),
                                onPressed: () async {
                                  Navigator.pop(context); // Close sheet first

                                  // Request permission if needed (Android/iOS)
                                  var status = await Permission.photos
                                      .request();
                                  if (!status.isGranted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Photo save permission denied',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  try {
                                    final response = await http.get(
                                      Uri.parse('$serverUrl/images/$filename'),
                                    );
                                    if (response.statusCode == 200) {
                                      final result =
                                          await ImageGallerySaver.saveImage(
                                            Uint8List.fromList(
                                              response.bodyBytes,
                                            ),
                                            quality: 100,
                                            name: filename,
                                          );
                                      if (result['isSuccess']) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Saved to gallery!'),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Save failed'),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Download error'),
                                      ),
                                    );
                                  }
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) => const Icon(Icons.error),
                        ),
                      ),
                      if (isCurrent)
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.visibility,
                              color: Colors.amber[400],
                              size: 20,
                            ),
                          ),
                        ),
                      if (isSelected)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteImage(String filename) async {
    await http.delete(Uri.parse('$serverUrl/delete/$filename'));
    _refreshImages();
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
                  SnackBar(content: Text('Server updated: $serverUrl')),
                );
              },
              child: const Text('Save Server URL'),
            ),
            const SizedBox(height: 40),
            Text(
              'Current server: $serverUrl',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
