import 'package:flutter/foundation.dart';
import 'package:library_nitc/cache/cache_store.dart';
import 'package:library_nitc/services/curriculum_service.dart';

class CurriculumProvider extends ChangeNotifier {
  late final CurriculumService _service;

  CurriculumProvider({CacheStore? cacheStore}) {
    _service = CurriculumService(cacheStore: cacheStore);
  }

  String? _version;
  Map<String, dynamic>? _curriculumData;
  bool _isLoading = false;
  String? _error;

  String? get version => _version;
  Map<String, dynamic>? get data => _curriculumData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoaded => _curriculumData != null;

  Future<void> loadCurriculum() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final remoteVersion = await _service.fetchVersion();
      if (_version != remoteVersion || _curriculumData == null) {
        final curriculum = await _service.fetchCurriculum();
        _version = remoteVersion;
        _curriculumData = curriculum;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
