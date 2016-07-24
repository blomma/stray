import Foundation
import CoreData

extension Tag {

    @NSManaged var name: String?
    @NSManaged var sortIndex: Int64
    @NSManaged var heldByEvents: NSSet?

}
