//
//  LinkDemoApp.swift
//
//
//  Created by Ryan Carver on 1/12/21.
//

import SwiftUI
import Combine
import AppRouter

/// The root SwiftUI View
struct ContentView: View {

    var body: some View {
        RouterNavigationView(with: Router(state: 0))
            .navigationViewStyle(StackNavigationViewStyle())
    }
}

/// Router implementation
final class Router: StackRouting {

    init(state: Int, parent: Router? = nil) {
        self.route = StackRoute(state)
        self.parent = parent
    }

    @Published var route: StackRoute<Int>
    let parent: Router?

    func makeChildRouter(state: Int) -> Router {
        Router(state: state, parent: self)
    }

    func makeContentView(state: Int) -> some View {
        CounterView(model: CounterViewModel(count: state))
    }
}

/// Custom route state transitions.
extension Router {

    /// Move to the next screen with a increment.
    func next(_ inc: Int) {
        state += inc
    }

    /// Move to the previous screen, popping if appropriate.
    func previous() {
        transition(.link(.autoPop)) { state in
            state -= 1
        }
    }
}

class CounterViewModel: ObservableObject {

    init(count: Int) {
        self.count = count

        Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .scan(0) { count, _ in count + 1 }
            .map { "Plus \($0)" }
            .assign(to: &$delayedMessage)
    }

    deinit {
        // Ensure that this model is deallocated with its view.
        print("CounterViewModel.deinit", count)
    }

    private var cancellables = Set<AnyCancellable>()

    @Published var count: Int
    @Published var delayedMessage: String = "Start"
}

/// Display the counter screen.
struct CounterView: View {

    @ObservedObject var model: CounterViewModel
    @EnvironmentObject private var router: Router

    var body: some View {
        VStack(spacing: 20) {
            Text(model.delayedMessage)
            Button(action: { router.next(1) }) { Text("Next +1") }
            Button(action: { router.next(2) }) { Text("Next +2") }
            Button(action: { router.next(0) }) { Text("Next 0 (No Change)") }
            Button(action: { router.previous() }) { Text("Previous (AutoPop)") }
            Button(action: { router.pop() }) { Text("Back") }
            Button(action: { router.popToRoot() }) { Text("Back to Top") }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .buttonStyle(CustomButtonStyle())
        .background(Color.pick(model.count))
        .navigationBarTitle("Count is \(model.count)")
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

