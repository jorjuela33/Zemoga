//
//  ContentLoading.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import Foundation

enum ContentLoadingState: StateMachineState {
    case initial
    case loadingContent
    case contentLoaded
    case ignored
    case refreshingContent
    case noContent
    case error

    // MARK: Intance methods

    func canTransition(to newState: ContentLoadingState) -> Bool {
        switch (self, newState) {
        case (.initial, .loadingContent): return true
        case (.loadingContent, .contentLoaded), (.loadingContent, .noContent), (.loadingContent, .error): return true
        case (.refreshingContent, .contentLoaded), (.refreshingContent, .noContent), (.refreshingContent, .error): return true
        case (.contentLoaded, .refreshingContent), (.contentLoaded, .noContent), (.contentLoaded, .error): return true
        case (.noContent, .refreshingContent), (.noContent, .contentLoaded), (.noContent, .error): return true
        case (.error, .loadingContent), (.error, .refreshingContent), (.error, .noContent), (.error, .contentLoaded): return true
        default: return false
        }
    }
}

protocol ContentLoading {
    typealias LoadingCallback = (Loading) -> Void

    /// Any error that occurred during content loading.
    var loadingError: Error? { get }

    /// The current state of the content loading operation
    var loadingState: ContentLoadingState { get }

    /// method used to begin loading the content.
    func loadContent()

    /// Method used by implementers of -loadContent to manage the loading operation.
    func loadContentWithCallback(_ callback: LoadingCallback)

    /// method used to reset the content of the receiver.
    func resetContent()
}

class Loading {
    typealias ContentLoadingCallback = (ContentLoadingState, Error?, LoadingUpdateCallback?) -> Void
    typealias LoadingUpdateCallback = (DataSource) -> Void

    private var callback: ContentLoadingCallback?
    private var completed: Int32 = 0

    ///it should inform previous instances that they are no longer the current instance.
    var isCurrent = true

    // MARK: Initialization

    init(callback: @escaping ContentLoadingCallback) {
        self.callback = callback
    }

    // MARK: Instance methods

    /// Signals that loading is complete with no errors.
    func done() {
        doneWith(.contentLoaded, error: nil, updateCallback: nil)
    }

    /// Signals that loading failed with an error.
    func doneWithError(_ error: Error) {
        doneWith(.error, error: error, updateCallback: nil)
    }

    /// Signals that this result should be ignored.
    func ignore() {
        doneWith(.ignored, error: nil, updateCallback: nil)
    }

    /// Signals that loading is complete.
    func updateWithContent(_ callback: LoadingUpdateCallback? = nil) {
        doneWith(.contentLoaded, error: nil, updateCallback: callback)
    }

    /// Signals that loading completed with no content.
    func updateWithNoContent(_ callback: LoadingUpdateCallback? = nil) {
        doneWith(.noContent, error: nil, updateCallback: callback)
    }

    // MARK: Private methods

    private func doneWith(_ newState: ContentLoadingState, error: Error?, updateCallback: LoadingUpdateCallback?) {
        #if DEBUG
            if !OSAtomicCompareAndSwap32(0, 1, &self.completed) {
                fatalError("completion method called more than once")
            }
        #endif

        let callback = self.callback
        DispatchQueue.main.async {
            callback?(newState, error, updateCallback)
        }

        self.callback = nil
    }
}

