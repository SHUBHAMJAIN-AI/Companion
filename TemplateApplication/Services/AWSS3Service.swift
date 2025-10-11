//
// AWS S3 Integration Service for Health Companion
//

import Foundation
import CryptoKit

@MainActor
class AWSS3Service: ObservableObject {
    private let bucketName = "health-companion-documents"
    private let region = "us-east-1"
    private let accessKey = APIKeys.awsAccessKey
    private let secretKey = APIKeys.awsSecretKey
    
    func uploadDocument(_ document: HealthDocument, data: Data) async throws -> String {
        let key = "documents/\(document.id.uuidString)/\(document.name)".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let urlString = "https://\(bucketName).s3.\(region).amazonaws.com/\(key)"
        
        guard let url = URL(string: urlString) else { throw S3Error.uploadFailed }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        
        let contentType = getContentType(for: document.type)
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
            method: "PUT", path: "/\(key)", date: amzDate, dateStamp: dateStamp,
            contentType: contentType, contentLength: data.count, payloadHash: payloadHash
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
        
        let canonicalHash = sha256Hash(canonicalRequest.data(using: .utf8)!)
        let stringToSign = "AWS4-HMAC-SHA256\n\(params.date)\n\(credentialScope)\n\(canonicalHash)"
        
        let signingKey = getSignatureKey(key: secretKey, dateStamp: params.dateStamp, regionName: region, serviceName: "s3")
        let signatureData = hmacSHA256(data: stringToSign.data(using: .utf8)!, key: signingKey)
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
        let kDate = hmacSHA256(data: dateStamp.data(using: .utf8)!, key: "AWS4\(key)".data(using: .utf8)!)
        let kRegion = hmacSHA256(data: regionName.data(using: .utf8)!, key: kDate)
        let kService = hmacSHA256(data: serviceName.data(using: .utf8)!, key: kRegion)
        let kSigning = hmacSHA256(data: "aws4_request".data(using: .utf8)!, key: kService)
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
        case .other:
            return "application/octet-stream"
        }
    }
}

enum S3Error: Error {
    case uploadFailed
    case downloadFailed
}