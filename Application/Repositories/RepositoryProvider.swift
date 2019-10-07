//
//  RepositoryProvider.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Domain

public class RepositoryProvider: Domain.RepositoryProvider {

    // MARK: Initializers

    public init() {
        
    }

    // MARK: RepositoryProvider

    public func makeCommentsRepository() -> Domain.CommentsRepository {
        return CommentsRepository(database: Database.default, network: NetworkManager(connection: PersistentConnection.default))
    }

    public func makePostsRepository() -> Domain.PostsRepository {
        return PostsRepository(database: Database.default, network: NetworkManager(connection: PersistentConnection.default))
    }

    public func makeUsersRepository() -> Domain.UsersRepository {
        return UsersRepository(database: Database.default, network: NetworkManager(connection: PersistentConnection.default))
    }
}
