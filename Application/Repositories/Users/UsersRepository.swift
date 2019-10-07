//
//  UsersRepository.swift
//  Application
//
//  Created by Jorge Orjuela on 10/5/19.
//

import Domain
import RxSwift

class UsersRepository: Repository {
    private let database: Database
    private let network: Network
    private let syncTree: SyncTree

    // MARK: Initializers

    init(database: Database, network: Network) {
        self.database = database
        self.network = network
        self.syncTree = SyncTree(database: database)
    }
}

extension UsersRepository: Domain.UsersRepository {

    // MARK: UsersRepository

    func observeChanges(forUserWithID userID: Int64) -> Observable<[User]> {
        return Observable.create({ observer in
            let query = DatabaseQuery<UserEntity>(database: self.database).order(by: PostEntity.primaryKeyAttributeName)
            let databaseHandle = query.observeEventType(.data, withBlock: { snapshot in
                observer.onNext(snapshot.value.mapToDomain())
            })
            return Disposables.create {
                query.removeObserverWithHandle(databaseHandle)
            }
        })
    }

    func retrieveUser(withID userID: Int64) -> Single<User> {
        return Single.create(subscribe: { observer in
            self.beginLoading()
            let connectionRequestRegistration = self.network.retrieveUser(withID: userID, withCallback: { result in
                switch result {
                case let .failure(error):
                    self.endLoadingStateWithState(.error)
                    observer(.error(error))

                case let .success(user):
                    DatabaseQuery<UserEntity>(database: self.database)
                        .update(user, withCallback: { error in
                            guard let error = error else {
                                self.endLoadingStateWithState(.contentLoaded)
                                observer(.success(user.asDomain()))
                                return
                            }

                            self.endLoadingStateWithState(.error)
                            observer(.error(error))
                        })
                }
            })
            return Disposables.create {
                self.network.cancelConnectionRequest(withRegistration: connectionRequestRegistration)
            }
        })
    }
}
