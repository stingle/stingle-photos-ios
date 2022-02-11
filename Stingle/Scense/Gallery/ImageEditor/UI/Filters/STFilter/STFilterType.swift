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
            return "BRIGHTNESS"
        case .contrast:
            return "CONTRAST"
        case .saturation:
            return "SATURATION"
        case .vibrance:
            return "VIBRANCE"
        case .exposure:
            return "EXPOSURE"
        case .highlights:
            return "HIGHLIGHTS"
        case .shadows:
            return "SHADOWS"
        case .whitePoint:
            return "WHITE POINT"
        case .temperature:
            return "TEMPERATURE"
        case .tint:
            return "TINT"
        case .sharpness:
            return "Sharpness"
        case .noiseReduction:
            return "Noise Reduction"
        case .vignette:
            return "Vignette"
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
