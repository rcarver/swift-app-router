//
//  File.swift
//  
//
//  Created by Ryan Carver on 1/14/21.
//

import XCTest
import SwiftUI
@testable import AppRouter

class StackRoutingTests: XCTestCase {

    struct StackTransition: Equatable, CustomStringConvertible {
        init(_ oldState: Int, _ newState: Int) {
            self.oldState = oldState
            self.newState = newState
        }
        var oldState: Int
        var newState: Int
        var description: String { "\(oldState):\(newState)" }
    }

    final class TestRouter: StackRouting {

        init(state: Int, transition: @escaping Transition, parent: TestRouter? = nil) {
            self.route = StackRoute(state)
            self.transition = transition
            self.parent = parent
        }

        var route: StackRoute<Int>

        // Note: the type should be `Transition`, but it fails to compile:
        // Reference to invalid type alias 'Transition' of type 'StackRoutingTests.TestRouter'
        var transition: (Int, Int) -> Void

        var parent: TestRouter?

        func makeChildRouter(state: Int) -> TestRouter {
            TestRouter(state: state, transition: transition, parent: self)
        }

        func makeContentView(state: Int) -> some View {
            Text("Hello \(state)")
        }
    }

    var transitions: [StackTransition]!
    var transitionHandler: TestRouter.Transition!

    override func setUp() {
        transitions = []
        transitionHandler = {
            self.transitions.append(StackTransition($0, $1))
        }
    }

    func test_route_base() {
        let parent = TestRouter(state: 0, transition: transitionHandler)
        XCTAssertEqual(parent.route, StackRoute(0))

        parent.pop()
        XCTAssertEqual(parent.route, StackRoute(0), "no change")

        XCTAssertEqual(transitions, [])
    }

    func test_push_route_state() {
        let parent = TestRouter(state: 0, transition: transitionHandler)
        parent.state = 1
        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 1, presentation: .link))

        XCTAssertEqual(transitions, [
            StackTransition(0, 1)
        ])

        parent.pop()
        XCTAssertEqual(parent.route, StackRoute(0), "parent drops push")

        XCTAssertEqual(transitions, [
            StackTransition(0, 1),
            StackTransition(1, 0)
        ])
    }

    func test_push_route_state_to_child() throws {
        let parent = TestRouter(state: 0, transition: transitionHandler)
        parent.state = 1

        let child = parent.makeChildRouter(state: try XCTUnwrap(parent.route.pushed?.state))

        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child.route, StackRoute(1))

        child.pop()
        XCTAssertEqual(parent.route, StackRoute(0), "parent drops push")
        XCTAssertEqual(child.route, StackRoute(1))

        XCTAssertEqual(transitions, [
            StackTransition(0, 1),
            StackTransition(1, 0)
        ])
    }

    func test_push_route_state_to_children() throws {
        let parent = TestRouter(state: 0, transition: transitionHandler)
        parent.state = 1

        let child1 = parent.makeChildRouter(state: try XCTUnwrap(parent.route.pushed?.state))
        child1.state = 2

        let child2 = child1.makeChildRouter(state: try XCTUnwrap(child1.route.pushed?.state))
        child2.state = 3

        let child3 = child2.makeChildRouter(state: try XCTUnwrap(child2.route.pushed?.state))
        child3.state = 4 // orphan pushed state

        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child1.route, StackRoute(base: 1, pushed: 2, presentation: .link))
        XCTAssertEqual(child2.route, StackRoute(base: 2, pushed: 3, presentation: .link))
        XCTAssertEqual(child3.route, StackRoute(base: 3, pushed: 4, presentation: .link))

        child3.pop()
        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child1.route, StackRoute(base: 1, pushed: 2, presentation: .link))
        XCTAssertEqual(child2.route, StackRoute(2), "parent push is dropped")
        XCTAssertEqual(child3.route, StackRoute(3), "orphaned push is dropped")

        XCTAssertEqual(transitions, [
            StackTransition(0, 1),
            StackTransition(1, 2),
            StackTransition(2, 3),
            StackTransition(3, 4),
            StackTransition(4, 2)
        ])
    }

    func test_popToRoot() throws {
        let parent = TestRouter(state: 0, transition: transitionHandler)
        parent.state = 1

        let child1 = parent.makeChildRouter(state: try XCTUnwrap(parent.route.pushed?.state))
        child1.state = 2

        let child2 = child1.makeChildRouter(state: try XCTUnwrap(child1.route.pushed?.state))
        child2.state = 3

        let child3 = child2.makeChildRouter(state: try XCTUnwrap(child2.route.pushed?.state))
        child3.state = 4 // orphan pushed state

        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child1.route, StackRoute(base: 1, pushed: 2, presentation: .link))
        XCTAssertEqual(child2.route, StackRoute(base: 2, pushed: 3, presentation: .link))
        XCTAssertEqual(child3.route, StackRoute(base: 3, pushed: 4, presentation: .link))

        child3.popToRoot()
        XCTAssertEqual(parent.route, StackRoute(0), "parent drops push")
        XCTAssertEqual(child1.route, StackRoute(base: 1, pushed: 2, presentation: .link), "intermediate children are unaffected")
        XCTAssertEqual(child2.route, StackRoute(base: 2, pushed: 3, presentation: .link), "intermediate children are unaffected")
        XCTAssertEqual(child3.route, StackRoute(3), "orphaned push is dropped")

        XCTAssertEqual(transitions, [
            StackTransition(0, 1),
            StackTransition(1, 2),
            StackTransition(2, 3),
            StackTransition(3, 4),
            StackTransition(4, 0)
        ])
    }

    func test_transition() {
        let parent = TestRouter(state: 0, transition: transitionHandler)

        parent.transition(1, via: .sheet)

        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 1, presentation: .sheet))

        XCTAssertEqual(transitions, [
            StackTransition(0, 1)
        ])
    }

    func test_transition_closure() {
        let parent = TestRouter(state: 0, transition: transitionHandler)

        parent.transition(.sheet) { state in
            state += 2
        }

        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 2, presentation: .sheet))

        XCTAssertEqual(transitions, [
            StackTransition(0, 2)
        ])
    }

    func test_transition_closure_return() {
        let parent = TestRouter(state: 0, transition: transitionHandler)

        let result = parent.transition(.sheet) { state -> String in
            state += 2
            return "OK"
        }

        XCTAssertEqual(result, "OK")
        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 2, presentation: .sheet))

        XCTAssertEqual(transitions, [
            StackTransition(0, 2)
        ])
    }

    func test_transition_closure_throws() {
        let parent = TestRouter(state: 0, transition: transitionHandler)

        struct Err: Error, Equatable {}

        do {
            try parent.transition(.sheet) { state in
                state += 2
                throw Err()
            }
            XCTFail("should throw")
        } catch {
            XCTAssertEqual(error as? Err, Err())
        }

        XCTAssertEqual(parent.route, StackRoute(0))

        XCTAssertEqual(transitions, [])
    }
}

class PresentableTests: XCTestCase {

    final class PresentableRouter: StackRouting, Presentable {

        internal init(state: Int, parent: PresentableRouter? = nil) {
            self.route = StackRoute(state)
            self.parent = parent
        }

        var route: StackRoute<Int>
        var parent: PresentableRouter?

        var defaultPresentation: PresentationType { .sheet }

        func makeChildRouter(state: Int) -> PresentableRouter {
            PresentableRouter(state: state, parent: self)
        }

        func makeContentView(state: Int) -> some View {
            Text("Hello \(state)")
        }

        func stateDidTransition(from oldState: Int, to newState: Int) {

        }
    }

    func test_defaultPresentation() {
        let parent = PresentableRouter(state: 0)

        parent.state = 3

        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 3, presentation: .sheet))
    }
}
