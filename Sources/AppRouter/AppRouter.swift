//
//  AppRouter.swift
//
//  Created by Ryan Carver on 1/12/21.
//

import SwiftUI

public struct RouterContentView<Router: AppRouting>: View {

    public init(with router: Router) {
        self.router = router
    }

    @ObservedObject private var router: Router

    public var body: some View {
        router.makeContentView(route: router.baseRoute)
            .routing(with: router)
    }
}

public extension View {

    func routing<Router: AppRouting>(with router: Router) -> some View {
        RoutableView<Router>(content: self).environmentObject(router)
    }
}

public struct RouteState<Route> {

    public init(_ base: Route) {
        self.base = base
    }

    let base: Route
    private(set) var pushed: Route? = nil

    var current: Route {
        pushed ?? base
    }

    var isPushed: Bool {
        pushed != nil
    }

    mutating func push(route: Route) {
        pushed = route
    }

    mutating func pop() {
        pushed = nil
    }
}

public protocol AppRouting: ObservableObject {
    associatedtype Route: CustomStringConvertible
    associatedtype Content: View
    associatedtype NestedRouter: AppRouting where NestedRouter == Self
    var state: RouteState<Route> { get set }
    var parent: NestedRouter? { get }
    func makeContentView(route: Route) -> Content
    func makeChildRouter(route: Route) -> NestedRouter
}

public extension AppRouting {

    var baseRoute: Route {
        state.base
    }

    var currentRoute: Route {
        state.current
    }

    func push(route: Route) {
        state.push(route: route)
    }

    func pop() {
        parent?.state.pop()
    }

    func popToRoot() {
        var root: NestedRouter? = parent
        while root?.parent != nil { root = root?.parent }
        root?.state.pop()
    }
}

fileprivate extension AppRouting {

    var isPushedBinding: Binding<Bool> {
        Binding(get: { self.state.isPushed },
                set: { if !$0 { self.state.pop() } })
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
        if let route = router.state.pushed {
            let child = router.makeChildRouter(route: route)
            let content = child.makeContentView(route: route)
            let view = RoutableView(content: content)
            return AnyView(view.environmentObject(child))
        } else {
            return AnyView(EmptyView())
        }
    }
}
