import Foundation
import CoreData

final class Event: NSManagedObject {
    convenience init(_ context: NSManagedObjectContext,
                startDate: NSDate,
                guid: String? = NSUUID().UUIDString,
                stopDate: NSDate? = nil,
                inTag: Tag? = nil)
    {
        guard let entity = NSEntityDescription.entityForName(self.dynamicType.entityName, inManagedObjectContext: context) else {
            fatalError("Unable to create entity for Event")
        }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.startDate = startDate
        self.guid = guid
        self.stopDate = stopDate
        self.inTag = inTag
    }
}
