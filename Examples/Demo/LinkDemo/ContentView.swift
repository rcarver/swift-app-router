//
//  LinkDemoApp.swift
//
//
//  Created by Ryan Carver on 1/12/21.
//

import SwiftUI
import AppRouter

/// The root SwiftUI View
struct ContentView: View {

    var body: some View {
        RouterNavigationView(with: Router(state: 0))
            .navigationViewStyle(StackNavigationViewStyle())
    }
}

/// Router implementation
final class Router: AppRouting {

    init(state: Int, parent: Router? = nil) {
        self.route = Route(state)
        self.parent = parent
    }

    @Published var route: Route<Int>
    let parent: Router?

    func makeChildRouter(state: Int) -> Router {
        Router(state: state, parent: self)
    }

    func makeContentView(state: Int) -> some View {
        CounterView(count: state)
    }
}

/// Custom route state transitions.
extension Router {

    /// Move to the next screen with a increment.
    func next(_ inc: Int) {
        state += inc
    }
}

/// Display the counter screen.
struct CounterView: View {

    var count: Int

    @EnvironmentObject private var router: Router

    var body: some View {
        VStack(spacing: 20) {
            Button(action: { router.next(1) }) { Text("Next +1") }
            Button(action: { router.next(2) }) { Text("Next +2") }
            Button(action: { router.pop() }) { Text("Back") }
            Button(action: { router.popToRoot() }) { Text("Back to Top") }
            Button(action: { router.root = count * 10 }) { Text("Top x10") }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .buttonStyle(CustomButtonStyle())
        .background(Color.pick(count))
        .navigationBarTitle("Count is \(count)")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
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

