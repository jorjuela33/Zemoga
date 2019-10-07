//
//  PostsRepository.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Domain
import RxSwift

class PostsRepository: Repository {
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

extension PostsRepository: Domain.PostsRepository {

    // MARK: PostsRepository

    func deleteAllPosts() -> Completable {
        return Completable.create(subscribe: { observer in
            DatabaseQuery<PostEntity>(database: self.database).delete(withCallback: { error in
                guard let error = error else {
                    observer(.completed)
                    return
                }

                observer(.error(error))
            })
            return Disposables.create()
        })
    }

    func deletePost(withID postID: Int64) -> Completable {
        return Completable.create { observer in
            let connectionRequestRegistration = self.network.deletePost(withID: postID, withCallback: { result in
                switch result {
                    case let .failure(error):
                    observer(.error(error))

                case .success:
                    DatabaseQuery<PostEntity>(database: self.database)
                        .where("%K == %i", PostEntity.primaryKeyAttributeName, postID)
                        .delete()

                    observer(.completed)
                }
            })

            return Disposables.create {
                self.network.cancelConnectionRequest(withRegistration: connectionRequestRegistration)
            }
        }
    }

    func markPost(_ post: Post, asFavorite favorite: Bool) -> Completable {
        return Completable.create(subscribe: { observer in
            let post = PostEntity(id: post.id, body: post.body, isFavorite: favorite, read: post.read, title: post.title, userID: post.userID)
            DatabaseQuery<PostEntity>(database: self.database).update(post) { error in
                guard let error = error else {
                    observer(.completed)
                    return
                }

                observer(.error(error))
            }
            return Disposables.create()
        })
    }

    func observeChanges(forPostWithID postID: Int64, filteringBy filter: Filter) -> Observable<[Post]> {
        return Observable.create({ observer in
            var query = DatabaseQuery<PostEntity>(database: self.database).order(by: PostEntity.primaryKeyAttributeName)

            switch filter {
            case .favorites: query = query.where("%K == %i", "isFavorite", true)
            case .notFavorites: query = query.where("%K == %i", "isFavorite", false)
            default: break
            }

            if postID > 0 {
                query = query.and("%K == %i", PostEntity.primaryKeyAttributeName, postID)
            }

            let databaseHandle = query.observeEventType(.data, withBlock: { snapshot in
                observer.onNext(snapshot.value.mapToDomain())
            })
            return Disposables.create {
                query.removeObserverWithHandle(databaseHandle)
            }
        })
    }

    func retrievePosts() -> Single<[Post]> {
        return Single.create(subscribe: { observer in
            self.beginLoading()
            let connectionRequestRegistration = self.network.retrievePosts(withCallback: { result in
                switch result {
                case let .failure(error):
                    self.endLoadingStateWithState(.error)
                    observer(.error(error))

                case let .success(posts):
                    let query = DatabaseQuery<PostEntity>(database: self.database)
                    let completionCallback: ((Error?) -> Void) = { error in
                        guard let error = error else {
                            self.endLoadingStateWithState(.contentLoaded)
                            observer(.success(posts.mapToDomain()))
                            return
                        }

                        self.endLoadingStateWithState(.error)
                        observer(.error(error))
                    }

                    query.update(posts, withCallback: { error in
                         let subposts =  posts.count > 20 ? Array(posts[0..<20]) : posts
                         let readPosts = subposts.map({ PostEntity(
                            id: $0.id,
                            body: $0.body,
                            isFavorite: false,
                            read: true,
                            title: $0.title,
                            userID: $0.userID
                            )
                        })
                        query.update(readPosts, withCallback: completionCallback)
                    })
                }
            })
            return Disposables.create {
                self.network.cancelConnectionRequest(withRegistration: connectionRequestRegistration)
            }
        })
    }
}
