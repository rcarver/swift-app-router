//
//  File.swift
//  
//
//  Created by Ryan Carver on 1/13/21.
//

import SwiftUI

public extension View {

    /// Wrap the view to handle router state changes.
    ///
    /// You'll need to supply your own NavigationView if needed.
    func routeSubviews<Router: AppRouting>(with router: Router) -> some View {
        PushedStateView(router: router, content: self)
    }
}

/// Presents the base state of the router wrapped in a NavigationView,
/// passing the router to children through the environment.
public struct RouterNavigationView<Router: AppRouting>: View {

    public init(with router: Router) {
        self.router = router
    }

    @ObservedObject private var router: Router

    public var body: some View {
        NavigationView {
            FullyRoutedView(router: router)
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
        FullyRoutedView(router: router)
    }
}


// MARK: - Internal Views

/// Implements a fully routed view. The view's content is the router's
/// base state and pushed states are presented as appropriate.
struct FullyRoutedView<Router: AppRouting>: View {

    @ObservedObject var router: Router

    /// This view owns the result of Router.makeContentView. We maintain a reference
    /// here so that any long-lived objects created along with the view stay alive.
    @State private var storedView: AnyView?

    var body: some View {
        PushedStateView(router: router, content: contentView)
    }

    private var contentView: AnyView {
        if let view = storedView {
            return view
        }

        let view = router.makeContentView(state: router.route.base)
            .environmentObject(router)

        DispatchQueue.main.async {
            self.storedView = AnyView(view)
        }

        return AnyView(view)
    }
}

/// Implements presentation of pushed states, wrapping some content.
struct PushedStateView<Router: AppRouting, Content: View>: View {

    @ObservedObject var router: Router
    var content: Content

    var body: some View {
        VStack(spacing: 0) {
            NavigationLink(
                destination: presentedView,
                isActive: router.isLinkActiveBinding) { EmptyView() }
            content
        }
        .sheet(isPresented: router.isSheetPresentedBinding, content: {
            presentedView
        })
    }

    private var presentedView: AnyView {
        guard let pushed = router.route.pushed else {
            return AnyView(EmptyView())
        }

        let child = router.makeChildRouter(state: pushed.state)
        let view = FullyRoutedView(router: child)

        switch pushed.presentation {
        case .sheet(let options):
            if options.makeContentNavigable {
                return AnyView(NavigationView { view })
            } else {
                return AnyView(view)
            }
        case .link:
            return AnyView(view)
        case .replace, .root:
            return AnyView(EmptyView())
        }
    }
}
