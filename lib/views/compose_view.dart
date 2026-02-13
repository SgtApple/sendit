import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/posting_service.dart';
import 'settings_view.dart';

class ComposeView extends StatefulWidget {
  const ComposeView({super.key});

  @override
  State<ComposeView> createState() => _ComposeViewState();
}

class _ComposeViewState extends State<ComposeView> {
  final TextEditingController _textController = TextEditingController();
  final List<String> _selectedImages = [];
  bool _postToMastodon = false;
  bool _postToBluesky = false;
  bool _postToNostr = false;
  bool _postToX = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _selectedImages.addAll(result.paths.whereType<String>());
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _handlePost() async {
    final postingService = context.read<PostingService>();
    final content = _textController.text;
    
    if (content.isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text or select an image.')),
      );
      return;
    }

    if (!_postToMastodon && !_postToBluesky && !_postToNostr && !_postToX) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one platform.')),
      );
      return;
    }

    final results = await postingService.postAll(
      content,
      _selectedImages,
      postToMastodon: _postToMastodon,
      postToBluesky: _postToBluesky,
      postToNostr: _postToNostr,
      postToX: _postToX,
    );

    if (!mounted) return;

    final mastodonStatus = results['mastodon'];
    final blueskyStatus = results['bluesky'];
    final nostrStatus = results['nostr'];
    final xStatus = results['x'];
    
    List<String> statusParts = [];
    if (_postToMastodon) statusParts.add('Mastodon: $mastodonStatus');
    if (_postToBluesky) statusParts.add('Bluesky: $blueskyStatus');
    if (_postToNostr) statusParts.add('Nostr: $nostrStatus');
    if (_postToX) statusParts.add('X: $xStatus');
    String message = 'Posting complete.\n${statusParts.join('\n')}';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    bool allSucceeded = 
        (!_postToMastodon || mastodonStatus == 'Success') &&
        (!_postToBluesky || blueskyStatus == 'Success') &&
        (!_postToNostr || nostrStatus == 'Success') &&
        (!_postToX || xStatus == 'Success');
    
    if (allSucceeded) {
      _textController.clear();
      setState(() {
        _selectedImages.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final postingService = context.watch<PostingService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SendIt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsView()),
              );
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: postingService.isPosting ? null : _handlePost,
            tooltip: 'Publish',
          ),
        ],
      ),
      body: Column(
        children: [
          if (postingService.isPosting)
            const LinearProgressIndicator(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        hintText: 'Write something... (Markdown supported for Mastodon)',
                        border: InputBorder.none,
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder(
                    valueListenable: _textController,
                    builder: (context, TextEditingValue value, child) {
                      final plainText = postingService.stripMarkdownForPlainText(value.text);
                      final xLength = postingService.calculateXLength(plainText);
                      final limits = postingService.getCharacterLimits();
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_postToX)
                            Text(
                              'X: $xLength/${limits['x']}',
                              style: TextStyle(
                                color: xLength > limits['x']! ? Colors.red : Colors.grey,
                                fontWeight: xLength > limits['x']! ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          if (_postToBluesky)
                            Text(
                              'Bluesky: ${plainText.length}/${limits['bluesky']}',
                              style: TextStyle(
                                color: plainText.length > limits['bluesky']! ? Colors.orange : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          if (_postToMastodon)
                            Text(
                              'Mastodon: ${value.text.length}/${limits['mastodon']}',
                              style: TextStyle(
                                color: value.text.length > limits['mastodon']! ? Colors.orange : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      FilterChip(
                        label: const Text('Mastodon'),
                        selected: _postToMastodon,
                        onSelected: (selected) {
                          setState(() => _postToMastodon = selected);
                        },
                      ),
                      FilterChip(
                        label: const Text('Bluesky'),
                        selected: _postToBluesky,
                        onSelected: (selected) {
                          setState(() => _postToBluesky = selected);
                        },
                      ),
                      FilterChip(
                        label: const Text('Nostr'),
                        selected: _postToNostr,
                        onSelected: (selected) {
                          setState(() => _postToNostr = selected);
                        },
                      ),
                      FilterChip(
                        label: const Text('X'),
                        selected: _postToX,
                        onSelected: (selected) {
                          setState(() => _postToX = selected);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(_selectedImages[index])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            color: Colors.black54,
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.image),
                  tooltip: 'Add Image',
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: postingService.isPosting ? null : _handlePost,
                  child: const Text('Publish'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
