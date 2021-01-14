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

    @StateObject var router = Router(tab: .home)

    var body: some View {
        TabView(selection: $router.state) {
            HomeTabView()
                .tabItem { Text("Home") }
                .tag(Tab.home)

            ExploreTabView()
                .tabItem { Text("Explore") }
                .tag(Tab.explore)

            ProfileTabView()
                .tabItem { Text("Profile") }
                .tag(Tab.profile)
        }
        .environmentObject(router)
    }
}

/// The State type
enum Tab: Hashable {
    case home
    case explore
    case profile
}

/// Router implementation
final class Router: AppRouting {

    internal init(tab: Tab, parent: Router? = nil) {
        self.route = Route(tab)
        self.parent = parent
    }

    @Published var route: Route<Tab>
    var parent: Router?

    func makeChildRouter(state: Tab) -> Router {
        Router(tab: state, parent: self)
    }

    func makeContentView(state: Tab) -> some View {
        Text("Not Used")
    }
}

/// Custom route state transitions.
extension Router {

    /// Switch to a different tab
    func switchTo(tab: Tab) {
        state = tab
    }
}

// MARK: - Tab views

struct HomeTabView: View {
    @EnvironmentObject var router: Router
    var body: some View {
        VStack(spacing: 10) {
            Text("Home View")
            Button(action: { router.switchTo(tab: .explore) }) {
                Text("Go to Explore")
            }
            Button(action: { router.switchTo(tab: .profile) }) {
                Text("Go to Profile")
            }
        }
    }
}

struct ExploreTabView: View {
    @EnvironmentObject var router: Router
    var body: some View {
        VStack(spacing: 10) {
            Text("Explore View")
            Button(action: { router.switchTo(tab: .home) }) {
                Text("Go to Home")
            }
        }
    }
}

struct ProfileTabView: View {
    @EnvironmentObject var router: Router
    var body: some View {
        VStack(spacing: 10) {
            Text("Profile View")
            Button(action: { router.switchTo(tab: .home) }) {
                Text("Go to Home")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
