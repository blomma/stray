import UIKit

public typealias EndEdit = () -> ()
public typealias BeginEdit = () -> (Bool)
public protocol TagCellProtocol : class {
	var didEndEditing: EndEdit? { get set }
	var shouldBeginEdit: BeginEdit? { get set }
}

public class TagCell: UITableViewCell, UITextFieldDelegate, TagCellProtocol {
	@IBOutlet weak var name: UITextField!
	
	public var didEndEditing: EndEdit?
	public var shouldBeginEdit: BeginEdit?
}

typealias TextFieldDelegate = TagCell
extension TextFieldDelegate {
	public func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
		if let shouldBegin = self.shouldBeginEdit?() {
			return shouldBegin
		}

		return true
	}

    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }

    public func textFieldDidEndEditing(textField: UITextField) {
        textField.resignFirstResponder()
		self.didEndEditing?()
    }
}
