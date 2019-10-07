//
//  UserManagedObject.swift
//  Application
//
//  Created by Jorge Orjuela on 10/5/19.
//

import CoreData.NSManagedObject

final class UserManagedObject: NSManagedObject {
    @NSManaged var id: Int64
    @NSManaged var email: String
    @NSManaged var name: String
    @NSManaged var phone: String
    @NSManaged var website: String
}
