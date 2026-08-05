import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Independent encryption layer for sensitive medical data at rest.
///
/// Uses AES-256-CBC with PKCS7 padding (via PointyCastle through the `encrypt`
/// package). The encryption key is a random 256-bit seed generated on first
/// launch and stored in platform secure storage (iOS Keychain / Android
/// EncryptedSharedPreferences).
///
/// This layer is completely **database-agnostic** — it encrypts data BEFORE it
/// reaches any storage backend. Swapping Isar for another local database
/// does not require changing any encryption logic.
///
/// ## Design rationale
///
/// - **Independent layer**: Encryption happens at the application level, not
///   at the database level. This means the database engine can be replaced
///   without touching encryption code.
/// - **AES-256-CBC**: FIPS-compliant symmetric encryption. CBC mode is chosen
///   over GCM because the `encrypt` package has well-tested CBC support and
///   we are encrypting at-rest data (not streaming), making authentication
///   tags less critical.
/// - **Key in SecureStorage**: The encryption key never touches the filesystem
///   or source code. It lives in the OS-provided secure enclave.
/// - **Per-value IV**: Each encrypted value gets a random 16-byte IV to ensure
///   identical plaintexts produce different ciphertexts.
class EncryptionService {
  final FlutterSecureStorage _storage;
  static const _keySeedKey = 'encryption_key_seed';

  enc.Key? _key;

  EncryptionService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Ensure the encryption key exists in secure storage.
  ///
  /// On first launch a random 256-bit seed is generated and stored.
  /// The derived AES key is cached in memory for the session.
  Future<void> initialize() async {
    final stored = await _storage.read(key: _keySeedKey);
    if (stored == null) {
      final random = Random.secure();
      final seed = List<int>.generate(32, (_) => random.nextInt(256));
      await _storage.write(
        key: _keySeedKey,
        value: base64Encode(seed),
      );
      _key = enc.Key(Uint8List.fromList(seed));
    } else {
      _key = enc.Key(base64Decode(stored));
    }
  }

  enc.Key get _encryptionKey {
    if (_key == null) {
      throw StateError(
        'EncryptionService not initialized. Call initialize() first.',
      );
    }
    return _key!;
  }

  Future<bool> get isInitialized async {
    if (_key != null) return true;
    final stored = await _storage.read(key: _keySeedKey);
    return stored != null;
  }

  // --------------------------------------------------------------------------
  // String-level encryption
  // --------------------------------------------------------------------------

  /// Encrypt [plaintext] and return a base64-encoded string.
  ///
  /// Format: `base64(iv) : base64(ciphertext)`
  String encrypt(String plaintext) {
    if (plaintext.isEmpty) return plaintext;
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter =
        enc.Encrypter(enc.AES(_encryptionKey, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  /// Decrypt a value produced by [encrypt].
  ///
  /// Returns the original string on success. If the value does not look like
  /// an encrypted payload (no colon separator) it is returned as-is, so that
  /// unencrypted legacy data can still be read.
  String decrypt(String encrypted) {
    if (encrypted.isEmpty || !encrypted.contains(':')) return encrypted;
    try {
      final parts = encrypted.split(':');
      if (parts.length != 2) return encrypted;
      final iv = enc.IV(base64Decode(parts[0]));
      final ciphertext = enc.Encrypted.fromBase64(parts[1]);
      final encrypter =
          enc.Encrypter(enc.AES(_encryptionKey, mode: enc.AESMode.cbc));
      return encrypter.decrypt(ciphertext, iv: iv);
    } catch (_) {
      return encrypted;
    }
  }

  // --------------------------------------------------------------------------
  // Map-level field encryption
  // --------------------------------------------------------------------------

  /// Encrypt only the fields listed in [sensitiveFields], returning a new map.
  ///
  /// Non-sensitive fields are passed through unchanged.
  Map<String, dynamic> encryptFields(
    Map<String, dynamic> data,
    Set<String> sensitiveFields,
  ) {
    final result = Map<String, dynamic>.from(data);
    for (final field in sensitiveFields) {
      final value = result[field];
      if (value is String && value.isNotEmpty && !value.contains(':')) {
        result[field] = encrypt(value);
      }
    }
    return result;
  }

  /// Decrypt fields previously encrypted with [encryptFields].
  Map<String, dynamic> decryptFields(
    Map<String, dynamic> data,
    Set<String> sensitiveFields,
  ) {
    final result = Map<String, dynamic>.from(data);
    for (final field in sensitiveFields) {
      final value = result[field];
      if (value is String && value.isNotEmpty) {
        result[field] = decrypt(value);
      }
    }
    return result;
  }

  // --------------------------------------------------------------------------
  // Lifecycle
  // --------------------------------------------------------------------------

  /// Wipe the encryption key from both memory and secure storage.
  Future<void> reset() async {
    _key = null;
    await _storage.delete(key: _keySeedKey);
  }
}
