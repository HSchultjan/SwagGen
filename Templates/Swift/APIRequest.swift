//
// APIRequest.swift
//
// Generated by SwagGen
// https://github.com/yonaskolb/SwagGen
//

public class APIRequest<ResponseType> {

    public let service: APIService<ResponseType>
    public private(set) var parameters: [String: Any]
    public private(set) var jsonBody: Any?
    public var headers: [String: String] = [:]

    public var path: String {
        return service.path
    }

    public init(service: APIService<ResponseType>, parameters: [String: Any] = [:], jsonBody: Any? = nil, headers: [String: String] = [:]) {
        self.service = service
        self.parameters = parameters
        self.jsonBody = jsonBody
        self.headers = headers
    }

    public func addHeader(name: String, value: String) {
        if !value.isEmpty {
            headers[name] = value
        }
    }
}

public struct APIService<ResponseType> {

    public let id: String
    public let tag: String
    public let method: String
    public let path: String
    public let hasBody: Bool
    public let authorization: Authorization?
    public let decode: (Any) throws -> ResponseType

    public init(id: String, tag: String = "", method:String, path:String, hasBody: Bool, authorization: Authorization? = nil, decode: @escaping (Any) throws -> ResponseType) {
        self.id = id
        self.tag = tag
        self.method = method
        self.path = path
        self.hasBody = hasBody
        self.authorization = authorization
        self.decode = decode
    }
}

public struct Authorization {
    public let type:String
    public let scope:String

    public init(type: String, scope: String) {
        self.type = type
        self.scope = scope
    }
}
