import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 앱 소개를 이미 봤는지 기억한다. 처음 실행할 때만 소개를 보여 주려고 쓴다.
abstract interface class IntroStore {
  Future<bool> isSeen();
  Future<void> markSeen();
}

/// 늘 '이미 봤다'고 답한다. 소개 없이 바로 시작해야 하는 테스트와 미리보기의 기본값이다.
class SeenIntroStore implements IntroStore {
  const SeenIntroStore();

  @override
  Future<bool> isSeen() async => true;

  @override
  Future<void> markSeen() async {}
}

/// 기기의 보안 저장소에 기록한다. 로그인 정보와 같은 저장소를 써서 새 패키지가 필요 없다.
class SecureIntroStore implements IntroStore {
  SecureIntroStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'ahni.intro.seen';
  final FlutterSecureStorage _storage;

  @override
  Future<bool> isSeen() async {
    try {
      return await _storage.read(key: _key) == 'true';
    } on Object catch (_) {
      // 저장소를 못 읽으면 소개를 다시 보여 주는 편이 막히는 것보다 낫다.
      return false;
    }
  }

  @override
  Future<void> markSeen() async {
    try {
      await _storage.write(key: _key, value: 'true');
    } on Object catch (_) {
      // 기록하지 못하면 다음 실행에 소개가 한 번 더 보일 뿐이다.
    }
  }
}
