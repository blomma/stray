import UIKit

// MARK: - Public functions
extension SideMenuContainerController {
	func toggle() {
		if !transitionInProgress {
			if !sidePanelVisible {
				prepare(sidePanelForDisplay: true)
			}

			animate(toReveal: !sidePanelVisible)
		}
	}

	/// This embeds the SideViewController that contains, well
	/// the actual menu items you can select to jump around
	///
	/// This should only happens once, after that we only substitute
	/// CenterViewController
	///
	/// - parameter controller: SideViewController
	func embed(sideViewController controller: UIViewController) {
		if sideViewController != nil {
			return
		}

		guard let sidePanel = sidePanel else {
			fatalError("Missing sidePanel")
		}

		controller.view.frame = sidePanel.bounds
		sidePanel.addSubview(controller.view)

		addChildViewController(controller)
		controller.didMove(toParentViewController: self)

		sidePanel.isHidden = true

		self.sideViewController = controller
	}

	func embed(centerViewController controller: UIViewController) {
		guard let centerPanel = centerPanel else {
			fatalError("Missing centerPanel")
		}

		addChildViewController(controller)
		prepare(centerControllerForContainment: controller)
		centerPanel.addSubview(controller.view)

		// First time case
		guard let centerViewController = self.centerViewController else {
			controller.didMove(toParentViewController: self)
			self.centerViewController = controller

			return
		}

		let completion: () -> () = {
			centerViewController.willMove(toParentViewController: nil)
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
	}
}


// MARK: - GestureRecognizer
extension SideMenuContainerController {
	func handleCenterPanelPan(_ recognizer: UIPanGestureRecognizer) {
		guard sideViewController != nil else {
			return
		}

		flickVelocity = recognizer.velocity(in: recognizer.view).x

		switch(recognizer.state) {
		case .possible: break
		case .began:
			if !sidePanelVisible {
				sidePanelVisible = true
				prepare(sidePanelForDisplay: true)
			}

		case .changed:
			guard let centerPanel = centerPanel, let sidePanel = sidePanel else {
				fatalError("Missing centerPanel or sidePanel")
			}

			let translation = recognizer.translation(in: view).x

			// origin.x or origin.x + width
			let xPoint: CGFloat = centerPanel.center.x + translation + -1 * centerPanel.frame.width / 2
			if xPoint < 0 || xPoint > sidePanelWidth {
				return
			}

			var frame = centerPanel.frame
			frame.origin.x += translation

			var sidePanelFrame = sidePanel.frame
			sidePanelFrame.origin.x += translation

			update(centerPanelFrame: frame)
			update(sidePanelFrame: sidePanelFrame)

			recognizer.setTranslation(CGPoint.zero, in: view)

		case .ended, .cancelled, .failed:
			if sidePanelVisible {
				guard let centerPanel = centerPanel, let sidePanel = sidePanel else {
					fatalError("Missing centerPanel or sidePanel")
				}

				var reveal = true
				let centerFrame = centerPanel.frame
				let sideFrame = sidePanel.frame

				let leftToRight = flickVelocity > 0
				if leftToRight {
					// opening
					reveal = centerFrame.minX > sideFrame.width * shouldOpenPercentage
				} else {
					// closing
					reveal = centerFrame.minX > sideFrame.width * shouldHidePercentage
				}

				animate(toReveal: reveal)
			}
		}
	}
}

class SideMenuContainerController: UIViewController {
	// MARK: - Private configurable constants
	fileprivate let sidePanelWidth: CGFloat = 100
	fileprivate let reavealDuration = 0.3
	fileprivate let hideDuration = 0.2
	fileprivate let transitionAnimator: TransitionAnimatable.Type? = FadeAnimator.self
	fileprivate let shouldOpenPercentage: CGFloat = 0.2
	fileprivate let shouldHidePercentage: CGFloat = 0.8

	// MARK: - Private properties
	fileprivate(set) public var sidePanelVisible = false

	fileprivate var centerViewController: UIViewController?
	fileprivate var sideViewController: UIViewController?

	fileprivate var centerPanel: UIView?
	fileprivate var sidePanel: UIView?
	fileprivate var panRecognizer: UIPanGestureRecognizer?

	fileprivate var transitionInProgress = false
	fileprivate var flickVelocity: CGFloat = 0

	fileprivate lazy var screenSize: CGSize = {
		return UIScreen.main.bounds.size
	}()

	fileprivate var centerPanelFrame: CGRect {
		return CGRect(
			x: sidePanelVisible ? sidePanelWidth : 0,
			y: 0,
			width: screenSize.width,
			height: screenSize.height
		)
	}

	fileprivate var sidePanelFrame: CGRect {
		return CGRect(
			x: 0,
			y: 0,
			width: sidePanelWidth,
			height: screenSize.height
		)
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		setUpViewHierarchy()
	}

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

		setUpViewHierarchy()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		if sidePanelVisible {
			toggle()
		}
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)

		screenSize = size

		coordinator.animate(alongsideTransition: { _ in
			// reposition center panel
			self.update(centerPanelFrame: self.centerPanelFrame)

			// reposition side panel
			self.update(sidePanelFrame: self.sidePanelFrame)

			self.view.layoutIfNeeded()

			}, completion: nil)
	}

	fileprivate func setUpViewHierarchy() {
		view = UIView(frame: UIScreen.main.bounds)

		// configure views
		let centerPanel = UIView(frame: centerPanelFrame)
		view.addSubview(centerPanel)
		self.centerPanel = centerPanel

		let sidePanel = UIView(frame: sidePanelFrame)
		sidePanel.clipsToBounds = true
		view.addSubview(sidePanel)
		view.sendSubview(toBack: sidePanel)
		self.sidePanel = sidePanel

		// gesture recognizers
		let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleCenterPanelPan))
		panRecognizer.cancelsTouchesInView = false
		centerPanel.addGestureRecognizer(panRecognizer)
		self.panRecognizer = panRecognizer
	}

	fileprivate func update(centerPanelFrame frame: CGRect) {
		guard let centerPanel = centerPanel else {
			return
		}

		centerPanel.frame = frame
	}

	fileprivate func update(sidePanelFrame frame: CGRect) {
		guard let sidePanel = sidePanel else {
			return
		}

		sidePanel.frame = frame
	}

	fileprivate func prepare(centerControllerForContainment controller: UIViewController) {
		guard let centerPanel = centerPanel else {
			fatalError("Missing centerPanel")
		}
		controller.view.frame = centerPanel.bounds
	}

	fileprivate func prepare(sidePanelForDisplay display: Bool) {
		guard let sidePanel = sidePanel else {
			return
		}

		sidePanel.isHidden = !display
		if display {
			// We are about to display the sidepanel, so we move it into position
			var frame = sidePanel.frame
			frame.origin.x = -sidePanelWidth

			sidePanel.frame = frame
		}
	}

	fileprivate func animate(toReveal reveal: Bool) {
		guard let centerPanel = centerPanel, let sidePanel = sidePanel else {
			fatalError("Missing centerPanel or sidePanel")
		}

		transitionInProgress = true
		sidePanelVisible = reveal

		var centerPanelFrame = centerPanel.frame
		var sidePanelFrame = sidePanel.frame
		if reveal {
			centerPanelFrame.origin.x = sidePanelWidth
			sidePanelFrame.origin = CGPoint.zero
		} else {
			centerPanelFrame.origin = CGPoint.zero
			sidePanelFrame.origin.x = -sidePanelWidth
		}

		var duration = reveal
			? reavealDuration
			: hideDuration

		let absFlickVelocity = abs(flickVelocity)
		if absFlickVelocity > 0 {
			let newDuration = TimeInterval(sidePanel.frame.size.width / absFlickVelocity)
			flickVelocity = 0
			duration = min(newDuration, duration)
		}

		UIView.animate(withDuration: duration, animations: { _ in
			self.update(centerPanelFrame: centerPanelFrame)
			self.update(sidePanelFrame: sidePanelFrame)
			}, completion: { _ in
				if !reveal {
					self.prepare(sidePanelForDisplay: false)
				}

				self.transitionInProgress = false
				self.centerViewController?.view.isUserInteractionEnabled = !reveal
		})
	}
}
