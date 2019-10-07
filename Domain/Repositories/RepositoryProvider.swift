//
//  RepositoryProvider.swift
//  Domain
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

public protocol RepositoryProvider {
    func makeCommentsRepository() -> CommentsRepository
    func makePostsRepository() -> PostsRepository
    func makeUsersRepository() -> UsersRepository
}
