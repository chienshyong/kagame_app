import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchHistoryService {
  static const String _storageKey = 'recent_searches';
  static const int _maxSearches = 10;
  
  // Retrieve recent searches from storage
  static Future<List<String>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? searchesJson = prefs.getString(_storageKey);
      
      if (searchesJson == null) {
        return [];
      }
      
      final List<dynamic> decodedList = json.decode(searchesJson);
      return decodedList.map((item) => item.toString()).toList();
    } catch (e) {
      print('Error retrieving recent searches: $e');
      return [];
    }
  }
  
  // Save a new search to history
  static Future<void> saveSearch(String query) async {
    if (query.trim().isEmpty) {
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> currentSearches = await getRecentSearches();
      
      // Remove the query if it already exists (to avoid duplicates)
      currentSearches.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
      
      // Add the new query to the beginning of the list
      currentSearches.insert(0, query);
      
      // Limit the list to max number of searches
      final List<String> trimmedSearches = 
          currentSearches.length > _maxSearches ? 
          currentSearches.sublist(0, _maxSearches) : 
          currentSearches;
      
      // Save the updated list
      await prefs.setString(_storageKey, json.encode(trimmedSearches));
    } catch (e) {
      print('Error saving search: $e');
    }
  }
  
  // Clear all recent searches
  static Future<void> clearSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing searches: $e');
    }
  }
  
  // Remove a specific search from history
  static Future<void> removeSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> currentSearches = await getRecentSearches();
      
      currentSearches.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
      
      await prefs.setString(_storageKey, json.encode(currentSearches));
    } catch (e) {
      print('Error removing search: $e');
    }
  }
}