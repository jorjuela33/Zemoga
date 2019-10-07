//
//  PostsRepositories.swift
//  Domain
//
//  Created by Jorge Orjuela on 10/4/19.
//

import RxSwift

public enum Filter {
    case none
    case favorites
    case notFavorites
}

public protocol PostsRepository {
    func deleteAllPosts() -> Completable
    func deletePost(withID postID: Int64) -> Completable
    func markPost(_ post: Post, asFavorite favorite: Bool) -> Completable
    func observeChanges(forPostWithID postID: Int64, filteringBy filter: Filter) -> Observable<[Post]>
    func retrievePosts() -> Single<[Post]>
}

public extension PostsRepository {
    func observeChanges(forPostWithID postID: Int64 = 0, filteringBy filter: Filter = .none) -> Observable<[Post]> {
        return observeChanges(forPostWithID: postID, filteringBy: filter)
    }
}
