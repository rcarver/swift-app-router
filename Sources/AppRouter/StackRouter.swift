//
//  AppRouter.swift
//
//  Created by Ryan Carver on 1/12/21.
//

import SwiftUI

/// A stack router controls 'stack' navigation styles, such as NavigationView and Sheet.
///
/// This router is meant to be used for the majority of app navigation.
public protocol StackRouting: ObservableObject {

    /// A type that represents the current state.
    associatedtype State: Equatable

    /// The type of View content that's created.
    associatedtype Content: View

    /// A self-referential type for parent/child router relationships.
    associatedtype NestedRouter: StackRouting where NestedRouter == Self

    /// A function that receives (oldState, newState) whenever the state changes.
    typealias Transition = (_ oldState: Self.State, _ newState: Self.State) -> Void

    /// The current route.
    ///
    /// This property must be marked @Published to trigger state changes.
    ///
    /// You shouldn't have to get or set this property directly, instead use
    /// `state` and `transition`.
    var route: StackRoute<State> { get set }

    /// The parent router, if this router isn't the root of the stack.
    var parent: NestedRouter? { get }

    /// Handle events when the state changes. Optional.
    ///
    /// This is where you should handle any side effects of state transitions,
    /// because it will properly trigger on both forward (push) and backward
    /// (pop) transitions.
    /// 
    /// Make sure to pass the handler to child routers if appropriate.
    var transition: Transition { get }

    /// Construct a new instance of this type, state.
    ///
    /// The returned instance should have its `parent` property set
    /// to the current router.
    func makeChildRouter(state: State) -> NestedRouter

    /// Turns a state into a view.
    ///
    /// This is how the router transforms state to SwiftUI views.
    func makeContentView(state: State) -> Content
}

public extension StackRouting {

    /// Default transition handler does nothing.
    var transition: Transition { { _, _ in } }
}

/// Adopt this protocol to change how state transitions are presented by default.
public protocol Presentable {

    /// Return the default presentation for state transitions.
    var defaultPresentation: PresentationType { get }
}

public extension StackRouting {

    /// Get the current router state.
    ///
    /// Setting the state transitions with default presentation.
    var state: State {
        get { route.current }
        set { transition(newValue, via: defaultPresentation) }
    }

    /// Transition to state with presentation.
    func transition(_ state: State, via presentation: PresentationType) {
        let oldState = self.state
        presentation.route(self, to: state)
        let newState = self.state
        if oldState != newState {
            transition(oldState, newState)
        }
    }

    /// Transition via presentation, modifying state with closure.
    func transition<Out>(_ presentation: PresentationType, modify: (inout State) throws -> Out) rethrows -> Out {
        let oldState = state
        var newState = state
        let output = try modify(&newState)
        presentation.route(self, to: newState)
        if oldState != newState {
            transition(oldState, newState)
        }
        return output
    }

    /// Pop one level.
    func pop() {
        let oldState = self.state
        route.pop()
        parent?.route.pop()
        let newState = parent?.state ?? self.state
        if oldState != newState {
            transition(oldState, newState)
        }
    }

    /// Pop to root immediately, skipping each intermediate child.
    func popToRoot() {
        // FIXME: sheets pop the the first child. It seems like a problem
        // in the view, perhaps in SwiftUI.
        let oldState = self.state
        route.pop()
        rootRouter.route.pop()
        let newState = rootRouter.state
        if oldState != newState {
            transition(oldState, newState)
        }
    }
}

/// The current stack state.
public struct StackRoute<State> {

    /// Initialize a route to state.
    public init(_ base: State) {
        self.base = base
    }

    internal struct PushedState {
        var state: State
        var presentation: PresentationType
    }

    internal let base: State
    internal private(set) var pushed: PushedState? = nil
}

extension StackRoute: Equatable where State: Equatable {}
extension StackRoute.PushedState: Equatable where State: Equatable {}

internal extension StackRoute {

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

internal extension StackRouting {

    var isLinkActiveBinding: Binding<Bool> {
        Binding(get: { self.route.pushed?.presentation.isLink ?? false },
                set: { if !$0 { self.popViaBinding() } })
    }

    var isSheetPresentedBinding: Binding<Bool> {
        Binding(get: { self.route.pushed?.presentation.isSheet ?? false },
                set: { if !$0 { self.popViaBinding() } })
    }

    /// When called from a views binding, we're in the *parent* router,
    /// so calling parent.pop() causes recursion.
    func popViaBinding() {
        let oldState = self.state
        route.pop()
        let newState = self.state
        if oldState != newState {
            transition(oldState, newState)
        }
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

    var defaultPresentation: PresentationType {
        if let p = self as? Presentable {
            return p.defaultPresentation
        } else {
            return .default
        }
    }
}

fileprivate extension PresentationType {

    var isLink: Bool {
        switch self {
        case .link: return true
        default: return false
        }
    }

    var isSheet: Bool {
        switch self {
        case .sheet: return true
        default: return false
        }
    }
}
