//
//  AppRouter.swift
//
//  Created by Ryan Carver on 1/12/21.
//

import SwiftUI

public struct RouterNavigationView<Router: AppRouting>: View {

    public init(with router: Router) {
        self.router = router
    }

    @ObservedObject private var router: Router

    public var body: some View {
        NavigationView {
            RouterContentView(with: router)
        }
    }
}

public struct RouterContentView<Router: AppRouting>: View {

    public init(with router: Router) {
        self.router = router
    }

    @ObservedObject private var router: Router

    public var body: some View {
        router.makeContentView(state: router.route.base)
            .routing(with: router)
    }
}

public extension View {

    func routing<Router: AppRouting>(with router: Router) -> some View {
        RoutableView<Router>(content: self).environmentObject(router)
    }
}

public struct Route<State> {

    public init(_ base: State) {
        self.base = base
    }

    let base: State
    private(set) var pushed: State? = nil

    var current: State {
        pushed ?? base
    }

    var isPushed: Bool {
        pushed != nil
    }

    mutating func push(state: State) {
        pushed = state
    }

    mutating func pop() {
        pushed = nil
    }
}

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
        set { route.push(state: newValue) }
    }

    func pop() {
        parent?.route.pop()
    }

    func popToRoot() {
        var root: NestedRouter? = parent
        while root?.parent != nil { root = root?.parent }
        root?.route.pop()
    }
}

fileprivate extension AppRouting {

    var isPushedBinding: Binding<Bool> {
        Binding(get: { self.route.isPushed },
                set: { if !$0 { self.route.pop() } })
    }
}

struct RoutableView<Router: AppRouting>: View {

    init<Content: View>(content: Content) {
        self.content = AnyView(content)
    }

    private var content: AnyView
    @EnvironmentObject private var router: Router

    var body: some View {
        VStack(spacing: 0) {
            NavigationLink(
                destination: destinationView,
                isActive: router.isPushedBinding) { EmptyView() }
            content
        }
    }

    var destinationView: AnyView {
        if let state = router.route.pushed {
            let child = router.makeChildRouter(state: state)
            let content = child.makeContentView(state: state)
            let view = RoutableView(content: content)
            return AnyView(view.environmentObject(child))
        } else {
            return AnyView(EmptyView())
        }
    }
}
