//
//  TagsTableViewController.swift
//  Drift
//
//  Created by Mikael Hultgren on 28/11/14.
//  Copyright (c) 2014 Artsoftheinsane. All rights reserved.
//

import UIKit
import CoreData
import JSQCoreDataKit

class TagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, DismissProtocol {
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var editBarButtonItem: UIBarButtonItem!
	@IBOutlet weak var addBarButtonItem: UIBarButtonItem!

    var didDismiss: Dismiss?

    var userReorderingCells: Bool = false
	let stack: CoreDataStack = defaultCoreDataStack()
    let state: State = State()

    var selectedEvent: Event?

	var maxSortOrderIndex: Int = 0

    private lazy var fetchedResultsController: NSFetchedResultsController = {
		var fetchRequest = NSFetchRequest(entityName: Tag.entityName)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: false)]
		fetchRequest.fetchBatchSize = 20

		var controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.stack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
		controller.delegate = self

		var error: NSErrorPointer = NSErrorPointer()
		if !controller.performFetch(error) {
			println("Unresolved error \(error)")
			exit(-1)
		}

		return controller
		}()

    override func viewDidLoad() {
        super.viewDidLoad()

		let request = FetchRequest<Tag>(moc: stack.managedObjectContext)
		request.predicate = NSPredicate(format: "sortIndex == max(sortIndex)")
		let result = fetch(request)

		if result.success,
			let tag = result.objects.first,
			let sortIndex = tag.sortIndex as? Int {
				maxSortOrderIndex = sortIndex
		}

		if let guid = state.selectedEventGUID {
			let request = FetchRequest<Event>(moc: stack.managedObjectContext, attribute: "guid", value: guid)
			let result = fetch(request)

			if result.success,
				let event = result.objects.first,
				let tag = event.inTag,
				let indexPath = fetchedResultsController.indexPathForObject(tag) {
					selectedEvent = event

					tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .None)
					tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .None, animated: true)
			}
		}

		editBarButtonItem?.target = self
		editBarButtonItem?.action = "toggleEdit"

		addBarButtonItem?.target = self
		addBarButtonItem?.action = "addTagRow"
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        fetchedResultsController.delegate = nil
    }

    func configureCell(cell: TagCell, atIndexPath: NSIndexPath) -> Void {
        if let tag = fetchedResultsController.objectAtIndexPath(atIndexPath) as? Tag {
			cell.name.text = tag.name
			cell.name.enabled = tableView.editing

            if selectedEvent?.inTag?.guid == tag.guid {
                showSelectMark(cell)
            }

			cell.shouldBeginEdit = { [unowned self] in
				return self.tableView.editing
			}

			cell.didEndEditing = { [unowned self] in
				tag.name = cell.name.text
				saveContextAndWait(self.stack.managedObjectContext)
			}
        }
    }

    func toggleEdit() {
        if tableView.editing {
            tableView.setEditing(false, animated: true)
        } else {
            tableView.setEditing(true, animated: true)
        }

		for cell in tableView.visibleCells() {
			if let c = cell as? TagCell {
				c.name.enabled = tableView.editing
			}
		}
    }

	func addTagRow() {
		let tag = Tag(stack.managedObjectContext, sortIndex: maxSortOrderIndex)
		maxSortOrderIndex++
		saveContextAndWait(stack.managedObjectContext)
	}

    func showSelectMark(cell: TagCell) {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            cell.selectedMark.alpha = 1
        })
    }

    func hideSelectMark(cell: TagCell) {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            cell.selectedMark.alpha = 0
        })
    }
}

// MARK: - UITableViewDelegate
typealias TagsViewController_UITableViewDelegate = TagsViewController
extension TagsViewController_UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)

        if let selectedTag = selectedEvent?.inTag,
            let indexPath = fetchedResultsController.indexPathForObject(selectedTag),
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? TagCell {
                hideSelectMark(cell)
        }

        if let tag = fetchedResultsController.objectAtIndexPath(indexPath) as? Tag,
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? TagCell,
            let guid = state.selectedEventGUID,
			let event = selectedEvent {
				if let inTag = event.inTag where inTag.isEqual(tag) {
					event.inTag = nil
				} else {
					event.inTag = tag
				}

				saveContextAndWait(stack.managedObjectContext)
        }
    }

	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            if let tag = fetchedResultsController.objectAtIndexPath(indexPath) as? Tag {
                    stack.managedObjectContext.deleteObject(tag)
                    saveContextAndWait(stack.managedObjectContext)
            }
        }
    }

	func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

	func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        if sourceIndexPath == destinationIndexPath {
            return
        }

        if let tag = fetchedResultsController.objectAtIndexPath(sourceIndexPath) as? Tag {
                userReorderingCells = true
                tag.sortIndex = destinationIndexPath.row
                saveContextAndWait(stack.managedObjectContext)
                userReorderingCells = false
        }
    }
}

// MARK: - UITableViewDataSource
typealias TagsViewController_UITableViewDataSource = TagsViewController
extension TagsViewController_UITableViewDataSource {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo = fetchedResultsController.sections?[section] as? NSFetchedResultsSectionInfo {
            return sectionInfo.numberOfObjects
        }

        return 0
    }

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TagCellIdentifier") as! TagCell
        configureCell(cell, atIndexPath:indexPath)

        return cell
    }
}

// MARK: - NSFetchedResultsControllerDelegate
typealias TagsViewController_NSFetchedResultsControllerDelegate = TagsViewController
extension TagsViewController_NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        if userReorderingCells {
            return
        }

        tableView.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if userReorderingCells {
            return
        }

        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? TagCell {
                configureCell(cell, atIndexPath: indexPath!)
            }
        case .Move:
            tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if userReorderingCells {
            return
        }

        tableView.endUpdates()
    }
}
