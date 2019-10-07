//
//  DatabaseQuery.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import CoreData

class DatabaseQuery<T: DatabaseEntity> {
    private let atomicNumber = AtomicNumber.default
    private var predicate: NSPredicate = NSPredicate(value: true)
    private var sortDescriptors: [NSSortDescriptor] = []

    let limit: Int
    let starts: Int

    /// the entity associated to this query
    var entityName: String {
        return T.entityName
    }

    /// the database associated to the query
    let database: Database

    /// the associated fetch request
    var fetchRequest: NSFetchRequest<T.DatabaseType> {
        let fetchRequest = NSFetchRequest<T.DatabaseType>(entityName: entityName)
        fetchRequest.fetchLimit = limit
        fetchRequest.fetchOffset = starts
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        return fetchRequest
    }

    // MARK: Initializers

    init(database: Database = Database.default, limit:Int = Int.max, starts: Int = 0) {
        self.database = database
        self.limit = limit
        self.starts = starts
    }

    // MARK: Instance methods

    /// creates and append a new predicate to the current
    func and(_ and: String, _ argList: CVarArg...) -> DatabaseQuery<T> {
        let databaseQuery = DatabaseQuery(database: database, limit: limit, starts: starts)
        let andPredicate = withVaList(argList) { NSPredicate(format: and, arguments: $0) }
        databaseQuery.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, andPredicate])
        return databaseQuery
    }

    /// deletes the entity from the database
    func delete(withCallback callback: DatabaseTransactionCallback? = nil) {
        Database.sharedQueue.async {
            self.database.delete(forQuery: self, callback: callback)
        }
    }

    /// sets the limit of the current query
    func limit(to limit: Int) -> DatabaseQuery<T> {
        return DatabaseQuery(database: database, limit: limit, starts: starts)
    }

    /// observe the changes for the current query
    @discardableResult
    func observeEventType(
        _ eventType: DatabaseEventType,
        withBlock block: @escaping DataSnapshot<T>,
        cancelBlock cancel: CancelError? = nil
        ) -> DatabaseHandle {

        let eventRegistration: DatabaseEventRegistration

        if eventType == .data {
            eventRegistration = DatabaseDataEventRegistration(
                id: atomicNumber.getAndIncrement(),
                database: database,
                callback: block,
                cancelCallback: cancel
            )
        } else {
            eventRegistration = DatabaseChildEventRegistration(
                id: atomicNumber.getAndIncrement(),
                database: database,
                callbacks: [eventType: block],
                cancelCallback: cancel
            )
        }

        Database.sharedQueue.async {
            self.database.addEventRegistration(eventRegistration, forQuery: self)
        }

        return eventRegistration.id
    }

    /// observe a single event for the current query.
    func observeSingleEventOfType(
        _ eventType: DatabaseEventType,
        withBlock block: @escaping DataSnapshot<T>,
        cancelBlock cancel: CancelError? = nil
        ) {

        var callbacks: Int32 = 0
        var databaseHandle: DatabaseHandle = 0
        databaseHandle = observeEventType(
            eventType,
            withBlock: { [weak self] snapshot in
                if OSAtomicCompareAndSwap32(0, 1, &callbacks) {
                    self?.removeObserverWithHandle(databaseHandle)
                    block(snapshot)
                }
            }, cancelBlock: { [weak self] error in
                self?.removeObserverWithHandle(databaseHandle)
                cancel?(error)
        })
    }

    /// sets the order
    func order(by key: String, ascending: Bool = true) -> DatabaseQuery {
        let databaseQuery = DatabaseQuery(database: database, limit: limit, starts: starts)
        databaseQuery.predicate = predicate
        databaseQuery.sortDescriptors = sortDescriptors + [NSSortDescriptor(key: key, ascending: ascending)]
        return databaseQuery
    }

    /// remove the obsever associated with the given handle.
    func removeObserverWithHandle(_ handle: DatabaseHandle) {
        let dataEventRegistration = DatabaseDataEventRegistration<T>(id: handle, database: self.database)
        Database.sharedQueue.async {
            self.database.removeRegistrationEvent(dataEventRegistration, forQuery: self)
        }
    }

    /// sets the start point of the current query
    func starts(at starts: Int) -> DatabaseQuery<T> {
        return DatabaseQuery(database: database, limit: limit, starts: starts)
    }

    /// updates the values with the given entity.
    func update(_ entity: T, withCallback callback: DatabaseTransactionCallback?) {
        Database.sharedQueue.async {
            self.database.update(entity, forQuery: self, callback: callback)
        }
    }

    /// updates the values with the given array of entities.
    func update(_ entities: [T], withCallback callback: DatabaseTransactionCallback?) {
        Database.sharedQueue.async {
            self.database.update(entities, forQuery: self, callback: callback)
        }
    }

    /// the start point of the where clause
    /// if where is invoked after a where the previous
    /// predicate will be overriden
    func `where`(_ whre: String, _ argList: CVarArg...) -> DatabaseQuery<T> {
        let databaseQuery = DatabaseQuery(database: database, limit: limit, starts: starts)
        databaseQuery.predicate = withVaList(argList) { NSPredicate(format: whre, arguments: $0) }
        return databaseQuery
    }
}

extension DatabaseQuery: Hashable {

    // MARK: Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(predicate.hash)
    }

    static func == (lhs: DatabaseQuery, rhs: DatabaseQuery) -> Bool {
        return lhs.entityName == rhs.entityName &&
            lhs.fetchRequest == rhs.fetchRequest &&
            lhs.predicate == rhs.predicate
    }
}

