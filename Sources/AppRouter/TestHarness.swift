//
//  File.swift
//  
//
//  Created by Ryan Carver on 1/14/21.
//

import SwiftUI

enum TestHarness {

    struct State: Equatable, Presentable, CustomDebugStringConvertible {
        var count: Int
        var presentation: PresentationType = .link

        var debugDescription: String {
            "State[\(count)]"
        }
    }

    final class Router: AppRouting {

        internal init(state: State, parent: Router? = nil) {
            self.route = Route(state)
            self.parent = parent
        }

        @Published var route: Route<State>
        var parent: Router?

        func makeChildRouter(state: State) -> Router {
            Router(state: state, parent: self)
        }

        func makeContentView(state: State) -> some View {
            ContentView(count: state.count)
        }

        func nextSheet() {
            state = State(count: state.count + 1, presentation: .sheet(.navigable))
        }

        func nextLink() {
            state = State(count: state.count + 1, presentation: .link)
        }

        func nextReplace(_ multiplier: Int) {
            state = State(count: state.count * multiplier, presentation: .replace)
        }

        func nextRoot(_ inc: Int) {
            state = State(count: state.count + inc, presentation: .root)
        }
    }

    struct ContentView: View {
        var count: Int
        @EnvironmentObject var router: Router
        var body: some View {
            VStack {
                Button(action: { router.nextLink() }) { Text("Link") }
                Button(action: { router.nextSheet() }) { Text("Sheet") }
                Button(action: { router.nextReplace(10) }) { Text("Replace x10") }
                Button(action: { router.nextRoot(5) }) { Text("Root +5") }
                Divider()
                Button(action: { router.pop() }) { Text("Pop") }
                Button(action: { router.popToRoot() }) { Text("Pop to Root") }
                Divider()
                RouterDebugView(with: router)
            }
            .navigationBarTitle("Count \(count)")
        }
    }
}

struct TestHarness_Previews: PreviewProvider {
    typealias State = TestHarness.State
    typealias Router = TestHarness.Router

    static var previews: some View {
        RouterNavigationView(with: Router(state: State(count: 0)))
    }
}

