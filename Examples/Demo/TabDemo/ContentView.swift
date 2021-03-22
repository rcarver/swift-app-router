//
//  ContentView.swift
//  TabDemo
//
//  Created by Ryan Carver on 1/13/21.
//

import SwiftUI
import AppRouter

/// The root SwiftUI View
struct ContentView: View {

    @StateObject var router = TabRouter()

    var body: some View {
        RouterTabView(with: router)
    }
}

/// The Tab type
enum Tab: String, Hashable, CaseIterable {
    case home
    case explore
    case profile
}

/// Tab Router implementation
final class TabRouter: TabRouting, ObservableObject {

    init() {
        tabRouters = [
            .home: NavRouter(state: 1),
            .explore: NavRouter(state: 2),
            .profile: NavRouter(state: 3)
        ]
        route = TabRoute(.explore)
    }

    @Published var route: TabRoute<Tab>

    var transition: Transition { tabDidTransition }

    private var tabRouters: [ Tab : NavRouter ] = [:]

    func getStackRouter(tab: Tab) -> NavRouter {
        tabRouters[tab] ?? NavRouter(state: 999)
    }

    func makeContentView(tab: Tab, router: NavRouter) -> some View {
        RouterNavigationView(with: router)
    }

    @ViewBuilder
    func makeTabItemView(tab: Tab) -> some View {
        switch tab {
        case .home:
            VStack {
                Image(systemName: "house")
                Text("Home")
            }
        case .explore:
            VStack {
                Image(systemName: "flashlight.on.fill")
                Text("Explore")
            }
        case .profile:
            VStack {
                Image(systemName: "person")
                Text("Profile")
            }
        }
    }
}

func tabDidTransition(from oldTab: Tab, to newTab: Tab, with transition: TabTransitionType) {
    print("Tab transition from:\(oldTab) to:\(newTab) (\(transition))")
}

func stackDidTransition(from oldState: Int, to newState: Int, with transition: StackTransitionType) {
    print("Stack transition from:\(oldState) to:\(newState) (\(transition))")
}

extension TabRouter: TabBehaving {
    var defaultBehavior: TabBehavior {
        .popToRootIfRepeated
    }
}

extension TabRouter {

    /// Move to a specific tab at count.
    ///
    /// This shows that the tab router can perform compound tab/stack operations.
    func goToTabAtCount(_ tab: Tab, count: Int) {
        self.tab = tab
        getStackRouter(tab: tab).state = count
    }
}

/// Stack Router implementation
final class NavRouter: StackRouting {

    internal init(state: Int, parent: NavRouter? = nil) {
        self.route = StackRoute(state)
        self.parent = parent
    }

    @Published var route: StackRoute<Int>

    var transition: (Int, Int, StackTransitionType) -> Void { stackDidTransition }

    var parent: NavRouter?

    func makeChildRouter(state: Int) -> NavRouter {
        NavRouter(state: state, parent: self)
    }

    func makeContentView(state: Int) -> some View {
        CountView(count: state)
    }
}


// MARK: - Content views

struct CountView: View {
    var count: Int
    @EnvironmentObject var tabRouter: TabRouter
    @EnvironmentObject var navRouter: NavRouter
    var body: some View {
        VStack(spacing: 10) {
            Text("Count is \(count)")
            Text("Tab is \(tabRouter.tab.rawValue)")
            Button(action: { navRouter.state += 1 }) {
                Text("Plus One")
            }
            Button(action: { tabRouter.goToTabAtCount(.home, count: 5) }) {
                Text("Home at 5")
            }
        }
        .navigationTitle("Count is \(count)")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
