import UIKit
import CoreData

class TagsViewController: UIViewController, TagCellDelegate, CoreDataInjected {
	@IBOutlet weak var tableView: UITableView!

    private var userReorderingCells = false
    private var selectedTagID: URL?
	private var maxSortOrderIndex :Int64 = 0

	var eventID: URL?

    private var fetchedResultsController: NSFetchedResultsController<Tag>?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
		let request: NSFetchRequest<Tag> = Tag.fetchRequest()
		request.predicate = Predicate(format: "sortIndex == max(sortIndex)")
		let result: Result<Tag> = fetchFirst(request: request, inContext: persistentContainer.viewContext)
        do {
            let tag = try result.resolve()
			maxSortOrderIndex = tag.sortIndex
        } catch {
            // TODO: Errorhandling
        }


		let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        fetchRequest.sortDescriptors = [SortDescriptor(key: "sortIndex", ascending: false)]
        fetchRequest.fetchBatchSize = 20

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)

        let error: NSErrorPointer? = nil
        do {
            try controller.performFetch()
        } catch let error1 as NSError {
            error??.pointee = error1
            print("Unresolved error \(error)")
            exit(-1)
        }

        controller.delegate = self
        fetchedResultsController = controller

        if let id = eventID {
			let result: Result<Event> = fetch(url: id, inContext: persistentContainer.viewContext)
            do {
				let event: Event = try result.resolve()
                if let tag = event.inTag,
                    let indexPath = controller.indexPath(forObject: tag) {
                        selectedTagID = tag.objectID.uriRepresentation()
                        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                        tableView.scrollToRow(at: indexPath, at: .none, animated: true)
                }
            } catch {
                // TODO: Errorhandling
            }

        }
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
		do {
			try save(context: persistentContainer.viewContext)
		} catch {
			// TODO: Errorhandling
			print("*** ERROR: [\(#line)] \(#function) Error while executing fetch request:")
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
			do {
				try save(context: persistentContainer.viewContext)
			} catch {
				// TODO: Errorhandling
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
			let result: Result<Tag> = fetch(url: selectedTagID, inContext: persistentContainer.viewContext)
			do {
				let tag: Tag = try result.resolve()
				if let oldIndexPath = fetchedResultsController?.indexPath(forObject: tag),
					let cell = tableView.cellForRow(at: oldIndexPath) as? TagCell {
					hideSelectMark(cell)
				}
			} catch {
				// TODO
			}
		}

        if let id = eventID,
			let fetchedResultsController = fetchedResultsController {
			let result: Result<Event> = fetch(url: id, inContext: persistentContainer.viewContext)
			do {
				let event: Event = try result.resolve()
				let tag = fetchedResultsController.object(at: indexPath)

				if let inTag = event.inTag, inTag.isEqual(tag) {
					event.inTag = nil
				} else {
					event.inTag = tag
				}
				
				do {
					try save(context: persistentContainer.viewContext)
				} catch {
					// TODO: Errorhandling
				}

				self.performSegue(withIdentifier: "unwindToPresenter", sender: self)
			} catch {
				// TODO: Errorhandling
			}
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
			let fetchedResultsController = fetchedResultsController
		{
			let tag = fetchedResultsController.object(at: indexPath)
			remove(object: tag, inContext: persistentContainer.viewContext)
			do {
				try save(context: persistentContainer.viewContext)
			} catch {
				// TODO: Errorhandling
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

		if let fetchedResultsController = fetchedResultsController
		{
			let tag = fetchedResultsController.object(at: sourceIndexPath)
			userReorderingCells = true
			let i = destinationIndexPath.row
			tag.sortIndex = Int64(i)
			do {
				try save(context: persistentContainer.viewContext)
			} catch {
				// TODO: Errorhandling
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

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: AnyObject, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
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
