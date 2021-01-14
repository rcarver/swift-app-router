//
//  File.swift
//  
//
//  Created by Ryan Carver on 1/14/21.
//

import XCTest
import SwiftUI
@testable import AppRouter

class AppRoutingTests: XCTestCase {

    final class TestRouter: AppRouting {

        internal init(state: Int, parent: TestRouter? = nil) {
            self.route = Route(state)
            self.parent = parent
        }

        var route: Route<Int>
        var parent: TestRouter?

        func makeChildRouter(state: Int) -> TestRouter {
            TestRouter(state: state, parent: self)
        }

        func makeContentView(state: Int) -> some View {
            Text("Hello \(state)")
        }
    }

    func test_route_base() {
        let parent = TestRouter(state: 0)
        XCTAssertEqual(parent.route, Route(0))

        parent.pop()
        XCTAssertEqual(parent.route, Route(0), "no change")
    }

    func test_push_route_state() {
        let parent = TestRouter(state: 0)
        parent.state = 1
        XCTAssertEqual(parent.route, Route(base: 0, pushed: 1, presentation: .link))

        parent.pop()
        XCTAssertEqual(parent.route, Route(0), "parent drops push")
    }

    func test_push_route_state_to_child() throws {
        let parent = TestRouter(state: 0)
        parent.state = 1

        let child = parent.makeChildRouter(state: try XCTUnwrap(parent.route.pushed?.state))

        XCTAssertEqual(parent.route, Route(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child.route, Route(1))

        child.pop()
        XCTAssertEqual(parent.route, Route(0), "parent drops push")
        XCTAssertEqual(child.route, Route(1))
    }

    func test_popToRoot() throws {
        let parent = TestRouter(state: 0)
        parent.state = 1

        let child1 = parent.makeChildRouter(state: try XCTUnwrap(parent.route.pushed?.state))
        child1.state = 2

        let child2 = child1.makeChildRouter(state: try XCTUnwrap(child1.route.pushed?.state))
        child2.state = 3

        let child3 = child2.makeChildRouter(state: try XCTUnwrap(child2.route.pushed?.state))

        XCTAssertEqual(parent.route, Route(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child1.route, Route(base: 1, pushed: 2, presentation: .link))
        XCTAssertEqual(child2.route, Route(base: 2, pushed: 3, presentation: .link))
        XCTAssertEqual(child3.route, Route(3))

        child3.popToRoot()
        XCTAssertEqual(parent.route, Route(0), "parent drops push")
        XCTAssertEqual(child1.route, Route(base: 1, pushed: 2, presentation: .link), "intermediate children are unaffected")
        XCTAssertEqual(child2.route, Route(base: 2, pushed: 3, presentation: .link), "intermediate children are unaffected")
        XCTAssertEqual(child3.route, Route(3))
    }
}
