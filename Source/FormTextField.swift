import UIKit
import Formatter
import InputValidator

public enum FormTextFieldInputType: String {
    case Default, Name, Username, PhoneNumber, Integer, Decimal, Address, Email, Password, Unknown
}

public protocol FormTextFieldDelegate: NSObjectProtocol {
    func formTextFieldDidBeginEditing(textField: FormTextField)
    func formTextFieldDidEndEditing(textField: FormTextField)
    func formTextField(textField: FormTextField, didUpdateWithText text: String?)
    func formTextFieldDidReturn(textField: FormTextField)
}

public class FormTextField: UITextField, UITextFieldDelegate {
    dynamic public var borderWidth: CGFloat = 0 { didSet { self.layer.borderWidth = borderWidth } }
    dynamic public var cornerRadius: CGFloat = 0 { didSet { self.layer.cornerRadius = cornerRadius } }
    dynamic public var accessoryButtonColor: UIColor = UIColor.redColor()

    dynamic public var enabledBackgroundColor: UIColor = UIColor.redColor() { didSet { self.updateEnabled(self.enabled) } }
    dynamic public var enabledBorderColor: UIColor = UIColor.redColor() { didSet { self.updateEnabled(self.enabled) } }
    dynamic public var enabledTextColor: UIColor = UIColor.redColor() { didSet { self.updateEnabled(self.enabled) } }

    dynamic public var validBackgroundColor: UIColor = UIColor.redColor()
    dynamic public var validBorderColor: UIColor = UIColor.redColor()
    dynamic public var validTextColor: UIColor = UIColor.redColor()

    dynamic public var activeBackgroundColor: UIColor = UIColor.redColor()
    dynamic public var activeBorderColor: UIColor = UIColor.redColor()
    dynamic public var activeTextColor: UIColor = UIColor.redColor()

    dynamic public var inactiveBackgroundColor: UIColor = UIColor.redColor()
    dynamic public var inactiveBorderColor: UIColor = UIColor.redColor()
    dynamic public var inactiveTextColor: UIColor = UIColor.redColor()

    dynamic public var disabledBackgroundColor: UIColor = UIColor.redColor() { didSet { self.updateEnabled(self.enabled) } }
    dynamic public var disabledBorderColor: UIColor = UIColor.redColor() { didSet { self.updateEnabled(self.enabled) } }
    dynamic public var disabledTextColor: UIColor = UIColor.redColor() { didSet { self.updateEnabled(self.enabled) } }

    dynamic public var invalidBackgroundColor: UIColor = UIColor.redColor()
    dynamic public var invalidBorderColor: UIColor = UIColor.redColor()
    dynamic public var invalidTextColor: UIColor = UIColor.redColor()

    public var inputValidator: InputValidatable?
    public var formatter: Formattable?
    public weak var textFieldDelegate: FormTextFieldDelegate?

    static let LeftMargin = 10.0
    static let AccessoryButtonWidth = 30.0
    static let AccessoryButtonHeight = 20.0

    override public init(frame: CGRect) {
        self.inputType = .Default

        super.init(frame: frame)

        self.delegate = self

        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: FormTextField.LeftMargin, height: 0))
        self.leftView = paddingView
        self.leftViewMode = .Always

        self.addTarget(self, action: "textFieldDidUpdate:", forControlEvents: .EditingChanged)
        self.addTarget(self, action: "textFieldDidReturn:", forControlEvents: .EditingDidEndOnExit)

        self.returnKeyType = .Done
        self.rightViewMode = .WhileEditing
        self.backgroundColor = UIColor.clearColor()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var customClearButton: UIButton = {
        let image = FormTextFieldClearButton.imageForSize(CGSize(width: 18, height: 18), color: self.accessoryButtonColor)
        let button = UIButton(type: .Custom)
        button.setImage(image, forState: .Normal)
        button.addTarget(self, action: "clearButtonAction", forControlEvents: .TouchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: FormTextField.AccessoryButtonWidth, height: FormTextField.AccessoryButtonHeight)

        return button
    }()

    override public var enabled: Bool {
        didSet {
            self.updateEnabled(self.enabled)
        }
    }

    public var valid: Bool = true {
        didSet {
            if self.enabled {
                self.updateValid(self.valid)
            }
        }
    }

    public var inputType: FormTextFieldInputType {
        didSet {
            self.updateInputType(inputType)
        }
    }

    func updateText(newValue: String?) {
        let text = newValue ?? ""

        if self.formatter != nil {
            let textRange = self.selectedTextRange
            let newRawText = self.formatter!.formatString(text, reverse: false)

            let didAddText = (newRawText.characters.count > (self.text ?? "").characters.count)
            let didFormat = (newRawText.characters.count > (self.text ?? "").characters.count)
            let cursorAtStart = (self.selectedTextRange!.start == self.positionFromPosition(self.beginningOfDocument, offset: 1))
            if (didAddText && cursorAtStart) {
                self.text = newRawText
                self.selectedTextRange = textRange
            } else if (didAddText && didFormat) {
                super.text = newRawText
            } else {
                super.text = newRawText
                self.selectedTextRange = textRange
            }
        } else {
            self.text = text
        }
    }

    // MARK: Public

    func updateActive(active: Bool) {
        self.rightView = self.customClearButton

        if active {
            self.layer.backgroundColor = self.activeBackgroundColor.CGColor
            self.layer.borderColor = self.activeBorderColor.CGColor
            self.textColor = self.activeTextColor
        } else {
            self.layer.backgroundColor = self.inactiveBackgroundColor.CGColor
            self.layer.borderColor = self.inactiveBorderColor.CGColor
            self.textColor = self.inactiveTextColor
        }
    }

    func updateEnabled(enabled: Bool) {
        if enabled {
            self.layer.borderColor = self.enabledBorderColor.CGColor
            self.layer.backgroundColor = self.enabledBackgroundColor.CGColor
            self.textColor = self.enabledTextColor
        } else {
            self.layer.borderColor = self.disabledBorderColor.CGColor
            self.layer.backgroundColor = self.disabledBackgroundColor.CGColor
            self.textColor = self.disabledTextColor
        }
    }

    func updateValid(valid: Bool) {
        if valid {
            self.layer.backgroundColor = self.validBackgroundColor.CGColor
            self.layer.borderColor = self.validBorderColor.CGColor
            self.textColor = self.validTextColor
        } else {
            self.layer.backgroundColor = self.invalidBackgroundColor.CGColor
            self.layer.borderColor = self.invalidBorderColor.CGColor
            self.textColor = self.invalidTextColor
        }
    }

    public func validate() -> Bool {
        var isValid = true
        if let inputValidator = self.inputValidator {
            isValid = inputValidator.validateString(self.text ?? "")
        }

        self.valid = isValid

        return isValid
    }

    // MARK: Notification

    func textFieldDidUpdate(textField: FormTextField) {
        self.updateText(self.text)

        if self.valid == false {
            self.valid = true
        }

        self.textFieldDelegate?.formTextField(self, didUpdateWithText: self.text)
    }

    func textFieldDidReturn(textField: FormTextField) {
        self.textFieldDelegate?.formTextFieldDidReturn(self)
    }

    // MARK: Actions

    func clearButtonAction() {
        self.text = nil

        self.textFieldDelegate?.formTextField(self, didUpdateWithText: self.text)
    }
}

// MARK: UITextFieldDelegate

extension FormTextField {
    public func textFieldDidBeginEditing(textField: UITextField) {
        self.rightView = self.customClearButton

        self.updateActive(true)
    }

    public func textFieldDidEndEditing(textField: UITextField) {
        self.updateActive(false)

        self.textFieldDelegate?.formTextFieldDidEndEditing(self)
    }

    public func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            return true
        }

        var valid = true
        if let inputValidator = self.inputValidator {
            valid = inputValidator.validateReplacementString(string, fullString: self.text, inRange: range)
        }
        
        return valid
    }
}