//
//  LoadingStateMachine.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import Foundation

protocol LoadingStateMachineDelegate: class {
    func loadingStateMachine(_ loadingStateMachine: LoadingStateMachine, didEnterInState state: ContentLoadingState)
    func loadingStateMachine(_ loadingStateMachine: LoadingStateMachine, didExitFromState state: ContentLoadingState)
}

class LoadingStateMachine: StateMachine<ContentLoadingState> {

    weak var delegate: LoadingStateMachineDelegate?

    // MARK: Initializers

    required init() {
        super.init(state: .initial)
    }

    // MARK: Overriden methods

    override func didEnterInState(_ state: ContentLoadingState) {
        delegate?.loadingStateMachine(self, didEnterInState: state)
    }

    override func didExitFromState(_ state: ContentLoadingState) {
        delegate?.loadingStateMachine(self, didExitFromState: state)
    }
}
