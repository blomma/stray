import UIKit
import CoreData

class EventsViewController: UIViewController, EventCellDelegate, CoreDataStackInjected, StateInjected {

    @IBOutlet weak var tableView: UITableView!

	private let shortStandaloneMonthSymbols: [String] = DateFormatter().shortStandaloneMonthSymbols
    private let calendar = Calendar.autoupdatingCurrent

	private var fetchedResultsController: NSFetchedResultsController<Event>?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
		let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        fetchRequest.fetchBatchSize = 20

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)

        let error: NSErrorPointer? = nil
        do {
            try controller.performFetch()
        } catch let error1 as NSError {
            error??.pointee = error1
			print("Unresolved error \(String(describing: error))")
            exit(-1)
        }

        controller.delegate = self
        fetchedResultsController = controller

        if let id = state.selectedEventID {
			let result: Result<Event> = fetch(forURIRepresentation: id, inContext: persistentContainer.viewContext)
			guard let event: Event = result.value else {
				// TODO: Error handling
				fatalError("\(String(describing: result.error))")
			}

			if let indexPath = fetchedResultsController?.indexPath(forObject: event) {
				tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
				tableView.scrollToRow(at: indexPath, at: .none, animated: true)
			}
        }
    }

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "segueToTagsFromEvents",
			let controller = segue.destination as? TagsViewController,
			let cell = sender as? UITableViewCell,
			let indexPath = tableView?.indexPath(for: cell),
			let event = fetchedResultsController?.object(at: indexPath)
		{
			controller.eventID = event.objectID.uriRepresentation()
		}
	}

    private func configureCell(_ cell: EventCell, atIndexPath: IndexPath) -> Void {
        if let event = fetchedResultsController?.object(at: atIndexPath) {
			if state.selectedEventID == event.objectID.uriRepresentation() {
				showSelectMark(cell)
			}

            if let name = event.tag {
                let attributedString = NSAttributedString(string: name, attributes:
					[NSAttributedStringKey.font: UIFont(name: "Helvetica Neue", size: 14.0)!])
                cell.tagButton.setAttributedTitle(attributedString, for: UIControlState())
            }

            // StartTime
            let startTimeFlags: Set<Calendar.Component> = [.minute, .hour, .day, .month, .year]
            let startTimeComponents = calendar.dateComponents(startTimeFlags, from: event.startDate)

			if let hour = startTimeComponents.hour, let minute = startTimeComponents.minute,
				let day = startTimeComponents.day, let year = startTimeComponents.year, let month = startTimeComponents.month {

				cell.eventStartTime.text = String(format: "%02ld:%02ld", hour, minute)
				cell.eventStartDay.text = String(format: "%02ld", day)
				cell.eventStartYear.text = String(format: "%04ld", year)

				let startMonth = shortStandaloneMonthSymbols[month - 1]
				cell.eventStartMonth.text = startMonth
			}

            // EventTime
            let stopDate = event.stopDate != nil ? event.stopDate! : Date()
            let eventTimeFlags: Set<Calendar.Component> = [.minute, .hour]
			let eventTimeComponents = calendar.dateComponents(eventTimeFlags, from: event.startDate, to: stopDate)

			if let hour = eventTimeComponents.hour, let minute = eventTimeComponents.minute {
				cell.eventTimeHours.text = String(format: "%02ld", hour)
				cell.eventTimeMinutes.text = String(format: "%02ld", minute)
			}

            // StopTime
            if let stopDate = event.stopDate {
                let stopTimeFlags: Set<Calendar.Component> = [.minute, .hour, .day, .month, .year]
                let stopTimeComponents = calendar.dateComponents(stopTimeFlags, from: stopDate)

				if let hour = stopTimeComponents.hour,
					let minute = stopTimeComponents.minute,
					let day = stopTimeComponents.day,
					let year = stopTimeComponents.year,
					let month = stopTimeComponents.month {

					cell.eventStopTime.text = String(format: "%02ld:%02ld", hour, minute)
					cell.eventStopDay.text = String(format: "%02ld", day)
					cell.eventStopYear.text = String(format: "%04ld", year)

					let stopMonth = shortStandaloneMonthSymbols[month - 1]
					cell.eventStopMonth.text = stopMonth
				}
            } else {
                cell.eventStopTime.text = ""
                cell.eventStopDay.text = ""
                cell.eventStopYear.text = ""
                cell.eventStopMonth.text = ""
            }

            cell.delegate = self
        }
    }

    @IBAction func prepareForUnwind(_ sender: UIStoryboardSegue) {
        DLog()
    }

	@IBAction func toggleEdit(_ sender: UIBarButtonItem) {
		if tableView.isEditing {
			tableView.setEditing(false, animated: true)
		} else {
			tableView.setEditing(true, animated: true)
		}
	}

	private func showSelectMark(_ cell: EventCell) {
		UIView.animate(withDuration: 0.3, animations: { () -> Void in
			cell.selectedMark.alpha = 1
		})
	}

	private func hideSelectMark(_ cell: EventCell) {
		UIView.animate(withDuration: 0.3, animations: { () -> Void in
			cell.selectedMark.alpha = 0
		})
	}
}

// MARK: - UITableViewDelegate
extension EventsViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)

		if let eventID = state.selectedEventID {
			let result: Result<Event> = fetch(forURIRepresentation: eventID, inContext: persistentContainer.viewContext)
			guard let event: Event = result.value else {
				fatalError("\(String(describing: result.error))")
			}

			if let oldIndexPath = fetchedResultsController?.indexPath(forObject: event), let cell = tableView.cellForRow(at: oldIndexPath) as? EventCell {
				hideSelectMark(cell)
			}
		}

		if let event = fetchedResultsController?.object(at: indexPath),
			let cell = tableView.cellForRow(at: indexPath) as? EventCell {
			showSelectMark(cell)

			state.selectedEventID = event.objectID.uriRepresentation()
		}
	}
}

// MARK: - UITableViewDataSource
extension EventsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo = fetchedResultsController?.sections?[section] {
            return sectionInfo.numberOfObjects
        }

        return 0
    }

	func numberOfSections(in tableView: UITableView) -> Int {
		return fetchedResultsController?.sections?.count ?? 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "EventCellIdentifier", for: indexPath)

		if let cell = cell as? EventCell {
			configureCell(cell, atIndexPath: indexPath)
		}

		return cell
	}

	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == UITableViewCellEditingStyle.delete {
			if let event = fetchedResultsController?.object(at: indexPath) {
				if state.selectedEventID == event.objectID.uriRepresentation() {
					state.selectedEventID = nil
				}

				remove(object: event, inContext: persistentContainer.viewContext)
			}
		}
	}
}

// MARK: - EventCellDelegate
extension EventsViewController {
    func didPressTag(_ cell: EventCell) {
        performSegue(withIdentifier: "segueToTagsFromEvents", sender: cell)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension EventsViewController: NSFetchedResultsControllerDelegate {
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView?.beginUpdates()
	}

	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
		case .insert:
			tableView?.insertRows(at: [newIndexPath!], with: .fade)
		case .delete:
			tableView?.deleteRows(at: [indexPath!], with: .fade)
		case .update:
			if let cell = tableView?.cellForRow(at: indexPath!) as? EventCell {
				configureCell(cell, atIndexPath: indexPath!)
			}
		case .move:
			tableView?.deleteRows(at: [indexPath!], with: .fade)
			tableView?.insertRows(at: [newIndexPath!], with: .fade)
		}
	}

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.endUpdates()
    }
}

