import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/loading_indicator.dart';

class ActorDetailsScreen extends StatefulWidget {
  final int personId;
  const ActorDetailsScreen({super.key, required this.personId});

  @override
  State<ActorDetailsScreen> createState() => _ActorDetailsScreenState();
}

class _ActorDetailsScreenState extends State<ActorDetailsScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _person;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.dio.get('${ApiConstants.apiPrefix}/person/${widget.personId}');
      setState(() {
        _person = data.data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: AppColors.background, body: AppLoader());
    if (_person == null) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: Text('خطأ في التحميل', style: TextStyle(color: Colors.white))));

    final profilePath = _person!['profile_path'];
    final imageUrl = profilePath != null ? '${ApiConstants.tmdbImageBase}/w500$profilePath' : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_person!['name'] ?? 'ممثل')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 180,
                height: 270,
                child: imageUrl.isEmpty
                    ? Container(color: AppColors.surfaceLight, child: const Icon(Icons.person, size: 80, color: Colors.white54))
                    : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(_person!['name'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          if (_person!['birthday'] != null)
            Text('تاريخ الميلاد: ${_person!['birthday']}', style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
          if (_person!['place_of_birth'] != null)
            Text('مكان الميلاد: ${_person!['place_of_birth']}', style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          const Text('السيرة الذاتية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
          const SizedBox(height: 10),
          Text(
            _person!['biography'] ?? 'لا توجد سيرة ذاتية متاحة بالعربية.',
            style: const TextStyle(color: AppColors.textTertiary, height: 1.6),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
