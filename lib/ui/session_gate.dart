import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../data/community_backend.dart';
import '../data/firestore_community.dart';
import '../data/state_store.dart';
import '../firebase_options.dart';
import 'design.dart';

typedef SessionBuilder = Widget Function(
  StateStore store,
  Map<String, dynamic>? initialData,
  Future<void> Function()? signOut,
  SessionLinks? links,
);

/// What a signed-in session adds: the community backend and a way to
/// reopen after joining or leaving a shared kitchen.
class SessionLinks {
  const SessionLinks(this.community, this.reopen, {this.preview = false});
  final CommunityBackend community;
  final VoidCallback reopen;

  /// On-device community without an account (nothing is shared).
  final bool preview;
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key, required this.builder});
  final SessionBuilder builder;
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<void> ready = configure();
  Future<void> configure() async {
    if (firebaseConfigured && Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: firebaseOptions);
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: ready,
    builder: (context, init) {
      if (init.connectionState != ConnectionState.done) {
        return const LoadingSession();
      }
      if (init.hasError) {
        return SessionError(onRetry: () => setState(() => ready = configure()));
      }
      if (!firebaseConfigured) {
        return LoadedSession(
          store: LocalStateStore(),
          builder: widget.builder,
          links: SessionLinks(
            MemoryCommunity(MemoryServer(), 'this-device'),
            () {},
            preview: true,
          ),
        );
      }
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, auth) {
          if (auth.connectionState == ConnectionState.waiting) {
            return const LoadingSession();
          }
          final user = auth.data;
          if (user == null) return const SignInPage();
          return _KitchenSession(
            key: ValueKey(user.uid),
            uid: user.uid,
            builder: widget.builder,
          );
        },
      );
    },
  );
}

/// Opens the shared kitchen when the account belongs to one, else the
/// personal kitchen; reopens after joining or leaving.
class _KitchenSession extends StatefulWidget {
  const _KitchenSession({super.key, required this.uid, required this.builder});
  final String uid;
  final SessionBuilder builder;
  @override
  State<_KitchenSession> createState() => _KitchenSessionState();
}

class _KitchenSessionState extends State<_KitchenSession> {
  late final community = FirestoreCommunity(
    FirebaseFirestore.instance,
    widget.uid,
  );
  late Future<String?> kitchenId = community.membership();
  var opened = 0;

  void reopen() => setState(() {
    opened++;
    kitchenId = community.membership();
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: kitchenId,
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const LoadingSession();
      }
      if (snap.hasError) {
        return SessionError(
          onRetry: reopen,
          signOut: FirebaseAuth.instance.signOut,
        );
      }
      final id = snap.data;
      return LoadedSession(
        key: ValueKey('${id ?? 'personal'}-$opened'),
        store: id == null
            ? CloudStateStore(FirebaseFirestore.instance, widget.uid)
            : CloudStateStore.shared(FirebaseFirestore.instance, id),
        builder: widget.builder,
        signOut: FirebaseAuth.instance.signOut,
        links: SessionLinks(community, reopen),
      );
    },
  );
}

class LoadedSession extends StatefulWidget {
  const LoadedSession({
    super.key,
    required this.store,
    required this.builder,
    this.signOut,
    this.links,
  });
  final StateStore store;
  final SessionBuilder builder;
  final Future<void> Function()? signOut;
  final SessionLinks? links;
  @override
  State<LoadedSession> createState() => _LoadedSessionState();
}

class _LoadedSessionState extends State<LoadedSession> {
  late final StateStore store = widget.store;
  late Future<Map<String, dynamic>?> data = store.load();
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: data,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const LoadingSession();
      }
      if (snapshot.hasError) {
        return SessionError(
          onRetry: () => setState(() => data = store.load()),
          signOut: widget.signOut,
        );
      }
      return widget.builder(store, snapshot.data, widget.signOut, widget.links);
    },
  );
}

class LoadingSession extends StatelessWidget {
  const LoadingSession({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class SessionError extends StatelessWidget {
  const SessionError({super.key, required this.onRetry, this.signOut});
  final VoidCallback onRetry;
  final Future<void> Function()? signOut;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'مش قادرين نفتح بياناتك دلوقتي. راجع الاتصال وجرب تاني.',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
            if (signOut != null)
              TextButton(onPressed: signOut, child: const Text('تسجيل الخروج')),
          ],
        ),
      ),
    ),
  );
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool creating = false;
  bool busy = false;
  String? message;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit({bool reset = false}) async {
    if (busy) return;
    if (reset
        ? !email.text.trim().contains('@')
        : !form.currentState!.validate()) {
      if (reset) setState(() => message = 'اكتب البريد الإلكتروني الأول.');
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      if (reset) {
        await auth.sendPasswordResetEmail(email: email.text.trim());
        if (mounted) {
          setState(
            () => message = 'لو البريد مسجّل، هيوصلك رابط استعادة كلمة المرور.',
          );
        }
      } else if (creating) {
        await auth.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      } else {
        await auth.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => message = switch (error.code) {
            'network-request-failed' => 'راجع اتصال الإنترنت وجرب تاني.',
            'too-many-requests' => 'محاولات كتير. استنى شوية وجرب تاني.',
            'weak-password' => 'اختار كلمة مرور أقوى.',
            'email-already-in-use' => 'البريد مسجّل بالفعل. جرّب تسجيل الدخول.',
            'invalid-email' => 'راجع كتابة البريد الإلكتروني.',
            'operation-not-allowed' =>
              'تسجيل الحساب غير متاح حاليًا. جرب لاحقًا.',
            _ => 'تعذر الدخول. راجع البريد وكلمة المرور أو استعد حسابك.',
          },
        );
      }
    } catch (_) {
      if (mounted) setState(() => message = 'تعذر إكمال الطلب. جرب مرة تانية.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AutofillGroup(
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.restaurant_rounded,
                      size: 64,
                      color: Sofra.green,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      creating ? 'اعملي حساب لسفرتك' : 'أهلًا بيكي في سُفرة',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'مكونات بيتك واختياراتك محفوظة في حسابك.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: email,
                      enabled: !busy,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                      ),
                      validator: (v) => (v ?? '').trim().contains('@')
                          ? null
                          : 'اكتب بريدًا صحيحًا',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: password,
                      enabled: !busy,
                      obscureText: true,
                      textDirection: TextDirection.ltr,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: [
                        creating
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                      ),
                      validator: (v) => (v ?? '').length >= 6
                          ? null
                          : 'كلمة المرور 6 حروف على الأقل',
                      onFieldSubmitted: (_) => submit(),
                    ),
                    if (message != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          message!,
                          semanticsLabel: message,
                          style: const TextStyle(color: Sofra.ink),
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: busy ? null : () => submit(),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          busy
                              ? 'لحظة…'
                              : creating
                              ? 'إنشاء حساب'
                              : 'تسجيل الدخول',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              creating = !creating;
                              message = null;
                            }),
                      child: Text(
                        creating ? 'عندي حساب بالفعل' : 'أول مرة؟ اعملي حساب',
                      ),
                    ),
                    if (!creating)
                      TextButton(
                        onPressed: busy ? null : () => submit(reset: true),
                        child: const Text('نسيت كلمة المرور'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
