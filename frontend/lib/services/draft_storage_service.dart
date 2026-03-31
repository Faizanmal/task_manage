import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DraftStorageService {
  static const String _draftKey = 'task_draft';

  // Save draft task
  static Future<void> saveDraft(String title, String description, String dueDate, String status, int? blockedBy, [String recurring = 'NONE']) async {
    final prefs = await SharedPreferences.getInstance();
    final draft = {
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'status': status,
      'blockedBy': blockedBy,
      'recurring': recurring,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_draftKey, jsonEncode(draft));
  }

  // Get draft task
  static Future<Map<String, dynamic>?> getDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString(_draftKey);
    if (draftJson == null) return null;
    
    try {
      return jsonDecode(draftJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Clear draft
  static Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  // Check if draft exists
  static Future<bool> hasDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_draftKey);
  }
}
