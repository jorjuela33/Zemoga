//
//  Repository.swift
//  Domain
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

public enum LoadingState {
    case contentLoaded
    case error
    case initial
    case loadingContent
}

public protocol Repository {
    var currentState: LoadingState { get }
}
