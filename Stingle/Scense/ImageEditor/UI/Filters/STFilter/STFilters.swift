//
//  STFilter.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 12/22/21.
//

import Foundation
import CoreImage
import UIKit
import CoreImage.CIFilterBuiltins



protocol IFilter {
    var ciFilter: CIFilter? { get }
    func reset()
}

class STFilter: IFilter {
    
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
    
    var ciFilter: CIFilter? {
        return nil
    }
    
    func reset() {
        fatalError()
    }
        
}

extension STFilter {
    
    static var colorControls: ColorControls {
        return ColorControls()
    }
    
    class ColorControls: STFilter {
        static let brightnessRange = STFilter.Range(min: -0.2, max: 0.2, defaultValue: 0.0)
        static let contrastRange = STFilter.Range(min: 0.8, max: 1.2, defaultValue: 1.0)
        static let saturationRange = STFilter.Range(min: 0.0, max: 2.0, defaultValue: 1.0)

        var brightness: CGFloat?
        var contrast: CGFloat?
        var saturation: CGFloat?

        override var ciFilter: CIFilter? {
            guard self.brightness != nil || self.contrast != nil || self.saturation != nil else {
                return nil
            }
            let filter = CIFilter.colorControls()
            if let brightness = self.brightness {
                filter.brightness = Float(brightness)
            }
            if let contrast = self.contrast {
                filter.contrast = Float(contrast)
            }
            if let saturation = self.saturation {
                filter.saturation = Float(saturation)
            }
            return filter
        }

        override func reset() {
            self.brightness = nil
            self.contrast = nil
            self.saturation = nil
        }

    }
    
}

extension STFilter {
    
    static var whitePoint: WhitePoint {
        return WhitePoint()
    }
    
    class WhitePoint: STFilter {
        static let range = STFilter.Range(min: 0.5, max: 1.5, defaultValue: 1)

        var value: CGFloat?

        override var ciFilter: CIFilter? {
            guard let value = self.value else {
                return nil
            }
            let filter = CIFilter.gammaAdjust()
            filter.power = Float(value)
            return filter
        }

        override func reset() {
            self.value = nil
        }

    }

}

extension STFilter {
   
    static var vibrance: Vibrance {
        return Vibrance()
    }

    class Vibrance: STFilter {
        static let range = STFilter.Range(min: -1.0, max: 1.0, defaultValue: 0.0)

        var value: CGFloat?

        override var ciFilter: CIFilter? {
            guard let value = self.value else {
                return nil
            }
            let filter = CIFilter.vibrance()
            filter.amount = Float(value)
            return filter
        }

        override func reset() {
            self.value = nil
        }

    }
}

extension STFilter {
   
    static var exposure: Exposure {
        return Exposure()
    }

    class Exposure: STFilter {
        static let range = STFilter.Range(min: -1.0, max: 1.0, defaultValue: 0.0)

        var value: CGFloat?

        override var ciFilter: CIFilter? {
            guard let value = self.value else {
                return nil
            }
            let filter = CIFilter.exposureAdjust()
            filter.ev = Float(value)
            return filter
        }

        override func reset() {
            self.value = nil
        }

    }

}

extension STFilter {
    
    static var highlightShadow: HighlightShadow {
        return HighlightShadow()
    }

    class HighlightShadow: STFilter {
        static let highlightRange = STFilter.Range(min: 0.0, max: 1.0, defaultValue: 0.5)
        static let shadowRange = STFilter.Range(min: -1.0, max: 1.0, defaultValue: 0.0)

        var highlight: CGFloat?
        var shadow: CGFloat?

        override var ciFilter: CIFilter? {
            guard self.highlight != nil || self.shadow != nil else {
                return nil
            }
            let filter = CIFilter.highlightShadowAdjust()
            filter.radius = 1.5
            if let highlight = self.highlight {
                filter.highlightAmount = Float(highlight)
            }
            if let shadow = self.shadow {
                filter.shadowAmount = Float(shadow)
            }
            return filter
        }

        override func reset() {
            self.highlight = nil
            self.shadow = nil
        }
    }

}

extension STFilter {
 
    static var temperatureAndTint: TemperatureAndTint {
        return TemperatureAndTint()
    }

    class TemperatureAndTint: STFilter {
        static let temperatureRange = STFilter.Range(min: 15000.0, max: 3000.0, defaultValue: 6500.0)
        static let tintRange = STFilter.Range(min: 50.0, max: -50.0, defaultValue: 0.0)

        var temperature: CGFloat?
        var tint: CGFloat?

        override var ciFilter: CIFilter? {
            guard self.temperature != nil || self.tint != nil else {
                return nil
            }
            let filter = CIFilter.temperatureAndTint()
            var vector = CIVector(x: 6500.0, y: 0)
            if let temperature = self.temperature {
                vector = CIVector(x: temperature, y: vector.y)
            }
            if let tint = self.tint {
                vector = CIVector(x: vector.x, y: tint)
            }
            filter.targetNeutral = vector
            return filter
        }

        override func reset() {
            self.temperature = nil
            self.tint = nil
        }
    }

}

extension STFilter {
 
    static var noiseReductionAndSharpness: NoiseReductionAndSharpness {
        return NoiseReductionAndSharpness()
    }

    class NoiseReductionAndSharpness: STFilter {
        static let reductionRange = STFilter.Range(min: 0.0, max: 1, defaultValue: 0.0)
        static let sharpnessRange = STFilter.Range(min: 0.0, max: 5.0, defaultValue: 0.0)

        var reduction: CGFloat?
        var sharpness: CGFloat?

        override var ciFilter: CIFilter? {
            guard self.reduction != nil || self.sharpness != nil else {
                return nil
            }
            let filter = CIFilter.noiseReduction()
            if let reduction = self.reduction {
                filter.noiseLevel = Float(reduction)
            }
            if let sharpness = self.sharpness {
                filter.sharpness = Float(sharpness)
            }
            return filter
        }

        override func reset() {
            self.reduction = nil
            self.sharpness = nil
        }

    }

}

extension STFilter {
 
    static var vignette: Vignette {
        return Vignette()
    }

    class Vignette: STFilter {
        static let range = STFilter.Range(min: -2.0, max: 2.0, defaultValue: 0.0)

        var value: CGFloat?

        override var ciFilter: CIFilter? {
            guard let value = self.value else {
                return nil
            }
            let filter = CIFilter.vignette()
            filter.intensity = Float(value)
            filter.radius = 1.5
            return filter
        }

        override func reset() {
            self.value = nil
        }

    }

}
