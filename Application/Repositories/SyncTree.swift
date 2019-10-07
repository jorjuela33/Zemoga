//
//  SyncTree.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Domain

class SyncTree {
    private let database: Database
    private let queue = DispatchQueue(label: "com.sync.tree.queue")

    // MARK: Initializers

    init(database: Database = .default) {
        self.database = database
    }

    // MARK: Instance methods

    func applyServerOverwrite<T: DatabaseEntity>(_ newData: [T], withCallback callback: DatabaseTransactionCallback?) {
        let objectsIDS = newData.map({ $0.id })
        DatabaseQuery<T>(database: self.database)
            .where("NOT (%K IN %@)", T.primaryKeyAttributeName, objectsIDS)
            .delete(withCallback: { error in
                guard let error = error else {
                    DatabaseQuery<T>(database: self.database)
                        .update(newData, withCallback: { error in
                            guard let error = error else {
                                callback?(nil)
                                return
                            }

                            let wrappedError = ZMError(
                                key: "SyncTree.applyServerOverwrite()",
                                currentValue: newData,
                                reason: error.localizedDescription
                            )
                            callback?(wrappedError)
                        })
                    return
                }

                let wrappedError = ZMError(key: "SyncTree.applyServerOverwrite()", currentValue: newData, reason: error.localizedDescription)
                callback?(wrappedError)
            })
    }

    func applyServerWrite<T: DatabaseEntity>(_ newData: T, withCallback callback: DatabaseTransactionCallback?) {
        DatabaseQuery<T>(database: self.database)
            .update(newData, withCallback: { error in
                guard let error = error else {
                    callback?(nil)
                    return
                }

                let wrappedError = ZMError(key: "SyncTree.applyServerWrite()", currentValue: newData, reason: error.localizedDescription)
                callback?(wrappedError)
            })
    }
}
