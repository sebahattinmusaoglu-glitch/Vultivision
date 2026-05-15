import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  // youtube.readonly scope eklendi — abonelikler ve kanal bilgisi için
  final _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/youtube.readonly',
    ],
  );

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      return null;
    }
  }

  /// Mevcut oturumdan YouTube access token döner.
  /// Token süresi dolmuşsa google_sign_in otomatik yeniler.
  Future<String?> getYouTubeAccessToken() async {
    try {
      // Sessizce mevcut oturumu yenile (token refresh)
      final account =
          _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      if (account == null) return null;

      final auth = await account.authentication;
      return auth.accessToken;
    } catch (e) {
      return null;
    }
  }

  /// Kullanıcı daha önce scope olmadan giriş yaptıysa
  /// ek izin ister — yeniden tam sign-in gerekmez.
  // SONRA (doğru) — _googleSignIn üzerinde çağrılıyor
  Future<bool> requestYouTubeScope() async {
    try {
      final granted = await _googleSignIn.requestScopes([    // 
        'https://www.googleapis.com/auth/youtube.readonly',
      ]);
      return granted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasYouTubeScope() async {
    // v6'da grantedScopes yok — token alınabiliyorsa scope verilmiş demektir
    try {
      final token = await getYouTubeAccessToken();           //
      return token != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}