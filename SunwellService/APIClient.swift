import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(status: Int, message: String)
    case emptyData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."
        case .invalidResponse:
            return "Invalid server response."
        case .server(let status, let message):
            return "HTTP \(status): \(message)"
        case .emptyData:
            return "The server returned no data."
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let baseURL = URL(string: "https://linebot.sunwell.work/")!
    private let apiKey = "sunwell-mobile-2026-test-key"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    var credentials: AuthCredentials?

    private init() {}

    func login(username: String, password: String) async throws -> LoginResponse {
        let body = try encoder.encode(LoginRequest(username: username, password: password))
        return try await send(
            path: "api/login",
            method: "POST",
            bodyData: body
        )
    }

    func getPart(keyword: String, includeImage: Bool, mode: String) async throws -> PartDto {
        return try await send(
            path: "api/part",
            queryItems: [
                URLQueryItem(name: "keyword", value: keyword),
                URLQueryItem(name: "includeImage", value: includeImage ? "true" : "false"),
                URLQueryItem(name: "mode", value: mode)
            ]
        )
    }


    func getBomUp(partNo: String) async throws -> BomDto {
        return try await send(path: "api/bom/up/\(partNo.urlPathEncoded)")
    }

    func getBomDown(partNo: String) async throws -> BomDto {
        return try await send(path: "api/bom/down/\(partNo.urlPathEncoded)")
    }

    func getImage(partNo: String) async throws -> ImageDto {
        return try await send(path: "api/image/\(partNo.urlPathEncoded)")
    }

    func getPnc(partNo: String) async throws -> PncDto {
        return try await send(path: "api/pnc/\(partNo.urlPathEncoded)")
    }

    func getCreoBom(partNo: String) async throws -> CreoBomDto {
        return try await send(path: "api/creo-bom/\(partNo.urlPathEncoded)")
    }

    func getBtm(mode: Int, partNo: String) async throws -> BtmDto {
        return try await send(path: "api/btm/\(mode)/\(partNo.urlPathEncoded)")
    }

    func suggestParts(keyword: String, mode: String) async throws -> [String] {
        return try await send(
            path: "api/part/suggest",
            queryItems: [
                URLQueryItem(name: "keyword", value: keyword),
                URLQueryItem(name: "mode", value: mode)
            ]
        )
    }

    func getOrder(orderNo: String) async throws -> OrderDto {
        return try await send(path: "api/order/\(orderNo.urlPathEncoded)")
    }

    func searchOrder(mode: String, keyword: String) async throws -> OrderDto {
        return try await send(
            path: "api/order/search",
            queryItems: [
                URLQueryItem(name: "mode", value: mode),
                URLQueryItem(name: "keyword", value: keyword)
            ]
        )
    }

    func searchOracleOrder(keyword: String) async throws -> OracleSearchResponse {
        return try await send(
            path: "api/order/oracle",
            queryItems: [URLQueryItem(name: "keyword", value: keyword)]
        )
    }

    func suggestOrders(keyword: String) async throws -> [String] {
        return try await send(
            path: "api/order/suggest",
            queryItems: [URLQueryItem(name: "keyword", value: keyword)]
        )
    }



    func getErpStockChange(partNo: String) async throws -> ErpStockChangeResponse {
        return try await send(
            path: "api/erp/stock-change",
            queryItems: [URLQueryItem(name: "partNo", value: partNo)]
        )
    }

    func dataSearch(command: String, keyword: String) async throws -> DataSearchDto {
        return try await send(
            path: "api/datasearch/\(command.urlPathEncoded)",
            queryItems: [URLQueryItem(name: "keyword", value: keyword)]
        )
    }

    func getBnrLicense() async throws -> ToolDto {
        return try await send(path: "api/tools/bnr")
    }

    func searchTel(keyword: String) async throws -> ToolDto {
        return try await send(
            path: "api/tools/tel",
            queryItems: [URLQueryItem(name: "keyword", value: keyword)]
        )
    }

    func getTelLai() async throws -> ToolDto {
        return try await send(path: "api/tools/tel-lai")
    }

    func searchMail(keyword: String) async throws -> ToolDto {
        return try await send(
            path: "api/tools/mal",
            queryItems: [URLQueryItem(name: "keyword", value: keyword)]
        )
    }

    func searchTrip(keyword: String) async throws -> ToolDto {
        return try await send(
            path: "api/tools/trp",
            queryItems: [URLQueryItem(name: "keyword", value: keyword)]
        )
    }

    func getServiceChart(keyword: String) async throws -> ToolFileDto {
        return try await send(
            path: "api/tools/sc",
            queryItems: [URLQueryItem(name: "keyword", value: keyword)]
        )
    }
    func getDrawing(partNo: String) async throws -> DrawingDto {
        return try await send(path: "api/drw/\(partNo.urlPathEncoded)")
    }

    func getPdf(partNo: String) async throws -> DrawingDto {
        return try await send(path: "api/pdf/\(partNo.urlPathEncoded)")
    }

    func suggestDrawings(keyword: String, mode: String) async throws -> [String] {
        return try await send(
            path: "api/drawing/suggest",
            queryItems: [
                URLQueryItem(name: "keyword", value: keyword),
                URLQueryItem(name: "mode", value: mode)
            ]
        )
    }

    func searchServiceRecords(keyword: String) async throws -> [ServiceRecordDto] {
        return try await send(
            path: "api/service/search",
            queryItems: [URLQueryItem(name: "keyword", value: keyword)]
        )
    }

    private func send<Response: Decodable>(
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        bodyData: Data? = nil
    ) async throws -> Response {
        var request = try makeRequest(path: path, method: method, queryItems: queryItems)

        if let bodyData = bodyData {
            request.httpBody = bodyData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Request failed."
            throw APIError.server(status: httpResponse.statusCode, message: message)
        }

        guard !data.isEmpty else {
            throw APIError.emptyData
        }

        return try decoder.decode(Response.self, from: data)
    }

    private func makeRequest(
        path: String,
        method: String,
        queryItems: [URLQueryItem]
    ) throws -> URLRequest {
        guard let endpoint = URL(string: path, relativeTo: baseURL),
              var components = URLComponents(url: endpoint.absoluteURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 240
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")

        if let credentials = credentials {
            request.setValue("Bearer \(credentials.token)", forHTTPHeaderField: "Authorization")
            request.setValue(credentials.username, forHTTPHeaderField: "X-USERNAME")
        }

        return request
    }
}

private extension String {
    var urlPathEncoded: String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}






