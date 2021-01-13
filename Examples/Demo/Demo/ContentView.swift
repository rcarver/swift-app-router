//
//  File.swift
//
//
//  Created by Ryan Carver on 1/12/21.
//

import SwiftUI
import AppRouter

final class Router: LinkRoutable {

    required init(route: Int, parent: Router? = nil) {
        self.state = RouteState(route)
        self.parent = parent
    }

    @Published var state: RouteState<Int>
    let parent: Router?

    func next(_ inc: Int) {
        push(route: route + inc)
    }

    func makeChildRouter(route: Int) -> Router {
        Router(route: route, parent: self)
    }

    func makeContentView(route: Int) -> some View {
        CounterView(count: route)
    }
}

struct ContentView: View {

    var body: some View {
        NavigationView {
            RouterContentView(with: Router(route: 0))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct CounterView: View {

    var count: Int

    @EnvironmentObject private var router: Router

    var body: some View {
        VStack(spacing: 20) {
            Button(action: { router.next(1) }) { Text("Next +1") }
            Button(action: { router.next(2) }) { Text("Next +2") }
            Button(action: { router.pop() }) { Text("Back") }
            Button(action: { router.popToRoot() }) { Text("Top") }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .buttonStyle(CustomButtonStyle())
        .background(Color.pick(count))
        .navigationBarTitle("Count is \(count)")
    }

    struct CustomButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(10)
                .foregroundColor(.primary)
                .background(Color(.systemBackground).opacity(configuration.isPressed ? 0.2 : 0.5))
                .cornerRadius(10)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension Color {
    static func pick(_ count: Int) -> Color {
        switch count {
        case 0: return Color.purple
        case 1: return Color.red
        case 2: return Color.blue
        case 3: return Color.green
        case 4: return Color.yellow
        default: return Color.pink
        }
    }
}

