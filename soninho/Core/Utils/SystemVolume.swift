//
//  SystemVolume.swift
//  soninho
//
//  Forces the system media volume to maximum when the alarm fires. A `.playback`
//  alarm plays at the MEDIA volume (not the ringer), so if the user left media
//  low the alarm is quiet — native alarms and loud alarm apps (Alarmy, etc.)
//  side-step this by pushing the volume to max. Uses the MPVolumeView slider,
//  the long-standing accepted way to set output volume.
//

import MediaPlayer
import UIKit

// MARK: - System Volume
@MainActor
enum SystemVolume {
    // Off-screen volume view; its embedded UISlider drives the system volume.
    private static let volumeView = MPVolumeView(frame: CGRect(x: -2000, y: -2000, width: 1, height: 1))

    /// Attach the hidden volume view to a window. Call once at launch.
    static func prepare() {
        guard volumeView.superview == nil, let window = keyWindow() else { return }
        window.addSubview(volumeView)
    }

    /// Raise the system media volume to maximum.
    static func setMax() {
        prepare()
        applyMax()
        // The slider can be created asynchronously after attaching to a window.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { applyMax() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { applyMax() }
    }

    // MARK: - Private
    private static func applyMax() {
        volumeView.subviews
            .compactMap { $0 as? UISlider }
            .first?
            .setValue(1.0, animated: false)
    }

    private static func keyWindow() -> UIWindow? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        return windows.first { $0.isKeyWindow } ?? windows.first
    }
}
