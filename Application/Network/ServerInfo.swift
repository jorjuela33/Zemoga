//
//  ServerInfo.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

struct ServerInfo {
    let host: String
    let isSecure: Bool
    let path: String

    static let `default` = ServerInfo(host: "jsonplaceholder.typicode.com", isSecure: true)

    // MARK: Initializers

    init(host: String, isSecure: Bool, path: String = "") {
        self.host = host
        self.isSecure = isSecure
        self.path = path
    }

    // MARK: Instance methods

    func connectionURL() -> URL {
        let scheme = isSecure ? "https" : "http"
        guard let url = URL(string: "\(scheme)://\(host)") else {
            fatalError("If we want to send a request we should provide a valid url!")
        }

        return url.appendingPathComponent(path)
    }
}
