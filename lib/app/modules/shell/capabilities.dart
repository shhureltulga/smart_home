class Capabilities {
  // role -> зөвшөөрөгдөх drawer item кодууд
  static const Map<String, Set<String>> byRole = {
    'owner':  {'usage', 'call', 'gate', 'car', 'devices', 'terms', 'settings', 'logout'},
    'admin':  {'usage', 'call', 'gate', 'devices', 'terms', 'settings', 'logout'},
    'member': {'usage', 'call', 'gate', 'terms', 'logout'},
    'guest':  {'gate', 'terms', 'logout'},
  };

  static bool allow(String role, String code) {
    final set = byRole[role] ?? const {};
    return set.contains(code);
  }
}
