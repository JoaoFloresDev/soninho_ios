//
//  Collection+Extensions.swift
//  soninho
//

import Foundation

// MARK: - Safe Subscript
extension Collection {
    /// Returns the element at the given index, or nil when out of bounds.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
