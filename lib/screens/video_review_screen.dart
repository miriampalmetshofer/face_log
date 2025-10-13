import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/annotation_category.dart';
import '../services/annotation_service.dart';
import '../widgets/annotation_form.dart';

class VideoReviewScreen extends StatefulWidget {
  final String videoPath;

  const VideoReviewScreen({super.key, required this.videoPath});

  @override
  State<VideoReviewScreen> createState() => _VideoReviewScreenState();
}

class _VideoReviewScreenState extends State<VideoReviewScreen> {
  late VideoPlayerController _controller;
  List<AnnotationCategory>? _categories;
  bool _isLoadingSchema = true;

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
      });
    _loadAnnotationSchema();
  }

  Future<void> _loadAnnotationSchema() async {
    try {
      final categories = await AnnotationService.loadSchema();
      setState(() {
        _categories = categories;
        _isLoadingSchema = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSchema = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load annotation schema: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Video Preview')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Video Player ---
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600.0,
                  maxHeight: 400.0,
                ),
                child: _controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    : AspectRatio(
                        aspectRatio:
                            16 / 9,
                        child: Center(child: const CircularProgressIndicator()),
                      ),
              ),
            ),

            // --- Video Controls ---
            Container(
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 12.0,
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: Theme.of(context).colorScheme.primary,
                          bufferedColor: Colors.grey,
                          backgroundColor: Colors.black26,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_5, size: 35.0),
                            onPressed: () {
                              final newPosition =
                                  _controller.value.position -
                                  const Duration(seconds: 5);
                              _controller.seekTo(
                                newPosition.isNegative
                                    ? Duration.zero
                                    : newPosition,
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 35.0,
                            ),
                            onPressed: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.forward_5, size: 35.0),
                            onPressed: () {
                              final newPosition =
                                  _controller.value.position +
                                  const Duration(seconds: 5);
                              _controller.seekTo(
                                newPosition > _controller.value.duration
                                    ? _controller.value.duration
                                    : newPosition,
                              );
                            },
                          ),
                          Text(
                            '${_printDuration(_controller.value.position)} / ${_printDuration(_controller.value.duration)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(),

            // --- Dynamic Annotation Form ---
            _isLoadingSchema
                ? const Center(child: CircularProgressIndicator())
                : _categories != null
                    ? AnnotationFormContent(categories: _categories!)
                    : const Center(
                        child: Text('Failed to load annotation schema'),
                      ),
          ],
        ),
      ),
    );
  }
}
