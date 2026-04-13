import Foundation
import os.log
import UIKit

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

        guard let keyWindow = UIWindow.keyWindow,
              let rootViewController = keyWindow.rootViewController else {
            return false
        }

        let viewFrame = convert(bounds, to: rootViewController.view)

        let topSafeArea = rootViewController.view.safeAreaInsets.top
        let bottomSafeArea = rootViewController.view.safeAreaInsets.bottom

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
        return UIWindow.keyWindow?.rootViewController?.topMostViewController()
    }
}

extension UIWindow {
    static var keyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

public class EventPublisher {
    private let repository: EventRepository
    private var startupDelayInSeconds: UInt64 = 1
    private var flushFrequencyNanoseconds: UInt64
    private var httpApiReader: HttpApiClient
    private var current_breakpoint: String = ""
    private var new_breakpoints: Set<String> = []
    private var visited: Set<String> = []
    private var collect: Bool = false
    public var configuredBreakpoints: [String: String] = [:]
    private var flushTask: Task<Void, Never>?

    init(repository: EventRepository, httpApiReader: HttpApiClient, flushFrequency: Int, collect: Bool, configuredBreakpoints: [String: String]) {
        self.repository = repository
        self.httpApiReader = httpApiReader
        self.flushFrequencyNanoseconds = UInt64(flushFrequency) * 1_000_000_000
        self.collect = collect
        self.configuredBreakpoints = configuredBreakpoints
    }

    @MainActor
    private func scanViews(view: UIView) {
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

    @MainActor
    private func scanControllers(controller: UIViewController, isSubRoot: Bool = false) {
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

    @MainActor
    private func collectBreakpoints() async {
        guard let rootViewController = UIWindow.keyWindow?.rootViewController else { return }

        self.new_breakpoints = [String(describing: type(of: UIApplication.shared.topMostViewController()))]
        self.visited = []

        if self.collect || !self.configuredBreakpoints.isEmpty {
            self.scanControllers(controller: rootViewController)

            let new_breakpoint = String(self.new_breakpoints.sorted().joined(separator: "|").djb2hash)

            if new_breakpoint != self.current_breakpoint {
                Logger.debug("Switching from \(self.current_breakpoint) to \(new_breakpoint)")
                self.current_breakpoint = new_breakpoint
                if self.collect {
                    let screenJpeg = Data(base64Encoded: rootViewController.view.screenShot.jpegData(compressionQuality: 1)!.base64EncodedString())!
                    try? await self.httpApiReader.sendPost(
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

    public func start() {
        Logger.debug("Event publisher started")

        flushTask = Task {
            try? await Task.sleep(nanoseconds: startupDelayInSeconds * 1_000_000_000)

            while !Task.isCancelled {
                await collectBreakpoints()

                let events = self.repository.getEvents()

                if !events.isEmpty {
                    try? await self.httpApiReader.sendPost(
                        requestUri: "/sdk",
                        requestData: TrackingEventBatch(events: events, time: DateTime.now())
                    )
                    self.repository.clearByEvents(events: events)
                }

                try? await Task.sleep(nanoseconds: flushFrequencyNanoseconds)
            }
        }
    }

    public func stop() {
        flushTask?.cancel()
        flushTask = nil
    }
}
