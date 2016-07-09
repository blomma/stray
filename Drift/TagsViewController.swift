import UIKit
import CoreData

class TagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, TagCellDelegate {
	@IBOutlet weak var tableView: UITableView!

    private var userReorderingCells = false
    private var selectedTag: Tag?
    private var maxSortOrderIndex = 0

	var eventGuid: String?

    private var fetchedResultsController: NSFetchedResultsController<Tag>?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        let request = FetchRequest<Tag>(context: defaultCoreDataStack.managedObjectContext)
        do {
            let tag = try request.fetchFirst(Predicate(format: "sortIndex == max(sortIndex)"))
            if let sortIndex = tag.sortIndex as? Int {
                maxSortOrderIndex = sortIndex
            }
        } catch {
            // TODO: Errorhandling
        }


        let fetchRequest = NSFetchRequest<Tag>(entityName: Tag.entityName)
        fetchRequest.sortDescriptors = [SortDescriptor(key: "sortIndex", ascending: false)]
        fetchRequest.fetchBatchSize = 20

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: defaultCoreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)

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

        if let guid = eventGuid {
            let request = FetchRequest<Event>(context: defaultCoreDataStack.managedObjectContext)
            do {
                let event = try request.fetchFirstWhere("guid", value: guid)
                if let tag = event.inTag,
                    let indexPath = controller.indexPath(forObject: tag) {
                        selectedTag = tag
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

            if selectedTag?.guid == tag.guid {
                showSelectMark(cell)
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
        _ = Tag(defaultCoreDataStack.managedObjectContext, sortIndex: maxSortOrderIndex)
        maxSortOrderIndex += 1
		do {
			try saveContextAndWait(defaultCoreDataStack.managedObjectContext)
		} catch {
			// TODO: Errorhandling
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
				try saveContextAndWait(defaultCoreDataStack.managedObjectContext)
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
extension TagsViewController {
    @objc(tableView:didSelectRowAtIndexPath:) func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        if let selectedTag = selectedTag,
            let indexPath = fetchedResultsController?.indexPath(forObject: selectedTag),
            let cell = tableView.cellForRow(at: indexPath) as? TagCell {
                hideSelectMark(cell)
        }

        if let guid = eventGuid,
            let fetchedResultsController = fetchedResultsController {
                let request = FetchRequest<Event>(context: defaultCoreDataStack.managedObjectContext)
                do {
                    let event = try request.fetchFirstWhere("guid", value: guid)
					let tag = fetchedResultsController.object(at: indexPath)
					if let inTag = event.inTag where inTag.isEqual(tag) {
						event.inTag = nil
					} else {
						event.inTag = tag
					}

					do {
						try saveContextAndWait(defaultCoreDataStack.managedObjectContext)
					} catch {
						// TODO: Errorhandling
					}

					self.performSegue(withIdentifier: "unwindToPresenter", sender: self)
                } catch {
                    // TODO: Errorhandling
                }
		}
	}

	@objc(tableView:commitEditingStyle:forRowAtIndexPath:) func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete,
            let fetchedResultsController = fetchedResultsController
		{
			let tag = fetchedResultsController.object(at: indexPath)
			deleteObjects([tag], inContext: defaultCoreDataStack.managedObjectContext)
			do {
				try saveContextAndWait(defaultCoreDataStack.managedObjectContext)
			} catch {
				// TODO: Errorhandling
			}
		}
    }


	@objc(tableView:canMoveRowAtIndexPath:) func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

	@objc(tableView:moveRowAtIndexPath:toIndexPath:) func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath == destinationIndexPath {
            return
        }

        if let fetchedResultsController = fetchedResultsController
		{
			let tag = fetchedResultsController.object(at: sourceIndexPath)
			userReorderingCells = true
			tag.sortIndex = (destinationIndexPath as NSIndexPath).row
			do {
				try saveContextAndWait(defaultCoreDataStack.managedObjectContext)
			} catch {
				// TODO: Errorhandling
			}
			userReorderingCells = false
		}
    }
}

// MARK: - UITableViewDataSource
extension TagsViewController {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo = fetchedResultsController?.sections?[section] {
            return sectionInfo.numberOfObjects
        }

        return 0
    }

	@objc(numberOfSectionsInTableView:) func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }

	@objc(tableView:cellForRowAtIndexPath:) func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagCellIdentifier", for: indexPath)

        if let cell = cell as? TagCell {
            configureCell(cell, atIndexPath:indexPath)
        }

        return cell
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TagsViewController {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if userReorderingCells {
            return
        }

        tableView.beginUpdates()
    }

    @objc(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:) func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: AnyObject, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
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
