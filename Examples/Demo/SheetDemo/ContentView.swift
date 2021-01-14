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
        RouterNavigationView(with: Router(state: Screen(count: 0, message: "Welcome")))
            .navigationViewStyle(StackNavigationViewStyle())
    }
}

// Router state
struct Screen: Presentable {
    var count: Int
    var message: String
    var presentation: PresentationType = .link
}

/// Router implementation
final class Router: AppRouting {

    init(state: Screen, parent: Router? = nil) {
        self.route = Route(state)
        self.parent = parent
    }

    @Published var route: Route<Screen>
    let parent: Router?

    func makeChildRouter(state: Screen) -> Router {
        Router(state: state, parent: self)
    }

    @ViewBuilder
    func makeContentView(state: Screen) -> some View {
        MessageView(count: state.count, message: state.message)
    }
}

/// Custom route state transitions.
extension Router {

    func navigateTo(messsage: String) {
        state = Screen(count: state.count + 1, message: messsage, presentation: .link)
    }

    func showSheet(messsage: String) {
        if state.count >= 3 {
            state = Screen(count: state.count + 1, message: messsage, presentation: .sheet)
        } else {
            state = Screen(count: state.count + 1, message: messsage, presentation: .navigationSheet)
        }
    }
}

/// Display the counter screen.
struct MessageView: View {

    var count: Int
    var message: String

    @EnvironmentObject private var router: Router

    var body: some View {
        VStack(spacing: 20) {
            Text("\(message) \(count)")
            Button(action: { router.showSheet(messsage: "Sheet") }) { Text("Sheet") }
            Button(action: { router.navigateTo(messsage: "Push") }) { Text("Push") }
            Button(action: { router.pop() }) { Text("Back") }
            Button(action: { router.popToRoot() }) { Text("Back to Top") }
            Button(action: { router.root = Screen(count: count * 10, message: message) }) { Text("Top x10") }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .buttonStyle(CustomButtonStyle())
        .background(Color.pick(count))
        .navigationBarTitle("\(message) \(count)")
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


