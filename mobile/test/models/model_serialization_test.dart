import 'package:flutter_test/flutter_test.dart';

import 'package:car_post_all/models/user.dart';
import 'package:car_post_all/models/auth_tokens.dart';
import 'package:car_post_all/models/plate.dart';
import 'package:car_post_all/models/inbox_message.dart';
import 'package:car_post_all/models/sent_message.dart';

void main() {
  group('User', () {
    test('fromJson creates correct instance', () {
      final json = {
        'id': 'user-001',
        'email': 'alice@example.com',
        'displayName': 'Alice',
      };

      final user = User.fromJson(json);

      expect(user.id, equals('user-001'));
      expect(user.email, equals('alice@example.com'));
      expect(user.displayName, equals('Alice'));
    });

    test('toJson produces correct map', () {
      const user = User(
        id: 'user-001',
        email: 'alice@example.com',
        displayName: 'Alice',
      );

      final json = user.toJson();

      expect(json['id'], equals('user-001'));
      expect(json['email'], equals('alice@example.com'));
      expect(json['displayName'], equals('Alice'));
    });

    test('fromJson/toJson round-trip preserves data', () {
      final originalJson = {
        'id': 'user-002',
        'email': 'bob@example.com',
        'displayName': 'Bob',
      };

      final user = User.fromJson(originalJson);
      final roundTripped = user.toJson();

      expect(roundTripped, equals(originalJson));
    });

    test('equality works for identical data', () {
      const user1 = User(id: 'u1', email: 'a@b.com', displayName: 'A');
      const user2 = User(id: 'u1', email: 'a@b.com', displayName: 'A');

      expect(user1, equals(user2));
    });

    test('equality fails for different data', () {
      const user1 = User(id: 'u1', email: 'a@b.com', displayName: 'A');
      const user2 = User(id: 'u2', email: 'a@b.com', displayName: 'A');

      expect(user1, isNot(equals(user2)));
    });
  });

  group('AuthTokens', () {
    test('fromJson creates correct instance', () {
      final json = {
        'accessToken': 'eyJ.access.token',
        'refreshToken': 'eyJ.refresh.token',
      };

      final tokens = AuthTokens.fromJson(json);

      expect(tokens.accessToken, equals('eyJ.access.token'));
      expect(tokens.refreshToken, equals('eyJ.refresh.token'));
    });

    test('toJson produces correct map', () {
      const tokens = AuthTokens(
        accessToken: 'eyJ.access.token',
        refreshToken: 'eyJ.refresh.token',
      );

      final json = tokens.toJson();

      expect(json['accessToken'], equals('eyJ.access.token'));
      expect(json['refreshToken'], equals('eyJ.refresh.token'));
    });

    test('fromJson/toJson round-trip preserves data', () {
      final originalJson = {
        'accessToken': 'abc123',
        'refreshToken': 'def456',
      };

      final tokens = AuthTokens.fromJson(originalJson);
      final roundTripped = tokens.toJson();

      expect(roundTripped, equals(originalJson));
    });

    test('equality works for identical data', () {
      const t1 = AuthTokens(accessToken: 'a', refreshToken: 'b');
      const t2 = AuthTokens(accessToken: 'a', refreshToken: 'b');

      expect(t1, equals(t2));
    });
  });

  group('Plate', () {
    test('fromJson creates correct instance with all fields', () {
      final json = {
        'id': 'plate-001',
        'userId': 'user-001',
        'plateNumber': 'ABC123',
        'stateOrRegion': 'CA',
        'claimedAt': '2025-06-15T10:30:00.000Z',
        'isActive': true,
        'createdAt': '2025-06-01T08:00:00.000Z',
      };

      final plate = Plate.fromJson(json);

      expect(plate.id, equals('plate-001'));
      expect(plate.userId, equals('user-001'));
      expect(plate.plateNumber, equals('ABC123'));
      expect(plate.stateOrRegion, equals('CA'));
      expect(plate.claimedAt, isA<DateTime>());
      expect(plate.isActive, isTrue);
      expect(plate.createdAt, isA<DateTime>());
    });

    test('fromJson handles nullable fields as null', () {
      final json = {
        'id': 'plate-002',
        'plateNumber': 'XYZ789',
        'createdAt': '2025-06-01T08:00:00.000Z',
      };

      final plate = Plate.fromJson(json);

      expect(plate.userId, isNull);
      expect(plate.stateOrRegion, isNull);
      expect(plate.claimedAt, isNull);
    });

    test('fromJson defaults isActive to true when not present', () {
      final json = {
        'id': 'plate-003',
        'plateNumber': 'DEF456',
        'createdAt': '2025-06-01T08:00:00.000Z',
      };

      final plate = Plate.fromJson(json);

      expect(plate.isActive, isTrue);
    });

    test('toJson produces correct map', () {
      final plate = Plate(
        id: 'plate-001',
        userId: 'user-001',
        plateNumber: 'ABC123',
        stateOrRegion: 'CA',
        claimedAt: DateTime.utc(2025, 6, 15, 10, 30),
        isActive: true,
        createdAt: DateTime.utc(2025, 6, 1, 8, 0),
      );

      final json = plate.toJson();

      expect(json['id'], equals('plate-001'));
      expect(json['userId'], equals('user-001'));
      expect(json['plateNumber'], equals('ABC123'));
      expect(json['stateOrRegion'], equals('CA'));
      expect(json['claimedAt'], equals('2025-06-15T10:30:00.000Z'));
      expect(json['isActive'], isTrue);
      expect(json['createdAt'], equals('2025-06-01T08:00:00.000Z'));
    });

    test('toJson includes null for nullable fields when null', () {
      final plate = Plate(
        id: 'plate-002',
        plateNumber: 'XYZ789',
        createdAt: DateTime.utc(2025, 6, 1, 8, 0),
      );

      final json = plate.toJson();

      expect(json.containsKey('userId'), isTrue);
      expect(json['userId'], isNull);
      expect(json.containsKey('stateOrRegion'), isTrue);
      expect(json['stateOrRegion'], isNull);
      expect(json.containsKey('claimedAt'), isTrue);
      expect(json['claimedAt'], isNull);
    });

    test('fromJson/toJson round-trip preserves data', () {
      final plate = Plate(
        id: 'plate-rt',
        userId: 'user-rt',
        plateNumber: 'RT1234',
        stateOrRegion: 'NY',
        claimedAt: DateTime.utc(2025, 7, 1, 12, 0),
        isActive: false,
        createdAt: DateTime.utc(2025, 6, 1, 8, 0),
      );

      final json = plate.toJson();
      final restored = Plate.fromJson(json);

      expect(restored, equals(plate));
    });

    test('equality works for identical data', () {
      final createdAt = DateTime.utc(2025, 6, 1);
      final p1 = Plate(id: 'p', plateNumber: 'AB', createdAt: createdAt);
      final p2 = Plate(id: 'p', plateNumber: 'AB', createdAt: createdAt);

      expect(p1, equals(p2));
    });
  });

  group('InboxMessage', () {
    test('fromJson creates correct instance with all fields', () {
      final json = {
        'id': 'msg-001',
        'senderDisplayName': 'Alice',
        'subject': 'Hey!',
        'body': 'Nice car you have!',
        'recipientPlateId': 'plate-001',
        'isRead': true,
        'createdAt': '2025-06-15T14:30:00.000Z',
      };

      final message = InboxMessage.fromJson(json);

      expect(message.id, equals('msg-001'));
      expect(message.senderDisplayName, equals('Alice'));
      expect(message.subject, equals('Hey!'));
      expect(message.body, equals('Nice car you have!'));
      expect(message.recipientPlateId, equals('plate-001'));
      expect(message.isRead, isTrue);
      expect(message.createdAt, isA<DateTime>());
    });

    test('fromJson handles null subject', () {
      final json = {
        'id': 'msg-002',
        'senderDisplayName': 'Bob',
        'body': 'Your lights are on.',
        'recipientPlateId': 'plate-002',
        'createdAt': '2025-06-15T14:30:00.000Z',
      };

      final message = InboxMessage.fromJson(json);

      expect(message.subject, isNull);
    });

    test('fromJson defaults isRead to false when not present', () {
      final json = {
        'id': 'msg-003',
        'senderDisplayName': 'Carol',
        'body': 'Test body',
        'recipientPlateId': 'plate-003',
        'createdAt': '2025-06-15T14:30:00.000Z',
      };

      final message = InboxMessage.fromJson(json);

      expect(message.isRead, isFalse);
    });

    test('toJson produces correct map', () {
      final message = InboxMessage(
        id: 'msg-001',
        senderDisplayName: 'Alice',
        subject: 'Hey!',
        body: 'Nice car you have!',
        recipientPlateId: 'plate-001',
        isRead: true,
        createdAt: DateTime.utc(2025, 6, 15, 14, 30),
      );

      final json = message.toJson();

      expect(json['id'], equals('msg-001'));
      expect(json['senderDisplayName'], equals('Alice'));
      expect(json['subject'], equals('Hey!'));
      expect(json['body'], equals('Nice car you have!'));
      expect(json['recipientPlateId'], equals('plate-001'));
      expect(json['isRead'], isTrue);
      expect(json['createdAt'], equals('2025-06-15T14:30:00.000Z'));
    });

    test('fromJson/toJson round-trip preserves data', () {
      final message = InboxMessage(
        id: 'msg-rt',
        senderDisplayName: 'RoundTrip',
        subject: 'Test',
        body: 'Round trip body',
        recipientPlateId: 'plate-rt',
        isRead: false,
        createdAt: DateTime.utc(2025, 7, 1, 12, 0),
      );

      final json = message.toJson();
      final restored = InboxMessage.fromJson(json);

      expect(restored, equals(message));
    });

    test('fromJson/toJson round-trip preserves data with null subject', () {
      final message = InboxMessage(
        id: 'msg-rt2',
        senderDisplayName: 'RoundTrip',
        body: 'No subject body',
        recipientPlateId: 'plate-rt2',
        createdAt: DateTime.utc(2025, 7, 1, 12, 0),
      );

      final json = message.toJson();
      final restored = InboxMessage.fromJson(json);

      expect(restored, equals(message));
      expect(restored.subject, isNull);
    });

    test('equality works for identical data', () {
      final createdAt = DateTime.utc(2025, 6, 15);
      final m1 = InboxMessage(
        id: 'm',
        senderDisplayName: 'A',
        body: 'B',
        recipientPlateId: 'p',
        createdAt: createdAt,
      );
      final m2 = InboxMessage(
        id: 'm',
        senderDisplayName: 'A',
        body: 'B',
        recipientPlateId: 'p',
        createdAt: createdAt,
      );

      expect(m1, equals(m2));
    });
  });

  group('SentMessage', () {
    test('fromJson creates correct instance with all fields', () {
      final json = {
        'id': 'sent-001',
        'recipientPlateNumber': 'ABC123',
        'subject': 'Parking',
        'body': 'You are blocking my driveway.',
        'isRead': true,
        'createdAt': '2025-06-15T14:30:00.000Z',
      };

      final message = SentMessage.fromJson(json);

      expect(message.id, equals('sent-001'));
      expect(message.recipientPlateNumber, equals('ABC123'));
      expect(message.subject, equals('Parking'));
      expect(message.body, equals('You are blocking my driveway.'));
      expect(message.isRead, isTrue);
      expect(message.createdAt, isA<DateTime>());
    });

    test('fromJson handles null subject', () {
      final json = {
        'id': 'sent-002',
        'recipientPlateNumber': 'XYZ789',
        'body': 'No subject message.',
        'createdAt': '2025-06-15T14:30:00.000Z',
      };

      final message = SentMessage.fromJson(json);

      expect(message.subject, isNull);
    });

    test('fromJson defaults isRead to false when not present', () {
      final json = {
        'id': 'sent-003',
        'recipientPlateNumber': 'DEF456',
        'body': 'Test body',
        'createdAt': '2025-06-15T14:30:00.000Z',
      };

      final message = SentMessage.fromJson(json);

      expect(message.isRead, isFalse);
    });

    test('toJson produces correct map', () {
      final message = SentMessage(
        id: 'sent-001',
        recipientPlateNumber: 'ABC123',
        subject: 'Parking',
        body: 'You are blocking my driveway.',
        isRead: true,
        createdAt: DateTime.utc(2025, 6, 15, 14, 30),
      );

      final json = message.toJson();

      expect(json['id'], equals('sent-001'));
      expect(json['recipientPlateNumber'], equals('ABC123'));
      expect(json['subject'], equals('Parking'));
      expect(json['body'], equals('You are blocking my driveway.'));
      expect(json['isRead'], isTrue);
      expect(json['createdAt'], equals('2025-06-15T14:30:00.000Z'));
    });

    test('fromJson/toJson round-trip preserves data', () {
      final message = SentMessage(
        id: 'sent-rt',
        recipientPlateNumber: 'RT1234',
        subject: 'Test Subject',
        body: 'Round trip body',
        isRead: false,
        createdAt: DateTime.utc(2025, 7, 1, 12, 0),
      );

      final json = message.toJson();
      final restored = SentMessage.fromJson(json);

      expect(restored, equals(message));
    });

    test('fromJson/toJson round-trip preserves data with null subject', () {
      final message = SentMessage(
        id: 'sent-rt2',
        recipientPlateNumber: 'RT5678',
        body: 'No subject round trip',
        createdAt: DateTime.utc(2025, 7, 1, 12, 0),
      );

      final json = message.toJson();
      final restored = SentMessage.fromJson(json);

      expect(restored, equals(message));
      expect(restored.subject, isNull);
    });

    test('equality works for identical data', () {
      final createdAt = DateTime.utc(2025, 6, 15);
      final s1 = SentMessage(
        id: 's',
        recipientPlateNumber: 'P',
        body: 'B',
        createdAt: createdAt,
      );
      final s2 = SentMessage(
        id: 's',
        recipientPlateNumber: 'P',
        body: 'B',
        createdAt: createdAt,
      );

      expect(s1, equals(s2));
    });

    test('equality fails for different data', () {
      final createdAt = DateTime.utc(2025, 6, 15);
      final s1 = SentMessage(
        id: 's1',
        recipientPlateNumber: 'P',
        body: 'B',
        createdAt: createdAt,
      );
      final s2 = SentMessage(
        id: 's2',
        recipientPlateNumber: 'P',
        body: 'B',
        createdAt: createdAt,
      );

      expect(s1, isNot(equals(s2)));
    });
  });
}
