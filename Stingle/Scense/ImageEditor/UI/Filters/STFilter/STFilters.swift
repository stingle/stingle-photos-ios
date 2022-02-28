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
    static let contrastRange = STFilterRange(min: 0.9, max: 1.1, defaultValue: 1.0)
    static let saturationRange = STFilterRange(min: 0.0, max: 2.0, defaultValue: 1.0)

    var brightness: CGFloat?
    var contrast: CGFloat?
    var saturation: CGFloat?

    var ciFilter: CIFilter? {
        guard self.brightness != nil || self.contrast != nil || self.saturation != nil else {
            return nil
        }
        let filter = CIFilter(name: "CIColorControls")
        if let brightness = self.brightness {
            filter?.setValue(brightness, forKey: kCIInputBrightnessKey)
        }
        if let contrast = self.contrast {
            filter?.setValue(contrast, forKey: kCIInputContrastKey)
        }
        if let saturation = self.saturation {
            filter?.setValue(saturation, forKey: "inputSaturation")
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
    static let range = STFilterRange(min: 0.0, max: 1.0, defaultValue: 0.5)

    var value: CGFloat?

    var ciFilter: CIFilter? {
        guard let value = self.value else {
            return nil
        }
        let filter = CIFilter(name: "CIWhitePointAdjust")
        let ciColor = CIColor(color: UIColor(white: value, alpha: 1.0))
        filter?.setValue(ciColor, forKey: kCIInputColorKey)
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
        let filter = CIFilter(name: "CIVibrance")
        filter?.setValue(value, forKey: "inputAmount")
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
        let filter = CIFilter(name: "CIExposureAdjust")
        filter?.setValue(value, forKey: kCIInputEVKey)
        return filter
    }

    func reset() {
        self.value = nil
    }

}

class STHighlightShadowFilter: IFilter {
    static let highlightRange = STFilterRange(min: 0.0, max: 1.0, defaultValue: 0.5)
    static let shadowRange = STFilterRange(min: 0.0, max: 1.0, defaultValue: 0.5)

    var highlight: CGFloat?
    var shadow: CGFloat?

    var ciFilter: CIFilter? {
        guard self.highlight != nil || self.shadow != nil else {
            return nil
        }
        let filter = CIFilter(name: "CIHighlightShadowAdjust")
        if let highlight = self.highlight {
            filter?.setValue(highlight, forKey: "inputHighlightAmount")
        }
        if let shadow = self.shadow {
            filter?.setValue(shadow, forKey: "inputShadowAmount")
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
        let filter = CIFilter(name: "CITemperatureAndTint")
        var vector = CIVector(x: 6500.0, y: 0)
        if let temperature = self.temperature {
            vector = CIVector(x: temperature, y: vector.y)
        }
        if let tint = self.tint {
            vector = CIVector(x: vector.x, y: tint)
        }
        filter?.setValue(vector, forKey: "inputTargetNeutral")
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
        let filter = CIFilter(name: "CINoiseReduction")
        if let reduction = self.reduction {
            filter?.setValue(reduction, forKey: "inputNoiseLevel")
        }
        if let sharpness = self.sharpness {
            filter?.setValue(sharpness, forKey: "inputSharpness")
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
        let filter = CIFilter(name: "CIVignette")
        filter?.setValue(value, forKey: kCIInputIntensityKey)
        filter?.setValue(1.5, forKey: kCIInputRadiusKey)
        return filter
    }

    func reset() {
        self.value = nil
    }

}
