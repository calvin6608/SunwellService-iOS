import Foundation

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

struct LoginResponse: Decodable {
    let success: Bool
    let message: String?
    let token: String?
    let username: String?
}

struct PartDto: Decodable {
    let partNo: String
    let name: String?
    let imageUrl: String?
    let isPartNumber: Bool?
    let includeImage: Bool?
}

struct OrderDto: Decodable {
    let orderNo: String
    let result: String?
}

struct DrawingDto: Decodable {
    let partNo: String
    let success: Bool
    let message: String?
    let url: String?
    let resultType: String?
    let approvalRequired: Bool?
    let approvalRequestId: Int64?
}

struct ServiceRecordDto: Decodable, Identifiable {
    let id: Int
    let customer: String?
    let machineNo: String?
    let issue: String?
    let solution: String?
    let date: String?
}

struct AuthCredentials {
    let token: String
    let username: String
}

