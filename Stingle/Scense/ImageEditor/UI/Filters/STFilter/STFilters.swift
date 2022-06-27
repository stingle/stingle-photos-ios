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
    var hasChange: Bool { get }
    func reset()
}

class STFilter<Filter: CIFilter>: IFilter {
            
    var ciFilter: CIFilter? {
        get {
            guard self.hasChange else {
                return nil
            }
            if let filter = self.filter {
                self.update(filter: filter)
                return filter
            } else {
                let filter = self.createFilter()
                self.update(filter: filter)
                self.filter = filter
                return filter
            }
        }
    }
    
    var hasChange: Bool {
        fatalError()
    }
    
    private var filter: Filter?
    
    func createFilter() -> Filter {
        fatalError()
    }
    
    func update(filter: Filter) {
        fatalError()
    }
    
    func reset() {
        fatalError()
    }
        
}

extension STFilter {
    
    static var colorControls: ColorControls {
        return ColorControls()
    }
    
    class ColorControls: STFilter<CIFilter & CIColorControls> {
                
        var brightness: CGFloat?
        var contrast: CGFloat?
        var saturation: CGFloat?
        
        override var hasChange: Bool {
            return self.brightness != nil || self.contrast != nil || self.saturation != nil
        }
        
        override func createFilter() -> (CIFilter & CIColorControls) {
            return CIFilter.colorControls()
        }
        
        override func update(filter: CIFilter & CIColorControls) {
            if let brightness = self.brightness {
                filter.brightness = Float(brightness)
            }
            if let contrast = self.contrast {
                filter.contrast = Float(contrast)
            }
            if let saturation = self.saturation {
                filter.saturation = Float(saturation)
            }
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
    
    class WhitePoint: STFilter<CIFilter & CIGammaAdjust> {

        var value: CGFloat?
        
        override var hasChange: Bool {
            return self.value != nil
        }

        override func createFilter() -> (CIFilter & CIGammaAdjust) {
            let filter = CIFilter.gammaAdjust()
            return filter
        }
        
        override func update(filter: CIFilter & CIGammaAdjust) {
            if let value = self.value {
                filter.power = Float(value)
            }
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

    class Vibrance: STFilter<CIFilter & CIVibrance> {

        var value: CGFloat?
        
        override var hasChange: Bool {
            return self.value != nil
        }
        
        override func createFilter() -> CIFilter & CIVibrance {
            return CIFilter.vibrance()
        }
        
        override func update(filter: CIFilter & CIVibrance) {
            if let value = self.value {
                filter.amount = Float(value)
            }
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

    class Exposure: STFilter<CIFilter & CIExposureAdjust> {
        
        var value: CGFloat?
        
        override var hasChange: Bool {
            return self.value != nil
        }
        
        override func createFilter() -> CIFilter & CIExposureAdjust {
            return CIFilter.exposureAdjust()
        }
        
        override func update(filter: CIFilter & CIExposureAdjust) {
            if let value = self.value {
                filter.ev = Float(value)
            }
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

    class HighlightShadow: STFilter<CIFilter & CIHighlightShadowAdjust> {

        var highlight: CGFloat?
        var shadow: CGFloat?
        
        override var hasChange: Bool {
            return self.highlight != nil || self.shadow != nil
        }
        
        override func createFilter() -> CIFilter & CIHighlightShadowAdjust {
            let filter = CIFilter.highlightShadowAdjust()
            filter.radius = 1.5
            return filter
        }
        
        override func update(filter: CIFilter & CIHighlightShadowAdjust) {
            if let highlight = self.highlight {
                filter.highlightAmount = Float(highlight)
            }
            if let shadow = self.shadow {
                filter.shadowAmount = Float(shadow)
            }
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

    class TemperatureAndTint: STFilter<CIFilter & CITemperatureAndTint> {
        
        var temperature: CGFloat?
        var tint: CGFloat?
        
        override var hasChange: Bool {
            return self.temperature != nil || self.tint != nil
        }
        
        override func createFilter() -> CIFilter & CITemperatureAndTint {
            return CIFilter.temperatureAndTint()
        }
        
        override func update(filter: CIFilter & CITemperatureAndTint) {
            var vector = CIVector(x: 6500.0, y: 0)
            if let temperature = self.temperature {
                vector = CIVector(x: temperature, y: vector.y)
            }
            if let tint = self.tint {
                vector = CIVector(x: vector.x, y: tint)
            }
            filter.targetNeutral = vector
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

    class NoiseReductionAndSharpness: STFilter<CIFilter & CINoiseReduction> {

        var reduction: CGFloat?
        var sharpness: CGFloat?
        
        override var hasChange: Bool {
            return self.reduction != nil || self.sharpness != nil
        }
        
        override func createFilter() -> CIFilter & CINoiseReduction {
            return CIFilter.noiseReduction()
        }
        
        override func update(filter: CIFilter & CINoiseReduction) {
            if let reduction = self.reduction {
                filter.noiseLevel = Float(reduction)
            }
            if let sharpness = self.sharpness {
                filter.sharpness = Float(sharpness)
            }
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

    class Vignette: STFilter<CIFilter & CIVignette> {

        var value: CGFloat?
        
        override var hasChange: Bool {
            return self.value != nil
        }
        
        override func createFilter() -> CIFilter & CIVignette {
            let filter = CIFilter.vignette()
            filter.radius = 1.5
            return filter
        }

        override func update(filter: CIFilter & CIVignette) {
            if let value = self.value {
                filter.intensity = Float(value)
            }
        }
        
        override func reset() {
            self.value = nil
        }

    }

}
