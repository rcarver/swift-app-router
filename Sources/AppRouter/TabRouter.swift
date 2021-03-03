//
//  File.swift
//  
//
//  Created by Ryan Carver on 3/2/21.
//

import Foundation
import SwiftUI

/// A tab router controls 'tab' navigation, generally a TabView.
public protocol TabRouting: ObservableObject {

    /// The type that represents the current tab.
    ///
    /// This is generally an enum.
    associatedtype Tab: Hashable, CaseIterable

    /// The StackRouter implementation for each tab's navigation.
    associatedtype StackRouter: StackRouting

    /// The type of View content that's created for a tab's content.
    associatedtype TabContent: View

    /// The type of View content that's created for a tab item.
    associatedtype TabBarContent: View

    /// The current route.
    ///
    /// This property must be marked @Published to trigger state changes.
    ///
    /// You shouldn't have to get or set this property directly, instead use
    /// `tab` and `transition`.
    var route: TabRoute<Tab> { get set }

    /// Get the stack router for a tab.
    ///
    /// Each tab should have an separate persistent router.
    func getStackRouter(tab: Tab) -> StackRouter

    /// Turns a tab, at a router state, into a view.
    ///
    /// This is how the router transforms state to SwiftUI views.
    ///
    /// You'll generally want to delegate to the router to create its own content.
    /// `RouterNavigationView(with: router)` is a good way to do that.
    func makeContentView(tab: Tab, router: StackRouter) -> TabBarContent

    /// Make the view for the TabView's item.
    func makeTabItemView(tab: Tab) -> TabContent

    /// Respond to tab changes.
    ///
    /// This event will be called if the tab changes, OR the transition behavior
    /// causes the tab's router state to change. The `behavior` argument
    /// will reflect the action performed.
    ///
    /// It's common to want to perform some action when changing to a tab,
    /// generally by using the tab's router via `getStackRouter(tab: newTab)`.
    func tabDidTransition(from oldTab: Tab, to newTab: Tab, with behavior: TabBehavior)
}

/// Adopt this protocol to change how tab transitions behave by default.
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
        let current = self.tab

        route = TabRoute(tab: tab, behavior: behavior)

        switch behavior {
        case .keepState:
            if current != tab {
                tabDidTransition(from: current, to: tab, with: .keepState)
            }

        case .popToRoot:
            if current != tab {
                getStackRouter(tab: tab).popToRoot()
                tabDidTransition(from: current, to: tab, with: .popToRoot)
            }

        case .popToRootIfRepeated:
            if current == tab {
                getStackRouter(tab: tab).popToRoot()
                tabDidTransition(from: current, to: tab, with: .popToRoot)
            } else {
                tabDidTransition(from: current, to: tab, with: .keepState)
            }
        }
    }

    /// A Binding to the current selection. Used to update a TabView,
    /// and you can use it to sync your own views.
    var selectionBinding: Binding<Tab> {
        Binding(get: { self.tab },
                set: { self.tab = $0 })
    }
}

/// The current tab state.
public struct TabRoute<Tab> {

    /// Initialize a route to tab.
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

internal extension TabRouting {

    var defaultBehavior: TabBehavior {
        (self as? TabBehaving)?.defaultBehavior ?? .keepState
    }

    func makeTabView(_ tab: Tab) -> some View {
        let router = getStackRouter(tab: tab)
        return makeContentView(tab: tab, router: router)
            .environmentObject(router)
            .tabItem { makeTabItemView(tab: tab) }
            .tag(tab)
    }
}
