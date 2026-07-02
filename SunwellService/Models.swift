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


struct BomDto: Decodable {
    let partNo: String
    let direction: String
    let paths: [String]
}

struct ImageDto: Decodable {
    let partNo: String
    let success: Bool
    let message: String?
    let imageUrl: String?
}

struct PncDto: Decodable {
    let partNo: String
    let success: Bool
    let result: String?
    let imageUrl: String?
    let message: String?
}

struct CreoBomDto: Decodable {
    let partNo: String
    let success: Bool
    let message: String?
    let pdfUrl: String?
}

struct BtmDto: Decodable {
    let partNo: String
    let mode: String
    let success: Bool
    let result: String?
}



struct ErpStockChangeResponse: Decodable {
    let success: Bool
    let message: String
    let partNo: String
    let count: Int
    let items: [ErpStockChangeItemDto]
}

struct ErpStockChangeItemDto: Decodable {
    let documentNo: String
    let salesNo: String
    let partNo: String
    let changeTime: String
    let documentType: String
    let direction: String
    let quantity: Double
    let planMaster: ErpPlanMasterDto?
}

struct ErpPlanMasterDto: Decodable {
    let codItem: String?
    let dateClose: String?
    let dateOrder: String?
    let datePlanEnd: String?
    let namItem: String?
    let numCase: String?
    let numPs: String?
    let qtyPcs: Double?
    let spec: String?
    let statusCode: String?

    private enum CodingKeys: String, CodingKey {
        case codItem = "cod_item"
        case dateClose = "date_close"
        case dateOrder = "date_order"
        case datePlanEnd = "date_plan_end"
        case namItem = "nam_item"
        case numCase = "num_case"
        case numPs = "num_ps"
        case qtyPcs = "qty_pcs"
        case spec
        case statusCode = "status_code"
    }
}

struct DataSearchDto: Decodable {
    let command: String
    let keyword: String
    let success: Bool
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



