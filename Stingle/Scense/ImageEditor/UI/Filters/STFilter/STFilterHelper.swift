//
//  STFilterHelper.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 2/4/22.
//

import UIKit

class STFilterHelper {
    
    class Range {
        
        let min: CGFloat
        let max: CGFloat
        let defaultValue: CGFloat

        init(min: CGFloat, max: CGFloat, defaultValue: CGFloat) {
            self.min = min
            self.max = max
            self.defaultValue = defaultValue
        }
        
    }
    
    enum Constance {
    
        struct ColorControls {
            let brightnessRange = Range(min: -0.2, max: 0.2, defaultValue: 0.0)
            let contrastRange = Range(min: 0.8, max: 1.2, defaultValue: 1.0)
            let saturationRange = Range(min: 0.0, max: 2.0, defaultValue: 1.0)
        }
        
        struct WhitePoint {
            let range = Range(min: 0.5, max: 1.5, defaultValue: 1)
        }
        
        struct Vibrance {
            let range = Range(min: -1.0, max: 1.0, defaultValue: 0.0)
        }
        
        struct Exposure {
            let range = Range(min: -1.0, max: 1.0, defaultValue: 0.0)
        }
        
        struct HighlightShadow {
            let highlightRange = Range(min: 0.0, max: 1.0, defaultValue: 0.5)
            let shadowRange = Range(min: -1.0, max: 1.0, defaultValue: 0.0)
        }
        
        struct TemperatureAndTint {
            let temperatureRange = Range(min: 15000.0, max: 3000.0, defaultValue: 6500.0)
            let tintRange = Range(min: 50.0, max: -50.0, defaultValue: 0.0)
        }
        
        struct NoiseReductionAndSharpness {
            let reductionRange = Range(min: 0.0, max: 1, defaultValue: 0.0)
            let sharpnessRange = Range(min: 0.0, max: 5.0, defaultValue: 0.0)
        }
        
        struct Vignette {
            let range = Range(min: -2.0, max: 2.0, defaultValue: 0.0)
        }
        
    }
    
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

    private class func filterRange(type: STFilterType) -> Range {
        switch type {
        case .brightness:
            return Constance.ColorControls().brightnessRange
        case .contrast:
            return Constance.ColorControls().contrastRange
        case .saturation:
            return Constance.ColorControls().saturationRange
        case .vibrance:
            return Constance.Vibrance().range
        case .exposure:
            return Constance.Exposure().range
        case .highlights:
            return Constance.HighlightShadow().highlightRange
        case .shadows:
            return Constance.HighlightShadow().shadowRange
        case .whitePoint:
            return Constance.WhitePoint().range
        case .temperature:
            return Constance.TemperatureAndTint().temperatureRange
        case .tint:
            return Constance.TemperatureAndTint().tintRange
        case .sharpness:
            return Constance.NoiseReductionAndSharpness().sharpnessRange
        case .noiseReduction:
            return Constance.NoiseReductionAndSharpness().reductionRange
        case .vignette:
            return Constance.Vignette().range
        }
    }

}
