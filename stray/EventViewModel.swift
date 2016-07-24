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
			startDidUpdate?(start: start)
		}
	}
	var startDidUpdate: ((start: StartComponents) -> Void)?


	var stopDate: Date?
	var stop: StopComponents = StopComponents() {
		didSet {
			stopDidUpdate?(stop: stop)
		}
	}
	var stopDidUpdate: ((stop: StopComponents) -> Void)?


	private var running: RunningComponents = RunningComponents() {
		didSet {
			runningDidUpdate?(running: running)
		}
	}
	var runningDidUpdate: ((running: RunningComponents) -> Void)?


	var tag: String? {
		didSet {
			tagDidUpdate?(tag: tag)
		}
	}
	var tagDidUpdate: ((tag: String?) -> Void)?


	var isRunning: Bool = false {
		didSet {
			isRunningDidUpdate?(isRunning: isRunning, startDate: startDate, stopDate: stopDate)
		}
	}
	var isRunningDidUpdate: ((isRunning: Bool, startDate: Date?, stopDate: Date?) -> Void)?


	private let calendar = Calendar.autoupdatingCurrent
	private let shortStandaloneMonthSymbols: Array = DateFormatter().shortStandaloneMonthSymbols

	var selectedEventID: URL?


	func setup() {
		if let url = State().selectedEventID {
			let result: Result<Event, FetchError> = fetch(url: url, inContext: persistentContainer.viewContext)
			do {
				let event = try result.dematerialize()

				updateStart(with: event.startDate)
				updateStop(with: event.stopDate)

				selectedEventID = url

				tag = event.inTag?.name

				isRunning = event.stopDate == nil
			} catch {
				// TODO: Error handling
			}
		} else {
			updateStart(with: nil)
			updateStop(with: nil)

			selectedEventID = nil

			tag = nil

			isRunning = false
		}
	}

	func startEvent() {
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

	func stopEvent() {
		// We have a running event
		guard let id = selectedEventID else {
			// TODO Error handling
			fatalError("Missing selectedEventID")
		}

		let result: Result<Event, FetchError> = fetch(url: id, inContext: persistentContainer.viewContext)

		do {
			let event = try result.dematerialize()

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

		let unitFlags: Calendar.Unit = [.year, .month, .day, .hour, .minute]
		let components: DateComponents = calendar.components(unitFlags, from: date)
		if let minute = components.minute,
			let hour = components.hour,
			let day = components.day,
			let month = components.month,
			let year = components.year
		{
			let index = month - 1
			let shortMonth = shortStandaloneMonthSymbols[index]

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

		let unitFlags: Calendar.Unit = [.year, .month, .day, .hour, .minute]
		let components: DateComponents = calendar.components(unitFlags, from: date)
		if let minute = components.minute,
			let hour = components.hour,
			let day = components.day,
			let month = components.month,
			let year = components.year
		{
			let index = month - 1
			let shortMonth = shortStandaloneMonthSymbols[index]

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

		let unitFlags: Calendar.Unit = [.hour, .minute]

		let components: DateComponents = calendar.components(unitFlags, from: startDate, to: date)

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
