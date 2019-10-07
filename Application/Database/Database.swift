//
//  Database.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import CoreData
import Domain

typealias DatabaseHandle = Int64
typealias DatabaseTransactionCallback = (Error?) -> Void

protocol DatabaseEntity {
    associatedtype DatabaseType: NSFetchRequestResult

    static var entityName: String { get }
    var id: Int64 { get }
    static var primaryKeyAttributeName: String { get }

    static func map(from entity: DatabaseType) -> Self
    func update(_ entity: DatabaseType)
}

extension DatabaseEntity {
    static var primaryKeyAttributeName: String {
        return "id"
    }
}

private func createPersistentContainer() -> NSPersistentContainer {
    let storeURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("store.sqlite")
    let modelURL = Bundle(for: Database.self).url(forResource: "Zemoga", withExtension: "momd")!
    let model = NSManagedObjectModel(contentsOf: modelURL)!
    let persistentStoreDescription = NSPersistentStoreDescription(url: storeURL)
    let persistentContainer = NSPersistentContainer(name: "Zemoga", managedObjectModel: model)
    persistentContainer.persistentStoreDescriptions = [persistentStoreDescription]
    persistentContainer.loadPersistentStores { _, error in
        guard let error = error else { return }

        fatalError("\(error)")
    }

    persistentContainer.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
    persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    return persistentContainer
}

struct Snapshot<T: DatabaseEntity> {
    let changes: [ChangeType]
    let query: DatabaseQuery<T>
    let value: [T]

    // MARK: Initializers

    init(value: [T], query: DatabaseQuery<T>, changes: [ChangeType]) {
        self.changes = changes
        self.query = query
        self.value = value
    }
}

class Database {
    private let callbackQueue = DispatchQueue.main
    private var persistentContainer: NSPersistentContainer
    private var trackedQueryObservers: [AnyHashable: Any] = [:]
    private let syncTree = SyncPoint()

    static let sharedQueue = DispatchQueue(label: "com.database.shared.queue")

    /// defaul instance of the database
    static let `default` = Database()

    // MARK: Initializers

    init(persistentContainer: NSPersistentContainer = createPersistentContainer()) {
        self.persistentContainer = persistentContainer
    }

    // MARK: Instance methods

    func addEventRegistration<T: DatabaseEntity>(_ eventRegistration: DatabaseEventRegistration, forQuery query: DatabaseQuery<T>) {
        let events = syncTree.addEventRegistration(eventRegistration, forQuery: query)
        if !existsObserver(for: query) {
            let databaseObserver = DatabaseObserver(
                fetchRequest: query.fetchRequest,
                context: persistentContainer.viewContext
            ) { [weak self] entities, changes, error in
                guard let `self` = self else { return }

                if let error = error {
                    self.removeRegistrationEvent(eventRegistration, forQuery: query, cancelError: error)
                } else {
                    let events = self.syncTree.applyChanges(changes, entities: entities.compactMap(T.map), forQuery: query)
                    self.raiseEvents(for: events)
                }
            }

            trackedQueryObservers[query] = databaseObserver
        } else {
            raiseEvents(for: events)
        }
    }

    func delete<T: DatabaseEntity>(forQuery query: DatabaseQuery<T>, callback: DatabaseTransactionCallback?) {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        context.perform {
            do {
                guard let fetchRequest = query.fetchRequest as? NSFetchRequest<NSFetchRequestResult> else {
                    let error = ZMError(key: "database.delete()", currentValue: query, reason: "Invalid database objects.")
                    callback?(error)
                    return
                }

                try context.delete(fetchRequest)
                try context.save()
                callback?(nil)
            } catch {
                let error = ZMError(key: "database.delete()", currentValue: query, reason: error.localizedDescription)
                callback?(error)
                return
            }
        }
    }

    func removeRegistrationEvent<T: DatabaseEntity>(_ eventRegistration: DatabaseEventRegistration, forQuery query: DatabaseQuery<T>) {
        removeRegistrationEvent(eventRegistration, forQuery: query, cancelError: nil)
    }

    func reset() {
        persistentContainer.viewContext.reset()
        persistentContainer = createPersistentContainer()
    }

    func update<T: DatabaseEntity>(_ entity: T, forQuery query: DatabaseQuery<T>, callback: DatabaseTransactionCallback?) {
        update([entity], forQuery: query, callback: callback)
    }

    func update<T: DatabaseEntity>(_ entities: [T], forQuery query: DatabaseQuery<T>, callback: DatabaseTransactionCallback?) {
        func insertNewEntity(into context: NSManagedObjectContext) throws -> T.DatabaseType {
            guard let nEntity = NSEntityDescription.insertNewObject(forEntityName: T.entityName, into: context) as? T.DatabaseType else {
                throw ZMError(
                    key: "database.update()",
                    currentValue: entities,
                    reason: "Unable to convert the new entity into the associated type \(T.DatabaseType.self)"
                )
            }
            return nEntity
        }

        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        context.perform {
            do {
                for entity in entities {
                    let query = query.and("%K == %i", T.primaryKeyAttributeName, entity.id)
                    let cachedEntity = try context.fetch(query.fetchRequest).first ?? insertNewEntity(into: context)
                    entity.update(cachedEntity)
                }

                try context.save()
                callback?(nil)
            } catch {
                let error = ZMError(key: "database.update()", currentValue: entities, reason: error.localizedDescription)
                callback?(error)
                return
            }
        }
    }

    // MARK: Private methods

    private func existsObserver<T: DatabaseEntity>(for query: DatabaseQuery<T>) -> Bool {
        return (trackedQueryObservers[query] as? DatabaseObserver<T.DatabaseType>) != nil
    }

    private func raiseEvents(for events: [Event]) {
        events.forEach({ $0.fireOnQueue(self.callbackQueue) })
    }

    private func removeRegistrationEvent<T>(_ eventRegistration: DatabaseEventRegistration, forQuery query: DatabaseQuery<T>, cancelError: Error?) {
        let events = syncTree.removeEventRegistration(eventRegistration, forQuery: query, cancelError: cancelError)
        if syncTree[query] == nil {
            trackedQueryObservers.removeValue(forKey: query)
        }
        raiseEvents(for: events)
    }
}

private extension NSManagedObjectContext {

    // MARK: Instance methods

    func delete(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>) throws {
        if let cachedObjects = try fetch(fetchRequest) as? [NSManagedObject] {
            cachedObjects.forEach(delete)
        } else {
            throw ZMError(key: "database.delete()", currentValue: fetchRequest, reason: "Invalid database objects.")
        }
    }
}
