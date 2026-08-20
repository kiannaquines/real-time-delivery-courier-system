import 'dart:html' as html;

abstract class SessionStorage {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clear();
}

class DefaultSessionStorage implements SessionStorage {
  @override
  Future<void> write(String key, String value) async {
    try {
      html.window.localStorage['mns_$key'] = value;
    } catch (_) {}
  }

  @override
  Future<String?> read(String key) async {
    try {
      return html.window.localStorage['mns_$key'];
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      html.window.localStorage.remove('mns_$key');
    } catch (_) {}
  }

  @override
  Future<void> clear() async {
    try {
      html.window.localStorage.remove('mns_access_token');
      html.window.localStorage.remove('mns_refresh_token');
      html.window.localStorage.remove('mns_user_profile');
    } catch (_) {}
  }
}

class InMemorySessionStorage implements SessionStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return _data[key];
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }
}
