# Firebase Realtime Database Integration

This document describes how the IoT Healthcare app is integrated with Firebase Realtime Database for real-time data synchronization.

## Database URL

The app connects to:
```
https://iotbmtech-default-rtdb.asia-southeast1.firebasedatabase.app/
```

## Data Structure

The Firebase Realtime Database uses the following JSON structure:

```json
{
  "metrics": {
    "Heart Rate": {
      "value": "72",
      "unit": "BPM",
      "timestamp": "2024-01-15T10:30:00.000Z"
    },
    "Blood Pressure": {
      "value": "120/80",
      "unit": "mmHg",
      "timestamp": "2024-01-15T10:30:00.000Z"
    },
    "Temperature": {
      "value": "98.6",
      "unit": "°F",
      "timestamp": "2024-01-15T10:30:00.000Z"
    },
    "Oxygen Level": {
      "value": "98",
      "unit": "%",
      "timestamp": "2024-01-15T10:30:00.000Z"
    },
    "Steps": {
      "value": "8542",
      "unit": "steps",
      "timestamp": "2024-01-15T10:30:00.000Z"
    },
    "Calories": {
      "value": "1245",
      "unit": "kcal",
      "timestamp": "2024-01-15T10:30:00.000Z"
    },
    "Gauge": {
      "temperature": 72.0,
      "timestamp": "2024-01-15T10:30:00.000Z"
    },
    "Heart Rate Chart": {
      "dataSource": "heartrate",
      "data": [],
      "timestamp": "2024-01-15T10:30:00.000Z"
    }
  }
}
```

## Features

### Real-time Synchronization

- **Bidirectional Sync**: Changes in Firebase automatically update the app in real-time, and the app can update Firebase data
- **Stream-based Updates**: Uses Firebase Realtime Database streams to listen for changes
- **Automatic Initialization**: Default metrics structure is created automatically if it doesn't exist

### How It Works

1. **Firebase Service** (`lib/services/firebase_database_service.dart`):
   - Manages all Firebase Realtime Database operations
   - Provides methods for reading, writing, updating, and deleting data
   - Streams real-time updates using `watchMetricsData()`

2. **Reactive Widget** (`ReactiveHealthMetricsWidget`):
   - Listens to Firebase data changes using `StreamBuilder`
   - Automatically rebuilds UI when Firebase data changes
   - Handles loading and error states

3. **Data Flow**:
   - App startup → Initialize Firebase → Load default metrics if needed
   - User views dashboard → Stream listens to `/metrics` path
   - Firebase data changes → Stream emits new data → UI updates automatically
   - App can update Firebase → Changes propagate to all connected clients

## Usage

### Reading Data

```dart
final firebaseService = FirebaseDatabaseService();

// Read once
final data = await firebaseService.getMetricsData();

// Stream real-time updates
firebaseService.watchMetricsData().listen((data) {
  // Handle data updates
});
```

### Updating Data

```dart
// Update a specific metric
await firebaseService.updateMetric('Heart Rate', {
  'value': '75',
  'unit': 'BPM',
  'timestamp': DateTime.now().toIso8601String(),
});
```

### Writing Data

```dart
// Write complete metrics structure
await firebaseService.writeData('metrics', {
  'Heart Rate': {
    'value': '72',
    'unit': 'BPM',
    'timestamp': DateTime.now().toIso8601String(),
  },
  // ... other metrics
});
```

## Firebase Rules

Make sure your Firebase Realtime Database rules allow read/write access. Example rules:

```json
{
  "rules": {
    "metrics": {
      ".read": true,
      ".write": true
    }
  }
}
```

**Note**: For production, implement proper authentication-based rules.

## Testing

1. Open Firebase Console → Realtime Database
2. Navigate to the database URL
3. Manually update values in the `/metrics` path
4. Observe the app updating in real-time

## Troubleshooting

- **Connection Issues**: Ensure the database URL is correct and accessible
- **Permission Errors**: Check Firebase Realtime Database rules
- **Data Not Updating**: Verify the stream is properly subscribed
- **Initialization Errors**: Check Firebase Core initialization in `main.dart`


