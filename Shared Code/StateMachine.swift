//
//  StateMachine.swift
//  Domain
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

protocol StateMachineState: Equatable {
    func canTransition(to newState: Self) -> Bool
}

class StateMachine<State: StateMachineState>: NSObject {
    private let lock = NSLock()
    private var internalState: State

    /// the current state of the machine
    var currentState: State {
        lock.lock()
        defer { lock.unlock() }
        return internalState
    }

    // MARK: Initializers

    init(state: State) {
        self.internalState = state
    }

    // MARK: Instance methods

    /// notifies the new state transition
    /// to be overriden by subclasses
    func didEnterInState(_ state: State) {
    }

    /// notifies when the machine leaves a state
    /// to be overriden by subclasses
    func didExitFromState(_ state: State) {
    }

    /// set current state and return YES if the state changed successfully to the supplied state, NO otherwise.
    @discardableResult
    func setState(_ newState: State) -> Bool {
        guard newState != currentState else { return false }

        let fromState = currentState
        print("••• request state change from \(fromState) to \(newState) •••")

        guard fromState.canTransition(to: newState) else {
            print("••• \(self) cannot transition to \(newState) from \(fromState) •••")
            return false
        }

        lock.lock()
        internalState = newState
        lock.unlock()
        performTransition(fromState: fromState, toState: newState)
        return true
    }

    // MARK: Private methods

    private func performTransition(fromState state: State, toState newState: State) {
        print("••• \(self) state change from \(state) to \(newState) •••")
        didEnterInState(newState)
        didExitFromState(state)
    }
}
