import Foundation
import CoreData

extension Event {

	@NSManaged var tag: String?
	@NSManaged var startDate: Date
	@NSManaged var stopDate: Date?
	@NSManaged var id: String

}
