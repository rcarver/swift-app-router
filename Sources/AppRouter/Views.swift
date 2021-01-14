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
