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

    struct State: Equatable, Presentable {
        var count: Int
        var presentation: PresentationType = .link
    }

    final class TestRouter: AppRouting {

        internal init(state: State, parent: TestRouter? = nil) {
            self.route = Route(state)
            self.parent = parent
        }

        var route: Route<State>
        var parent: TestRouter?

        func makeChildRouter(state: State) -> TestRouter {
            TestRouter(state: state, parent: self)
        }

        func makeContentView(state: State) -> some View {
            Text("Hello \(state.count)")
        }
    }

    final class IntRouter: AppRouting {

        internal init(state: Int, parent: IntRouter? = nil) {
            self.route = Route(state)
            self.parent = parent
        }

        var route: Route<Int>
        var parent: IntRouter?

        func makeChildRouter(state: Int) -> IntRouter {
            IntRouter(state: state, parent: self)
        }

        func makeContentView(state: Int) -> some View {
            Text("Hello \(state)")
        }
    }
}

extension PresentationTests {

    func test_route_link() {
        let parent = IntRouter(state: 0)

        PresentationType.link.route(parent, to: 1)

        XCTAssertEqual(parent.route, Route(base: 0, pushed: 1, presentation: .link))
    }

    func test_route_link_autoPop() throws {
        let parent = IntRouter(state: 0)

        PresentationType.link.route(parent, to: 1)
        let child1 = parent.makeChildRouter(state: try XCTUnwrap(parent.route.pushed?.state))

        XCTAssertEqual(parent.route, Route(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child1.route, Route(1))

        PresentationType.link(.autoPop).route(child1, to: 2)
        let child2 = child1.makeChildRouter(state: try XCTUnwrap(child1.route.pushed?.state))

        XCTAssertEqual(parent.route, Route(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child1.route, Route(base: 1, pushed: 2, presentation: .link(.autoPop)))
        XCTAssertEqual(child2.route, Route(2))

        PresentationType.link(.autoPop).route(child2, to: 1)

        XCTAssertEqual(parent.route, Route(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child1.route, Route(1))
        XCTAssertEqual(child2.route, Route(2))
    }

    func test_route_sheet() {
        let parent = IntRouter(state: 0)

        PresentationType.sheet.route(parent, to: 1)

        XCTAssertEqual(parent.route, Route(base: 0, pushed: 1, presentation: .sheet))
    }

    func test_route_replace() throws {
        let parent = IntRouter(state: 0)

        PresentationType.link.route(parent, to: 1)

        let child = parent.makeChildRouter(state: try XCTUnwrap(parent.route.pushed?.state))

        XCTAssertEqual(parent.route, Route(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child.route, Route(1))

        PresentationType.replace.route(child, to: 2)

        XCTAssertEqual(parent.route, Route(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child.route, Route(2))
    }

    func test_route_root() throws {
        let parent = IntRouter(state: 0)

        PresentationType.link.route(parent, to: 1)

        let child = parent.makeChildRouter(state: try XCTUnwrap(parent.route.pushed?.state))

        XCTAssertEqual(parent.route, Route(base: 0, pushed: 1, presentation: .link))
        XCTAssertEqual(child.route, Route(1))

        PresentationType.root.route(child, to: 2)

        XCTAssertEqual(parent.route, Route(2))
        XCTAssertEqual(child.route, Route(1))
    }
}
