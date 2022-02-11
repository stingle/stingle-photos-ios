//
//  STFilter.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 12/22/21.
//

import Foundation
import CoreImage

class STFilterRange<T> {
    let min: T
    let max: T
    let defaultValue: T

    init(min: T, max: T, defaultValue: T) {
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
    static let brightnessRange = STFilterRange<CGFloat>(min: -0.2, max: 0.2, defaultValue: 0.0)
    static let contrastRange = STFilterRange<CGFloat>(min: 0.0, max: 2.0, defaultValue: 1.0)
    static let saturationRange = STFilterRange<CGFloat>(min: 0.0, max: 2.0, defaultValue: 1.0)

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
    static let range = STFilterRange<CGFloat>(min: 0.0, max: 1.0, defaultValue: 0.5)

    var value: CGFloat?

    var ciFilter: CIFilter? {
        guard let value = self.value else {
            return nil
        }
        let filter = CIFilter(name: "CIWhitePointAdjust")
        let white = CGFloat(value)
        filter?.setValue(CIColor(red: white, green: white, blue: white, alpha: 1.0), forKey: kCIInputColorKey)
        return filter
    }

    func reset() {
        self.value = nil
    }

}

class STVibranceFilter: IFilter {
    static let range = STFilterRange<CGFloat>(min: -1.0, max: 1.0, defaultValue: 0.0)

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
    static let range = STFilterRange<CGFloat>(min: -1.0, max: 1.0, defaultValue: 0.0)

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
    static let highlightRange = STFilterRange<CGFloat>(min: 0.0, max: 1.0, defaultValue: 0.5)
    static let shadowRange = STFilterRange<CGFloat>(min: 0.0, max: 1.0, defaultValue: 0.5)

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
    static let temperatureRange = STFilterRange<CGFloat>(min: 3500.0, max: 9500.0, defaultValue: 6500.0)
    static let tintRange = STFilterRange<CGFloat>(min: -100.0, max: 100.0, defaultValue: 0.0)

    var temperature: CGFloat?
    var tint: CGFloat?

    var ciFilter: CIFilter? {
        guard self.temperature != nil || self.tint != nil else {
            return nil
        }
        let filter = CIFilter(name: "CITemperatureAndTint")
        filter?.setValue(CIVector(x: 6500.0, y: 0.0), forKey: "inputTargetNeutral")
        var vector = CIVector(x: 6500.0, y: 0)
        if let temperature = self.temperature {
            vector = CIVector(x: temperature, y: vector.y)
        }
        if let tint = self.tint {
            vector = CIVector(x: vector.x, y: tint)
        }
        filter?.setValue(vector, forKey: "inputNeutral")
        return filter
    }

    func reset() {
        self.temperature = nil
        self.tint = nil
    }
}

class STSharpnessFilter: IFilter {
    static let range = STFilterRange<CGFloat>(min: 0.0, max: 2.0, defaultValue: 0.0)

    var value: CGFloat?

    var ciFilter: CIFilter? {
        guard let value = self.value else {
            return nil
        }
//        let filter = CIFilter(name: "CICheckerboardGenerator")
//        filter?.setValue(value, forKey: kCIInputSharpnessKey)
        return nil//filter
    }

    func reset() {
        self.value = nil
    }

}

class STNoiseReductionFilter: IFilter {
    static let range = STFilterRange<CGFloat>(min: 0.0, max: 2.0, defaultValue: 0.0)

    var value: CGFloat?

    var ciFilter: CIFilter? {
        guard let value = self.value else {
            return nil
        }
//        let filter = CIFilter(name: "CINoiseReduction")
//        filter?.setValue(value, forKey: kCIInputSharpnessKey)
        return nil//filter
    }

    func reset() {
        self.value = nil
    }

}

class STVignetteFilter: IFilter {
    static let range = STFilterRange<CGFloat>(min: -1.0, max: 1.0, defaultValue: 0.0)

    var value: CGFloat?

    var ciFilter: CIFilter? {
        guard let value = self.value else {
            return nil
        }
//        let filter = CIFilter(name: "CIVignette")
//        filter?.setValue(value, forKey: kCIInputIntensityKey)
        return nil//filter
    }

    func reset() {
        self.value = nil
    }

}
