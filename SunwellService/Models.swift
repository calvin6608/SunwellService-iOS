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

struct OracleSearchResponse: Decodable {
    let success: Bool?
    let keyword: String?
    let maxRowsPerTable: Int?
    let count: Int?
    let searchFields: [OracleSearchField]?
    let items: [OracleItem]?
    let cards: [OracleCard]?
    let error: String?
}

struct OracleSearchField: Decodable {
    let table: String?
    let field: String?
}

struct OracleItem: Decodable {
    let sourceTable: String?
    let matchedField: String?
    let codProj: String?
    let codProja: String?
    let codProjm: String?
    let namCusts: String?
    let namProjm: String?
    let codProjs: String?
    let dateShip: String?
}

struct OracleCard: Decodable {
    let title: String?
    let subtitle: String?
    let badges: [String]?
    let rows: [OracleCardRow]?
}

struct OracleCardRow: Decodable {
    let label: String?
    let value: String?
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
