import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../../core/constants.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String videoUrl;
  final int? tmdbId;
  final String? mediaType;
  final int? seasonNumber;
  final int? episodeNumber;

  const VideoPlayerScreen({
    super.key,
    required this.title,
    required this.videoUrl,
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
    // السماح بالتدوير الحر (عمودي + أفقي)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // إخفاء شريط الحالة لشاشة سينمائية
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _vlcController = VlcPlayerController.network(
      widget.videoUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(2000),
        ]),
        audio: VlcAudioOptions([
          VlcAudioOptions.setVolume(150),
        ]),
        video: VlcVideoOptions([
          VlcVideoOptions.hardwareAcceleration,
        ]),
      ),
    );
    _vlcController.addListener(() {
      if (_vlcController.value.isInitialized) {
        _vlcController.setVolume(150);
      }
    });
  }

  @override
  void dispose() {
    // إعادة قفل الشاشة على العمودي عند الخروج
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
