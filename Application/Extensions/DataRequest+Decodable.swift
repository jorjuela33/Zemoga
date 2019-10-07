//
//  DataRequest+Decodable.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Alamofire

protocol ResponseSerializer: DataResponseSerializerProtocol & DownloadResponseSerializerProtocol {
    var emptyRequestMethods: Set<HTTPMethod> { get }
    var emptyResponseCodes: Set<Int> { get }
}

extension ResponseSerializer {
    static var defaultEmptyRequestMethods: Set<HTTPMethod> { return [.head] }
    static var defaultEmptyResponseCodes: Set<Int> { return [204, 205] }

    var emptyRequestMethods: Set<HTTPMethod> { return Self.defaultEmptyRequestMethods }
    var emptyResponseCodes: Set<Int> { return Self.defaultEmptyResponseCodes }

    func requestAllowsEmptyResponseData(_ request: URLRequest?) -> Bool? {
        return request.flatMap { $0.httpMethod }
            .flatMap(HTTPMethod.init)
            .map { emptyRequestMethods.contains($0) }
    }

    func responseAllowsEmptyResponseData(_ response: HTTPURLResponse?) -> Bool? {
        return response.flatMap { $0.statusCode }
            .map { emptyResponseCodes.contains($0) }
    }

    func emptyResponseAllowed(forRequest request: URLRequest?, response: HTTPURLResponse?) -> Bool {
        return requestAllowsEmptyResponseData(request) ?? responseAllowsEmptyResponseData(response) ?? false
    }
}

protocol DataDecoder {
    func decode<D: Decodable>(_ type: D.Type, from data: Data) throws -> D
}

extension JSONDecoder: DataDecoder { }

struct Empty: Decodable {
    static let value = Empty()
}

final class DecodableResponseSerializer<T: Decodable>: DataResponseSerializerProtocol {
    let decoder: DataDecoder
    var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<T>

    // MARK: Initialization

    init(decoder: DataDecoder = JSONDecoder()) {
        self.decoder = decoder
        serializeResponse = { request, response, data, error in
            guard error == nil else {
                return .failure(error!)
            }

            guard let data = data, !data.isEmpty else {
                guard let emptyValue = Empty.value as? T else {
                    return .failure(AFError.responseSerializationFailed(reason: .inputDataNil))
                }

                return .success(emptyValue)
            }

            do {
                return .success(try decoder.decode(T.self, from: data))
            } catch {
                return .failure(AFError.responseSerializationFailed(reason: .jsonSerializationFailed(error: error)))
            }
        }
    }
}

extension DataRequest {

    // MARK: Instance methods

    /// Adds a handler to be called once the request has finished.
    @discardableResult
    func responseDecodable<T: Decodable>(
        queue: DispatchQueue? = nil,
        decoder: DataDecoder = JSONDecoder(),
        completionHandler: @escaping (DataResponse<T>) -> Void
        ) -> Self {

        return response(
            queue: queue,
            responseSerializer: DecodableResponseSerializer(decoder: decoder),
            completionHandler: completionHandler
        )
    }
}
