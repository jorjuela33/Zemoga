//
//  ErrorBuilder.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import Foundation

let defaultErrorTitle = "Error"
let defaultErrorMessage = "We have issues at this moment. Please try again later."

struct ErrorBuilder {

    // MARK: Static methods

    static func create(_ error: Error) -> Message {
        return Message(title: defaultErrorTitle, message: error.localizedDescription)
    }
}
