import Foundation

struct StartComponents {
	let minute: Int
	let hour: Int
	let day: Int
	let month: Int
	let year: Int

	init(minute: Int = 0, hour: Int = 0, day: Int = 0, month: Int = 0, year: Int = 0) {
		self.minute = minute
		self.hour = hour
		self.day = day
		self.month = month
		self.year = year
	}
}

struct StopComponents {
	let minute: Int
	let hour: Int
	let day: Int
	let month: Int
	let year: Int

	init(minute: Int = 0, hour: Int = 0, day: Int = 0, month: Int = 0, year: Int = 0) {
		self.minute = minute
		self.hour = hour
		self.day = day
		self.month = month
		self.year = year
	}
}

struct RunningComponents {
	let minute: Int
	let hour: Int

	init(minute: Int = 0, hour: Int = 0) {
		self.minute = minute
		self.hour = hour
	}
}

class EventViewModel: CoreDataInjected {
	private var startDate: Date?
	var start: StartComponents = StartComponents() {
		didSet {
			startDidUpdate?(start)
		}
	}
	var startDidUpdate: ((_ start: StartComponents) -> Void)?


	private var stopDate: Date?
	var stop: StopComponents = StopComponents() {
		didSet {
			stopDidUpdate?(stop)
		}
	}
	var stopDidUpdate: ((_ stop: StopComponents) -> Void)?


	private var running: RunningComponents = RunningComponents() {
		didSet {
			runningDidUpdate?(running)
		}
	}
	var runningDidUpdate: ((_ running: RunningComponents) -> Void)?


	private var tag: String? {
		didSet {
			tagDidUpdate?(tag)
		}
	}
	var tagDidUpdate: ((_ tag: String?) -> Void)?


	private var isRunning: Bool = false {
		didSet {
			isRunningDidUpdate?(isRunning, startDate, stopDate)
		}
	}
	var isRunningDidUpdate: ((_ isRunning: Bool, _ startDate: Date?, _ stopDate: Date?) -> Void)?


	fileprivate var calendar = Calendar.autoupdatingCurrent
	var selectedEventID: URL?


	/// Sync exeution
	func setup() {
		guard let url = State().selectedEventID else {
			updateStart(with: nil)
			updateStop(with: nil)

			selectedEventID = nil

			tag = nil

			isRunning = false

			return
		}

		let result: Result<Event> = fetch(url: url, inContext: persistentContainer.viewContext)

		do {
			let event: Event = try result.resolve()

			updateStart(with: event.startDate)
			updateStop(with: event.stopDate)

			selectedEventID = url

			tag = event.inTag?.name

			isRunning = event.stopDate == nil
		} catch let error {
			// TODO: Error handling
			DLog("\(error)")
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
		let event = Event(inContext: persistentContainer.viewContext)
		event.startDate = Date()

		// TODO: Only needed to get permanent object id, maybe a better way to do this
		do {
			try save(context: persistentContainer.viewContext)
		} catch {
			// TODO: Error handling
		}

		selectedEventID = event.objectID.uriRepresentation()

		updateStart(with: event.startDate)
		updateStop(with: event.stopDate)

		tag = nil

		isRunning = true
	}

	private func stopEvent() {
		// We have a running event
		guard let id = selectedEventID else {
			// TODO Error handling
			fatalError("Missing selectedEventID")
		}

		let result: Result<Event> = fetch(url: id, inContext: persistentContainer.viewContext)
		do {
			let event: Event = try result.resolve()

			event.stopDate = Date()
			updateStop(with: event.stopDate)

			isRunning = false
		}
		catch let e as NSError {
			// TODO: Error handling
			fatalError(e.localizedDescription)
		}
	}

	func updateStart(with date: Date?) {
		startDate = date

		guard let date = date else {
			start = StartComponents()
			return
		}

		let unitFlags: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
		let components: DateComponents = calendar.dateComponents(unitFlags, from: date)
		if let minute = components.minute,
			let hour = components.hour,
			let day = components.day,
			let month = components.month,
			let year = components.year
		{
			start = StartComponents(
				minute: minute,
				hour: hour,
				day: day,
				month: month,
				year: year)
		}

		let runningDate: Date = stopDate != nil ? stopDate! : Date()
		updateRunning(with: runningDate)
	}

	func updateStop(with date: Date?) {
		stopDate = date

		guard let date = date else {
			stop = StopComponents()
			return
		}

		let unitFlags: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
		let components: DateComponents = calendar.dateComponents(unitFlags, from: date)
		if let minute = components.minute,
			let hour = components.hour,
			let day = components.day,
			let month = components.month,
			let year = components.year
		{
			stop = StopComponents(
				minute: minute,
				hour: hour,
				day: day,
				month: month,
				year: year)
		}

		updateRunning(with: date)
	}

	func updateRunning(with date: Date) {
		guard let startDate = startDate else {
			// We were called without a startDate
			// this is never right
			// TODO: Error handling
			fatalError()
		}

		let unitFlags: Set<Calendar.Component> = [.hour, .minute]
		let components: DateComponents = calendar.dateComponents(unitFlags, from: startDate, to: date)

		if let minute = components.minute,
			let hour = components.hour
		{
			running = RunningComponents(
				minute: minute,
				hour: hour)
		}
	}
}
