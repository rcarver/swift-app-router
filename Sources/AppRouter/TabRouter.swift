//
//  File.swift
//  
//
//  Created by Ryan Carver on 3/2/21.
//

import Foundation
import SwiftUI

public protocol TabRouting: ObservableObject {

    associatedtype StackRouter: AppRouting
    associatedtype Tab: Hashable, CaseIterable
    associatedtype TabContent: View
    associatedtype TabBarContent: View

    var route: TabRoute<Tab> { get set }

    func getRouter(tab: Tab) -> StackRouter
    func makeContentView(tab: Tab, router: StackRouter) -> TabBarContent
    func makeTabItemView(tab: Tab) -> TabContent
}

public struct TabRoute<Tab: Hashable> {

    public init(tab: Tab) {
        self.tab = tab
        self.behavior = .keepState
    }

    init(tab: Tab, behavior: TabBehavior) {
        self.tab = tab
        self.behavior = behavior
    }

    internal let tab: Tab
    internal let behavior: TabBehavior
}

public enum TabBehavior {
    case keepState
    case popToRoot
    case popToRootIfRepeated
}

public protocol TabBehaving {
    var defaultBehavior: TabBehavior { get }
}

public extension TabRouting {

    /// Get the current tab.
    ///
    /// Set the current tab with default behavior.
    var tab: Tab {
        get { route.tab }
        set { transition(newValue, with: defaultBehavior) }
    }

    /// Transition to tab with behavior.
    func transition(_ tab: Tab, with behavior: TabBehavior) {
        let current = tab

        route = TabRoute(tab: tab, behavior: behavior)

        switch behavior {
        case .keepState:
            break
        case .popToRoot:
            getRouter(tab: tab).popToRoot()
        case .popToRootIfRepeated:
            if current == tab {
                getRouter(tab: tab).popToRoot()
            }
        }
    }
}

internal extension TabRouting {

    var defaultBehavior: TabBehavior {
        (self as? TabBehaving)?.defaultBehavior ?? .keepState
    }

    func makeTabView(_ tab: Tab) -> some View {
        let router = getRouter(tab: tab)
        return makeContentView(tab: tab, router: router)
            .environmentObject(router)
            .tabItem { makeTabItemView(tab: tab) }
            .tag(tab)
    }

    var tabSelectionBinding: Binding<Tab> {
        Binding(get: { self.tab },
                set: { self.tab = $0 })
    }
}
