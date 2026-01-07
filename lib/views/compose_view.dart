import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/posting_service.dart';
import 'settings_view.dart'; // Import SettingsView

class ComposeView extends StatefulWidget {
  const ComposeView({super.key});

  @override
  State<ComposeView> createState() => _ComposeViewState();
}

class _ComposeViewState extends State<ComposeView> {
  final TextEditingController _textController = TextEditingController();
  final List<String> _selectedImages = [];
  bool _postToMicroblog = true;
  bool _postToX = true;

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

    if (!_postToMicroblog && !_postToX) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one platform.')),
      );
      return;
    }

    final results = await postingService.postAll(
      content,
      _selectedImages,
      postToMicroblog: _postToMicroblog,
      postToX: _postToX,
    );

    if (!mounted) return;

    final microblogStatus = results['microblog'];
    final xStatus = results['x'];
    
    List<String> statusParts = [];
    if (_postToMicroblog) statusParts.add('Micro.blog: $microblogStatus');
    if (_postToX) statusParts.add('X: $xStatus');
    String message = 'Posting complete.\n${statusParts.join('\n')}';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    bool allSucceeded = (!_postToMicroblog || microblogStatus == 'Success') &&
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
                        hintText: 'Write something... (Markdown supported)',
                        border: InputBorder.none,
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder(
                    valueListenable: _textController,
                    builder: (context, TextEditingValue value, child) {
                      final xLength = postingService.calculateXLength(value.text);
                      final isOverLimit = xLength > 300;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'X: $xLength/300',
                            style: TextStyle(
                              color: isOverLimit ? Colors.red : Colors.grey,
                              fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Micro.blog'),
                        selected: _postToMicroblog,
                        onSelected: (selected) {
                          setState(() => _postToMicroblog = selected);
                        },
                      ),
                      const SizedBox(width: 8),
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
