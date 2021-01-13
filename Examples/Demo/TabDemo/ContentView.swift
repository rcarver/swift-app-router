//
//  ContentView.swift
//  TabDemo
//
//  Created by Ryan Carver on 1/13/21.
//

import SwiftUI

struct ContentView: View {

    @State var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
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
    }
}

enum Tab: Hashable {
    case home
    case explore
    case profile
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct HomeTabView: View {
    var body: some View {
        Text("Home View")
    }
}

struct ExploreTabView: View {
    var body: some View {
        Text("Explore View")
    }
}

struct ProfileTabView: View {
    var body: some View {
        Text("Profile View")
    }
}
