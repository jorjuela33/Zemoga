//
//  UsersRepository.swift
//  Domain
//
//  Created by Jorge Orjuela on 10/5/19.
//

import RxSwift

public protocol UsersRepository {
    func observeChanges(forUserWithID userID: Int64) -> Observable<[User]>
    func retrieveUser(withID userID: Int64) -> Single<User>
}
