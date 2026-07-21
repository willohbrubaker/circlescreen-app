import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'user_selector_screen.dart';
import 'star_field.dart'; // your star_field.dart file

const _storage = FlutterSecureStorage();

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
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            shadows: [
              Shadow(color: Color(0xFF00F0FF), blurRadius: 10),
              Shadow(color: Color(0xFFC300FF), blurRadius: 18),
            ],
          ),
          bodyLarge: TextStyle(color: Color(0xF2FFFFFF)),
          bodyMedium: TextStyle(color: Color(0xCCFFFFFF)),
          bodySmall: TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4FF).withOpacity(0.92),
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            elevation: 10,
            shadowColor: const Color(0xFF00F0FF).withOpacity(0.70),
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00F0FF),
          brightness: Brightness.dark,
          primary: const Color(0xFF00F0FF),
          secondary: const Color(0xFFFFA500),
          tertiary: const Color(0xFFFF8C00),
          surface: const Color(0xFF0A0E1F).withOpacity(0.90),
          background: Colors.transparent,
        ),
      ),
      home: UserSelectorScreen(),
    );
  }
}

String serverUrl = 'https://pearlgourami.immenseaccumulationonline.online:443';

Future<String> getCurrentUser() async {
  final user = await _storage.read(key: 'selected_screen');
  return user ?? 'home';
}

Future<Map<String, String>> getAuthHeaders() async {
  String rawToken = await _storage.read(key: 'auth_token') ?? '';

  String token = rawToken.trim();
  token = token.replaceAll('"', '');
  token = token.replaceAll("'", '');
  token = token.replaceAll('\n', '');
  token = token.replaceAll('\r', '');
  token = token.replaceAll('\t', '');
  token = token.replaceAll(RegExp(r'\s+'), '');

  if (token.isEmpty || !token.contains('.') || !token.startsWith('eyJ')) {
    return {};
  }

  final header = 'Bearer $token';

  return {'Authorization': header};
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
      extendBody: true,
      body: Stack(
        children: [
          const StarField(opacity: 0.38),
          SafeArea(child: _pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.upload),
                label: 'Upload',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.photo_library),
                label: 'Library',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFFFFA500),
            unselectedItemColor: Colors.white60,
            backgroundColor: const Color(0xFF0A0E1F).withOpacity(0.75),
            elevation: 0,
            onTap: _onItemTapped,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00D4FF).withOpacity(0.7),
        foregroundColor: Colors.white,
        onPressed: () async {
          await _storage.deleteAll();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => UserSelectorScreen()),
            );
          }
        },
        child: const Icon(Icons.swap_horiz),
        tooltip: 'Switch Screen',
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
  Map<String, String> _authHeaders = {};

  @override
  void initState() {
    super.initState();
    _loadAuthHeaders();
    _loadRandomImage().then((_) => _startImageRotationTimer());
  }

  Future<void> _loadAuthHeaders() async {
    _authHeaders = await getAuthHeaders();
    if (mounted) setState(() {});
  }

  Future<void> _loadRandomImage() async {
    try {
      final user = await getCurrentUser();
      final headers = await getAuthHeaders();

      final response = await http.get(
        Uri.parse('$serverUrl/list/$user'),
        headers: headers,
      );

      if (response.statusCode == 200 && mounted) {
        final List<String> filenames = List<String>.from(
          json.decode(response.body),
        );
        final available = filenames.where((f) => f != 'current.jpg').toList();

        if (available.isNotEmpty && mounted) {
          setState(() {
            _imageFilenames = available;
            final random = Random();
            final selected = available[random.nextInt(available.length)];
            _currentImageUrl = '$serverUrl/images/$user/$selected';
          });
        }
      } else if ([401, 403, 422].contains(response.statusCode)) {
        await _storage.deleteAll();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => UserSelectorScreen()),
          );
        }
      }
    } catch (e) {
      print('Load image error: $e');
    }
  }

  void _startImageRotationTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_imageFilenames.isNotEmpty && mounted) {
        final random = Random();
        final selected =
            _imageFilenames[random.nextInt(_imageFilenames.length)];
        final user = await getCurrentUser();
        setState(() {
          _currentImageUrl = '$serverUrl/images/$user/$selected';
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
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => MultiPreviewScreen(imageFiles: imageFiles),
            ),
          )
          .then((_) => _loadRandomImage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const StarField(opacity: 0.42),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withOpacity(0.8),
                          blurRadius: 55,
                          spreadRadius: 18,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFFA500).withOpacity(0.65),
                          blurRadius: 70,
                          spreadRadius: 12,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFF4500).withOpacity(0.45),
                          blurRadius: 45,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer rainbow ring (unchanged)
                        Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: const [
                                Color(0xFF00FFFF),
                                Color(0xFF00D4FF),
                                Color(0xFF40C4FF),
                                Color(0xFFFFA500),
                                Color(0xFFFF4500),
                                Color(0xFFFF8C00),
                                Color(0xFFFFD700),
                                Color(0xFF00FFFF),
                              ],
                              stops: const [
                                0.0,
                                0.14,
                                0.28,
                                0.42,
                                0.57,
                                0.71,
                                0.85,
                                1.0,
                              ],
                            ),
                          ),
                        ),

                        // Inner image – now forced square + ClipOval for consistent cropping
                        SizedBox(
                          width: 170,
                          height: 170,
                          child: ClipOval(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 1300),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                              child: _currentImageUrl != null
                                  ? CachedNetworkImage(
                                      key: ValueKey(_currentImageUrl),
                                      imageUrl: _currentImageUrl!,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                      memCacheWidth: 300,
                                      memCacheHeight: 300,
                                      httpHeaders: _authHeaders,
                                      placeholder: (_, __) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: const Color(0xFF0A0E1F),
                                      ),
                                    )
                                  : Container(color: const Color(0xFF0A0E1F)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: const Text(
                        'CircleScreen',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.4,
                          height: 1.0,
                          shadows: [
                            Shadow(color: Color(0xFF00F0FF), blurRadius: 32),
                            Shadow(color: Color(0xFFFFA500), blurRadius: 48),
                            Shadow(color: Color(0xFFFF4500), blurRadius: 64),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Upload photos to your circular display!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, color: Colors.white70),
                  ),
                  const SizedBox(height: 80),
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 34,
                    ),
                    label: const Text(
                      'Select Photos',
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PreviewScreen extends StatelessWidget {
  final File imageFile;

  const PreviewScreen({super.key, required this.imageFile});

  Future<void> _upload(BuildContext context) async {
    final user = await getCurrentUser();
    final headers = await getAuthHeaders();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$serverUrl/upload/$user'),
    );
    request.headers.addAll(headers);
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
            SnackBar(content: Text('Upload failed — ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Preview')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const StarField(opacity: 0.36),
          Center(
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
                          color: const Color(0xFF00F0FF).withOpacity(0.7),
                          blurRadius: 45,
                          spreadRadius: 14,
                        ),
                        BoxShadow(
                          color: const Color(0xFFC300FF).withOpacity(0.5),
                          blurRadius: 65,
                          spreadRadius: 12,
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
        ],
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

    final user = await getCurrentUser();
    final headers = await getAuthHeaders();

    int success = 0, fail = 0;

    for (var file in widget.imageFiles) {
      try {
        final bytes = await file.readAsBytes();
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$serverUrl/upload/$user'),
        );
        request.headers.addAll(headers);
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );

        var response = await request.send().timeout(
          const Duration(seconds: 60),
        );
        if (response.statusCode == 200)
          success++;
        else
          fail++;
      } catch (_) {
        fail++;
      }
      setState(() => _uploadedCount = success + fail);
    }

    if (mounted) {
      final msg = fail == 0
          ? 'All uploaded! 🎉'
          : 'Uploaded $success of ${widget.imageFiles.length} ($fail failed)';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: Text('${widget.imageFiles.length} Photos')),
      body: Stack(
        children: [
          const StarField(opacity: 0.32),
          Column(
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
                    final file = widget.imageFiles[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          const Text(
                            'Preview',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF00F0FF,
                                  ).withOpacity(0.6),
                                  blurRadius: 40,
                                  spreadRadius: 12,
                                ),
                                BoxShadow(
                                  color: const Color(
                                    0xFFC300FF,
                                  ).withOpacity(0.4),
                                  blurRadius: 60,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.file(file, fit: BoxFit.cover),
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
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    child: ElevatedButton.icon(
                      onPressed: _uploadAll,
                      icon: const Icon(Icons.upload_file),
                      label: Text('Upload All (${widget.imageFiles.length})'),
                    ),
                  ),
                ),
            ],
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
  final Set<String> selectedFilenames = {};
  bool _isDownloading = false;
  int _downloadedCount = 0;
  int _totalToDownload = 0;
  String _currentUser = 'home';
  Map<String, String> _authHeaders = {};

  @override
  void initState() {
    super.initState();
    _loadAuthHeaders();
    _loadCurrentUser();
    _refreshImages();
  }

  Future<void> _loadAuthHeaders() async {
    _authHeaders = await getAuthHeaders();
    if (mounted) setState(() {});
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await getCurrentUser();
    if (mounted) setState(() {});
  }

  Future<void> _refreshImages() async {
    setState(() {
      selectedFilenames.clear();
      _imagesFuture = _fetchImages();
    });
  }

  Future<List<String>> _fetchImages() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$serverUrl/list/$_currentUser'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return List<String>.from(json.decode(response.body));
      } else if ([401, 403, 422].contains(response.statusCode)) {
        await _storage.deleteAll();
        if (mounted)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => UserSelectorScreen()),
          );
      }
    } catch (e) {
      print('Gallery fetch error: $e');
    }
    return [];
  }

  Future<void> _deleteSelected() async {
    final user = await getCurrentUser();
    for (var fn in selectedFilenames) {
      await http.delete(
        Uri.parse('$serverUrl/delete/$user/$fn'),
        headers: await getAuthHeaders(),
      );
    }
    _refreshImages();
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedFilenames.length} photo(s) deleted')),
      );
  }

  Future<void> _downloadSelected() async {
    setState(() {
      _isDownloading = true;
      _downloadedCount = 0;
      _totalToDownload = selectedFilenames.length;
    });

    int success = 0, fail = 0;

    if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo library permission denied')),
        );
      setState(() => _isDownloading = false);
      return;
    }

    for (var fn in selectedFilenames) {
      try {
        final resp = await http.get(
          Uri.parse('$serverUrl/images/$_currentUser/$fn'),
          headers: await getAuthHeaders(),
        );
        if (resp.statusCode == 200) {
          await Gal.putImageBytes(resp.bodyBytes, album: 'CircleScreen');
          success++;
        } else
          fail++;
      } catch (_) {
        fail++;
      }
      setState(() => _downloadedCount = success + fail);
    }

    if (mounted) {
      final msg = fail == 0
          ? '${selectedFilenames.length} saved! 📸'
          : 'Saved $success of ${selectedFilenames.length} ($fail failed)';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() {
        selectedFilenames.clear();
        _isDownloading = false;
      });
    }
  }

  Future<void> _downloadSingle(String filename) async {
    if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo library permission denied')),
        );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final resp = await http.get(
        Uri.parse('$serverUrl/images/$_currentUser/$filename'),
        headers: await getAuthHeaders(),
      );
      if (resp.statusCode == 200) {
        await Gal.putImageBytes(resp.bodyBytes, album: 'CircleScreen');
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved to gallery! 📸')));
      } else
        throw Exception();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Save failed')));
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelecting = selectedFilenames.isNotEmpty;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isSelecting ? '${selectedFilenames.length} selected' : ''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: isSelecting
            ? [
                if (_isDownloading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          value: _totalToDownload > 0
                              ? _downloadedCount / _totalToDownload
                              : null,
                        ),
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
      body: Stack(
        children: [
          const StarField(opacity: 0.30),
          RefreshIndicator(
            onRefresh: _refreshImages,
            color: const Color(0xFF00F0FF),
            child: FutureBuilder<List<String>>(
              future: _imagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
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
                    childAspectRatio: 1.0,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final filename = images[index];
                    final imageUrl =
                        '$serverUrl/images/$_currentUser/$filename';
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
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullImagePreviewScreen(
                                    imageUrl: imageUrl,
                                    filename: filename,
                                    authHeaders: _authHeaders,
                                    onSave: () async {
                                      await _downloadSingle(filename);
                                      if (context.mounted)
                                        Navigator.pop(context);
                                    },
                                    onDelete: () async {
                                      await _deleteImage(filename);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        _refreshImages();
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: Container(
                                color: const Color(0xFF0A0E1F),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  httpHeaders: _authHeaders,
                                  placeholder: (_, __) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00F0FF,
                                  ).withOpacity(0.7),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00F0FF),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.visibility,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          if (isSelected)
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFC300FF).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 54,
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
        ],
      ),
    );
  }

  Future<void> _deleteImage(String filename) async {
    await http.delete(
      Uri.parse('$serverUrl/delete/$_currentUser/$filename'),
      headers: await getAuthHeaders(),
    );
    _refreshImages();
  }
}

class FullImagePreviewScreen extends StatelessWidget {
  final String imageUrl;
  final String filename;
  final Map<String, String> authHeaders;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  const FullImagePreviewScreen({
    super.key,
    required this.imageUrl,
    required this.filename,
    required this.authHeaders,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000814),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(filename, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const StarField(opacity: 0.28),
          Center(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(80),
              minScale: 0.4,
              maxScale: 5.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                httpHeaders: authHeaders,
                fit: BoxFit.contain, // full uncropped view
                alignment: Alignment.center,
                placeholder: (_, __) =>
                    const CircularProgressIndicator(color: Color(0xFF00F0FF)),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  size: 120,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Save'),
                      onPressed: onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete'),
                      onPressed: onDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
