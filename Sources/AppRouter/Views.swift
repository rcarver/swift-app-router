//
//  File.swift
//  
//
//  Created by Ryan Carver on 1/13/21.
//

import SwiftUI

/// Presents the base state of the router wrapped in a NavigationView,
/// passing the router to children through the environment.
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

/// Presents the base state of the router, passing the router to children
/// through the environment.
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

    /// Wraps the view to handle router changes.
    func routing<Router: AppRouting>(with router: Router) -> some View {
        RoutableView<Router>(content: self).environmentObject(router)
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
                isActive: router.isLinkActiveBinding) { EmptyView() }
            content
        }
        .sheet(isPresented: router.isSheetPresentedBinding, content: {
            destinationView
        })
    }

    var destinationView: AnyView {
        guard let pushed = router.route.pushed else {
            return AnyView(EmptyView())
        }

        let child = router.makeChildRouter(state: pushed.state)
        let content = child.makeContentView(state: pushed.state)
        let view = RoutableView(content: content).environmentObject(child)

        switch pushed.presentation {
        case .navigationSheet:
            return AnyView(NavigationView { view })
        case .sheet:
            return AnyView(view)
        case .link:
            return AnyView(view)
        }
    }
}

public struct RouterDebugView<Router: AppRouting>: View {

    public init(with router: Router) {
        self.router = router
    }

    private var router: Router

    public var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Routers: \(routerStack.count)")
                .font(.subheadline)
            ForEach(routerStack.indices) { index in
                RouterView(router: routerStack[index])
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
        .padding(8)
        .background(Color(.systemBackground).opacity(0.5))
        .border(Color.black)
        .padding(8)
    }

    struct RouterView: View {
        var router: Router
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(describing: router.objectAddress)).fontWeight(.bold)
                    + Text(" parent: ")
                    + Text(String(describing: router.parent?.objectAddress))
                Text(String(describing: router.route.base))
                    + Text(" pushed: ")
                    + Text(String(describing: router.route.pushed?.state))
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.1))
        }
    }

    var routerStack: [Router] {
        var stack: [Router] = [router]
        while let p = stack.last?.parent { stack.append(p) }
        return stack
    }
}

// MARK: - Test Harness

enum TestHarness {

    struct State: Presentable, CustomDebugStringConvertible {
        var count: Int
        var presentation: PresentationType = .link

        var debugDescription: String {
            "State[\(count)]"
        }
    }

    final class Router: AppRouting {

        internal init(state: State, parent: Router? = nil) {
            self.route = Route(state)
            self.parent = parent
        }

        @Published var route: Route<State>
        var parent: Router?

        func makeChildRouter(state: State) -> Router {
            Router(state: state, parent: self)
        }

        func makeContentView(state: State) -> some View {
            ContentView(count: state.count)
        }

        func nextSheet() {
            state = State(count: state.count + 1, presentation: .navigationSheet)
        }

        func nextLink() {
            state = State(count: state.count + 1, presentation: .link)
        }
    }

    struct ContentView: View {
        var count: Int
        @EnvironmentObject var router: Router
        var body: some View {
            VStack {
                Button(action: { router.nextLink() }) { Text("Link") }
                Button(action: { router.nextSheet() }) { Text("Sheet") }
                Divider()
                Button(action: { router.pop() }) { Text("Pop") }
                Button(action: { router.popToRoot() }) { Text("Pop to Root") }
                Divider()
                RouterDebugView(with: router)
            }
            .navigationBarTitle("Count \(count)")
        }
    }
}

struct TestHarness_Previews: PreviewProvider {
    typealias State = TestHarness.State
    typealias Router = TestHarness.Router

    static var previews: some View {
        RouterNavigationView(with: Router(state: State(count: 0)))
    }
}
