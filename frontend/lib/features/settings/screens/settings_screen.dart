import '../../../core/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '1.0.0';
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      setState(() => _version = info.version);
    });
  }

  Future<void> _clearCache() async {
    setState(() => _clearing = true);
    try {
      await DefaultCacheManager().emptyCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم مسح ذاكرة التخزين المؤقت بنجاح'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء المسح'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _clearing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildTile(Icons.info_outline, 'إصدار التطبيق', _version),
          _buildTile(Icons.person_outline, 'المطور', 'جلولي مصطفى\nDjellouli Mustafa'),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.primaryLight),
            title: const Text('مسح ذاكرة التخزين المؤقت', style: TextStyle(color: Colors.white)),
            subtitle: const Text('تحرير مساحة الهاتف وإعادة تحميل الصور', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            trailing: _clearing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: _clearing ? null : _clearCache,
          ),
          const Divider(color: AppColors.surfaceLight),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'شكراً لاستخدامك تطبيق Sttiten Movies.\nصُنع بكل حب لخدمة المحتوى العربي.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textTertiary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryLight),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}
