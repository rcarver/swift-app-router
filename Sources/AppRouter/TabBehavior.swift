//
//  File.swift
//  
//
//  Created by Ryan Carver on 3/2/21.
//

import Foundation

/// The ways that changing tabs can behave.
public enum TabBehavior {

    /// Keep the current state of the stack navigation in the tab.
    case keepState

    /// Pop the stack navigation to root whenever the tab changes.
    case popToRoot

    /// Pop the stack navigation to root if the current tab is selected again.
    case popToRootIfRepeated
}

extension TabBehavior: CustomStringConvertible {
    public var description: String {
        switch self {
        case .keepState: return "keepState"
        case .popToRoot: return "popToRoot"
        case .popToRootIfRepeated: return "popToRootIfRepeated"
        }
    }
}
