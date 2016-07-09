import Foundation
import CoreData

final class Tag: NSManagedObject {
    convenience init(_ context: NSManagedObjectContext,
                guid: String? = UUID().uuidString,
                name: String? = nil,
                sortIndex: NSNumber? = nil,
                heldByEvents: NSSet? = nil)
    {
        guard let entity = NSEntityDescription.entity(forEntityName: self.dynamicType.entityName, in: context) else {
            fatalError("Unable to create entity for Tag")
        }
        
        self.init(entity: entity, insertInto: context)
        
        self.guid = guid
        self.name = name
        self.sortIndex = sortIndex
        self.heldByEvents = heldByEvents
    }
}
