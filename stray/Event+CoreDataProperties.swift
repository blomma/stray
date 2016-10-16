import Foundation
import CoreData

extension Event {

    @NSManaged var startDate: Date
    @NSManaged var stopDate: Date?
    @NSManaged var inTag: Tag?
	@NSManaged var id: String

}
