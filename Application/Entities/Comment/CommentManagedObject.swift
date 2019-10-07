//
//  CommentManagedObject.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import CoreData.NSManagedObject

final class CommentManagedObject: NSManagedObject {
    @NSManaged var id: Int64
    @NSManaged var body: String
    @NSManaged var email: String
    @NSManaged var name: String
    @NSManaged var postID: Int64
}
