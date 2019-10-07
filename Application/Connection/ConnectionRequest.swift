//
//  ConnectionRequest.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Alamofire

protocol ConnectionRequestDelegate: class {
    func connectionRequestDidCancel(_ connectionRequest: ConnectionRequest)
    func connectionRequestDidFinish(_ connectionRequest: ConnectionRequest)
    func connectionRequestDidResume(_ connectionRequest: ConnectionRequest)
    func connectionRequestDidSuspend(_ connectionRequest: ConnectionRequest)
}

class ConnectionRequest {
    typealias CompletionCallback = () -> Void
    typealias ResponseDataCallback = ((Data?, Error?) -> Void)
    typealias ResponseJSONCallback = ((Any?, Error?) -> Void)

    private let dataRequest: DataRequest

    /// A finished request may finish either because it was cancelled or because it successfully
    var completionCallback: CompletionCallback?
    let identifier: ConnectionRequestRegistration
    weak var delegate: ConnectionRequestDelegate?

    var httpBody: Data? {
        return dataRequest.request?.httpBody
    }

    var url: URL? {
        return dataRequest.request?.url
    }

    enum ResponseState: String {
        case invalidBackupCode = "afc546"
        case invalidEmailOrPassword = "afc506"
        case invalidOtpCode = "afc536"
        case notFound = "000404"
        case tfaEnabled = "afc526"
        case wrongEmailAndPassword = "afc516"
    }

    // MARK: Initialization

    init(dataRequest: DataRequest, requestMonitor: RequestMonitor) {
        self.dataRequest = dataRequest
        self.identifier = AtomicNumber.default.getAndIncrement()
        requestMonitor.subscribeToStateUpdates(self, callback: stateCallback)
    }

    // MARK: Intance methods

    /// Cancels the `Request`.
    func cancel() {
        dataRequest.cancel()
    }

    /// returns true if the underlying request is equals
    func matches(_ request: Request) -> Bool {
        return dataRequest === request
    }

    /// Adds a handler to be called once the request has finished.
    @discardableResult
    func response<T: Decodable>(_ callback: @escaping (T?, Error?) -> Void) -> Self {
        dataRequest.responseDecodable { (response: DataResponse<T>) in
            callback(response.value, response.error)
        }

        return self
    }

    /// Adds a handler to be called once the request has finished.
    @discardableResult
    func responseData(_ callback: @escaping ResponseDataCallback) -> Self {
        dataRequest.responseData { response in
            callback(response.value, response.error)
        }

        return self
    }

    /// Adds a handler to be called once the request has finished.
    @discardableResult
    func responseJSON(_ callback: @escaping ResponseJSONCallback) -> Self {
        dataRequest.responseJSON { response in
            callback(response.value, response.error)
        }

        return self
    }

    /// Resume the `Request`.
    @discardableResult
    func resume() -> Self {
        dataRequest.resume()
        return self
    }

    /// Suspends the `Request`.
    @discardableResult
    func suspend() -> Self {
        dataRequest.suspend()
        return self
    }

    /// Validates the request. Checks for valid status codes
    @discardableResult
    func validate() -> Self {
        dataRequest.validate()
        return self
    }

    // MARK: Private methods

    private func stateCallback(_ state: RequestMonitorState) {
        switch state {
        case .resumed: delegate?.connectionRequestDidResume(self)
        case .suspended: delegate?.connectionRequestDidSuspend(self)

        case .canceled:
            completionCallback?()
            delegate?.connectionRequestDidCancel(self)

        case .finished:
            completionCallback?()
            delegate?.connectionRequestDidFinish(self)
        }
    }
}

extension ConnectionRequest: Equatable {

    // MARK: Equatable

    static func ==(lhs: ConnectionRequest, rhs: ConnectionRequest) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
