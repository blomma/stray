import Foundation
import CoreData

final class Tag: NSManagedObject {
    convenience init(_ context: NSManagedObjectContext,
                guid: String? = NSUUID().UUIDString,
                name: String? = nil,
                sortIndex: NSNumber? = nil,
                heldByEvents: NSSet? = nil)
    {
        guard let entity = NSEntityDescription.entityForName(self.dynamicType.entityName, inManagedObjectContext: context) else {
            fatalError("Unable to create entity for Tag")
        }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.guid = guid
        self.name = name
        self.sortIndex = sortIndex
        self.heldByEvents = heldByEvents
    }
}
