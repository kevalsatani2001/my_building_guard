import 'package:flutter_test/flutter_test.dart';
import 'package:building_guard/blocs/auth/auth_bloc.dart';

void main() {
  group('Auth States & Events Unit Tests', () {
    test('AuthInitial equality', () {
      expect(const AuthInitial(), equals(const AuthInitial()));
    });

    test('AuthLoading equality and props', () {
      const state1 = AuthLoading(message: 'લૉગિન થઈ રહ્યું છે...');
      const state2 = AuthLoading(message: 'લૉગિન થઈ રહ્યું છે...');
      expect(state1, equals(state2));
      expect(state1.message, equals('લૉગિન થઈ રહ્યું છે...'));
    });

    test('Unauthenticated equality', () {
      expect(const Unauthenticated(), equals(const Unauthenticated()));
    });

    test('AuthLoginFailure equality and props', () {
      const error1 = AuthLoginFailure('ખોટો પાસવર્ડ!');
      const error2 = AuthLoginFailure('ખોટો પાસવર્ડ!');
      expect(error1, equals(error2));
      expect(error1.errorMessage, equals('ખોટો પાસવર્ડ!'));
    });

    test('AuthLoginRequested event equality and props', () {
      const event1 = AuthLoginRequested(input: 'admin@society.com', password: 'secretPassword');
      const event2 = AuthLoginRequested(input: 'admin@society.com', password: 'secretPassword');
      expect(event1, equals(event2));
      expect(event1.input, equals('admin@society.com'));
      expect(event1.password, equals('secretPassword'));
    });

    test('AuthLogoutRequested event equality', () {
      expect(const AuthLogoutRequested(), equals(const AuthLogoutRequested()));
    });

    test('AuthDestination enum integrity', () {
      expect(AuthDestination.values.contains(AuthDestination.superAdmin), isTrue);
      expect(AuthDestination.values.contains(AuthDestination.admin), isTrue);
      expect(AuthDestination.values.contains(AuthDestination.watchman), isTrue);
      expect(AuthDestination.values.contains(AuthDestination.member), isTrue);
      expect(AuthDestination.values.contains(AuthDestination.adminSuspended), isTrue);
      expect(AuthDestination.values.contains(AuthDestination.societySuspended), isTrue);
    });
  });
}
