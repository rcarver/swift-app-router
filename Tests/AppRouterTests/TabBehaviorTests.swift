//
//  File.swift
//
//
//  Created by Ryan Carver on 1/14/21.
//

import XCTest
import SwiftUI
@testable import AppRouter

class TabBehaviorTests: XCTestCase {

    final class TestStackRouter: StackRouting {

        internal init(state: Int, parent: TestStackRouter? = nil) {
            self.route = StackRoute(state)
            self.parent = parent
        }

        var route: StackRoute<Int>
        var parent: TestStackRouter?

        func makeChildRouter(state: Int) -> TestStackRouter {
            TestStackRouter(state: state, parent: self)
        }

        func makeContentView(state: Int) -> some View {
            Text("Hello \(state)")
        }
    }

    enum Tab: String, Hashable, CaseIterable {
        case first
        case second
    }

    struct Transition: Equatable {
        var oldTab: Tab
        var newTab: Tab
        var behavior: TabBehavior
    }

    final class TestTabRouter: TabRouting {

        init() {
            firstRouter = TestStackRouter(state: 1)
            secondRouter = TestStackRouter(state: 2)
            route = TabRoute(tab: .first)
        }

        var firstRouter: TestStackRouter
        var secondRouter: TestStackRouter

        @Published var route: TabRoute<Tab>

        func getStackRouter(tab: Tab) -> TestStackRouter {
            switch tab {
            case .first: return firstRouter
            case .second: return secondRouter
            }
        }

        func makeContentView(tab: Tab, router: TestStackRouter) -> some View {
            RouterNavigationView(with: router)
        }

        func makeTabItemView(tab: Tab) -> some View {
            Text(tab.rawValue)
        }

        var transitions: [Transition] = []

        func tabDidTransition(from oldTab: Tab, to newTab: Tab, with behavior: TabBehavior) {
            transitions.append(Transition(oldTab: oldTab, newTab: newTab, behavior: behavior))
        }
    }
}

extension TabBehaviorTests {

    func test_transition_keepState() {
        let router = TestTabRouter()
        router.secondRouter.state = 5

        router.transition(.second, with: .keepState)

        XCTAssertEqual(router.tab, .second)
        XCTAssertEqual(router.secondRouter.state, 5)
        XCTAssertEqual(router.transitions, [
            Transition(oldTab: .first, newTab: .second, behavior: .keepState)
        ])
    }

    func test_transition_keepState_no_change() {
        let router = TestTabRouter()

        router.transition(.first, with: .keepState)

        XCTAssertEqual(router.tab, .first)
        XCTAssertEqual(router.transitions, [])
    }

    func test_transition_popToRoot() {
        let router = TestTabRouter()
        router.secondRouter.state = 5

        router.transition(.second, with: .popToRoot)

        XCTAssertEqual(router.tab, .second)
        XCTAssertEqual(router.secondRouter.state, 2)
        XCTAssertEqual(router.transitions, [
            Transition(oldTab: .first, newTab: .second, behavior: .popToRoot)
        ])
    }

    func test_transition_popToRoot_no_change() {
        let router = TestTabRouter()

        router.transition(.first, with: .popToRoot)

        XCTAssertEqual(router.tab, .first)
        XCTAssertEqual(router.transitions, [])
    }

    func test_transition_popToRootIfRepeated() {
        let router = TestTabRouter()
        router.secondRouter.state = 5

        router.transition(.second, with: .popToRootIfRepeated)

        XCTAssertEqual(router.tab, .second)
        XCTAssertEqual(router.secondRouter.state, 5)
        XCTAssertEqual(router.transitions, [
            Transition(oldTab: .first, newTab: .second, behavior: .keepState)
        ])

        router.transition(.second, with: .popToRootIfRepeated)

        XCTAssertEqual(router.tab, .second)
        XCTAssertEqual(router.secondRouter.state, 2)
        XCTAssertEqual(router.transitions, [
            Transition(oldTab: .first, newTab: .second, behavior: .keepState),
            Transition(oldTab: .second, newTab: .second, behavior: .popToRoot)
        ])
    }
}
