import UIKit
import CoreData

class TagsViewController: UIViewController, TagCellDelegate, CoreDataStackInjected {
	@IBOutlet weak var tableView: UITableView!

    private var userReorderingCells = false
    private var selectedTagID: URL?
	private var maxSortOrderIndex :Int = 0

	var eventID: URL?

    var fetchedResultsController: NSFetchedResultsController<Tag>?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
		let request: NSFetchRequest<Tag> = Tag.fetchRequest()
		request.predicate = NSPredicate(format: "sortIndex == max(sortIndex)")

		let result: Result<[Tag]> = fetch(request: request, inContext: persistentContainer.viewContext)
		if result.isError {
			fatalError("\(String(describing: result.error))")
		}
		
		if let tag = result.value?.first {
			maxSortOrderIndex = tag.sortIndex
		}

		let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: false)]
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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    private func configureCell(_ cell: TagCell, atIndexPath: IndexPath) -> Void {
        if let tag = fetchedResultsController?.object(at: atIndexPath) {
			cell.delegate = self

            cell.name.text = tag.name
			cell.name.isEnabled = tableView.isEditing

			if let selectedTagID = selectedTagID {
				if selectedTagID == tag.objectID.uriRepresentation() {
					showSelectMark(cell)
				}
			}
        }
    }

	@IBAction func toggleEdit(_ sender: UIBarButtonItem) {
		if tableView.isEditing {
			tableView.setEditing(false, animated: true)
		} else {
			tableView.setEditing(true, animated: true)
		}

		for cell in tableView.visibleCells {
			if let c = cell as? TagCell {
				c.name.isEnabled = tableView.isEditing
			}
		}
	}

	@IBAction func addTag(_ sender: UIBarButtonItem) {
		let tag = Tag(context: persistentContainer.viewContext)
		tag.sortIndex = maxSortOrderIndex
        maxSortOrderIndex += 1

		let saveResult = save(context: persistentContainer.viewContext)
		if saveResult.isError {
			// TODO: Error handling
			fatalError("\(String(describing: saveResult.error))")
		}

	}

    private func showSelectMark(_ cell: TagCell) {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            cell.selectedMark.alpha = 1
        })
    }

    private func hideSelectMark(_ cell: TagCell) {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            cell.selectedMark.alpha = 0
        })
    }
}

// MARK: - TagCellDelegate
extension TagsViewController {
	func didEndEditing(_ cell: TagCell) {
        if let fetchedResultsController = fetchedResultsController,
            let indexPath = tableView.indexPath(for: cell)
		{
			let tag = fetchedResultsController.object(at: indexPath)
			tag.name = cell.name.text

			let saveResult = save(context: persistentContainer.viewContext)
			if saveResult.isError {
				// TODO: Error handling
				fatalError("\(String(describing: saveResult.error))")
			}
		}
	}

	func shouldBeginEdit() -> Bool {
		return tableView.isEditing
	}
}

// MARK: - UITableViewDelegate
extension TagsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

		if let selectedTagID = selectedTagID {
			let result: Result<Tag> = fetch(forURIRepresentation: selectedTagID, inContext: persistentContainer.viewContext)
			guard let tag: Tag = result.value else {
				fatalError("\(String(describing: result.error))")
			}
			if let oldIndexPath = fetchedResultsController?.indexPath(forObject: tag),
				let cell = tableView.cellForRow(at: oldIndexPath) as? TagCell {
				hideSelectMark(cell)
			}
		}

        if let id = eventID,
			let fetchedResultsController = fetchedResultsController {
			let result: Result<Event> = fetch(forURIRepresentation: id, inContext: persistentContainer.viewContext)
			guard let event: Event = result.value else {
				fatalError("\(String(describing: result.error))")
			}

			let tag = fetchedResultsController.object(at: indexPath)
			event.tag = tag.name

			let saveResult = save(context: persistentContainer.viewContext)
			if saveResult.isError {
				fatalError("\(String(describing: saveResult.error))")
			}

			self.performSegue(withIdentifier: "unwindToPresenter", sender: self)
		}
	}
}

// MARK: - UITableViewDataSource
extension TagsViewController: UITableViewDataSource {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagCellIdentifier", for: indexPath)

        if let cell = cell as? TagCell {
            configureCell(cell, atIndexPath:indexPath)
        }

        return cell
    }

	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == UITableViewCellEditingStyle.delete,
			let fetchedResultsController = fetchedResultsController {
			let tag = fetchedResultsController.object(at: indexPath)
			remove(object: tag, inContext: persistentContainer.viewContext)

			let saveResult = save(context: persistentContainer.viewContext)
			if saveResult.isError {
				// TODO: Error handling
				fatalError("\(String(describing: saveResult.error))")
			}
		}
	}

	func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return true
	}

	func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		if sourceIndexPath == destinationIndexPath {
			return
		}

		if let fetchedResultsController = fetchedResultsController {
			let tag = fetchedResultsController.object(at: sourceIndexPath)
			userReorderingCells = true
			tag.sortIndex = destinationIndexPath.row

			let saveResult = save(context: persistentContainer.viewContext)
			if saveResult.isError {
				// TODO: Error handling
				fatalError("\(String(describing: saveResult.error))")
			}

			userReorderingCells = false
		}
	}
}

// MARK: - NSFetchedResultsControllerDelegate
extension TagsViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if userReorderingCells {
            return
        }

        tableView.beginUpdates()
    }

	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		if userReorderingCells {
			return
		}

		switch type {
		case .insert:
			tableView.insertRows(at: [newIndexPath!], with: .fade)
		case .delete:
			tableView.deleteRows(at: [indexPath!], with: .fade)
		case .update:
			if let cell = tableView.cellForRow(at: indexPath!) as? TagCell {
				configureCell(cell, atIndexPath: indexPath!)
			}
		case .move:
			tableView.moveRow(at: indexPath!, to: newIndexPath!)
		}
	}

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if userReorderingCells {
            return
        }

        tableView.endUpdates()
    }
}
