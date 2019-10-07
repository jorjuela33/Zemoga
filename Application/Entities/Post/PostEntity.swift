//
//  PostEntity.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Domain

struct PostEntity: Codable {
    let id: Int64
    let body: String
    let isFavorite: Bool
    let read: Bool
    let title: String
    let userID: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case body
        case title
        case userID = "userId"
    }

    // MARK: Intizalizers

    init(id: Int64, body: String, isFavorite: Bool, read: Bool, title: String, userID: Int64) {
        self.id = id
        self.body = body
        self.isFavorite = isFavorite
        self.read = read
        self.title = title
        self.userID = userID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        body = try container.decode(String.self, forKey: .body)
        isFavorite = false
        read = false
        title = try container.decode(String.self, forKey: .title)
        userID = try container.decode(Int64.self, forKey: .userID)
    }
}

extension PostEntity: DatabaseEntity {

    // MARK: DatabaseEntity

    static var entityName: String {
        return "Post"
    }

    static func map(from entity: PostManagedObject) -> PostEntity {
        return PostEntity(
            id: entity.id,
            body: entity.body,
            isFavorite: entity.isFavorite,
            read: entity.read,
            title: entity.title,
            userID: entity.userID
        )
    }

    func update(_ entity: PostManagedObject) {
        entity.id = id
        entity.body = body
        entity.isFavorite = isFavorite
        entity.read = read
        entity.title = title
        entity.userID = userID
    }
}

extension PostEntity: DomainTypeConvertible {

    // MARK: DomainTypeConvertible

    func asDomain() -> Post {
        return Post(id: id, body: body, isFavorite: isFavorite, read: read, title: title, userID: userID)
    }
}
