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
            return "ic_brightness"
        case .contrast:
            return "ic_contrast"
        case .saturation:
            return "ic_saturation"
        case .vibrance:
            return "ic_vibrance"
        case .exposure:
            return "ic_exposure"
        case .highlights:
            return "ic_highlights"
        case .shadows:
            return "ic_shadows"
        case .whitePoint:
            return "ic_whitePoint"
        case .temperature:
            return "ic_temperature"
        case .tint:
            return "ic_tint"
        case .sharpness:
            return "ic_sharpness"
        case .noiseReduction:
            return "ic_noiseReduction"
        case .vignette:
            return "ic_vignette"
        }
    }

}
