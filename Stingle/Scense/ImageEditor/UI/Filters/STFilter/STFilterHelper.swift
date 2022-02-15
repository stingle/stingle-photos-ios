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
        let filterValues = self.filterRange(type: type)
        let (min, _, max) = self.rullerMinMaxValues(for: type)
        let rullerRange = max - min
        let filterRange = filterValues.max - filterValues.min
        let step = rullerRange / filterRange 
        let value = min + (filterValue - filterValues.min) * step
        return value
    }

    class func value(for type: STFilterType, rullerValue: CGFloat) -> CGFloat? {
//        guard rullerValue != 0.0 else { return nil }

        let filterValues = self.filterRange(type: type)
        let (min, _, max) = self.rullerMinMaxValues(for: type)
        let rullerRange = max - min
        let filterRange = filterValues.max - filterValues.min
        let step = filterRange / rullerRange
        let value = filterValues.min + (rullerValue - min) * step
        return value
    }

    // MARK: - Private methdos

    private class func filterRange(type: STFilterType) -> (min: CGFloat, max: CGFloat) {
        switch type {
        case .brightness:
            return (STColorControlsFilter.brightnessRange.min, STColorControlsFilter.brightnessRange.max)
        case .contrast:
            return (STColorControlsFilter.contrastRange.min, STColorControlsFilter.contrastRange.max)
        case .saturation:
            return (STColorControlsFilter.saturationRange.min, STColorControlsFilter.saturationRange.max)
        case .vibrance:
            return (STVibranceFilter.range.min, STVibranceFilter.range.max)
        case .exposure:
            return (STExposureFilter.range.min, STExposureFilter.range.max)
        case .highlights:
            return (STHighlightShadowFilter.highlightRange.min, STHighlightShadowFilter.highlightRange.max)
        case .shadows:
            return (STHighlightShadowFilter.shadowRange.min, STHighlightShadowFilter.shadowRange.max)
        case .whitePoint:
            return (STWhitePointFilter.range.min, STWhitePointFilter.range.max)
        case .temperature:
            return (STTemperatureAndTintFilter.temperatureRange.min, STTemperatureAndTintFilter.temperatureRange.max)
        case .tint:
            return (STTemperatureAndTintFilter.tintRange.min, STTemperatureAndTintFilter.tintRange.max)
        case .sharpness:
            return (STSharpnessFilter.range.min, STSharpnessFilter.range.max)
        case .noiseReduction:
            return (STNoiseReductionFilter.range.min, STNoiseReductionFilter.range.max)
        case .vignette:
            return (STVignetteFilter.range.min, STVignetteFilter.range.max)
        }
    }

}
