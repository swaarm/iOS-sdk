import Foundation
import os.log
import SwiftUI

extension String {
    var djb2hash: Int {
        let unicodeScalars = self.unicodeScalars.map { $0.value }
        return unicodeScalars.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1)
        }
    }
}

extension NSObject {
    var className: String {
        return String(describing: type(of: self))
    }

    class var className: String {
        return String(describing: self)
    }
}

extension UIView {
    var screenShot: UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let image = renderer.image { _ in
            drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        }
        return image
    }
}

extension UIView {
    var isVisibleToUser: Bool {
        if isHidden || alpha == 0 || superview == nil || window == nil {
            return false
        }

        guard let rootViewController = UIWindow.key!.rootViewController else {
            return false
        }

        let viewFrame = convert(bounds, to: rootViewController.view)

        let topSafeArea: CGFloat
        let bottomSafeArea: CGFloat

        if #available(iOS 11.0, *) {
            topSafeArea = rootViewController.view.safeAreaInsets.top
            bottomSafeArea = rootViewController.view.safeAreaInsets.bottom
        } else {
            topSafeArea = rootViewController.topLayoutGuide.length
            bottomSafeArea = rootViewController.bottomLayoutGuide.length
        }

        return viewFrame.minX >= 0 &&
            viewFrame.maxX <= rootViewController.view.bounds.width &&
            viewFrame.minY >= topSafeArea &&
            viewFrame.maxY <= rootViewController.view.bounds.height - bottomSafeArea
    }
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if presentedViewController == nil {
            return self
        }
        if let navigation = presentedViewController as? UINavigationController {
            return navigation.visibleViewController!.topMostViewController()
        }
        if let tab = presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        return presentedViewController!.topMostViewController()
    }
}

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        return UIWindow.key!.rootViewController?.topMostViewController()
    }
}

extension UIWindow {
    static var key: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}

public class EventPublisher {
    private let repository: EventRepository
    private let workerQueue: DispatchQueue = .init(label: "swaarm-event-publisher", qos: .utility)
    private var startupDelayInSeconds = 1
    private var timer: DispatchSourceTimer
    private var httpApiReader: HttpApiClient
    private var current_breakpoint: String = ""
    private var new_breakpoints: Set<String> = []
    private var visited: Set<String> = []
    private var collect: Bool = false
    public var configuredBreakpoints: [String: String] = [:]

    init(repository: EventRepository, httpApiReader: HttpApiClient, flushFrequency: Int, collect: Bool, configuredBreakpoints: [String: String]) {
        self.repository = repository
        timer = DispatchSource.makeTimerSource(queue: workerQueue)
        self.httpApiReader = httpApiReader
        self.collect = collect
        self.configuredBreakpoints = configuredBreakpoints

        timer.schedule(
            deadline: .now() + DispatchTimeInterval.seconds(startupDelayInSeconds),
            repeating: DispatchTimeInterval.seconds(flushFrequency)
        )
    }

    public func scanViews(view: UIView) {
        visited.insert(view.className)
        if view.isVisibleToUser {
            new_breakpoints.insert(view.className)
        }
        if let subRoot = view.window?.rootViewController {
            if !visited.contains(String(describing: type(of: subRoot))) {
                scanControllers(controller: subRoot, isSubRoot: true)
            }
        }
        for v in view.subviews {
            scanViews(view: v)
        }
    }

    public func scanControllers(controller: UIViewController, isSubRoot: Bool = false) {
        visited.insert(controller.className)
        if controller.isBeingPresented {
            new_breakpoints.insert(controller.className)
        }
        if isSubRoot {
            Logger.debug("subRoot \(controller)")
        }
        for c in controller.children {
            scanControllers(controller: c)
        }
        if let view = controller.viewIfLoaded {
            scanViews(view: view)
        }
    }

    public func start() {
        Logger.debug("Event publisher started")
        timer.setEventHandler {
            DispatchQueue.main.async {
                let rootViewController = UIWindow.key!.rootViewController
                self.new_breakpoints = [String(describing: type(of: UIApplication.shared.topMostViewController()))]
                self.visited = []
                if self.collect || !self.configuredBreakpoints.isEmpty {
                    self.scanControllers(controller: rootViewController!)

                    let new_breakpoint = String(self.new_breakpoints.sorted().joined(separator: "|").djb2hash)

                    if new_breakpoint != self.current_breakpoint {
                        Logger.debug("Switching from \(self.current_breakpoint) to \(new_breakpoint)")
                        self.current_breakpoint = new_breakpoint
                        if self.collect {
                            let screenJpeg = Data(base64Encoded: rootViewController!.view.screenShot.jpegData(compressionQuality: 1)!.base64EncodedString())!
                            try? self.httpApiReader.sendPostBlocking(
                                requestUri: "/sdk-breakpoints",
                                requestData: Breakpoint(type: "VIEW", data: BreakpointData(name: new_breakpoint, screenshot: screenJpeg))
                            )
                        }
                        if self.configuredBreakpoints.keys.contains(new_breakpoint) {
                            self.repository.addEvent(typeId: self.configuredBreakpoints[new_breakpoint])
                        }
                    }
                }
            }

            let events = self.repository.getEvents()

            if events.count == 0 {
                return
            }

            try? self.httpApiReader.sendPostBlocking(
                requestUri: "/sdk",
                requestData: TrackingEventBatch(events: events, time: DateTime.now())
            )
            self.repository.clearByEvents(events: events)
        }

        timer.resume()
    }

    public func stop() {
        timer.suspend()
    }
}
