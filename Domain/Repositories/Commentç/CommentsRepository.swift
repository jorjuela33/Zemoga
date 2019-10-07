//
//  CommentsRepository.swift
//  Domain
//
//  Created by Jorge Orjuela on 10/4/19.
//

import RxSwift

public protocol CommentsRepository {
    func observeChanges(forPostWithID postID: Int64) -> Observable<[Comment]>
    func retrieveComments(forPostWithID postID: Int64) -> Single<[Comment]>
}

