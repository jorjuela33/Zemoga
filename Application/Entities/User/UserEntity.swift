//
//  UserEntity.swift
//  Application
//
//  Created by Jorge Orjuela on 10/5/19.
//

import Domain

struct UserEntity: Codable {
    let id: Int64
    let email: String
    let name: String
    let phone: String
    let website: String
}

extension UserEntity: DatabaseEntity {

    // MARK: DatabaseEntity

    static var entityName: String {
        return "User"
    }

    static func map(from entity: UserManagedObject) -> UserEntity {
        return UserEntity(id: entity.id, email: entity.email, name: entity.name, phone: entity.phone, website: entity.website)
    }

    func update(_ entity: UserManagedObject) {
        entity.id = id
        entity.email = email
        entity.name = name
        entity.phone = phone
        entity.website = website
    }
}

extension UserEntity: DomainTypeConvertible {

    // MARK: DomainTypeConvertible

    func asDomain() -> User {
        return User(id: id, email: email, name: name, phone: phone, website: website)
    }
}
