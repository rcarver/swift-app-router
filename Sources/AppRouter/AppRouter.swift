//
//  AppRouter.swift
//
//  Created by Ryan Carver on 1/12/21.
//

import SwiftUI

public protocol AppRouting: ObservableObject {
    associatedtype State
    associatedtype Content: View
    associatedtype NestedRouter: AppRouting where NestedRouter == Self
    var route: Route<State> { get set }
    var parent: NestedRouter? { get }
    func makeChildRouter(state: State) -> NestedRouter
    func makeContentView(state: State) -> Content
}

public extension AppRouting {

    /// Get the current router state.
    ///
    /// Setting the state modifies the pushed state.
    var state: State {
        get {
            route.current
        }
        set {
            if let pState = newValue as? Presentable {
                switch pState.presentation {
                case .link, .sheet, .navigationSheet:
                    route.push(state: newValue, presentation: pState.presentation)
                case .replace:
                    route = Route(newValue)
                case .root:
                    rootRouter.route = Route(newValue)
                }
            } else {
                route.push(state: newValue, presentation: .link)
            }
        }
    }

    /// Pop one level.
    func pop() {
        route.pop()
        parent?.route.pop()
    }

    /// Pop to root immediately, skipping each intermediate child.
    func popToRoot() {
        route.pop()
        rootRouter.route.pop()

    }
}

/// The suppored types of presentation.
public enum PresentationType {

    /// Present the state via NavigationLink.
    case link

    /// Present the state via sheet().
    case sheet

    /// Present the state via sheet(), embedding content in a NavigationView.
    case navigationSheet

    /// Replace the current base state, instead of pushing a new state.
    case replace

    /// Replace the root router's base state, popping all children.
    case root
}

/// If your router's State adopts this protocol it can control how
/// the pushed state is presented.
public protocol Presentable {

    /// The presentation to use for pushed state.
    var presentation: PresentationType { get }
}

public struct Route<State> {

    public init(_ base: State) {
        self.base = base
    }

    internal struct PushedState<State> {
        var state: State
        var presentation: PresentationType
    }

    internal let base: State
    internal private(set) var pushed: PushedState<State>? = nil
}

extension Route: Equatable where State: Equatable {}
extension Route.PushedState: Equatable where State: Equatable {}

internal extension Route {

    init(base: State, pushed: State, presentation: PresentationType) {
        self.base = base
        self.pushed = PushedState(state: pushed, presentation: presentation)
    }

    var current: State {
        pushed?.state ?? base
    }

    mutating func push(state: State, presentation: PresentationType) {
        pushed = PushedState(state: state, presentation: presentation)
    }

    mutating func pop() {
        pushed = nil
    }
}

internal extension AppRouting {

    var isLinkActiveBinding: Binding<Bool> {
        Binding(get: { self.route.pushed?.presentation == .link },
                set: { if !$0 { self.route.pop() } })
    }

    var isSheetPresentedBinding: Binding<Bool> {
        Binding(get: { self.route.pushed?.presentation.isSheet ?? false },
                set: { if !$0 { self.route.pop() } })
    }

    var objectAddress: String {
        String("\(Unmanaged.passUnretained(self).toOpaque())".suffix(6))
    }

    var rootRouter: NestedRouter {
        var root: NestedRouter = self
        while let p = root.parent { root = p }
        return root
    }

    var routerStack: [NestedRouter] {
        var stack: [NestedRouter] = [self]
        while let p = stack.last?.parent { stack.append(p) }
        return stack
    }
}

internal extension PresentationType {

    var isSheet: Bool {
        switch self {
        case .sheet, .navigationSheet: return true
        case .link: return false
        case .replace: return false
        case .root: return false
        }
    }
}

