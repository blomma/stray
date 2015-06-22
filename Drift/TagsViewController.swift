//
//  TagsTableViewController.swift
//  Drift
//
//  Created by Mikael Hultgren on 28/11/14.
//  Copyright (c) 2014 Artsoftheinsane. All rights reserved.
//

import UIKit
import CoreData

class TagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, TagCellDelegate {
	@IBOutlet weak var tableView: UITableView!

    private var userReorderingCells = false
    private var selectedTag: Tag?
    private var maxSortOrderIndex = 0

	var eventGuid: String?

    private var fetchedResultsController: NSFetchedResultsController?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        let request = FetchRequest<Tag>(context: defaultCoreDataStack.managedObjectContext)
        request.predicate = NSPredicate(format: "sortIndex == max(sortIndex)")
        let result = request.fetch()

        if result.success,
            let tag = result.objects.first,
            let sortIndex = tag.sortIndex as? Int {
                maxSortOrderIndex = sortIndex
        }

        var fetchRequest = NSFetchRequest(entityName: Tag.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: false)]
        fetchRequest.fetchBatchSize = 20

        var controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: defaultCoreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)

        var error: NSErrorPointer = NSErrorPointer()
        if !controller.performFetch(error) {
            println("Unresolved error \(error)")
            exit(-1)
        }

        controller.delegate = self
        fetchedResultsController = controller

        if let guid = eventGuid {
            let request = FetchRequest<Event>(context: defaultCoreDataStack.managedObjectContext)
            let result = request.fetchWhere("guid", value: guid)

            if result.success,
                let event = result.objects.first,
                let tag = event.inTag,
                let indexPath = controller.indexPathForObject(tag) {
                    selectedTag = tag
                    tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .None)
                    tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .None, animated: true)
            }
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }

    private func configureCell(cell: TagCell, atIndexPath: NSIndexPath) -> Void {
        if let tag = fetchedResultsController?.objectAtIndexPath(atIndexPath) as? Tag {
			cell.delegate = self

			cell.name.text = tag.name
			cell.name.enabled = tableView.editing

            if selectedTag?.guid == tag.guid {
                showSelectMark(cell)
            }
        }
    }

	@IBAction func toggleEdit(sender: UIBarButtonItem) {
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

	@IBAction func addTag(sender: UIBarButtonItem) {
        let tag = Tag(defaultCoreDataStack.managedObjectContext, sortIndex: maxSortOrderIndex)
        maxSortOrderIndex++
        saveContext(defaultCoreDataStack.managedObjectContext, { (ContextSaveResult) -> Void in

        })
	}

    private func showSelectMark(cell: TagCell) {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            cell.selectedMark.alpha = 1
        })
    }

    private func hideSelectMark(cell: TagCell) {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            cell.selectedMark.alpha = 0
        })
    }
}

// MARK: - TagCellDelegate
typealias TagsViewControllerTagCellDelegate = TagsViewController
extension TagsViewControllerTagCellDelegate {
	func didEndEditing(cell: TagCell) {
        if let fetchedResultsController = fetchedResultsController,
            let indexPath = tableView.indexPathForCell(cell),
            let tag = fetchedResultsController.objectAtIndexPath(indexPath) as? Tag {
                tag.name = cell.name.text
                saveContext(defaultCoreDataStack.managedObjectContext, { (ContextSaveResult) -> Void in
                })
        }
    }

	func shouldBeginEdit() -> Bool {
		return tableView.editing
	}
}

// MARK: - UITableViewDelegate
typealias TagsViewController_UITableViewDelegate = TagsViewController
extension TagsViewController_UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)

        if let selectedTag = selectedTag,
            let indexPath = fetchedResultsController?.indexPathForObject(selectedTag),
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? TagCell {
                hideSelectMark(cell)
        }

        if let guid = eventGuid,
            let fetchedResultsController = fetchedResultsController {
                let request = FetchRequest<Event>(context: defaultCoreDataStack.managedObjectContext)
                let result = request.fetchWhere("guid", value: guid)

			if result.success,
				let event = result.objects.first,
                let tag = fetchedResultsController.objectAtIndexPath(indexPath) as? Tag {
					if let inTag = event.inTag where inTag.isEqual(tag) {
						event.inTag = nil
					} else {
						event.inTag = tag
					}

                    saveContext(defaultCoreDataStack.managedObjectContext, { (ContextSaveResult) -> Void in
                    })

					self.performSegueWithIdentifier("unwindToPresenter", sender: self)
			}
		}
	}

	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete,
            let fetchedResultsController = fetchedResultsController,
            let tag = fetchedResultsController.objectAtIndexPath(indexPath) as? Tag {
                deleteObjects([tag], inContext: defaultCoreDataStack.managedObjectContext)
                saveContext(defaultCoreDataStack.managedObjectContext, { (ContextSaveResult) -> Void in
                })
        }
    }


	func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

	func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        if sourceIndexPath == destinationIndexPath {
            return
        }

        if let fetchedResultsController = fetchedResultsController,
            let tag = fetchedResultsController.objectAtIndexPath(sourceIndexPath) as? Tag {
                userReorderingCells = true
                tag.sortIndex = destinationIndexPath.row
                saveContext(defaultCoreDataStack.managedObjectContext, { (ContextSaveResult) -> Void in
                })
                userReorderingCells = false
        }
    }
}

// MARK: - UITableViewDataSource
typealias TagsViewController_UITableViewDataSource = TagsViewController
extension TagsViewController_UITableViewDataSource {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo = fetchedResultsController?.sections?[section] as? NSFetchedResultsSectionInfo {
            return sectionInfo.numberOfObjects
        }

        return 0
    }

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
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
