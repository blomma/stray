import UIKit

typealias EndEdit = () -> ()
typealias BeginEdit = () -> (Bool)
protocol TagCellProtocol : class {
	var didEndEditing: EndEdit? { get set }
	var shouldBeginEdit: BeginEdit? { get set }
}

class TagCell: UITableViewCell, UITextFieldDelegate, TagCellProtocol {
	@IBOutlet weak var name: UITextField!
    @IBOutlet weak var selectedMark: UIView!

	var didEndEditing: EndEdit?
	var shouldBeginEdit: BeginEdit?

    override func prepareForReuse() {
        selectedMark.alpha = 0
    }
}

typealias TextFieldDelegate = TagCell
extension TextFieldDelegate {
	func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
		if let shouldBegin = self.shouldBeginEdit?() {
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
		self.didEndEditing?()
    }
}
