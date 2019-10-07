//
//  SwipeToEditStateMachine.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import UIKit

enum SwipeToEditState: StateMachineState {
    case animatingOpen
    case animatingShut
    case editing
    case groupEdit
    case nothing
    case tracking

    // MARK: Instance methods

    func canTransition(to newState: SwipeToEditState) -> Bool {
        switch (self, newState) {
        case (.nothing, .tracking), (.nothing, .animatingOpen): return true
        case (.tracking, .animatingOpen), (.tracking, .tracking), (.tracking, .nothing): return true
        case (.animatingOpen, .editing), (.animatingOpen, .animatingShut), (.animatingOpen, .tracking), (.animatingOpen, .nothing): return true
        case (.animatingShut, .nothing): return true
        case (.editing, .tracking), (.editing, .animatingShut), (.editing, .nothing): return true
        default: return false
        }
    }
}

protocol SwipeToEditStateMachineDelegate: class {
    func swipeToEditStateMachine(_ loadingStateMachine: SwipeToEditStateMachine, didEnterInState state: SwipeToEditState)
    func swipeToEditStateMachine(_ loadingStateMachine: SwipeToEditStateMachine, didExitFromState state: SwipeToEditState)
}

class SwipeToEditStateMachine: StateMachine<SwipeToEditState> {
    private let collectionView: UICollectionView
    private var editingCell: CollectionViewCell?
    private let lock = NSLock()
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var startTrackingX: CGFloat = 0

    weak var delegate: SwipeToEditStateMachineDelegate?
    var isBatchEditing = false
    var trackedIndexPath: IndexPath?

    // MARK: Initializers

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init(state: .nothing)

        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        self.panGestureRecognizer.delegate = self

        if let gestureRecognizers = collectionView.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if gestureRecognizer is UIPanGestureRecognizer {
                    gestureRecognizer.require(toFail: panGestureRecognizer)
                }
            }
        }

        collectionView.addGestureRecognizer(panGestureRecognizer)
    }

    // MARK: Instance methods

    func shutActionPaneForEditingCell(animated: Bool) {
        guard currentState != .nothing else { return }

        setState(.animatingShut)
        editingCell?.closeActionPane(animated: animated, completionCallback: { finished in
            if finished {
                self.setState(.nothing)
            }
        })
    }

    func viewDidDissapear(animated: Bool) {
        guard currentState != .nothing else { return }

        shutActionPaneForEditingCell(animated: false)
    }

    // MARK: Overriden methods

    override func didEnterInState(_ state: SwipeToEditState) {
        switch state {
        case .animatingOpen:
            editingCell?.isUserInteractionEnabled = false

        case .animatingShut:
            editingCell?.isUserInteractionEnabled = false

        case .editing:
            editingCell?.isUserInteractionEnabled = true
            editingCell?.isUserInteractionEnabledForEditing = true

        case .nothing:
            startTrackingX = 0
            editingCell?.hideEditActions()
            collectionView.isScrollEnabled = true
            editingCell?.isUserInteractionEnabled = true
            editingCell = nil

        default: break
        }

        delegate?.swipeToEditStateMachine(self, didEnterInState: state)
    }

    override func didExitFromState(_ state: SwipeToEditState) {
        switch state {
        case .editing:
            editingCell?.isUserInteractionEnabledForEditing = false

        case .nothing:
            collectionView.isScrollEnabled = false
            editingCell?.showEditActions()

        default: break
        }

        delegate?.swipeToEditStateMachine(self, didExitFromState: state)
    }

    // MARK: Private methods

    @objc
    private func handleLongPressGesture(_ sender: UILongPressGestureRecognizer) {

    }

    @objc
    private func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began: break
        case .cancelled: shutActionPaneForEditingCell(animated: true)
        case .changed:
            let translation = sender.translation(in: editingCell)
            let xPosition = min(0, startTrackingX + translation.x)
            editingCell?.swipeTrackingPosition = xPosition
            setState(.tracking)

        case .ended:
            let xPosition = editingCell?.swipeTrackingPosition ?? 0
            let targetX = editingCell?.minimumSwipeTrackingPosition ?? 0
            let velocityInX = sender.velocity(in: editingCell).x
            let translatedPoint = sender.translation(in: editingCell)
            let threshhold: CGFloat = 100
            if velocityInX <= 0  && (-velocityInX > threshhold || xPosition <= targetX) {
                let newVelocityInX = 0.2 * velocityInX
                var finalX = translatedPoint.x + newVelocityInX
                let animationDuration: TimeInterval = abs(Double(newVelocityInX)) * 0.0002 + 2
                finalX = max(targetX, finalX)
                setState(.animatingOpen)
                UIView.animate(
                    withDuration: animationDuration,
                    delay: 0,
                    options: .curveEaseOut,
                    animations: {
                    self.editingCell?.swipeTrackingPosition = finalX
                    }, completion: { _ in
                    guard self.currentState == .animatingOpen else { return }

                    self.setState(.editing)
                    })
            } else {
                shutActionPaneForEditingCell(animated: true)
            }

        default: break
        }
    }
}

extension SwipeToEditStateMachine: UIGestureRecognizerDelegate {

    // MARK: UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === panGestureRecognizer {
           switch currentState {
           case .nothing, .editing, .animatingOpen:
               if
                   /// indexPath
                   let indexPath = collectionView.indexPathForItem(at: panGestureRecognizer.location(in: collectionView)),

                   /// touched cell
                   let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell {

                   let velocity = panGestureRecognizer.velocity(in: collectionView)

                   if currentState != .nothing && cell != editingCell {
                       return false
                   }

                   if cell.editActions.isEmpty {
                       return false
                   }

                   if abs(velocity.y) >= abs(velocity.x) {
                       return false
                   }

                   startTrackingX = cell.swipeTrackingPosition
                   editingCell = cell
                   setState(.tracking)
                   return true
               } else {
                   return false
               }

           default: return false
           }
        }

        return false
    }
}
