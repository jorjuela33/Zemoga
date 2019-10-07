//
//  PostManagedObject.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import CoreData.NSManagedObject

final class PostManagedObject: NSManagedObject {
    @NSManaged var id: Int64
    @NSManaged var body: String
    @NSManaged var isFavorite: Bool
    @NSManaged var read: Bool
    @NSManaged var title: String
    @NSManaged var userID: Int64
}
