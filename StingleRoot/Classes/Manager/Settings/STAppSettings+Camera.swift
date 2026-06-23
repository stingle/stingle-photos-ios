//
//  STAppSettings+Camera.swift
//  StingleRoot
//
//  Preferences for the native camera. Intentionally has NO save-to-Photos
//  option — Stingle's camera is encrypted-only by design.
//

import Foundation

public extension STAppSettings {

    struct Camera: Codable {

        public var defaultMode: STCameraMode
        public var videoResolution: STVideoResolution
        public var videoCodecHEVC: Bool
        public var videoFPS: Int
        public var slowMoFPS: Int
        public var timeLapseInterval: TimeInterval
        public var selfTimerSeconds: Int      // 0 / 3 / 10
        public var mirrorFrontCamera: Bool
        public var gridEnabled: Bool
        public var geotaggingEnabled: Bool    // default false: no GPS unless opted in

        static public var `default`: Camera {
            return Camera(defaultMode: .photo,
                          videoResolution: .hd1080,
                          videoCodecHEVC: true,
                          videoFPS: 30,
                          slowMoFPS: 120,
                          timeLapseInterval: 1.0,
                          selfTimerSeconds: 0,
                          mirrorFrontCamera: true,
                          gridEnabled: false,
                          geotaggingEnabled: false)
        }

        public static func != (lhs: Self, rhs: Self) -> Bool {
            return lhs.defaultMode != rhs.defaultMode
                || lhs.videoResolution != rhs.videoResolution
                || lhs.videoCodecHEVC != rhs.videoCodecHEVC
                || lhs.videoFPS != rhs.videoFPS
                || lhs.slowMoFPS != rhs.slowMoFPS
                || lhs.timeLapseInterval != rhs.timeLapseInterval
                || lhs.selfTimerSeconds != rhs.selfTimerSeconds
                || lhs.mirrorFrontCamera != rhs.mirrorFrontCamera
                || lhs.gridEnabled != rhs.gridEnabled
                || lhs.geotaggingEnabled != rhs.geotaggingEnabled
        }
    }
}
