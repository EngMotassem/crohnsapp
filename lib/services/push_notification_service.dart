import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Callback for showing notifications in the app
  static Function(String title, String body)? onNotificationReceived;
  
  // Stream subscription for in-app notifications
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  bool _isFirstSnapshot = true;
  DateTime? _initTime;

  Future<void> initialize(String? userId, {String? userRole}) async {
    if (!kIsWeb) return;

    try {
      debugPrint('PushNotificationService: Starting initialization...');
      
      // Store initialization time to filter old notifications
      _initTime = DateTime.now();
      
      // Start in-app notification listener (works without Cloud Functions)
      _startInAppNotificationListener(userRole ?? 'patient');
      
      // Request permission for notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('PushNotificationService: Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('PushNotificationService: User granted notification permission');
        
        // Get FCM token without VAPID key for now
        // Note: For production, you need to set the VAPID key from Firebase Console
        // Go to Firebase Console > Project Settings > Cloud Messaging > Web Push certificates
        String? token;
        try {
          token = await _messaging.getToken();
          debugPrint('PushNotificationService: FCM Token obtained: ${token?.substring(0, 20)}...');
        } catch (e) {
          debugPrint('PushNotificationService: Error getting token: $e');
        }
        
        if (token != null && userId != null) {
          await _saveTokenToFirestore(userId, token);
          debugPrint('PushNotificationService: Token saved for user $userId');
        } else {
          debugPrint('PushNotificationService: Token is null or userId is null');
        }
        
        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          debugPrint('PushNotificationService: Token refreshed');
          if (userId != null) {
            _saveTokenToFirestore(userId, newToken);
          }
        });
        
        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        debugPrint('PushNotificationService: Foreground message listener set up');
        
      } else {
        debugPrint('PushNotificationService: User declined notification permission');
      }
    } catch (e) {
      debugPrint('PushNotificationService: Error initializing: $e');
    }
  }
  
  // In-app notification listener - works without Cloud Functions
  void _startInAppNotificationListener(String userRole) {
    debugPrint('PushNotificationService: Starting in-app notification listener for role: $userRole');
    _isFirstSnapshot = true;
    
    _notificationSubscription = _firestore
        .collection('notifications')
        .orderBy('sentAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      // Skip the first snapshot to avoid showing old notifications
      if (_isFirstSnapshot) {
        _isFirstSnapshot = false;
        debugPrint('PushNotificationService: Skipping initial snapshot (${snapshot.docs.length} docs)');
        return;
      }
      
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        
        final data = change.doc.data();
        if (data == null) continue;
        
        // Check if notification is new (created after initialization)
        final sentAt = data['sentAt'] as Timestamp?;
        if (sentAt != null && _initTime != null) {
          if (sentAt.toDate().isBefore(_initTime!)) {
            debugPrint('PushNotificationService: Skipping old notification');
            continue;
          }
        }
        
        // Check target audience
        final targetAudience = data['targetAudience'] as String? ?? 'all';
        if (targetAudience != 'all' && targetAudience != userRole) {
          debugPrint('PushNotificationService: Skipping notification not for this role');
          continue;
        }
        
        final title = data['title'] as String? ?? '';
        final body = data['body'] as String? ?? '';
        
        if (title.isNotEmpty && body.isNotEmpty && onNotificationReceived != null) {
          debugPrint('PushNotificationService: Showing in-app notification: $title');
          onNotificationReceived!(title, body);
        }
      }
    }, onError: (error) {
      debugPrint('PushNotificationService: Error listening to notifications: $error');
    });
  }
  
  // Stop the in-app notification listener
  void stopInAppNotificationListener() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _isFirstSnapshot = true;
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM token saved to Firestore');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

    void _handleForegroundMessage(RemoteMessage message) {
      debugPrint('PushNotificationService: Received foreground message');
      debugPrint('PushNotificationService: Title: ${message.notification?.title}');
      debugPrint('PushNotificationService: Body: ${message.notification?.body}');
    
      // Call the callback if set to show notification in the app
      if (onNotificationReceived != null && 
          message.notification?.title != null && 
          message.notification?.body != null) {
        onNotificationReceived!(
          message.notification!.title!,
          message.notification!.body!,
        );
      }
    }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> removeToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }
}
