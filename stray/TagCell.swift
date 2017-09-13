import UIKit

protocol TagCellDelegate : class {
	func didEndEditing(_ cell: TagCell)
	func shouldBeginEdit() -> Bool
}

class TagCell: UITableViewCell, UITextFieldDelegate {
	@IBOutlet weak var name: UITextField!
	@IBOutlet weak var selectedMark: UIView!

	weak var delegate: TagCellDelegate?

	override func prepareForReuse() {
		selectedMark.alpha = 0
	}
}

typealias TextFieldDelegate = TagCell
extension TextFieldDelegate {
	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		if let shouldBegin = delegate?.shouldBeginEdit() {
			return shouldBegin
		}

		return true
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()

		return true
	}

	func textFieldDidEndEditing(_ textField: UITextField) {
		textField.resignFirstResponder()
		delegate?.didEndEditing(self)
	}
}
