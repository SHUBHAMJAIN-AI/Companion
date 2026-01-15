//
// AWS S3 Integration Service for Health Companion
//

import CryptoKit
import Foundation

@MainActor
class AWSS3Service: ObservableObject {
    private let bucketName = "us-west-raw-files-sid"
    private let region = "us-west-2"
    private let accessKey = APIKeys.awsAccessKey
    private let secretKey = APIKeys.awsSecretKey
    
    func uploadDocument(_ document: HealthDocument, data: Data) async throws -> String {
        let key = "data-second-raw/\(document.name)".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        return try await uploadToS3(key: key, data: data, contentType: getContentType(for: document.type))
    }
    
    func uploadDocument(data: Data, filename: String) async {
        let key = "data-second-raw/\(filename)".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        _ = try? await uploadToS3(key: key, data: data, contentType: "text/plain")
    }
    
    private func uploadToS3(key: String, data: Data, contentType: String) async throws -> String {
        let urlString = "https://\(bucketName).s3.\(region).amazonaws.com/\(key)"
        
        guard let url = URL(string: urlString) else { throw S3Error.uploadFailed }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let amzDate = dateFormatter.string(from: date)
        
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateStamp = dateFormatter.string(from: date)
        
        let payloadHash = sha256Hash(data)
        
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(amzDate, forHTTPHeaderField: "x-amz-date")
        request.setValue(payloadHash, forHTTPHeaderField: "x-amz-content-sha256")
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        
        let sigParams = SignatureParams(
            method: "PUT",
            path: "/\(key)",
            date: amzDate,
            dateStamp: dateStamp,
            contentType: contentType,
            contentLength: data.count,
            payloadHash: payloadHash
        )
        let signature = createSignature(sigParams)
        request.setValue(signature, forHTTPHeaderField: "Authorization")
        
        print("S3 Upload URL: \(urlString)")
        print("S3 Authorization: \(signature)")
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw S3Error.uploadFailed
        }
        
        print("S3 Status Code: \(httpResponse.statusCode)")
        if httpResponse.statusCode != 200 {
            let errorBody = String(data: responseData, encoding: .utf8) ?? "No error body"
            print("S3 Error Response: \(errorBody)")
            throw S3Error.uploadFailed
        }
        
        return key
    }
    
    private func createSignature(_ params: SignatureParams) -> String {
        let credentialScope = "\(params.dateStamp)/\(region)/s3/aws4_request"
        let canonicalHeaders = "content-length:\(params.contentLength)\ncontent-type:\(params.contentType)\n" +
            "host:\(bucketName).s3.\(region).amazonaws.com\nx-amz-content-sha256:\(params.payloadHash)\nx-amz-date:\(params.date)\n"
        let signedHeaders = "content-length;content-type;host;x-amz-content-sha256;x-amz-date"
        let canonicalRequest = "\(params.method)\n\(params.path)\n\n\(canonicalHeaders)\n\(signedHeaders)\n\(params.payloadHash)"

        guard let canonicalRequestData = canonicalRequest.data(using: .utf8),
              let stringToSignData = "AWS4-HMAC-SHA256\n\(params.date)\n\(credentialScope)\n\(sha256Hash(canonicalRequestData))".data(using: .utf8) else {
            return ""
        }

        let signingKey = getSignatureKey(key: secretKey, dateStamp: params.dateStamp, regionName: region, serviceName: "s3")
        let signatureData = hmacSHA256(data: stringToSignData, key: signingKey)
        let signature = signatureData.map { String(format: "%02x", $0) }.joined()

        return "AWS4-HMAC-SHA256 Credential=\(accessKey)/\(credentialScope), " +
            "SignedHeaders=\(signedHeaders), Signature=\(signature)"
    }
    
    private struct SignatureParams {
        let method: String
        let path: String
        let date: String
        let dateStamp: String
        let contentType: String
        let contentLength: Int
        let payloadHash: String
    }
    
    private func getSignatureKey(key: String, dateStamp: String, regionName: String, serviceName: String) -> Data {
        guard let dateStampData = dateStamp.data(using: .utf8),
              let awsKeyData = "AWS4\(key)".data(using: .utf8),
              let regionNameData = regionName.data(using: .utf8),
              let serviceNameData = serviceName.data(using: .utf8),
              let aws4RequestData = "aws4_request".data(using: .utf8) else {
            return Data()
        }
        let kDate = hmacSHA256(data: dateStampData, key: awsKeyData)
        let kRegion = hmacSHA256(data: regionNameData, key: kDate)
        let kService = hmacSHA256(data: serviceNameData, key: kRegion)
        let kSigning = hmacSHA256(data: aws4RequestData, key: kService)
        return kSigning
    }
    
    private func hmacSHA256(data: Data, key: Data) -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)
        return Data(signature)
    }
    
    private func sha256Hash(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    private func getContentType(for documentType: DocumentType) -> String {
        switch documentType {
        case .pdf:
            return "application/pdf"
        case .image:
            return "image/jpeg"
        case .text:
            return "text/plain"
        case .document:
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case .other:
            return "application/octet-stream"
        }
    }
    
    func downloadDocument(filename: String) async throws -> String {
        let key = "data-second-raw/\(filename)".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let urlString = "https://\(bucketName).s3.\(region).amazonaws.com/\(key)"
        
        guard let url = URL(string: urlString) else { throw S3Error.downloadFailed }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let amzDate = dateFormatter.string(from: date)
        
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateStamp = dateFormatter.string(from: date)
        
        request.setValue(amzDate, forHTTPHeaderField: "x-amz-date")
        
        let sigParams = SignatureParams(
            method: "GET",
            path: "/\(key)",
            date: amzDate,
            dateStamp: dateStamp,
            contentType: "",
            contentLength: 0,
            payloadHash: sha256Hash(Data())
        )
        let signature = createSignature(sigParams)
        request.setValue(signature, forHTTPHeaderField: "Authorization")
        
        print("S3 Download URL: \(urlString)")
        print("S3 Download Authorization: \(signature)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("S3 Download: Invalid response")
            throw S3Error.downloadFailed
        }
        
        print("S3 Download Status Code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
            print("S3 Download Error Response: \(errorBody)")
            throw S3Error.downloadFailed
        }
        
        return String(data: data, encoding: .utf8) ?? "Unable to decode content"
    }
}

enum S3Error: Error {
    case uploadFailed
    case downloadFailed
}
