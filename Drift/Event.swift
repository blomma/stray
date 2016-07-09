import Foundation
import CoreData

final class Event: NSManagedObject {
    convenience init(_ context: NSManagedObjectContext,
                startDate: Date,
                guid: String? = UUID().uuidString,
                stopDate: Date? = nil,
                inTag: Tag? = nil)
    {
        guard let entity = NSEntityDescription.entity(forEntityName: self.dynamicType.entityName, in: context) else {
            fatalError("Unable to create entity for Event")
        }
        
        self.init(entity: entity, insertInto: context)
        
        self.startDate = startDate
        self.guid = guid
        self.stopDate = stopDate
        self.inTag = inTag
    }
}
