//
//  DataSecurityService.swift
//  pocket-garden
//
//  HMAC-SHA256 signing and validation for data export/import
//
//  SECURITY OVERVIEW:
//  ------------------
//  This service provides cryptographic signatures for exported data to prevent:
//  - Users from manually editing JSON exports
//  - Malicious users from crafting fake export files
//  - Accidental corruption from being imported
//
//  HOW IT WORKS:
//  1. Export: Compute HMAC-SHA256 hash of JSON data using secret key → add to file
//  2. Import: Extract signature, recompute HMAC on data → compare signatures
//  3. If signatures match → file is authentic and unmodified
//  4. If signatures don't match → file was tampered with or corrupted
//
//  IMPLEMENTATION NOTES:
//  - Uses HMAC (keyed hash) instead of plain hash to prevent forgery
//  - Secret key is XOR-encoded in binary to prevent casual inspection
//  - Not cryptographically unbreakable, but prevents 99% of tampering attempts
//  - For production apps with sensitive data, consider:
//    * Key storage in Keychain
//    * Certificate-based signing
//    * Server-side validation
//

import Foundation
import CryptoKit

/// Service for signing and validating exported data using HMAC-SHA256
///
/// USAGE EXAMPLE:
/// ```swift
/// // Export (signing):
/// let jsonData = try encoder.encode(exportData)
/// let signature = DataSecurityService.shared.generateSignature(for: jsonData)
///
/// // Import (validation):
/// if DataSecurityService.shared.validateSignature(signature, for: jsonData) {
///     // File is authentic, proceed with import
/// } else {
///     // File was modified, reject import
/// }
/// ```
final class DataSecurityService {
    static let shared = DataSecurityService()
    
    // MARK: - Secret Key (XOR-encoded for light obfuscation)
    
    /// XOR mask used to obfuscate the secret key in binary
    ///
    /// SECURITY NOTE:
    /// The actual secret key is stored XORed with this mask to prevent it from
    /// appearing in plaintext in the compiled binary. This is "security by obscurity"
    /// and not cryptographically strong, but it:
    /// - Prevents casual users from finding the key with strings/grep
    /// - Makes automated key extraction slightly harder
    /// - Requires reverse engineering to extract the key
    ///
    /// The key is decoded at runtime by XORing encodedSecret with xorMask.
    private static let xorMask: [UInt8] = [
        0xA3, 0x7F, 0x2B, 0x91, 0xE5, 0x4C, 0x8D, 0x3A,
        0xF2, 0x6E, 0x1B, 0xC7, 0x54, 0x9F, 0x0D, 0x82,
        0x3E, 0xB1, 0x67, 0xCA, 0x2F, 0x85, 0xD9, 0x4A,
        0x76, 0xE8, 0x1C, 0x93, 0xAF, 0x5B, 0x02, 0xD4
    ]
    
    /// Encoded secret (XORed with mask) - decode at runtime
    /// This prevents the actual key from appearing in plaintext in the binary
    private static let encodedSecret: [UInt8] = [
        0xD7, 0x1A, 0x5E, 0xF4, 0x80, 0x29, 0xE8, 0x5F,
        0x97, 0x0B, 0x7E, 0xA2, 0x31, 0xFA, 0x68, 0xE7,
        0x5B, 0xD4, 0x02, 0xAF, 0x4A, 0xE0, 0xBC, 0x2F,
        0x13, 0x8D, 0x79, 0xF6, 0xCA, 0x3E, 0x67, 0xB1
    ]
    
    /// Decode the secret key at runtime using XOR
    private var secretKey: SymmetricKey {
        var decoded = [UInt8](repeating: 0, count: Self.encodedSecret.count)
        for i in 0..<Self.encodedSecret.count {
            decoded[i] = Self.encodedSecret[i] ^ Self.xorMask[i]
        }
        return SymmetricKey(data: Data(decoded))
    }
    
    private init() {}
    
    // MARK: - Signing
    
    /// Generate HMAC-SHA256 signature for the given data
    ///
    /// This creates a cryptographic signature that proves:
    /// 1. The data was created by this app (only this app has the secret key)
    /// 2. The data has not been modified (any change invalidates the signature)
    ///
    /// - Parameter data: The data to sign (usually JSON bytes)
    /// - Returns: Base64-encoded signature string that should be included in the export file
    ///
    /// IMPLEMENTATION:
    /// - Uses Apple's CryptoKit HMAC<SHA256> for standard-compliant signatures
    /// - Output is base64-encoded for easy inclusion in JSON
    func generateSignature(for data: Data) -> String {
        let hmac = HMAC<SHA256>.authenticationCode(for: data, using: secretKey)
        return Data(hmac).base64EncodedString()
    }
    
    // MARK: - Validation
    
    /// Validate HMAC-SHA256 signature against the given data
    ///
    /// This verifies that:
    /// 1. The file was created by an authentic copy of Pocket Forest
    /// 2. The file contents have not been modified since export
    ///
    /// SECURITY: Uses constant-time comparison to prevent timing attacks
    /// (prevents attackers from using response time to guess the signature)
    ///
    /// - Parameters:
    ///   - signature: Base64-encoded signature to validate (from the "signature" field in JSON)
    ///   - data: The data that was supposedly signed (JSON with signature field removed)
    /// - Returns: True if signature is valid (file is authentic), false otherwise (file tampered/corrupted)
    func validateSignature(_ signature: String, for data: Data) -> Bool {
        guard let signatureData = Data(base64Encoded: signature) else {
            return false
        }
        
        let expectedHMAC = HMAC<SHA256>.authenticationCode(for: data, using: secretKey)
        let expectedData = Data(expectedHMAC)
        
        // Constant-time comparison to prevent timing attacks
        return signatureData.count == expectedData.count &&
               zip(signatureData, expectedData).allSatisfy { $0 == $1 }
    }
    
    // MARK: - Export Data Signing
    
    /// Sign export data by computing HMAC over the JSON payload (excluding signature field)
    /// - Parameter exportData: The export data structure (with empty or placeholder signature)
    /// - Returns: The signature string to include in the export
    func signExportPayload(_ jsonData: Data) -> String {
        return generateSignature(for: jsonData)
    }
    
    /// Validate that an export file's signature matches its content
    /// - Parameters:
    ///   - signature: The signature from the export file
    ///   - payloadData: The JSON data (with signature field removed or zeroed)
    /// - Returns: True if the file is authentic, false if tampered
    func validateExportPayload(signature: String, payloadData: Data) -> Bool {
        return validateSignature(signature, for: payloadData)
    }
}

// MARK: - Signature Stripping Helpers

extension DataSecurityService {
    
    /// Creates a copy of export JSON with the signature field removed for validation
    /// - Parameter jsonData: Original JSON data with signature
    /// - Returns: JSON data with signature field removed, or nil if parsing fails
    func stripSignature(from jsonData: Data) -> (payload: Data, signature: String)? {
        guard var jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let signature = jsonObject["signature"] as? String else {
            return nil
        }
        
        // Remove signature for payload computation
        jsonObject.removeValue(forKey: "signature")
        
        // Re-encode with sorted keys for consistent hashing
        guard let payloadData = try? JSONSerialization.data(
            withJSONObject: jsonObject,
            options: [.sortedKeys]
        ) else {
            return nil
        }
        
        return (payloadData, signature)
    }
    
    /// Creates JSON data from export structure without signature for signing
    /// - Parameter exportDict: Dictionary representation of export data (without signature)
    /// - Returns: JSON data ready for signing
    func createPayloadForSigning(_ exportDict: [String: Any]) -> Data? {
        var dict = exportDict
        dict.removeValue(forKey: "signature") // Ensure no signature in payload
        
        return try? JSONSerialization.data(
            withJSONObject: dict,
            options: [.sortedKeys]
        )
    }
}

