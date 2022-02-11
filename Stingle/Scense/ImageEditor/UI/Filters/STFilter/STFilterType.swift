//
//  STFilterType.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 12/24/21.
//

import Foundation
import CoreImage

enum STFilterType: Int, CaseIterable {
    case exposure
    case highlights
    case shadows
    case contrast
    case brightness
    case whitePoint
    case saturation
    case vibrance
    case temperature
    case tint
    case sharpness
    case noiseReduction
    case vignette

    var title: String {
        switch self {
        case .brightness:
            return "editor_brightness".localized.uppercased()
        case .contrast:
            return "editor_contrast".localized.uppercased()
        case .saturation:
            return "editor_saturation".localized.uppercased()
        case .vibrance:
            return "editor_vibrance".localized.uppercased()
        case .exposure:
            return "editor_exposuer".localized.uppercased()
        case .highlights:
            return "editor_highlights".localized.uppercased()
        case .shadows:
            return "editor_shadows".localized.uppercased()
        case .whitePoint:
            return "editor_white_point".localized.uppercased()
        case .temperature:
            return "editor_remperature".localized.uppercased()
        case .tint:
            return "editor_tint".localized.uppercased()
        case .sharpness:
            return "editor_sharpness".localized.uppercased()
        case .noiseReduction:
            return "editor_noise_reduction".localized.uppercased()
        case .vignette:
            return "editor_vignette".localized.uppercased()
        }
    }

    var iconName: String {
        switch self {
        case .brightness:
            return "brightness"
        case .contrast:
            return "contrast"
        case .saturation:
            return "saturation"
        case .vibrance:
            return "vibrance"
        case .exposure:
            return "exposure"
        case .highlights:
            return "highlights"
        case .shadows:
            return "shadows"
        case .whitePoint:
            return "whitePoint"
        case .temperature:
            return "temperature"
        case .tint:
            return "tint"
        case .sharpness:
            return "sharpness"
        case .noiseReduction:
            return "noiseReduction"
        case .vignette:
            return "vignette"
        }
    }

}
