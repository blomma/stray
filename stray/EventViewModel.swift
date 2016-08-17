import Foundation

struct StartComponents {
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

struct StopComponents {
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

struct RunningComponents {
	let minute: String
	let hour: String

	init(minute: String = "", hour: String = "") {
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


	private let calendar = Calendar.autoupdatingCurrent
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
			let index = month - 1
			let shortMonth = calendar.shortStandaloneMonthSymbols[index]

			start = StartComponents(
				time: String(format: "%02ld:%02ld", hour, minute),
				day: String(format: "%02ld", day),
				month: shortMonth,
				year: String(format: "%04ld", year))
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
			let index = month - 1
			let shortMonth = calendar.shortStandaloneMonthSymbols[index]

			stop = StopComponents(
				time: String(format: "%02ld:%02ld", hour, minute),
				day: String(format: "%02ld", day),
				month: shortMonth,
				year: String(format: "%04ld", year))
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
			var runningHours: String = String(format:"%02ld", hour)
			if hour < 0 || minute < 0 {
				runningHours = String(format:"-%@", runningHours)
			}

			running = RunningComponents(
				minute: String(format:"%02ld", minute),
				hour: runningHours)
		}
	}
}
