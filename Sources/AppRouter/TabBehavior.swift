//
//  File.swift
//  
//
//  Created by Ryan Carver on 3/2/21.
//

import Foundation

/// The ways that chaging tabs can behave.
public enum TabBehavior {

    /// Keep the current state of the stack navigation in the tab.
    case keepState

    /// Pop the stack navigation to root whenever the tab changes.
    case popToRoot

    /// Pop the stack navigation to root if the current tab is selected again.
    case popToRootIfRepeated
}
