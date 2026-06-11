import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../models/chat.dart';
import '../models/profile.dart';
import '../models/shipment.dart';
import '../supabase/client.dart';
import 'mock_data.dart';

/// Result wrapper for repository calls.
class RepoResult<T> {
  final T? data;
  final Object? error;
  const RepoResult.ok(this.data) : error = null;
  const RepoResult.fail(this.error) : data = null;
  bool get isOk => error == null;
}

/// Repository facade. When USE_MOCK_DATA is true (default) or the
/// Supabase anon key is not configured it serves from [MockData];
/// otherwise it round-trips the live Supabase project.
class ShipmentRepository {
  ShipmentRepository();

  bool get _useMock => AppEnv.useMockData || !SupabaseClientProvider.isConfigured;

  SupabaseClient get _db => SupabaseClientProvider.instance;

  // ── Shipments ──────────────────────────────────────────────────────────

  Future<RepoResult<List<Shipment>>> listShipments({String? userId}) async {
    try {
      if (_useMock) {
        return RepoResult.ok(await MockData.instance.listShipments(userId: userId));
      }
      var query = _db.from('shipments').select();
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      final res = await query.order('created_at', ascending: false);
      final list = (res as List)
          .map((e) => Shipment.fromMap((e as Map).cast<String, dynamic>()))
          .toList();
      return RepoResult.ok(list);
    } catch (e) {
      return RepoResult.fail(e);
    }
  }

  Future<RepoResult<Shipment?>> getByTracking(String tracking) async {
    try {
      if (_useMock) {
        return RepoResult.ok(
            await MockData.instance.getShipmentByTracking(tracking));
      }
      final res = await _db
          .from('shipments')
          .select()
          .eq('tracking_number', tracking)
          .maybeSingle();
      if (res == null) return RepoResult.ok(null);
      return RepoResult.ok(Shipment.fromMap((res as Map).cast<String, dynamic>()));
    } catch (e) {
      return RepoResult.fail(e);
    }
  }

  Future<RepoResult<List<TrackingEvent>>> events(String shipmentId) async {
    try {
      if (_useMock) {
        return RepoResult.ok(
            await MockData.instance.eventsForShipment(shipmentId));
      }
      final res = await _db
          .from('tracking_events')
          .select()
          .eq('shipment_id', shipmentId)
          .order('occurred_at', ascending: false);
      final list = (res as List)
          .map((e) => TrackingEvent.fromMap((e as Map).cast<String, dynamic>()))
          .toList();
      return RepoResult.ok(list);
    } catch (e) {
      return RepoResult.fail(e);
    }
  }

  Future<RepoResult<Shipment>> create({
    required String userId,
    required Address origin,
    required Address destination,
    required Package package,
    required String service,
    String? reference,
  }) async {
    try {
      if (_useMock) {
        final created = await MockData.instance.createShipment(
          userId: userId,
          origin: origin,
          destination: destination,
          package: package,
          service: service,
          reference: reference,
        );
        return RepoResult.ok(created);
      }
      final tracking = _generateTracking();
      final payload = {
        'tracking_number': tracking,
        'user_id': userId,
        'status': 'created',
        'service': service,
        'origin': origin.toMap(),
        'destination': destination.toMap(),
        'package': package.toMap(),
        if (reference != null) 'reference': reference,
        'created_at': DateTime.now().toIso8601String(),
      };
      final res = await _db.from('shipments').insert(payload).select().single();
      return RepoResult.ok(Shipment.fromMap((res as Map).cast<String, dynamic>()));
    } catch (e) {
      return RepoResult.fail(e);
    }
  }

  Future<RepoResult<Shipment>> updateStatus(
      String shipmentId, ShipmentStatus next) async {
    try {
      if (_useMock) {
        final updated =
            await MockData.instance.updateShipmentStatus(shipmentId, next);
        return RepoResult.ok(updated);
      }
      final res = await _db
          .from('shipments')
          .update({'status': next.name}).eq('id', shipmentId).select().single();
      return RepoResult.ok(Shipment.fromMap((res as Map).cast<String, dynamic>()));
    } catch (e) {
      return RepoResult.fail(e);
    }
  }

  // ── Profile ────────────────────────────────────────────────────────────

  Future<RepoResult<AppProfile?>> getProfile(String userId) async {
    try {
      if (_useMock) {
        return RepoResult.ok(await MockData.instance.getProfile(userId));
      }
      final res = await _db
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (res == null) return RepoResult.ok(null);
      return RepoResult.ok(
          AppProfile.fromMap((res as Map).cast<String, dynamic>()));
    } catch (e) {
      return RepoResult.fail(e);
    }
  }

  Future<RepoResult<List<AppProfile>>> listProfiles() async {
    try {
      if (_useMock) {
        return RepoResult.ok(await MockData.instance.listProfiles());
      }
      final res = await _db.from('profiles').select();
      final list = (res as List)
          .map((e) => AppProfile.fromMap((e as Map).cast<String, dynamic>()))
          .toList();
      return RepoResult.ok(list);
    } catch (e) {
      return RepoResult.fail(e);
    }
  }

  Future<RepoResult<AppProfile>> upsertProfile(AppProfile p) async {
    try {
      if (_useMock) {
        return RepoResult.ok(await MockData.instance.upsertProfile(p));
      }
      final res = await _db.from('profiles').upsert(p.toMap()).select().single();
      return RepoResult.ok(
          AppProfile.fromMap((res as Map).cast<String, dynamic>()));
    } catch (e) {
      return RepoResult.fail(e);
    }
  }

  // ── Chat ───────────────────────────────────────────────────────────────

  Future<RepoResult<List<ChatMessage>>> messages(String threadId) async {
    try {
      if (_useMock) {
        return RepoResult.ok(
            await MockData.instance.messagesForThread(threadId));
      }
      final res = await _db
          .from('chat_messages')
          .select()
          .eq('thread_id', threadId)
          .order('sent_at', ascending: true);
      final list = (res as List)
          .map((e) => ChatMessage.fromMap((e as Map).cast<String, dynamic>()))
          .toList();
      return RepoResult.ok(list);
    } catch (e) {
      return RepoResult.fail(e);
    }
  }

  Future<RepoResult<ChatMessage>> postMessage({
    required String threadId,
    required String senderId,
    required String senderName,
    required String text,
    required bool fromAgent,
  }) async {
    try {
      if (_useMock) {
        final msg = await MockData.instance.postMessage(
            threadId: threadId,
            senderId: senderId,
            senderName: senderName,
            text: text,
            fromAgent: fromAgent);
        return RepoResult.ok(msg);
      }
      final payload = {
        'thread_id': threadId,
        'sender_id': senderId,
        'sender_name': senderName,
        'text': text,
        'sent_at': DateTime.now().toIso8601String(),
        'from_agent': fromAgent,
      };
      final res =
          await _db.from('chat_messages').insert(payload).select().single();
      return RepoResult.ok(
          ChatMessage.fromMap((res as Map).cast<String, dynamic>()));
    } catch (e) {
      return RepoResult.fail(e);
    }
  }

  // ── Notifications ──────────────────────────────────────────────────────

  Future<RepoResult<List<NotificationItem>>> notifications(String userId) async {
    try {
      if (_useMock) {
        return RepoResult.ok(
            await MockData.instance.notificationsForUser(userId));
      }
      final res = await _db
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('sent_at', ascending: false);
      final list = (res as List)
          .map((e) =>
              NotificationItem.fromMap((e as Map).cast<String, dynamic>()))
          .toList();
      return RepoResult.ok(list);
    } catch (e) {
      return RepoResult.fail(e);
    }
  }

  String _generateTracking() {
    final seq = DateTime.now().millisecondsSinceEpoch % 90000 + 10000;
    final date = DateTime.now()
        .toIso8601String()
        .substring(0, 10)
        .replaceAll('-', '');
    return 'APK$date${seq.toString().padLeft(5, '0')}';
  }
}
