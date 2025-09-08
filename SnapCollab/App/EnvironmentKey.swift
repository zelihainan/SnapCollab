//
//  EnvironmentKey.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import SwiftUI

private struct DIKey: EnvironmentKey {
    static let defaultValue: DIContainer = .bootstrap()
}

extension EnvironmentValues {
    var di: DIContainer {
        get { self[DIKey.self] }
        set { self[DIKey.self] = newValue }
    }
}
