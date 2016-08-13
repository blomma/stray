import UIKit

// MARK: - Public methods -

public extension SideMenuController {

	/**
	Toggles the side pannel visible or not.
	*/
	public func toggle() {

		if !transitionInProgress {
			if !sidePanelVisible {
				prepare(sidePanelForDisplay: true)
			}

			animate(toReveal: !sidePanelVisible)
		}
	}

	/**
	Embeds a new side controller

	- parameter sideViewController: controller to be embedded
	*/
	public func embed(sideViewController controller: UIViewController) {
		if sideViewController == nil {
			sideViewController = controller
			sideViewController.view.frame = sidePanel.bounds

			sidePanel.addSubview(sideViewController.view)

			addChildViewController(sideViewController)
			sideViewController.didMove(toParentViewController: self)

			sidePanel.isHidden = true
		}
	}

	/**
	Embeds a new center controller.

	- parameter centerViewController: controller to be embedded
	*/
	public func embed(centerViewController controller: UIViewController) {

		addChildViewController(controller)
		if let controller = controller as? UINavigationController {
			prepare(centerControllerForContainment: controller)
		}
		centerPanel.addSubview(controller.view)

		if centerViewController == nil {
			centerViewController = controller
			centerViewController.didMove(toParentViewController: self)
		} else {
			centerViewController.willMove(toParentViewController: nil)

			let completion: () -> () = {
				self.centerViewController.view.removeFromSuperview()
				self.centerViewController.removeFromParentViewController()
				controller.didMove(toParentViewController: self)
				self.centerViewController = controller
			}

			if let animator = _preferences.animating.transitionAnimator {
				animator.performTransition(forView: controller.view, completion: completion)
			} else {
				completion()
			}

			if sidePanelVisible {
				animate(toReveal: false, statusUpdateAnimated: false)
			}
		}
	}
}

public class SideMenuController: UIViewController, UIGestureRecognizerDelegate {

	// MARK:- Custom types -
	public enum SidePanelPosition {
		case underCenterPanelLeft
		case underCenterPanelRight
		case overCenterPanelLeft
		case overCenterPanelRight

		var isPositionedLeft: Bool {
			return self == SidePanelPosition.underCenterPanelLeft || self == SidePanelPosition.overCenterPanelLeft
		}
	}

	public struct Preferences {
		public struct Drawing {
			public var sidePanelPosition = SidePanelPosition.underCenterPanelLeft
			public var sidePanelWidth: CGFloat = 200
			public var centerPanelOverlayColor = UIColor(hue:0.15, saturation:0.21, brightness:0.17, alpha:0.6)
			public var centerPanelShadow = false
		}

		public struct Animating {
			public var reavealDuration = 0.3
			public var hideDuration = 0.2
			public var transitionAnimator: TransitionAnimatable.Type? = FadeAnimator.self
		}

		public struct Interaction {
			public var panningEnabled = true
			public var swipingEnabled = true
			public var menuButtonAccessibilityIdentifier: String?
		}

		public var drawing = Drawing()
		public var animating = Animating()
		public var interaction = Interaction()

		public init() {}
	}

	// MARK: - Properties -

	// MARK: Public
	public static var preferences: Preferences = Preferences()
	private(set) public var sidePanelVisible = false

	// MARK: Private
	private lazy var _preferences: Preferences = {
		return self.dynamicType.preferences
	}()

	private var centerViewController: UIViewController!
	private var centerNavController: UINavigationController? {
		return centerViewController as? UINavigationController
	}
	private var sideViewController: UIViewController!
	private var centerPanel: UIView!
	private var sidePanel: UIView!
	private var centerPanelOverlay: UIView!
	private var leftSwipeRecognizer: UISwipeGestureRecognizer!
	private var rightSwipeGesture: UISwipeGestureRecognizer!
	private var panRecognizer: UIPanGestureRecognizer!

	private var transitionInProgress = false
	private var flickVelocity: CGFloat = 0

	private lazy var screenSize: CGSize = {
		return UIScreen.main.bounds.size
	}()

	private lazy var sidePanelPosition: SidePanelPosition = {
		return self._preferences.drawing.sidePanelPosition
	}()

	// MARK: Computed
	private var centerPanelFrame: CGRect {
		if sidePanelVisible {
			let sidePanelWidth = _preferences.drawing.sidePanelWidth
			return CGRect(x: sidePanelPosition.isPositionedLeft ? sidePanelWidth : -sidePanelWidth, y: 0, width: screenSize.width, height: screenSize.height)
		} else {
			return CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
		}
	}

	private var sidePanelFrame: CGRect {
		let panelWidth = _preferences.drawing.sidePanelWidth
		let sidePanelFrame = CGRect(x: sidePanelPosition.isPositionedLeft ? 0 :
			screenSize.width - panelWidth, y: 0, width: panelWidth, height: screenSize.height)

		return sidePanelFrame
	}

	// MARK:- View lifecycle -

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setUpViewHierarchy()
	}

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		setUpViewHierarchy()
	}

	private func setUpViewHierarchy() {
		view = UIView(frame: UIScreen.main.bounds)
		configureViews()
	}

	public override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		if sidePanelVisible {
			toggle()
		}
	}

	override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)

		screenSize = size

		coordinator.animate(alongsideTransition: { _ in
			// reposition center panel
			self.update(centerPanelFrame: self.centerPanelFrame)
			// reposition side panel
			self.sidePanel.frame = self.sidePanelFrame

			// reposition the center shadow view
			if let overlay = self.centerPanelOverlay {
				overlay.frame = self.centerPanelFrame
			}

			self.view.layoutIfNeeded()

			}, completion: nil)
	}

	// MARK: - Configurations -

	private func configureViews() {
		centerPanel = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
		view.addSubview(centerPanel)

		sidePanel = UIView(frame: sidePanelFrame)
		view.addSubview(sidePanel)
		sidePanel.clipsToBounds = true

		view.sendSubview(toBack: sidePanel)

		configureGestureRecognizers()
	}

	private func configureGestureRecognizers() {
		panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleCenterPanelPan))
		panRecognizer.delegate = self
		
		centerPanel.addGestureRecognizer(panRecognizer)
	}

	func update(centerPanelFrame frame: CGRect) {
		centerPanel.frame = frame
	}

	// MARK:- Containment -

	private func prepare(centerControllerForContainment controller: UINavigationController) {
		controller.view.frame = centerPanel.bounds
	}

	private func prepare(sidePanelForDisplay display: Bool) {
		sidePanel.isHidden = !display
	}

	private func animate(toReveal reveal: Bool, statusUpdateAnimated: Bool = true) {
		transitionInProgress = true
		sidePanelVisible = reveal

		setUnderSidePanel(hidden: !reveal, completion: { _ in
			if !reveal {
				self.prepare(sidePanelForDisplay: false)
			}
			
			self.transitionInProgress = false
			self.centerViewController.view.isUserInteractionEnabled = !reveal
		})
	}

	private func setUnderSidePanel(hidden: Bool, completion: ((Bool) -> Void)? = nil) {
		var centerPanelFrame = centerPanel.frame

		if !hidden {
			let originX = sidePanelPosition.isPositionedLeft
				? sidePanel.frame.maxX
				: sidePanel.frame.minX - centerPanel.frame.width
			centerPanelFrame.origin.x = originX
		} else {
			centerPanelFrame.origin = CGPoint.zero
		}

		var duration = hidden
			? _preferences.animating.hideDuration
			: _preferences.animating.reavealDuration

		let absFlickVelocity = abs(flickVelocity)
		if absFlickVelocity > 0 {
			let newDuration = TimeInterval(sidePanel.frame.size.width / absFlickVelocity)
			flickVelocity = 0
			duration = min(newDuration, duration)
		}

		UIView.animate(withDuration: duration, animations: { _ in
			self.update(centerPanelFrame: centerPanelFrame)
			}, completion: completion)
	}

	func handleCenterPanelPan(_ recognizer: UIPanGestureRecognizer) {
		guard sideViewController != nil else {
			return
		}

		flickVelocity = recognizer.velocity(in: recognizer.view).x

		switch(recognizer.state) {

		case .began:
			if !sidePanelVisible {
				sidePanelVisible = true
				prepare(sidePanelForDisplay: true)
			}

		case .changed:
			let translation = recognizer.translation(in: view).x
			let sidePanelFrame = sidePanel.frame

			// origin.x or origin.x + width
			let xPoint: CGFloat = centerPanel.center.x + translation +
				(sidePanelPosition.isPositionedLeft ? -1  : 1 ) * centerPanel.frame.width / 2


			if xPoint < sidePanelFrame.minX || xPoint > sidePanelFrame.maxX {
				return
			}

			var frame = centerPanel.frame
			frame.origin.x += translation
			update(centerPanelFrame: frame)
			recognizer.setTranslation(CGPoint.zero, in: view)

		default:
			if sidePanelVisible {
				var reveal = true
				let centerFrame = centerPanel.frame
				let sideFrame = sidePanel.frame

				let shouldOpenPercentage = CGFloat(0.2)
				let shouldHidePercentage = CGFloat(0.8)

				let leftToRight = flickVelocity > 0
				if sidePanelPosition.isPositionedLeft {
					if leftToRight {
						// opening
						reveal = centerFrame.minX > sideFrame.width * shouldOpenPercentage
					} else {
						// closing
						reveal = centerFrame.minX > sideFrame.width * shouldHidePercentage
					}
				} else {
					if leftToRight {
						//closing
						reveal = centerFrame.maxX < sideFrame.minX + shouldOpenPercentage * sideFrame.width
					} else {
						// opening
						reveal = centerFrame.maxX < sideFrame.minX + shouldHidePercentage * sideFrame.width
					}
				}

				animate(toReveal: reveal)
			}
		}
	}

	// MARK:- UIGestureRecognizerDelegate -

	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {

		switch gestureRecognizer {
		case panRecognizer:
			return _preferences.interaction.panningEnabled
		default:
			if gestureRecognizer is UISwipeGestureRecognizer {
				return _preferences.interaction.swipingEnabled
			}
			return true
		}
	}
}
