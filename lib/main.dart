import 'dart:io';
import 'dart:typed_data';

import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
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
        useMaterial3: true, // Enables modern color roles and nicer defaults
        scaffoldBackgroundColor: const Color(
          0xFF1A0D2C,
        ), // Deeper purple-black base for more contrast/pop
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2A1B4A), // Richer purple app bar
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: TextTheme(
          headlineMedium: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            shadows: [
              Shadow(
                color: Color(0xFF9F00E7),
                blurRadius: 8,
                offset: Offset(0, 0),
              ),
            ],
          ),
          bodyLarge: const TextStyle(
            color: Color(0xF2FFFFFF),
          ), // ~95% opacity white, fully constant
          bodyMedium: const TextStyle(
            color: Color(0xCCFFFFFF),
          ), // Optional: for slightly more transparent text
          bodySmall: const TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(
              0xFFE9008D,
            ), // Hot magenta/pink button (Lisa Frank classic)
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            elevation: 12,
            shadowColor: const Color(
              0xFFFF6F98,
            ).withOpacity(0.7), // Pink glow shadow
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(
            0xFF7B2CBF,
          ), // Rich mid-purple as base (vibrant but not too blue)
          brightness: Brightness.dark,
          primary: const Color(0xFF9F00E7), // Neon purple for main accents
          secondary: const Color(0xFF05ADED), // Electric teal/cyan
          tertiary: const Color(0xFFFF6F98), // Cotton candy hot pink
          surface: const Color(0xFF1A0D2C),
          background: const Color(0xFF1A0D2C),
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

  final List<Widget> _pages = [const HomePage(), const GalleryScreen()];

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
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFFF6F98), // Hot pink for selected
        unselectedItemColor: Colors.white60,
        backgroundColor: const Color(0xFF2A1B4A), // Matches app bar purple
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
              Icon(
                Icons.circle_outlined,
                size: 160,
                color: const Color(0xFF9F00E7),
              ),
              const SizedBox(height: 40),
              const Text(
                'CircleScreen',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(color: Color(0xFF9F00E7), blurRadius: 12),
                    Shadow(color: Color(0xFFFF6F98), blurRadius: 20),
                  ],
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
                      color: const Color(
                        0xFF9F00E7,
                      ).withOpacity(0.6), // Bright neon purple
                      blurRadius: 30,
                      spreadRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                    BoxShadow(
                      color: const Color(
                        0xFFFF6F98,
                      ).withOpacity(0.4), // Add pink outer halo
                      blurRadius: 50,
                      spreadRadius: 12,
                      offset: const Offset(0, 0),
                    ),
                    BoxShadow(
                      color: const Color(
                        0xFF05ADED,
                      ).withOpacity(0.3), // Teal inner glow for depth
                      blurRadius: 15,
                      spreadRadius: -4,
                      offset: const Offset(0, 0),
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
                              color: const Color(
                                0xFF9F00E7,
                              ).withOpacity(0.6), // Bright neon purple
                              blurRadius: 30,
                              spreadRadius: 8,
                              offset: const Offset(0, 0),
                            ),
                            BoxShadow(
                              color: const Color(
                                0xFFFF6F98,
                              ).withOpacity(0.4), // Add pink outer halo
                              blurRadius: 50,
                              spreadRadius: 12,
                              offset: const Offset(0, 0),
                            ),
                            BoxShadow(
                              color: const Color(
                                0xFF05ADED,
                              ).withOpacity(0.3), // Teal inner glow for depth
                              blurRadius: 15,
                              spreadRadius: -4,
                              offset: const Offset(0, 0),
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
                                  Navigator.pop(
                                    context,
                                  ); // Close the action sheet

                                  // gal handles permission prompting automatically, but we can check/request explicitly
                                  final bool hasAccess = await Gal.hasAccess();
                                  if (!hasAccess) {
                                    final bool granted =
                                        await Gal.requestAccess();
                                    if (!granted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Photo library permission denied',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                  }

                                  try {
                                    final response = await http.get(
                                      Uri.parse('$serverUrl/images/$filename'),
                                    );
                                    if (response.statusCode != 200) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to download image',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    // Save directly from bytes — no temp file needed!
                                    await Gal.putImageBytes(
                                      response.bodyBytes,
                                      album:
                                          'CircleScreen', // Creates a nice grouped album
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Saved to gallery! 📸'),
                                      ),
                                    );
                                  } on GalException catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Save failed: ${e.type.name}',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
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
