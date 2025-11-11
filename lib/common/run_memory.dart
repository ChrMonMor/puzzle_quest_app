class RunMemory {
  static final List<Map<String, dynamic>> _createdRuns = [];

  static void addRun(Map<String, dynamic> run) {
    _createdRuns.add(run);
  }

  static List<Map<String, dynamic>> get runs => List.unmodifiable(_createdRuns);

  static void clear() => _createdRuns.clear();
}
