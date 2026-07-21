import 'dart:async';
import 'dart:math';
import 'package:http_parser/http_parser.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'dart:convert';
import 'dart:io';

// ─────────────────────────────────────────────────────────────
// Hardcoded for this special hibiscus version 🌺
// ─────────────────────────────────────────────────────────────
const String pin = 'pattie';
const String bearerToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJwYXR0aWUiLCJleHAiOjE4NjM4MjMyMjZ9.ZkDMe0QAUZN51GaNlTXm4qm6yrkpSRgjORNOuuz3Xjg';

// Headers helper for all protected requests
Map<String, String> getAuthHeaders() => {
  'Authorization': 'Bearer $bearerToken',
};

String serverUrl = 'https://pearlgourami.immenseaccumulationonline.online:9026';

void main() {
  runApp(const CircleScreenApp());
}

class CircleScreenApp extends StatelessWidget {
  const CircleScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CircleScreen 🌺',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F071A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E0F2E),
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
                color: Color(0xFFFF2E63),
                blurRadius: 12,
                offset: Offset(0, 0),
              ),
            ],
          ),
          bodyLarge: const TextStyle(color: Color(0xF2FFFFFF)),
          bodyMedium: const TextStyle(color: Color(0xCCFFFFFF)),
          bodySmall: const TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF3366), // Bright coral-hot pink
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            elevation: 15,
            shadowColor: const Color(0xFFFF2E63).withOpacity(0.8),
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF2E63), // Dominant hot tropical pink-red
          brightness: Brightness.dark,
          primary: const Color(0xFFFF2E63),
          secondary: const Color(0xFFFF5252), // Bright coral
          tertiary: const Color(0xFFFF6B00), // Vivid orange-red
          surface: const Color(0xFF0F071A),
          background: const Color(0xFF0F071A),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [const HomePage(), const GalleryScreen()];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
        selectedItemColor: const Color(0xFFFF6F98),
        unselectedItemColor: Colors.white60,
        backgroundColor: const Color(0xFF2A1B4A),
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
  List<String> _imageFilenames = [];
  String? _currentImageUrl;
  Timer? _timer;

  Future<void> _loadRandomImage() async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/list/$pin'),
        headers: getAuthHeaders(),
      );
      if (response.statusCode == 200 && mounted) {
        final List<String> filenames = List<String>.from(
          json.decode(response.body),
        );
        final available = filenames.where((f) => f != 'current.jpg').toList();
        if (available.isNotEmpty) {
          final random = Random();
          final selected = available[random.nextInt(available.length)];
          setState(() {
            _imageFilenames = available;
            _currentImageUrl = '$serverUrl/images/$pin/$selected';
          });
        }
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _loadRandomImage();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_imageFilenames.isNotEmpty) {
        final random = Random();
        final selected =
            _imageFilenames[random.nextInt(_imageFilenames.length)];
        setState(() {
          _currentImageUrl = '$serverUrl/images/$pin/$selected';
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 85);
    if (pickedFiles.isNotEmpty && mounted) {
      final imageFiles = pickedFiles.map((f) => File(f.path)).toList();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MultiPreviewScreen(imageFiles: imageFiles),
        ),
      ).then((_) => _loadRandomImage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ultra-saturated tropical hibiscus glow
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFFFF2E63,
                      ).withOpacity(0.9), // Intense hot pink-red
                      blurRadius: 50,
                      spreadRadius: 18,
                    ),
                    BoxShadow(
                      color: const Color(
                        0xFFFF3366,
                      ).withOpacity(0.7), // Coral-pink layer
                      blurRadius: 80,
                      spreadRadius: 25,
                    ),
                    BoxShadow(
                      color: const Color(
                        0xFFFF6B00,
                      ).withOpacity(0.75), // Tropical orange-red punch
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rotating sweep gradient ring (ultra-saturated tropical colors)
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            const Color(0xFFFF2E63), // hot pink-red
                            const Color(0xFFFF3366), // coral pink
                            const Color(0xFFFF5252), // bright red
                            const Color(0xFFFF6B00), // vivid orange
                            const Color(0xFFFF3366), // back to coral
                            const Color(0xFFFF2E63), // hot pink-red
                            const Color(0xFFFF5252), // bright red
                            const Color(0xFFFF2E63), // loop
                          ],
                          stops: const [
                            0.0,
                            0.12,
                            0.25,
                            0.4,
                            0.55,
                            0.7,
                            0.85,
                            1.0,
                          ],
                        ),
                      ),
                    ),
                    // Cropped display image
                    Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: ClipOval(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 1200),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: _currentImageUrl != null
                              ? CachedNetworkImage(
                                  key: ValueKey(_currentImageUrl),
                                  imageUrl: _currentImageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (_, __, ___) =>
                                      Container(color: const Color(0xFF0F071A)),
                                )
                              : Container(color: const Color(0xFF0F071A)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'CircleScreen 🌺',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(color: Color(0xFFFF2E63), blurRadius: 30),
                    Shadow(color: Color(0xFFFF6B00), blurRadius: 50),
                    Shadow(color: Color(0xFFFF3366), blurRadius: 70),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upload photos to your circular display! 🌺',
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

// ─────────────────────────────────────────────────────────────
// Preview & Multi-Upload – with Bearer token added
// ─────────────────────────────────────────────────────────────

class PreviewScreen extends StatelessWidget {
  final File imageFile;
  const PreviewScreen({super.key, required this.imageFile});

  Future<void> _upload(BuildContext context) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$serverUrl/upload/$pin'),
    );
    request.headers.addAll(getAuthHeaders());
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    try {
      var response = await request.send();
      if (context.mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploaded successfully! 🌺🎉')),
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
      appBar: AppBar(title: const Text('Preview')),
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
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF69B4).withOpacity(0.7),
                      blurRadius: 40,
                      spreadRadius: 12,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF1493).withOpacity(0.4),
                      blurRadius: 60,
                      spreadRadius: 15,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF4500).withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.file(imageFile, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 70),
              SafeArea(
                bottom: true,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Choose Another'),
                ),
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
    int success = 0, fail = 0;

    for (var file in widget.imageFiles) {
      try {
        final bytes = await file.readAsBytes();
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$serverUrl/upload/$pin'),
        );
        request.headers.addAll(getAuthHeaders());
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
        var resp = await request.send().timeout(const Duration(seconds: 60));
        if (resp.statusCode == 200) {
          success++;
        } else {
          fail++;
        }
      } catch (_) {
        fail++;
      }
      setState(() => _uploadedCount++);
    }

    if (mounted) {
      final msg = fail == 0
          ? 'All ${widget.imageFiles.length} uploaded successfully! 🌺🎉'
          : 'Uploaded $success of ${widget.imageFiles.length} ($fail failed)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.imageFiles.length} Photos Selected'),
      ),
      body: Column(
        children: [
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: LinearProgressIndicator(
                value: _uploadedCount / widget.imageFiles.length,
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.imageFiles.length,
              itemBuilder: (context, i) {
                final f = widget.imageFiles[i];
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
                              color: const Color(0xFFFF69B4).withOpacity(0.7),
                              blurRadius: 40,
                              spreadRadius: 12,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF1493).withOpacity(0.4),
                              blurRadius: 60,
                              spreadRadius: 15,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF4500).withOpacity(0.5),
                              blurRadius: 25,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.file(f, fit: BoxFit.cover),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (!_isUploading)
            SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: ElevatedButton.icon(
                  onPressed: _uploadAll,
                  icon: const Icon(Icons.upload),
                  label: Text('Upload All ${widget.imageFiles.length} Photos'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GalleryScreen – with Bearer token on list/delete
// ─────────────────────────────────────────────────────────────

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});
  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  Future<List<String>>? _imagesFuture;
  Set<String> selectedFilenames = {};
  bool _isDownloading = false;
  int _downloadedCount = 0;
  int _totalToDownload = 0;

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
      final resp = await http.get(
        Uri.parse('$serverUrl/list/$pin'),
        headers: getAuthHeaders(),
      );
      if (resp.statusCode == 200) {
        return List<String>.from(json.decode(resp.body));
      }
    } catch (_) {}
    return [];
  }

  Future<void> _deleteSelected() async {
    for (var fn in selectedFilenames) {
      await http.delete(
        Uri.parse('$serverUrl/delete/$pin/$fn'),
        headers: getAuthHeaders(),
      );
    }
    _refreshImages();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedFilenames.length} photo(s) deleted')),
      );
    }
  }

  Future<void> _downloadSelected() async {
    setState(() {
      _isDownloading = true;
      _downloadedCount = 0;
      _totalToDownload = selectedFilenames.length;
    });

    int ok = 0, fail = 0;

    final hasAccess = await Gal.hasAccess() || await Gal.requestAccess();
    if (!hasAccess && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Permission denied')));
      setState(() => _isDownloading = false);
      return;
    }

    for (var fn in selectedFilenames) {
      try {
        final resp = await http.get(Uri.parse('$serverUrl/images/$pin/$fn'));
        if (resp.statusCode == 200) {
          await Gal.putImageBytes(resp.bodyBytes, album: 'CircleScreen');
          ok++;
        } else {
          fail++;
        }
      } catch (_) {
        fail++;
      }
      setState(() => _downloadedCount = ok + fail);
    }

    if (mounted) {
      final msg = fail == 0
          ? '${selectedFilenames.length} photo(s) downloaded successfully! 🌺📸'
          : 'Downloaded $ok of ${selectedFilenames.length} ($fail failed)';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() {
        selectedFilenames.clear();
        _isDownloading = false;
      });
    }
  }

  Future<void> _downloadSingle(String filename) async {
    final hasAccess = await Gal.hasAccess() || await Gal.requestAccess();
    if (!hasAccess && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Permission denied')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final resp = await http.get(
        Uri.parse('$serverUrl/images/$pin/$filename'),
      );
      if (resp.statusCode == 200) {
        await Gal.putImageBytes(resp.bodyBytes, album: 'CircleScreen');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to gallery! 🌺📸')),
          );
        }
      } else {
        throw Exception();
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Save failed')));
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _deleteImage(String filename) async {
    await http.delete(
      Uri.parse('$serverUrl/delete/$pin/$filename'),
      headers: getAuthHeaders(),
    );
    _refreshImages();
  }

  @override
  Widget build(BuildContext context) {
    final isSelecting = selectedFilenames.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSelecting ? '${selectedFilenames.length} selected' : 'Library',
        ),
        actions: isSelecting
            ? [
                if (_isDownloading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: _totalToDownload > 0
                            ? _downloadedCount / _totalToDownload
                            : null,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _isDownloading ? null : _downloadSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => showCupertinoDialog(
                    context: context,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: const Text('Delete Selected?'),
                      content: Text(
                        'Remove ${selectedFilenames.length} photo(s)?',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          child: const Text('Delete'),
                          onPressed: () {
                            Navigator.pop(ctx);
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
                final imageUrl = '$serverUrl/images/$pin/$filename';
                final isCurrent = filename == 'current.jpg';
                final isSelected = selectedFilenames.contains(filename);

                return GestureDetector(
                  onLongPress: () {
                    setState(() {
                      if (isSelected)
                        selectedFilenames.remove(filename);
                      else
                        selectedFilenames.add(filename);
                    });
                  },
                  onTap: isSelecting
                      ? () {
                          setState(() {
                            if (isSelected)
                              selectedFilenames.remove(filename);
                            else
                              selectedFilenames.add(filename);
                          });
                        }
                      : () => showCupertinoModalPopup(
                          context: context,
                          builder: (ctx) => CupertinoActionSheet(
                            title: Text(filename),
                            actions: [
                              CupertinoActionSheetAction(
                                child: const Text('Save to Device'),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await _downloadSingle(filename);
                                },
                              ),
                              CupertinoActionSheetAction(
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                                isDestructiveAction: true,
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _deleteImage(filename);
                                },
                              ),
                            ],
                            cancelButton: CupertinoActionSheetAction(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(ctx),
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
}
