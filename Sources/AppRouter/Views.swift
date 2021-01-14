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
            RoutableView(with: router)
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
        RoutableView(with: router)
    }
}

struct RoutableView<Router: AppRouting>: View {

    public init(with router: Router) {
        self.router = router
    }

    @ObservedObject private var router: Router

    var body: some View {
        VStack(spacing: 0) {
            NavigationLink(
                destination: presentedView,
                isActive: router.isLinkActiveBinding) { EmptyView() }
            contentView
        }
        .sheet(isPresented: router.isSheetPresentedBinding, content: {
            presentedView
        })
    }

    var contentView: some View {
        router.makeContentView(state: router.route.base)
            .environmentObject(router)
    }

    var presentedView: AnyView {
        guard let pushed = router.route.pushed else {
            return AnyView(EmptyView())
        }

        let child = router.makeChildRouter(state: pushed.state)
        let view = RoutableView(with: child)

        switch pushed.presentation {
        case .navigationSheet:
            return AnyView(NavigationView { view })
        case .sheet:
            return AnyView(view)
        case .link:
            return AnyView(view)
        case .replace, .root:
            return AnyView(EmptyView())
        }
    }
}
