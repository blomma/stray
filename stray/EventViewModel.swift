import Foundation
import CoreData
import CloudKit

struct Start {
	let time: String
	let day: String
	let month: String
	let year: String

	init(time: String = "", day: String = "", month: String = "", year: String = "") {
		self.time = time
		self.day = day
		self.month = month
		self.year = year
	}
}

struct Stop {
	let time: String
	let day: String
	let month: String
	let year: String

	init(time: String = "", day: String = "", month: String = "", year: String = "") {
		self.time = time
		self.day = day
		self.month = month
		self.year = year
	}
}

struct Running {
	let minute: String
	let hour: String

	init(minute: String = "", hour: String = "") {
		self.minute = minute
		self.hour = hour
	}
}

struct IsRunning {
	let isRunning: Bool
	let startDate: Date?
	let stopDate: Date?
	let startStop: String

	init(isRunning: Bool = false, startDate: Date? = nil, stopDate: Date? = nil, startStop: String = "") {
		self.isRunning = isRunning
		self.startDate = startDate
		self.stopDate = stopDate
		self.startStop = startStop
	}
}

class EventViewModel: CoreDataStackInjected, StateInjected, CloudKitStackInjected {
	private var startDate: Date?
	private var start: Start = Start() {
		didSet {
			startDidUpdate?(start)
		}
	}
	var startDidUpdate: ((_ value: Start) -> Void)?


	private var stopDate: Date?
	private var stop: Stop = Stop() {
		didSet {
			stopDidUpdate?(stop)
		}
	}
	var stopDidUpdate: ((_ value: Stop) -> Void)?


	private var running: Running = Running() {
		didSet {
			runningDidUpdate?(running)
		}
	}
	var runningDidUpdate: ((_ value: Running) -> Void)?


	private var tag: String? {
		didSet {
			tagDidUpdate?(tag)
		}
	}
	var tagDidUpdate: ((_ tag: String?) -> Void)?


	private var isRunning: Bool = false {
		didSet {
			isRunningDidUpdate?(
				IsRunning(
					isRunning: isRunning,
					startDate: startDate,
					stopDate: stopDate,
					startStop: isRunning ? "STOP" : "START"
			))
		}
	}
	var isRunningDidUpdate: ((_ value: IsRunning) -> Void)?


	private var calendar = Calendar.autoupdatingCurrent
	var selectedEventID: URL?
	
	
	var observer: NSObjectProtocol?
	
	/// Sync exeution
	func setup() {
		observer = NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextDidSave, object: persistentContainer.viewContext, queue: nil) { (notification: Notification) in
			guard let changes = notification.userInfo else {
				return
			}
			
			var inserted: [CKRecord]? = nil
			if let i = changes[NSInsertedObjectsKey] as? Set<Event>, i.count > 0 {
				inserted = i.map { $0.record() }
			}
			
			var updated: [CKRecord]? = nil
			if let u = changes[NSUpdatedObjectsKey] as? Set<Event>, u.count > 0 {
				updated = u.map { $0.record() }
			}
			
			var deleted: [CKRecordID]? = nil
			if let d = changes[NSDeletedObjectsKey] as? Set<Event>, d.count > 0 {
				deleted = d.map { $0.recordID() }
			}
			
			self.cloudKitStack.sync(insertedRecords: inserted, updatedRecords: updated, deletedRecords: deleted)
		}
		
		guard let id = state.selectedEventID else {
			updateStart(with: nil)
			updateStop(with: nil)
			updateRunning(from: nil, to: nil)

			tag = nil
			isRunning = false
			selectedEventID = nil

			return
		}

		let result: Result<Event> = fetch(forURIRepresentation: id, inContext: persistentContainer.viewContext)
		guard let event: Event = result.value else {
			// TODO: Error handling
			fatalError("\(String(describing: result.error))")
		}

		updateStart(with: event.startDate)
		updateStop(with: event.stopDate)

		tag = event.tag
		isRunning = event.stopDate == nil
		selectedEventID = id
	}
	
	deinit {
		if let observer = observer {
			NotificationCenter.default.removeObserver(observer)
		}
	}
	
	func toggleEventRunning() {
		if isRunning {
			stopEvent()
		} else {
			startEvent()
		}
	}

	private func startEvent() {
		selectedEventID = nil

		let startDate = Date()
		let context = persistentContainer.viewContext

		let event = Event(inContext: context)
		event.startDate = startDate

		let result = save(context: context)
		if let error = result.error {
			fatalError("\(error)")
		}
		
		updateStart(with: startDate)
		updateStop(with: nil)

		state.selectedEventID = event.objectID.uriRepresentation()
		selectedEventID = state.selectedEventID

		tag = nil
		isRunning = true
	}

	private func stopEvent() {
		guard (state.selectedEventID != nil) else {
			// TODO Error handling
			fatalError("Missing selectedEventID")
		}

		let stopDate = Date()
		updateStop(with: stopDate)

		isRunning = false
	}

	func updateStart(with date: Date?, isTransforming: Bool = false) {
		startDate = date

		guard let date = date else {
			start = Start()

			return
		}

		if let id = selectedEventID, !isTransforming {
			let context = persistentContainer.viewContext

			let result: Result<Event> = fetch(forURIRepresentation: id, inContext: context)
			guard let event: Event = result.value else {
				fatalError("\(String(describing: result.error))")
			}
			event.startDate = date
			
			let saveResult = save(context: context)
			if let error = saveResult.error {
				fatalError("\(error)")
			}
		}

		let unitFlags: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
		let components: DateComponents = calendar.dateComponents(unitFlags, from: date)
		if let minute = components.minute,
			let hour = components.hour,
			let day = components.day,
			let month = components.month,
			let year = components.year
		{
			let index = month - 1
			let shortMonth = self.calendar.shortStandaloneMonthSymbols[index]

			start = Start(
				time: String(format: "%02ld:%02ld", hour, minute),
				day: String(format: "%02ld", day),
				month: shortMonth,
				year: String(format: "%04ld", year))
		}

		updateRunning(from: startDate, to: stopDate != nil ? stopDate! : Date())
	}

	func updateStop(with date: Date?, isTransforming: Bool = false) {
		stopDate = date

		guard let date = date else {
			stop = Stop()

			return
		}

		if let id = selectedEventID, !isTransforming {
			let context = persistentContainer.viewContext

			let result: Result<Event> = fetch(forURIRepresentation: id, inContext: context)
			guard let event: Event = result.value else {
				fatalError("\(String(describing: result.error))")
			}
			event.stopDate = stopDate

			let saveResult = save(context: context)
			if let error = saveResult.error {
				fatalError("\(error)")
			}
		}

		let unitFlags: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
		let components: DateComponents = calendar.dateComponents(unitFlags, from: date)
		if let minute = components.minute,
			let hour = components.hour,
			let day = components.day,
			let month = components.month,
			let year = components.year
		{
			let index = month - 1
			let shortMonth = self.calendar.shortStandaloneMonthSymbols[index]

			stop = Stop(
				time: String(format: "%02ld:%02ld", hour, minute),
				day: String(format: "%02ld", day),
				month: shortMonth,
				year: String(format: "%04ld", year))
		}

		updateRunning(from: startDate, to: stopDate)
	}

	func updateRunning(from startDate: Date?, to stopDate: Date?) {
		guard let startDate = startDate, let stopDate = stopDate else {
			running = Running(minute: "00", hour: "00")

			return
		}

		let unitFlags: Set<Calendar.Component> = [.hour, .minute]
		let components: DateComponents = calendar.dateComponents(unitFlags, from: startDate, to: stopDate)

		if let minute = components.minute,
			let hour = components.hour
		{
			let isFuture: Bool = hour < 0 || minute < 0
			running = Running(
				minute: String(format:"%02ld", abs(minute)),
				hour: isFuture ? String(format:"-%02ld", abs(hour)) : String(format:"%02ld", abs(hour))
			)
		}
	}
}
