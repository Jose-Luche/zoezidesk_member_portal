import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/core/notifications/push_messaging.dart';
import 'package:zoezidesk_member/core/storage/session_storage.dart';
import 'package:zoezidesk_member/data/api/auth_api.dart';
import 'package:zoezidesk_member/data/dto/member_summary.dart';

class InMemorySecureStore implements SecureStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> deleteAll() async => values.clear();
}

class MockAuthApi extends Mock implements AuthApi {}

const testMember = MemberSummary(
  id: 7,
  name: 'Jane Wanjiru',
  memberNumber: 'ZD-0007',
  phone: '254711000001',
  gymName: 'Test Gym',
  status: 'active',
);

/// Answers dio requests from a queue of canned responses or errors.
class FakeAdapter implements HttpClientAdapter {
  final responses = <Object>[];
  final requests = <RequestOptions>[];

  void reply(int status, [Object? body]) => responses.add((status, body));

  void fail(DioExceptionType type) => responses.add(type);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    // Nothing queued behaves like being offline.
    final next = responses.isEmpty ? DioExceptionType.connectionError : responses.removeAt(0);
    if (next is DioExceptionType) {
      throw DioException(requestOptions: options, type: next);
    }
    final (status, body) = next as (int, Object?);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Firebase Cloud Messaging stand-in: tests push messages and tokens in.
class FakePushMessaging implements PushMessaging {
  bool allow = true;
  String? token = 'fcm-1';
  final calls = <String>[];
  final refreshes = StreamController<String>.broadcast();
  final foreground = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();
  PushMessage? launchedFrom;

  @override
  bool get available => true;

  @override
  Future<bool> requestPermission() async {
    calls.add('permission');
    return allow;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get tokenRefresh => refreshes.stream;

  @override
  Future<void> deleteToken() async => calls.add('deleteToken');

  @override
  Stream<PushMessage> get foregroundMessages => foreground.stream;

  @override
  Stream<PushMessage> get openedMessages => opened.stream;

  @override
  Future<PushMessage?> initialMessage() async {
    final m = launchedFrom;
    launchedFrom = null;
    return m;
  }
}
