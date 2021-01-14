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

    var state: State {
        get { route.current }
        set {
            if let pState = newValue as? Presentable {
                route.push(state: newValue, presentation: pState.presentation)
            } else {
                route.push(state: newValue, presentation: .link)
            }
        }
    }

    var root: State {
        get { rootRouter.state }
        set { rootRouter.route = Route(newValue) }
    }

    func pop() {
        parent?.route.pop()
    }

    func popToRoot() {
        rootRouter.route.pop()
    }

    private var rootRouter: NestedRouter {
        var root: NestedRouter = self
        while let p = root.parent { root = p }
        return root
    }
}

public enum PresentationType {

    /// Present the state via NavigationLink.
    case link

    /// Present the state via sheet()
    case sheet

    /// Present the state via sheet(), embedding the in a NavigationView
    case navigationSheet
}

public protocol Presentable {
    var presentation: PresentationType { get }
}

public struct Route<State> {

    public init(_ base: State) {
        self.base = base
    }

    struct PushedState<State> {
        var state: State
        var presentation: PresentationType
    }

    let base: State
    private(set) var pushed: PushedState<State>? = nil

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

extension AppRouting {

    var isLinkActiveBinding: Binding<Bool> {
        Binding(get: { self.route.pushed?.presentation == .link },
                set: { if !$0 { self.route.pop() } })
    }

    var isSheetPresentedBinding: Binding<Bool> {
        Binding(get: { self.route.pushed?.presentation.isSheet ?? false },
                set: { if !$0 { self.route.pop() } })
    }
}

extension PresentationType {

    var isSheet: Bool {
        switch self {
        case .sheet, .navigationSheet: return true
        case .link: return false
        }
    }
}

