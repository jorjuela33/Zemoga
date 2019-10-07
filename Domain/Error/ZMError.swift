//
//  ZMError.swift
//  Domain
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

public struct ZMError: Error {
    public let key: String
    public let currentValue: Any?
    public let reason: String?
    public let file: StaticString?
    public let function: StaticString?
    public let line: UInt

    // MARK: Initialization

    public init(
        key: String,
        currentValue: Any? = nil,
        reason: String? = nil,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
        ) {

        self.key = key
        self.currentValue = currentValue
        self.reason = reason
        self.file = file
        self.function = function
        self.line = line
    }
}

extension ZMError: CustomStringConvertible {

    // MARK: CustomStringConvertible

    public var description: String {
        let location = ((String(describing: file).components(separatedBy: "/").last ?? "").components(separatedBy: ".").first ?? "")
        let info: [(String, Any?)] = [("- reason", reason), ("- location", location), ("- key", key), ("- currentValue", currentValue)]
        let infoString = info.map({ "\($0.0): \($0.1 ?? "nil")" }).joined(separator: "\n")
        return "Error. \n\(infoString)"
    }
}

extension ZMError: LocalizedError {

    // MARK: LocalizedError

    public var errorDescription: String? {
        return reason
    }

    public var localizedDescription: String {
        return reason ?? ""
    }
}
