import UIKit

extension SideMenuController {
	func toggle() {
		if !transitionInProgress {
			if !sidePanelVisible {
				prepare(sidePanelForDisplay: true)
			}

			animate(toReveal: !sidePanelVisible)
		}
	}

	func embed(sideViewController controller: UIViewController) {
		if sideViewController != nil {
			return
		}

		sideViewController = controller
		controller.view.frame = sidePanel.bounds

		sidePanel.addSubview(controller.view)

		addChildViewController(controller)
		controller.didMove(toParentViewController: self)

		sidePanel.isHidden = true
	}

	func embed(centerViewController controller: UINavigationController) {
		addChildViewController(controller)

		prepare(centerControllerForContainment: controller)

		guard let centerPanel = centerPanel else {
			fatalError("Missing centerPanel")
		}
		centerPanel.addSubview(controller.view)

		guard let centerViewController = centerViewController else {
			self.centerViewController = controller
			controller.didMove(toParentViewController: self)

			return
		}

		centerViewController.willMove(toParentViewController: nil)

		let completion: () -> () = {
			centerViewController.view.removeFromSuperview()
			centerViewController.removeFromParentViewController()

			controller.didMove(toParentViewController: self)
			self.centerViewController = controller
		}

		if let animator = transitionAnimator {
			animator.performTransition(forView: controller.view, completion: completion)
		} else {
			completion()
		}

		if sidePanelVisible {
			animate(toReveal: false)
		}

		// if centerViewController == nil {
		// 	centerViewController = controller
		// 	centerViewController.didMove(toParentViewController: self)
		// } else {
		// 	centerViewController.willMove(toParentViewController: nil)

		// 	let completion: () -> () = {
		// 		self.centerViewController.view.removeFromSuperview()
		// 		self.centerViewController.removeFromParentViewController()
		// 		controller.didMove(toParentViewController: self)
		// 		self.centerViewController = controller
		// 	}

		// 	if let animator = transitionAnimator {
		// 		animator.performTransition(forView: controller.view, completion: completion)
		// 	} else {
		// 		completion()
		// 	}

		// 	if sidePanelVisible {
		// 		animate(toReveal: false)
		// 	}
		// }
	}
}

class SideMenuController: UIViewController {
	fileprivate var sidePanelPosition = SidePanelPosition.underCenterPanelLeft
	fileprivate var sidePanelWidth: CGFloat = 200
	fileprivate var reavealDuration = 0.3
	fileprivate var hideDuration = 0.2
	fileprivate var transitionAnimator: TransitionAnimatable.Type? = FadeAnimator.self

	enum SidePanelPosition {
		case underCenterPanelLeft
		case underCenterPanelRight

		var isPositionedLeft: Bool {
			return self == SidePanelPosition.underCenterPanelLeft
		}
	}

	fileprivate(set) public var sidePanelVisible = false

	fileprivate var centerViewController: UINavigationController?
	fileprivate var sideViewController: UIViewController?

	fileprivate var centerPanel: UIView?
	fileprivate var sidePanel: UIView!
	fileprivate var panRecognizer: UIPanGestureRecognizer!

	fileprivate var transitionInProgress = false
	fileprivate var flickVelocity: CGFloat = 0

	fileprivate lazy var screenSize: CGSize = {
		return UIScreen.main.bounds.size
	}()

	fileprivate var centerPanelFrame: CGRect {
		if sidePanelVisible {
			return CGRect(x: sidePanelPosition.isPositionedLeft ? sidePanelWidth : -sidePanelWidth, y: 0, width: screenSize.width, height: screenSize.height)
		} else {
			return CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
		}
	}

	fileprivate var sidePanelFrame: CGRect {
		let sidePanelFrame = CGRect(x: sidePanelPosition.isPositionedLeft ? 0 :
			screenSize.width - sidePanelWidth, y: 0, width: sidePanelWidth, height: screenSize.height)

		return sidePanelFrame
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setUpViewHierarchy()
	}

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		setUpViewHierarchy()
	}

	fileprivate func setUpViewHierarchy() {
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

			self.view.layoutIfNeeded()

			}, completion: nil)
	}

	fileprivate func configureViews() {
		let centerPanel = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
		view.addSubview(centerPanel)
		self.centerPanel = centerPanel

		sidePanel = UIView(frame: sidePanelFrame)
		view.addSubview(sidePanel)
		sidePanel.clipsToBounds = true

		view.sendSubview(toBack: sidePanel)

		configureGestureRecognizers()
	}

	fileprivate func configureGestureRecognizers() {
		guard let centerPanel = centerPanel else {
			return
		}

		panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleCenterPanelPan))
//		panRecognizer.delegate = self

		centerPanel.addGestureRecognizer(panRecognizer)
	}

	fileprivate func update(centerPanelFrame frame: CGRect) {
		// TODO: Set alpha fading
		guard let centerPanel = centerPanel else {
			return
		}
		centerPanel.frame = frame
	}

	fileprivate func prepare(centerControllerForContainment controller: UINavigationController) {
		guard let centerPanel = centerPanel else {
			fatalError("Missing centerPanel")
		}
		controller.view.frame = centerPanel.bounds
	}

	fileprivate func prepare(sidePanelForDisplay display: Bool) {
		sidePanel.isHidden = !display
	}

	fileprivate func animate(toReveal reveal: Bool) {
		transitionInProgress = true
		sidePanelVisible = reveal

		setUnderSidePanel(hidden: !reveal, completion: { _ in
			if !reveal {
				self.prepare(sidePanelForDisplay: false)
			}

			self.transitionInProgress = false
			self.centerViewController?.view.isUserInteractionEnabled = !reveal
		})
	}

	fileprivate func setUnderSidePanel(hidden: Bool, completion: ((Bool) -> Void)? = nil) {
		guard let centerPanel = centerPanel else {
			fatalError("Missing centerPaenl")
		}
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
			? hideDuration
			: reavealDuration

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
			guard let centerPanel = centerPanel else {
				fatalError("Missing centerPanel")
			}
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
				guard let centerPanel = centerPanel else {
					fatalError("Missing centerPanel")
				}
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
}
