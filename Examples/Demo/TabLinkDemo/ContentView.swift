//
//  ContentView.swift
//  TabLinkDemo
//
//  Created by Ryan Carver on 1/13/21.
//

import SwiftUI
import AppRouter

/// The root SwiftUI View
struct ContentView: View {

    @StateObject var router = Router(screen:.home(HomeState()))

    var body: some View {
        TabView(selection: router.selectedTab) {
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
enum Screen: Equatable {
    case home(HomeState)
    case explore(ExploreState)
    case profile(ProfileState)
    case settings(SettingsState)
}

extension Screen: CustomStringConvertible {
    var description: String {
        switch self {
        case .home: return "home"
        case .explore: return "explore"
        case .profile: return "profile"
        case .settings: return"settings"
        }
    }
}

/// Sub-states for each screen
struct HomeState: Equatable {
    var tab: Tab { .home }
}

struct ExploreState: Equatable {
    var tab: Tab { .explore }
}

struct ProfileState: Equatable {
    var tab: Tab { .profile }
}

struct SettingsState: Equatable {
    var tab: Tab { .profile }
}

/// Each screen belongs to a tab
enum Tab: Hashable {
    case home
    case explore
    case profile
}

/// Router implementation
final class Router: StackRouting {

    internal init(screen: Screen, parent: Router? = nil) {
        self.route = Route(screen)
        self.parent = parent
    }

    @Published var route: Route<Screen>
    var parent: Router?

    func makeChildRouter(state: Screen) -> Router {
        Router(screen: state, parent: self)
    }

    @ViewBuilder
    func makeContentView(state: Screen) -> some View {
        switch state {
        case .settings:
            SettingsView()
        case .profile:
            ProfileView()
        default:
            Text("Other State: \(state.description)")
        }
    }
}

/// Custom route state transitions.
extension Router {

    func switchToHome() {
        transition(.home(HomeState()), via: .root)
    }

    func switchToExplore() {
        transition(.explore(ExploreState()), via: .root)
    }

    func switchToProfile() {
        transition(.profile(ProfileState()), via: .root)
    }

    func switchToSettings() {
        // TODO: it would be nice to let Settings define which tab it lives in
        switchToProfile()
        state = .settings(SettingsState())
    }

    var selectedTab: Binding<Tab> {
        Binding(get: { self.currentTab },
                set: { self.switchTo(tab: $0) })
    }

    private func switchTo(tab: Tab) {
        switch tab {
        case .home:
            switchToHome()
        case .explore:
            switchToExplore()
        case .profile:
            switchToProfile()
        }
    }

    private var currentTab: Tab {
        switch state {
        case .home(let state): return state.tab
        case .explore(let state): return state.tab
        case .profile(let state): return state.tab
        case .settings(let state): return state.tab
        }
    }
}

// MARK: - Tab views

struct HomeTabView: View {
    @EnvironmentObject var router: Router
    var body: some View {
        VStack(spacing: 10) {
            Text("Home View")
            Button(action: { router.switchToExplore() }) {
                Text("Go to Explore")
            }
            Button(action: { router.switchToProfile() }) {
                Text("Go to Profile")
            }
            Button(action: { router.switchToSettings() }) {
                Text("Settings")
            }
        }
    }
}

struct ExploreTabView: View {
    @EnvironmentObject var router: Router
    var body: some View {
        VStack(spacing: 10) {
            Text("Explore View")
            Button(action: { router.switchToHome() }) {
                Text("Go to Home")
            }
        }
    }
}

struct ProfileTabView: View {
    @EnvironmentObject var router: Router
    var body: some View {
        NavigationView {
            ProfileView()
                .routeSubviews(with: router)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ProfileView: View {
    @EnvironmentObject var router: Router
    var body: some View {
        VStack(spacing: 10) {
            Text("Profile View")
            Button(action: { router.switchToHome() }) {
                Text("Go to Home")
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { router.switchToSettings() }) {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings")
            .navigationTitle("Settings")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
