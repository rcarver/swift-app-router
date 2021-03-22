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

    final class TestTabRouter: TabRouting {

        init(transition: @escaping Transition) {
            firstRouter = TestStackRouter(state: 1)
            secondRouter = TestStackRouter(state: 2)
            route = TabRoute(.first)
            self.transition = transition
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

        var transition: (Tab, Tab, TabTransitionType) -> Void
    }

    struct TabTransition: Equatable {
        init(_ oldTab: Tab, _ newTab: Tab, _ transition: TabTransitionType) {
            self.oldTab = oldTab
            self.newTab = newTab
            self.transition = transition
        }
        var oldTab: Tab
        var newTab: Tab
        var transition: TabTransitionType
    }

    var transitions: [TabTransition]!
    var transitionHandler: TestTabRouter.Transition!

    override func setUp() {
        transitions = []
        transitionHandler = { oldTab, newTab, transition in
            self.transitions.append(TabTransition(oldTab, newTab, transition))
        }
    }
}

extension TabBehaviorTests {

    func test_transition_keepState() {
        let router = TestTabRouter(transition: transitionHandler)
        router.secondRouter.state = 5

        router.transition(.second, with: .keepState)

        XCTAssertEqual(router.tab, .second)
        XCTAssertEqual(router.secondRouter.state, 5)
        XCTAssertEqual(transitions, [
            TabTransition(.first, .second, .keepState)
        ])
    }

    func test_transition_keepState_no_change() {
        let router = TestTabRouter(transition: transitionHandler)

        router.transition(.first, with: .keepState)

        XCTAssertEqual(router.tab, .first)
        XCTAssertEqual(transitions, [])
    }

    func test_transition_popToRoot() {
        let router = TestTabRouter(transition: transitionHandler)
        router.secondRouter.state = 5

        router.transition(.second, with: .popToRoot)

        XCTAssertEqual(router.tab, .second)
        XCTAssertEqual(router.secondRouter.state, 2)
        XCTAssertEqual(transitions, [
            TabTransition(.first, .second, .popToRoot)
        ])
    }

    func test_transition_popToRoot_no_change() {
        let router = TestTabRouter(transition: transitionHandler)

        router.transition(.first, with: .popToRoot)

        XCTAssertEqual(router.tab, .first)
        XCTAssertEqual(transitions, [])
    }

    func test_transition_popToRootIfRepeated() {
        let router = TestTabRouter(transition: transitionHandler)
        router.secondRouter.state = 5

        router.transition(.second, with: .popToRootIfRepeated)

        XCTAssertEqual(router.tab, .second)
        XCTAssertEqual(router.secondRouter.state, 5)
        XCTAssertEqual(transitions, [
            TabTransition(.first, .second, .keepState)
        ])

        router.transition(.second, with: .popToRootIfRepeated)

        XCTAssertEqual(router.tab, .second)
        XCTAssertEqual(router.secondRouter.state, 2)
        XCTAssertEqual(transitions, [
            TabTransition(.first, .second, .keepState),
            TabTransition(.second, .second, .popToRoot)
        ])
    }
}
