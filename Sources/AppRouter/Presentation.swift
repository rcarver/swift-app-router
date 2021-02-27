//
//  File.swift
//  
//
//  Created by Ryan Carver on 2/26/21.
//

import Foundation

/// If your router's State adopts this protocol it can control how
/// the pushed state is presented.
public protocol Presentable {

    /// The presentation to use for pushed state.
    var presentation: PresentationType { get }
}

/// Options for the behvior of presenting via link.
public struct LinkOptions: Equatable {

    /// Enable autoPop for links.
    public static var autoPop: Self { .init(autoPopToPreviousState: true) }

    /// If a link would move to the previous state, the router
    /// automatically pops the current state instead of pushing a new state.
    var autoPopToPreviousState: Bool = false
}

/// The supported types of presentation.
public enum PresentationType: Equatable {

    /// The default presentation.
    public static var `default`: Self { .link }

    /// Present the state via NavigationLink, with default link options.
    public static var link: Self { .link(LinkOptions()) }

    /// Present the state via NavigationLink, with link options.
    case link(LinkOptions)

    /// Present the state via sheet().
    case sheet

    /// Present the state via sheet(), embedding content in a NavigationView.
    case navigationSheet

    /// Replace the current base state, instead of pushing a new state.
    case replace

    /// Replace the root router's base state, popping all children.
    case root
}

extension PresentationType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .link(_):
            return "link"
        case .sheet:
            return "sheet"
        case .navigationSheet:
            return "navigationSheet"
        case .replace:
            return "replace"
        case .root:
            return "root"
        }
    }
}

extension PresentationType {

    func route<Router: AppRouting>(_ router: Router, to state: Router.State) {
        switch self {

        case .link(let options):
            if options.autoPopToPreviousState {
                if let previous = router.parent?.route.base, previous == state {
                    router.pop()
                } else {
                    router.route.push(state: state, presentation: self)
                }
            } else {
                router.route.push(state: state, presentation: self)
            }

        case .sheet, .navigationSheet:
            router.route.push(state: state, presentation: self)

        case .replace:
            router.route = Route(state)

        case .root:
            router.rootRouter.route = Route(state)
        }
    }
}
