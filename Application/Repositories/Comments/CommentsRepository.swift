//
//  CommentsRepository.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Domain
import RxSwift

class CommentsRepository: Repository {
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

extension CommentsRepository: Domain.CommentsRepository {

    // MARK: CommentsRepository

    func observeChanges(forPostWithID postID: Int64) -> Observable<[Comment]> {
        return Observable.create({ observer in
            let query = DatabaseQuery<CommentEntity>(database: self.database)
                .where("%K == %i", "postID", postID)
                .order(by: CommentEntity.primaryKeyAttributeName)
            
            let databaseHandle = query.observeEventType(.data, withBlock: { snapshot in
                observer.onNext(snapshot.value.mapToDomain())
            })
            return Disposables.create {
                query.removeObserverWithHandle(databaseHandle)
            }
        })
    }

    func retrieveComments(forPostWithID postID: Int64) -> Single<[Comment]> {
        return Single.create(subscribe: { observer in
            self.beginLoading()
            let connectionRequestRegistration = self.network.retrieveComments(forPostWithID: postID, withCallback: { result in
                switch result {
                case let .failure(error):
                    self.endLoadingStateWithState(.error)
                    observer(.error(error))

                case let .success(comments):
                    DatabaseQuery<CommentEntity>(database: self.database)
                        .update(comments, withCallback: { error in
                            guard let error = error else {
                                self.endLoadingStateWithState(.contentLoaded)
                                observer(.success(comments.mapToDomain()))
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

