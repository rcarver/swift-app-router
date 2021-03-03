//
//  File.swift
//  
//
//  Created by Ryan Carver on 1/14/21.
//

import SwiftUI

enum TestHarness {

    struct State: Equatable, CustomDebugStringConvertible {
        var count: Int

        var debugDescription: String {
            "State[\(count)]"
        }
    }

    final class Router: StackRouting {

        internal init(state: State, parent: Router? = nil) {
            self.route = StackRoute(state)
            self.parent = parent
        }

        @Published var route: StackRoute<State>
        var parent: Router?

        func makeChildRouter(state: State) -> Router {
            Router(state: state, parent: self)
        }

        func makeContentView(state: State) -> some View {
            ContentView(count: state.count)
        }

        func nextSheet() {
            transition(.sheet(.navigable)) { state in
                state.count += 1
            }
        }

        func nextLink() {
            transition(.link) { state in
                state.count += 1
            }
        }

        func previousAutoPop() {
            transition(.link(.autoPop)) { state in
                state.count -= 1
            }
        }

        func nextReplace(_ multiplier: Int) {
            transition(.replace) { state in
                state.count *= multiplier
            }
        }

        func nextRoot(_ inc: Int) {
            transition(.root) { state in
                state.count += inc
            }
        }
    }

    struct ContentView: View {
        var count: Int
        @EnvironmentObject var router: Router
        var body: some View {
            VStack {
                Button(action: { router.nextLink() }) { Text("Link") }
                Button(action: { router.previousAutoPop() }) { Text("AutoPop") }
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

