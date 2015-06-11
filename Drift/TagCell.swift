import UIKit

protocol TagCellDelegate : class {
	func didEndEditing(cell:TagCell)
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
	func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
		if let shouldBegin = delegate?.shouldBeginEdit() {
			return shouldBegin
		}

		return true
	}

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }

    func textFieldDidEndEditing(textField: UITextField) {
        textField.resignFirstResponder()
		delegate?.didEndEditing(self)
    }
}
