//
//  Created by Mikael Hultgren on 2016-11-14.
//  Copyright © 2016 Artsoftheinsane. All rights reserved.
//

import Foundation
import UIKit

protocol EventTimerDelegate: class {
	func updatedStart(to: Date, whileEditing: Bool)
	func updatedStop(to: Date, whileEditing: Bool)
	func updatedRunningWith(start: Date, stop: Date)
}

@IBDesignable
class EventTimer: UIView {
	// Delegates
	public weak var delegate: EventTimerDelegate?

    // Private
    private let pi2 = .pi * 2.0
    private let pi2_60 = .pi * 2.0 / 60

    private var updateTimer: Timer?
    private var isStopped: Bool = false
    private var isStarted: Bool = false

    private var startTouchPathLayer: CAShapeLayer = CAShapeLayer()
    private var startLayer: CAShapeLayer = CAShapeLayer()
    private var startPathLayer: CAShapeLayer = CAShapeLayer()

    private var stopTouchPathLayer: CAShapeLayer = CAShapeLayer()
    private var stopLayer: CAShapeLayer = CAShapeLayer()
    private var stopPathLayer: CAShapeLayer = CAShapeLayer()

    private var secondLayer: CAShapeLayer = CAShapeLayer()
    private var secondProgressTicksLayer: CAShapeLayer = CAShapeLayer()

    private var deltaAngle: Double = 0
    private var deltaTransform: CATransform3D?
    private var deltaLayer: CAShapeLayer?

    private var tracking: Bool = false
    private var trackingTouch: Int = 0

    private var startDate: Date?
    private var runningDate: Date?
    private var stopDate: Date?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup(frame: self.bounds)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    override func prepareForInterfaceBuilder() {
        setup(frame: CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height))
    }

    // MARK: Gestures
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !tracking
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // If we have more than one touch then the intent clearly isn't to
        // rotate the dial
        guard
			isStarted,
			touches.count == 1,
			let touch = touches.first else {
				super.touchesBegan(touches, with: event)

				return
		}

        let point = touch.location(in: self)
        deltaLayer = nil

        if let presentation = startPathLayer.presentation(),
			presentation.hitTest(startPathLayer.convert(point, from: layer)) != nil {
            deltaLayer = startLayer

            startTouchPathLayer.strokeEnd = 1
        } else if isStopped, let presentation = stopPathLayer.presentation(),
			presentation.hitTest(stopPathLayer.convert(point, from: layer)) != nil {
            deltaLayer = stopLayer

			stopTouchPathLayer.strokeEnd = 1
        }

        // If the touch hasnt touched either stop or start then forward up
        // the chain and return
        guard let deltaLayer = deltaLayer else {
            super.touchesBegan(touches, with: event)

            return
        }

		updateTimer?.invalidate()

        // Calculate the angle in radians
        let cx = deltaLayer.position.x
        let cy = deltaLayer.position.y

        let dx = point.x - cx
        let dy = point.y - cy

        let angle = atan2(dy, dx)

        deltaAngle = Double(angle)
        deltaTransform = deltaLayer.transform

        trackingTouch = touch.hash
        tracking = true
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard
			let deltaLayer = deltaLayer,
			let deltaTransform = deltaTransform,
			let touch = touches.filter({ (t: UITouch) -> Bool in
				return trackingTouch == t.hash
			}).first else {
				tracking = false
				self.deltaLayer = nil

				super.touchesMoved(touches, with: event)

				return
		}

        let point = touch.location(in: self)

        // Calculate the angle in radians
        let cx = deltaLayer.position.x
        let cy = deltaLayer.position.y

        let dx = point.x - cx
        let dy = point.y - cy

        let angle = Double(atan2(dy, dx))
        let da = delta(from: deltaAngle, to: angle)

		// The deltaangle applied to the transform
        let transform = CATransform3DRotate(deltaTransform, CGFloat(da), 0, 0, 1)

		// Save for next iteration
		self.deltaAngle = angle
		self.deltaTransform = transform

		if deltaLayer == self.startLayer {
			let seconds = timeInterval(from: da)
			startDate = startDate?.addingTimeInterval(seconds)

			if let startDate = startDate {
				delegate?.updatedStart(to: startDate, whileEditing: true)
			}
		} else if deltaLayer == self.stopLayer {
			let seconds = timeInterval(from: da)
			stopDate = stopDate?.addingTimeInterval(seconds)

			if let stopDate = stopDate {
				delegate?.updatedStop(to: stopDate, whileEditing: true)
			}
		}

		CATransaction.begin()
		CATransaction.setDisableActions(true)

		deltaLayer.transform = transform

		CATransaction.commit()
    }

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard
			let deltaLayer = deltaLayer,
			touches.filter({ (t: UITouch) -> Bool in
				return trackingTouch == t.hash
			}).first != nil else {
				tracking = false
				self.deltaLayer = nil

				super.touchesEnded(touches, with: event)

				return
		}

		if deltaLayer == self.startLayer, let startDate = startDate {
			drawStart(with: startDate)

			delegate?.updatedStart(to: startDate, whileEditing: false)
			startTouchPathLayer.strokeEnd = 0

			if !isStopped {
				updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [unowned self] (timer) in
					let now = Date()
					self.runningDate = now
					self.drawStop(with: now)

					if let startDate = self.startDate {
						self.delegate?.updatedRunningWith(start: startDate, stop: now)
					}
				})
			}
		} else if deltaLayer == self.stopLayer, let stopDate = stopDate {
			drawStop(with: stopDate)

			delegate?.updatedStop(to: stopDate, whileEditing: false)
			stopTouchPathLayer.strokeEnd = 0
		}

		tracking = false
		self.deltaLayer = nil
	}

	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard
			deltaLayer != nil,
			touches.filter({ (t: UITouch) -> Bool in
				return trackingTouch == t.hash
			}).first != nil else {
				tracking = false
				self.deltaLayer = nil

				super.touchesCancelled(touches, with: event)

				return
		}

		tracking = false
		deltaLayer = nil
	}
}

// MARK: Public functions
extension EventTimer {
    public func setup(with startDate: Date, and stopDate: Date?) {
        reset()

        self.startDate = startDate
        drawStart(with: startDate)

        isStarted = true

        if let stopDate = stopDate {
            isStopped = true
            runningDate = stopDate
            drawStop(with: stopDate)
        } else {
            isStopped = false
            let now = Date()
            runningDate = now
            drawStop(with: now)

            updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [unowned self] (timer) in
                let now = Date()
                self.runningDate = now
                self.drawStop(with: now)

                if let startDate = self.startDate {
                    self.delegate?.updatedRunningWith(start: startDate, stop: now)
                }
            })
        }

        self.stopDate = stopDate
    }

    public func stop(with date: Date) {
        updateTimer?.invalidate()

        isStopped = true
        stopDate = date
    }
}

// MARK: Private functions
extension EventTimer {
    internal func reset() {
        updateTimer?.invalidate()

        isStarted = false
        isStopped = false

        secondLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1)
        startLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1)
        stopLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1)


        startTouchPathLayer.strokeEnd = 0
        stopTouchPathLayer.strokeEnd = 0

        secondProgressTicksLayer.sublayers?.forEach({ (element) in
            element.isHidden = false
        })
    }

    internal func timeInterval(from angle: Double) -> TimeInterval {
        return angle / pi2 * 3600
    }

    internal func delta(from angleA: Double, to angleB: Double) -> Double {
        var diff = angleB - angleA

        while diff < -.pi {
            diff += pi2
        }
        while diff > .pi {
            diff -= pi2
        }

        return diff
    }

    internal func drawStart(with date: Date) {
        let angle = pi2 * floor(fmod(date.timeIntervalSince1970, 3600) / 60) / 60
        startLayer.transform = CATransform3DMakeRotation(CGFloat(angle), 0, 0, 1)
    }

    internal func drawStop(with date: Date) {
        let stopSeconds = date.timeIntervalSince1970

        // We want a fluid update to the seconds
        let secondsIntoMinute = fmod(stopSeconds, 60)

        let secondAngle = pi2 * secondsIntoMinute / 60
        secondLayer.transform = CATransform3DMakeRotation(CGFloat(secondAngle), 0, 0, 1)

        // Update the tick marks for the seconds
        let currentSecondTick: Int = Int(floor(secondsIntoMinute))
        if let layers = secondProgressTicksLayer.sublayers {
            for (index, element) in layers.enumerated() {
                element.isHidden = index >= currentSecondTick
            }
        }

        let secondsIntoHour = fmod(stopSeconds, 3600)
        let minuteAngle = pi2 * floor(secondsIntoHour / 60) / 60
        stopLayer.transform = CATransform3DMakeRotation(CGFloat(minuteAngle), 0, 0, 1)
    }

    internal func setup(frame: CGRect) {
        // =====================
        // = Ticks initializer =
        // =====================
        let largeTickPathWidth: Double = 5
        let smallTickPathWidth: Double = 3

        let largeTickPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: largeTickPathWidth, height: 14))
        let smallTickPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: smallTickPathWidth, height: 11))

        for i in 1...60 {
            let tick = CAShapeLayer()
            let angle = pi2_60 * Double(i)

            if i % 15 == 0 {
                // position
                tick.bounds = CGRect(x: 0.0, y: 0.0, width: largeTickPathWidth, height: Double(frame.size.width / 2.0 - 30))
                tick.position = CGPoint(x: frame.midX, y: frame.midY)
                tick.anchorPoint = CGPoint(x: 0.5, y: 1)

                // drawing
                tick.transform = CATransform3DMakeRotation(CGFloat(angle), 0, 0, 1)
                tick.fillColor = UIColor(white: 0.167, alpha: 1).cgColor
                tick.lineWidth = 1
                tick.path = largeTickPath.cgPath
            } else {
                // position
                tick.bounds = CGRect(x: 0.0, y: 0.0, width: smallTickPathWidth, height: Double(frame.size.width / 2.0 - 31.5))
                tick.position = CGPoint(x: frame.midX, y: frame.midY)
                tick.anchorPoint = CGPoint(x: 0.5, y: 1)

                // drawing
                tick.transform = CATransform3DMakeRotation(CGFloat(angle), 0, 0, 1)
                tick.fillColor = UIColor(white: 0.292, alpha: 1).cgColor
                tick.lineWidth = 1
                tick.path = smallTickPath.cgPath
            }

            layer.addSublayer(tick)
        }

        // ==========================
        // = Stop initializer =
        // ==========================

        // We make the bounds larger for the hit test, otherwise the target is
        // to damn small for human hands, martians not included
        let stopPath = UIBezierPath()
        stopPath.move(to: CGPoint(x: 25, y: 17))
        stopPath.addLine(to: CGPoint(x: 20, y: 0))
        stopPath.addLine(to: CGPoint(x: 30, y: 0))

        stopPathLayer.frame = CGRect(x: 0, y: 0, width: 50, height: 50)

        let stopPathFillColor = UIColor(colorLiteralRed: 0.427, green: 0.784, blue: 0.992, alpha: 1)
        // drawing
        stopPathLayer.fillColor = stopPathFillColor.cgColor
        stopPathLayer.lineWidth = 1
        stopPathLayer.path = stopPath.cgPath

        // touch path
        let stopTouchPath = UIBezierPath(ovalIn: CGRect(x: -50, y: -50, width: 150, height: 150))

        stopTouchPathLayer.frame = CGRect(x: -10, y: -30, width: 70, height: 70)
        stopTouchPathLayer.fillColor = UIColor.clear.cgColor
        stopTouchPathLayer.strokeColor = stopPathFillColor.withAlphaComponent(0.5).cgColor
        stopTouchPathLayer.strokeEnd = 0
        stopTouchPathLayer.lineWidth = 6
        stopTouchPathLayer.path = stopTouchPath.cgPath

        // position
        stopLayer.bounds = CGRect(x: 0, y: 0, width: 50, height: frame.size.width / 2 - 10)
        stopLayer.anchorPoint = CGPoint(x: 0.5, y: 1)
        stopLayer.position = CGPoint(x: frame.midX, y: frame.midY)

        stopLayer.addSublayer(stopPathLayer)
        stopLayer.addSublayer(stopTouchPathLayer)
        layer.addSublayer(stopLayer)

        // =========================
        // = Start initializer =
        // =========================

        // We make the bounds larger for the hit test, otherwise the target is
        // to damn small for human hands, martians not included
        let startPath = UIBezierPath()
        startPath.move(to: CGPoint(x: 25, y: 17))
        startPath.addLine(to: CGPoint(x: 20, y: 0))
        startPath.addLine(to: CGPoint(x: 30, y: 0))

        startPathLayer.frame = CGRect(x: 0, y: 0, width: 50, height: 50)

        let startPathFillColor = UIColor(colorLiteralRed: 0.941, green: 0.686, blue: 0.314, alpha: 1)
        // drawing
        startPathLayer.fillColor = startPathFillColor.cgColor
        startPathLayer.lineWidth = 1
        startPathLayer.path = startPath.cgPath

        // touch path
        let startTouchPath = UIBezierPath(ovalIn: CGRect(x: -50, y: -50, width: 150, height: 150))

        startTouchPathLayer.frame = CGRect(x: -10, y: -30, width: 70, height: 70)
        startTouchPathLayer.fillColor = UIColor.clear.cgColor
        startTouchPathLayer.strokeColor = startPathFillColor.withAlphaComponent(0.5).cgColor
        startTouchPathLayer.strokeEnd = 0
        startTouchPathLayer.lineWidth = 6
        startTouchPathLayer.path = startTouchPath.cgPath

        // position
        startLayer.bounds = CGRect(x: 0, y: 0, width: 50, height: frame.size.width / 2 - 10)
        startLayer.anchorPoint = CGPoint(x: 0.5, y: 1)
        startLayer.position = CGPoint(x: frame.midX, y: frame.midY)

        startLayer.addSublayer(startPathLayer)
        startLayer.addSublayer(startTouchPathLayer)
        layer.addSublayer(startLayer)

        // ==========================
        // = Second initializer =
        // ==========================
        let secondPath = UIBezierPath()
        secondPath.move(to: CGPoint(x: 3.5, y: 0))
        secondPath.addLine(to: CGPoint(x: 0, y: 7))
        secondPath.addLine(to: CGPoint(x: 7, y: 7))

        // Position
        secondLayer.bounds = CGRect(x: 0, y: 0, width: 7, height: frame.size.width / 2 - 62)
        secondLayer.anchorPoint = CGPoint(x: 0.5, y: 1)
        secondLayer.position = CGPoint(x: frame.midX, y: frame.midY)

        let secondPathFillColor = UIColor(colorLiteralRed: 0.843, green: 0.306, blue: 0.314, alpha: 1)
        // drawing
        secondLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1)
        secondLayer.fillColor = secondPathFillColor.cgColor
        secondLayer.lineWidth = 1
        secondLayer.path = secondPath.cgPath

        layer.addSublayer(secondLayer)

        // =========================================
        // = Second progress ticks initializer =
        // =========================================
        secondProgressTicksLayer.bounds = CGRect(x: 0, y: 0, width: frame.size.width - 100, height: frame.size.width - 100)
        secondProgressTicksLayer.position = CGPoint(x: frame.midX, y: frame.midY)
        secondProgressTicksLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        layer.addSublayer(secondProgressTicksLayer)

        let secondTickPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 3, height: 2))
        for i in 1...60 {
            let angle = pi2_60 * Double(i)
            let tick = CAShapeLayer()

            // position
            tick.bounds = CGRect(x: 0, y: 0, width: 3, height: secondProgressTicksLayer.bounds.size.width / 2)
            tick.position = CGPoint(x: secondProgressTicksLayer.bounds.midX, y: secondProgressTicksLayer.bounds.midY)
            tick.anchorPoint = CGPoint(x: 0.5, y: 1)

            // drawing
            tick.transform = CATransform3DMakeRotation(CGFloat(angle), 0, 0, 1)
            tick.fillColor = secondPathFillColor.cgColor
            tick.lineWidth = 1
            tick.path = secondTickPath.cgPath

            secondProgressTicksLayer.addSublayer(tick)
        }
    }
}
