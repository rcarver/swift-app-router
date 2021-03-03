//
//  Test.m
//  
//
//  Created by Ryan Carver on 2/26/21.
//

import XCTest
import SwiftUI
@testable import AppRouter

class PresentationTests: XCTestCase {

    final class TestRouter: StackRouting {

        internal init(state: Int, parent: TestRouter? = nil) {
            self.route = StackRoute(state)
            self.parent = parent
        }

        var route: StackRoute<Int>
        var parent: TestRouter?

        func makeChildRouter(state: Int) -> TestRouter {
            TestRouter(state: state, parent: self)
        }

        func makeContentView(state: Int) -> some View {
            Text("Hello \(state)")
        }
    }
}

extension PresentationTests {

    func test_route_link() {
        let parent = TestRouter(state: 0)

        PresentationType.link.route(parent, to: 1)

        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 1, presentation: .link))
    }

    func test_route_link_same_state() {
        let parent = TestRouter(state: 0)

        PresentationType.link.route(parent, to: 0)

        XCTAssertEqual(parent.route, StackRoute(0))
    }

    func test_route_link_autoPop() throws {
        let parent = TestRouter(state: 0)

        PresentationType.link.route(parent, to: 1)
        let child1 = parent.makeChildRouter(state: try XCTUnwrap(parent.route.pushed?.state))

        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child1.route, StackRoute(1))

        PresentationType.link(.autoPop).route(child1, to: 2)
        let child2 = child1.makeChildRouter(state: try XCTUnwrap(child1.route.pushed?.state))

        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child1.route, StackRoute(base: 1, pushed: 2, presentation: .link(.autoPop)))
        XCTAssertEqual(child2.route, StackRoute(2))

        PresentationType.link(.autoPop).route(child2, to: 1)

        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child1.route, StackRoute(1))
        XCTAssertEqual(child2.route, StackRoute(2))
    }

    func test_route_sheet() {
        let parent = TestRouter(state: 0)

        PresentationType.sheet.route(parent, to: 1)

        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 1, presentation: .sheet))
    }

    func test_route_sheet_same_state() {
        let parent = TestRouter(state: 0)

        PresentationType.sheet.route(parent, to: 0)

        XCTAssertEqual(parent.route, StackRoute(0))
    }

    func test_route_replace() throws {
        let parent = TestRouter(state: 0)

        PresentationType.link.route(parent, to: 1)

        let child = parent.makeChildRouter(state: try XCTUnwrap(parent.route.pushed?.state))

        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child.route, StackRoute(1))

        PresentationType.replace.route(child, to: 2)

        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child.route, StackRoute(2))
    }

    func test_route_root() throws {
        let parent = TestRouter(state: 0)

        PresentationType.link.route(parent, to: 1)

        let child = parent.makeChildRouter(state: try XCTUnwrap(parent.route.pushed?.state))

        XCTAssertEqual(parent.route, StackRoute(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child.route, StackRoute(1))

        PresentationType.root.route(child, to: 2)

        XCTAssertEqual(parent.route, StackRoute(2))
        XCTAssertEqual(child.route, StackRoute(1))
    }
}
