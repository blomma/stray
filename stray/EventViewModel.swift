import Foundation

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

class EventViewModel: CoreDataInjected, StateInjected {
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


	fileprivate var calendar = Calendar.autoupdatingCurrent

	var selectedEventID: URL? {
		get { return state.selectedEventID }
	}

	/// Sync exeution
	func setup() {
		guard let url = state.selectedEventID else {
			updateStart(with: nil)
			updateStop(with: nil)
			updateRunning(from: nil, to: nil)

			tag = nil

			isRunning = false

			return
		}

		let result: Result<Event> = fetch(forURIRepresentation: url, inContext: persistentContainer.viewContext)
		guard let event: Event = result.value else {
			// TODO: Error handling
			fatalError("\(result.error)")
		}

		updateStart(with: event.startDate)
		updateStop(with: event.stopDate)

		state.selectedEventID = url
		tag = event.inTag?.name
		isRunning = event.stopDate == nil
	}

	func toggleEventRunning() {
		if isRunning {
			stopEvent()
		} else {
			startEvent()
		}
	}

	private func startEvent() {
		let startDate = Date()

		let event = Event(inContext: persistentContainer.viewContext)
		event.startDate = startDate

		self.state.selectedEventID = event.objectID.uriRepresentation()

		updateStart(with: startDate)
		updateStop(with: nil)

		tag = nil
		isRunning = true
	}

	private func stopEvent() {
		guard let id = state.selectedEventID else {
			// TODO Error handling
			fatalError("Missing selectedEventID")
		}

		let stopDate = Date()
		let result: Result<Event> = fetch(forURIRepresentation: id, inContext: persistentContainer.viewContext)
		guard let event: Event = result.value else {
			fatalError("\(result.error)")
		}
		event.stopDate = stopDate

		updateStop(with: stopDate)

		isRunning = false
	}

	func updateStart(with date: Date?) {
		startDate = date
		guard let date = date else {
			start = Start()

			return
		}

		guard let id = self.state.selectedEventID else {
			// TODO Error handling
			fatalError("Missing selectedEventID")
		}

		let result: Result<Event> = fetch(forURIRepresentation: id, inContext: persistentContainer.viewContext)
		guard let event: Event = result.value else {
			fatalError("\(result.error)")
		}
		event.startDate = date

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

	func updateStop(with date: Date?) {
		stopDate = date

		guard let date = date else {
			stop = Stop()

			return
		}

		guard let id = self.state.selectedEventID else {
			// TODO Error handling
			fatalError("Missing selectedEventID")
		}

		let result: Result<Event> = fetch(forURIRepresentation: id, inContext: persistentContainer.viewContext)
		guard let event: Event = result.value else {
			fatalError("\(result.error)")
		}
		event.stopDate = stopDate

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
