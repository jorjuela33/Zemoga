//
//  DatabaseObserver.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import CoreData
import Domain

enum ChangeType {
    case insert(IndexPath)
    case update(IndexPath)
    case move(IndexPath, IndexPath)
    case delete(IndexPath)
}

class DatabaseObserver<T: NSFetchRequestResult>: NSObject, NSFetchedResultsControllerDelegate {
    typealias ObserverCallback = ([T], [ChangeType], Error?) -> Void

    private let callback: ObserverCallback
    private var changes: [ChangeType] = []
    private let fetchedResultsController: NSFetchedResultsController<T>

    // MARK: Initializers

    init(
        fetchRequest: NSFetchRequest<T>,
        context: NSManagedObjectContext,
        sectionKeyPath: String? = nil,
        cacheName: String? = nil,
        callback: @escaping ObserverCallback
        ) {

        self.callback = callback
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: sectionKeyPath,
            cacheName: cacheName
        )

        super.init()

        context.performAndWait {
            self.fetchedResultsController.delegate = self
            do {
                try self.fetchedResultsController.performFetch()
                self.sendElements()
            } catch {
                let error = ZMError(
                    key: "EntityObserver.performAndWait()",
                    currentValue: nil,
                    reason: error.localizedDescription,
                    file: #file,
                    function: #function,
                    line: #line
                )

                callback([], [], error)
            }
        }
    }

    // MARK: NSFetchedResultsControllerDelegate

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
        ) {

        switch type {
        case .insert:
            guard let indexPath = newIndexPath else { return }

            changes.append(.insert(indexPath))

        case .update:
            guard let indexPath = indexPath else { return }

            changes.append(.update(indexPath))

        case .move:
            guard
                /// indexpath
                let indexPath = indexPath,

                /// new indexpath
                let newIndexPath = newIndexPath else { return }

            changes.append(.move(indexPath, newIndexPath))

        case .delete:
            guard let indexPath = indexPath else { return }

            changes.append(.delete(indexPath))

        @unknown default: print("not handled")
        }
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        changes = []
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sendElements()
    }

    // MARK: Private methods

    private final func sendElements() {
        let entities = self.fetchedResultsController.fetchedObjects ?? []
        callback(entities, self.changes, nil)
    }
}
