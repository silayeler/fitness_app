import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';
import 'ui_styles.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  List<FileSystemEntity> _videos = [];
  VideoPlayerController? _videoController;
  int? _playingIndex;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();
    
    // Filter for mp4 files
    setState(() {
      _videos = files.where((file) => file.path.endsWith('.mp4')).toList()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified)); // Newest first
    });
  }

  Future<void> _playVideo(File file, int index) async {
    if (_playingIndex == index) {
      // Toggle pause/play
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      setState(() {});
      return;
    }

    // Stop previous
    await _videoController?.dispose();
    setState(() {
      _playingIndex = null;
    });

    // Start new
    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();
    await _videoController!.play();
    setState(() {
      _playingIndex = index;
    });

    // Listen for end
    _videoController!.addListener(() {
       if (_videoController!.value.position >= _videoController!.value.duration) {
         setState(() {
           _playingIndex = null;
         });
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIStyles.darkBackground,
      appBar: AppBar(
        title: Text("Workout Library", style: UIStyles.heading),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _videos.isEmpty 
        ? Center(child: Text("No recordings yet.", style: TextStyle(color: Colors.white54)))
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _videos.length,
            itemBuilder: (context, index) {
              final file = _videos[index] as File;
              final filename = p.basename(file.path);
              final isPlaying = _playingIndex == index;

              return Card(
                color: Colors.black45,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPlaying ? UIStyles.primaryBlue.withAlpha(50) : Colors.white10,
                          shape: BoxShape.circle
                        ),
                        child: Icon(
                          isPlaying ? ( _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow) : Icons.play_circle_outline, 
                          color: isPlaying ? UIStyles.primaryBlue : Colors.white
                        ),
                      ),
                      title: Text(filename, style: UIStyles.cardTitle),
                      subtitle: Text("${file.lengthSync() ~/ 1024} KB", style: UIStyles.cardBody),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: UIStyles.dangerRed),
                        onPressed: () {
                           file.deleteSync();
                           _loadVideos();
                        },
                      ),
                      onTap: () => _playVideo(file, index),
                    ),
                    
                    // Video Player Preview Area
                    if (isPlaying && _videoController != null && _videoController!.value.isInitialized)
                      Container(
                        height: 200,
                        width: double.infinity,
                         margin: EdgeInsets.all(8),
                         child: ClipRRect(
                           borderRadius: BorderRadius.circular(8),
                           child: AspectRatio(
                             aspectRatio: _videoController!.value.aspectRatio,
                             child: VideoPlayer(_videoController!),
                           ),
                         ),
                      ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
