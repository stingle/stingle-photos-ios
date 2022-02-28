//
//  STFilterHelper.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 2/4/22.
//

import UIKit

class STFilterHelper {

    class func rullerMinMaxValues(for type: STFilterType) -> (min: CGFloat, `default`: CGFloat, max: CGFloat) {
        switch type {
        case .brightness, .contrast, .saturation, .vibrance, .exposure, .highlights, .shadows, .whitePoint, .temperature, .tint, .vignette:
            return (-100, 0, 100)
        case .sharpness, .noiseReduction:
            return (0, 0, 100)
        }
    }

    class func rullerValue(for type: STFilterType, filterValue: CGFloat) -> CGFloat {
        let filterRange = self.filterRange(type: type)
        let (min, defaultValue, max) = self.rullerMinMaxValues(for: type)
        guard filterValue != filterRange.defaultValue else { return defaultValue }
        switch type {
        case .temperature:
            if filterValue > filterRange.defaultValue {
                let step = (abs(filterRange.min) - abs(filterRange.defaultValue)) / 100.0
                return (abs(filterValue) - abs(filterRange.defaultValue)) / step
            } else {
                let step = (abs(filterRange.defaultValue) - abs(filterRange.max)) / 100.0
                return (abs(filterRange.defaultValue) - abs(filterValue)) / step
            }
        default:
            let rullerRange = max - min
            let step = rullerRange / (filterRange.max - filterRange.min)
            let value = min + (filterValue - filterRange.min) * step
            return value
        }
    }

    class func value(for type: STFilterType, rullerValue: CGFloat) -> CGFloat? {
        let (min, defaultValue, max) = self.rullerMinMaxValues(for: type)
        guard rullerValue != defaultValue else { return nil }
        let filterValues = self.filterRange(type: type)
        switch type {
        case .temperature:
            if rullerValue > 0 {
                let step = (filterValues.max - filterValues.defaultValue) * (rullerValue / 100)
                return filterValues.defaultValue + step
            } else {
                let step = (filterValues.defaultValue - filterValues.min) * abs(rullerValue) / 100
                return filterValues.defaultValue - step
            }
        default:
            let rullerRange = max - min
            let filterRange = filterValues.max - filterValues.min
            let step = filterRange / rullerRange
            let value = filterValues.min + (rullerValue - min) * step
            return value
        }
    }

    // MARK: - Private methdos

    private class func filterRange(type: STFilterType) -> STFilterRange {
        switch type {
        case .brightness:
            return STColorControlsFilter.brightnessRange
        case .contrast:
            return STColorControlsFilter.contrastRange
        case .saturation:
            return STColorControlsFilter.saturationRange
        case .vibrance:
            return STVibranceFilter.range
        case .exposure:
            return STExposureFilter.range
        case .highlights:
            return STHighlightShadowFilter.highlightRange
        case .shadows:
            return STHighlightShadowFilter.shadowRange
        case .whitePoint:
            return STWhitePointFilter.range
        case .temperature:
            return STTemperatureAndTintFilter.temperatureRange
        case .tint:
            return STTemperatureAndTintFilter.tintRange
        case .sharpness:
            return STSharpnessFilter.range
        case .noiseReduction:
            return STNoiseReductionFilter.range
        case .vignette:
            return STVignetteFilter.range
        }
    }

}
