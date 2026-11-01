import 'dart:async';
import 'package:checklist_app/features/account/account_gateway.dart';

class FakeAccountGateway implements AccountGateway {
  AccountProviders available;
  MemberAccount? member;
  Object? failure;
  Completer<void>? pendingEmail;
  final events = StreamController<MemberAccount?>.broadcast(sync: true);
  final emails = <String>[];
  final createAccountRequests = <bool>[];
  String? googleHint, ssoDomain;
  bool campusGoogle = false;
  FakeAccountGateway({
    this.available = const AccountProviders(email: true),
    this.member,
  });
  factory FakeAccountGateway.signedIn() => FakeAccountGateway(
    member: const MemberAccount(
      id: 'review-member',
      email: 'review@example.com',
      name: 'Tobias Andra Valentino',
      emailVerified: true,
    ),
  );
  void emit(MemberAccount? value) {
    member = value;
    events.add(value);
  }

  void _check() {
    if (failure != null) throw failure!;
  }

  @override
  MemberAccount? get current => member;
  @override
  Stream<MemberAccount?> get changes => events.stream;
  @override
  Future<AccountProviders> providers() async {
    _check();
    return available;
  }

  @override
  Future<void> requestEmailLogin(
    String email, {
    bool createAccount = false,
  }) async {
    _check();
    emails.add(email);
    createAccountRequests.add(createAccount);
    await pendingEmail?.future;
  }

  @override
  Future<void> verifyEmailCode(String email, String code) async {
    _check();
    if (code != '123456') throw const AccountFailure('Kode tidak cocok.');
    emit(
      MemberAccount(
        id: 'test-member',
        email: email,
        name: '',
        emailVerified: true,
      ),
    );
  }

  @override
  Future<void> signInGoogle({String? emailHint, bool campus = false}) async {
    _check();
    googleHint = emailHint;
    campusGoogle = campus;
  }

  @override
  Future<void> signInUb(String domain) async {
    _check();
    ssoDomain = domain;
  }

  @override
  Future<void> updateName(String name) async {
    _check();
    emit(
      MemberAccount(
        id: member!.id,
        email: member!.email,
        name: name,
        emailVerified: member!.emailVerified,
      ),
    );
  }

  @override
  Future<void> signOut() async {
    _check();
    emit(null);
  }

  Future<void> dispose() => events.close();
}
