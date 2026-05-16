import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/group.dart';

class StorageService {
  static const String _groupsKey = 'groups';
  static const String _defaultGroupIdKey = 'default_group_id';

  Future<List<Group>> loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_groupsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList
        .map((item) => Group.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveGroups(List<Group> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(groups.map((g) => g.toJson()).toList());
    await prefs.setString(_groupsKey, jsonString);
  }

  Future<void> addGroup(Group group) async {
    final groups = await loadGroups();
    groups.add(group);
    await saveGroups(groups);
  }

  Future<void> updateGroup(Group updatedGroup) async {
    final groups = await loadGroups();
    final index = groups.indexWhere((g) => g.id == updatedGroup.id);
    if (index != -1) {
      groups[index] = updatedGroup;
      await saveGroups(groups);
    }
  }

  Future<void> deleteGroup(String groupId) async {
    final groups = await loadGroups();
    groups.removeWhere((g) => g.id == groupId);
    await saveGroups(groups);
  }

  // ── Default group ────────────────────────────────────────────────────────

  Future<String?> getDefaultGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultGroupIdKey);
  }

  Future<void> saveDefaultGroupId(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultGroupIdKey, groupId);
  }

  Future<void> clearDefaultGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_defaultGroupIdKey);
  }
}