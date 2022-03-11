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

class STFilterRange {
    let min: CGFloat
    let max: CGFloat
    let defaultValue: CGFloat

    init(min: CGFloat, max: CGFloat, defaultValue: CGFloat) {
        self.min = min
        self.max = max
        self.defaultValue = defaultValue
    }
}

protocol IFilter {
    var ciFilter: CIFilter? { get }
    func reset()
}

class STColorControlsFilter: IFilter {
    static let brightnessRange = STFilterRange(min: -0.2, max: 0.2, defaultValue: 0.0)
    static let contrastRange = STFilterRange(min: 0.8, max: 1.2, defaultValue: 1.0)
    static let saturationRange = STFilterRange(min: 0.0, max: 2.0, defaultValue: 1.0)

    var brightness: CGFloat?
    var contrast: CGFloat?
    var saturation: CGFloat?

    var ciFilter: CIFilter? {
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

    func reset() {
        self.brightness = nil
        self.contrast = nil
        self.saturation = nil
    }

}

class STWhitePointFilter: IFilter {
    static let range = STFilterRange(min: 0.5, max: 1.5, defaultValue: 1)

    var value: CGFloat?

    var ciFilter: CIFilter? {
        guard let value = self.value else {
            return nil
        }
        let filter = CIFilter.gammaAdjust()
        filter.power = Float(value)
        return filter
    }

    func reset() {
        self.value = nil
    }

}

class STVibranceFilter: IFilter {
    static let range = STFilterRange(min: -1.0, max: 1.0, defaultValue: 0.0)

    var value: CGFloat?

    var ciFilter: CIFilter? {
        guard let value = self.value else {
            return nil
        }
        let filter = CIFilter.vibrance()
        filter.amount = Float(value)
        return filter
    }

    func reset() {
        self.value = nil
    }

}

class STExposureFilter: IFilter {
    static let range = STFilterRange(min: -1.0, max: 1.0, defaultValue: 0.0)

    var value: CGFloat?

    var ciFilter: CIFilter? {
        guard let value = self.value else {
            return nil
        }
        let filter = CIFilter.exposureAdjust()
        filter.ev = Float(value)
        return filter
    }

    func reset() {
        self.value = nil
    }

}

class STHighlightShadowFilter: IFilter {
    static let highlightRange = STFilterRange(min: 0.0, max: 1.0, defaultValue: 0.5)
    static let shadowRange = STFilterRange(min: -1.0, max: 1.0, defaultValue: 0.0)

    var highlight: CGFloat?
    var shadow: CGFloat?

    var ciFilter: CIFilter? {
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

    func reset() {
        self.highlight = nil
        self.shadow = nil
    }
}

class STTemperatureAndTintFilter: IFilter {
    static let temperatureRange = STFilterRange(min: 15000.0, max: 3000.0, defaultValue: 6500.0)
    static let tintRange = STFilterRange(min: 50.0, max: -50.0, defaultValue: 0.0)

    var temperature: CGFloat?
    var tint: CGFloat?

    var ciFilter: CIFilter? {
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

    func reset() {
        self.temperature = nil
        self.tint = nil
    }
}

class STNoiseReductionAndSharpnessFilter: IFilter {
    static let reductionRange = STFilterRange(min: 0.0, max: 1, defaultValue: 0.0)
    static let sharpnessRange = STFilterRange(min: 0.0, max: 5.0, defaultValue: 0.0)

    var reduction: CGFloat?
    var sharpness: CGFloat?

    var ciFilter: CIFilter? {
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

    func reset() {
        self.reduction = nil
        self.sharpness = nil
    }

}

class STVignetteFilter: IFilter {
    static let range = STFilterRange(min: -2.0, max: 2.0, defaultValue: 0.0)

    var value: CGFloat?

    var ciFilter: CIFilter? {
        guard let value = self.value else {
            return nil
        }
        let filter = CIFilter.vignette()
        filter.intensity = Float(value)
        filter.radius = 1.5
        return filter
    }

    func reset() {
        self.value = nil
    }

}
