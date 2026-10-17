import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../../core/constants.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String videoUrl;
  final Map<String, String>? headers;
  final int? tmdbId;
  final String? mediaType;
  final int? seasonNumber;
  final int? episodeNumber;

  const VideoPlayerScreen({
    super.key,
    required this.title,
    required this.videoUrl,
    this.headers,
    this.tmdbId,
    this.mediaType,
    this.seasonNumber,
    this.episodeNumber,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VlcPlayerController _vlcController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // استخراج الترويسات وتمريرها لـ VLC
    final referer = widget.headers?['Referer'] ?? widget.headers?['referer'] ?? 'https://core-latest-hogs.onrender.com/';
    final userAgent = widget.headers?['User-Agent'] ?? widget.headers?['user-agent'] ?? 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36';

    _vlcController = VlcPlayerController.network(
      widget.videoUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(
        http: VlcHttpOptions([
          VlcHttpOptions.userAgent(userAgent),
          VlcHttpOptions.referrer(referer),
        ]),
      ),
    );

    _vlcController.addListener(() {
      if (_vlcController.value.isInitialized) {
        _vlcController.setVolume(100);
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _vlcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _vlcController.seekTo(const Duration(seconds: 0));
              _vlcController.play();
            },
          ),
        ],
      ),
      body: Center(
        child: VlcPlayer(
          controller: _vlcController,
          aspectRatio: 16 / 9,
          placeholder: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      ),
    );
  }
}
