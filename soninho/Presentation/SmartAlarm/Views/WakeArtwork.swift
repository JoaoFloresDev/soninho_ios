//
//  WakeArtwork.swift
//  soninho
//

import Foundation

// MARK: - Wake Artwork
/// Picks which mascot pose greets the sleeper when an alarm rings.
///
/// The pose rotates so the same drawing does not appear every single morning,
/// which is what makes a wake-up screen start to feel like a loop. The index is
/// persisted, so the rotation continues across launches instead of resetting to
/// the first pose whenever the app is relaunched.
enum WakeArtwork {

    // MARK: - Constants
    private static let names = ["heroWake1", "heroWake2", "heroWake3"]
    private static let storageKey = "wakeArtworkIndex"

    // MARK: - Public Methods

    /// The pose for this ring. Advances the rotation as a side effect, so it is
    /// read once when the ringing screen appears.
    static var current: String {
        let defaults = UserDefaults.standard
        let index = defaults.integer(forKey: storageKey) % names.count
        defaults.set((index + 1) % names.count, forKey: storageKey)
        return names[safe: index] ?? names[0]
    }
}
