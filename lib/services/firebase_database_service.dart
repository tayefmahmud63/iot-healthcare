import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseDatabaseService {
  static const String databaseUrl =
      'https://iot-healthcare-20f1c-default-rtdb.firebaseio.com';
  late DatabaseReference _databaseRef;

  FirebaseDatabaseService() {
    _databaseRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseUrl,
    ).ref();
  }

  DatabaseReference getRef([String? path]) {
    if (path == null || path.isEmpty) {
      return _databaseRef;
    }
    return _databaseRef.child(path);
  }

  Stream<DatabaseEvent> watchData([String? path]) {
    return getRef(path).onValue;
  }

  Future<Map<String, dynamic>?> readData([String? path]) async {
    try {
      final snapshot = await getRef(path).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      print('Error reading data: $e');
      return null;
    }
  }

  Future<bool> writeData(String path, Map<String, dynamic> data) async {
    try {
      await getRef(path).set(data);
      return true;
    } catch (e) {
      print('Error writing data: $e');
      return false;
    }
  }

  Future<bool> updateData(String path, Map<String, dynamic> updates) async {
    try {
      await getRef(path).update(updates);
      return true;
    } catch (e) {
      print('Error updating data: $e');
      return false;
    }
  }

  Future<bool> deleteData(String path) async {
    try {
      await getRef(path).remove();
      return true;
    } catch (e) {
      print('Error deleting data: $e');
      return false;
    }
  }

  Future<bool> setValue(String path, dynamic value) async {
    try {
      await getRef(path).set(value);
      return true;
    } catch (e) {
      print('Error setting value: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getMetricsData() async {
    return await readData('metrics');
  }

  Future<bool> updateMetric(
    String metricName,
    Map<String, dynamic> metricData,
  ) async {
    return await updateData('metrics/$metricName', metricData);
  }

  Stream<Map<String, dynamic>?> watchMetricsData() {
    return watchData('metrics').map((event) {
      if (event.snapshot.exists) {
        final value = event.snapshot.value;
        if (value is Map) {
          return Map<String, dynamic>.from(value);
        }
      }
      return null;
    });
  }

  Future<void> initializeDefaultMetrics() async {
    final existing = await readData('metrics');
    if (existing == null || existing.isEmpty) {
      final defaultMetrics = {
        'Heart Rate': {
          'value': '72',
          'unit': 'BPM',
          'timestamp': DateTime.now().toIso8601String(),
        },
        'Blood Pressure': {
          'value': '120/80',
          'unit': 'mmHg',
          'timestamp': DateTime.now().toIso8601String(),
        },
        'Temperature': {
          'value': '98.6',
          'unit': '°F',
          'timestamp': DateTime.now().toIso8601String(),
        },
        'Oxygen Level': {
          'value': '98',
          'unit': '%',
          'timestamp': DateTime.now().toIso8601String(),
        },
        'Steps': {
          'value': '8542',
          'unit': 'steps',
          'timestamp': DateTime.now().toIso8601String(),
        },
        'Calories': {
          'value': '1245',
          'unit': 'kcal',
          'timestamp': DateTime.now().toIso8601String(),
        },
        'Gauge': {
          'value': 72,
          'unit': '°C',
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
      await writeData('metrics', defaultMetrics);
    }
  }
}
