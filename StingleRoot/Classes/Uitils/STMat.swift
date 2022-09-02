//
//  STMath.swift
//  Stingle
//
//  Created by Khoren Asatryan on 11/12/21.
//

import UIKit

public protocol IMathComponent: FloatingPoint {
    
    var sin: Self { get }
    var aSin: Self { get }
    
    var cos: Self { get }
    var aCos: Self { get }
    
    var tan: Self { get }
    var aTan: Self { get }
    
    var square: Self { get }
    
    static var zero: Self { get }
    
    func pow(_: Self) -> Self
    
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
    static func / (lhs: Self, rhs: Self) -> Self
    
    static func == (lhs: Self, rhs: Self) -> Bool
    static func != (lhs: Self, rhs: Self) -> Bool
               
}

public enum STMat {

    public struct Vector<T: IMathComponent> {
       
        let a: T
        let b: T
        
        public init(_ a: T, _ b: T) {
            self.a = a
            self.b = b
        }
        
        
        public var modul: T {
            let a = self.a
            let b = self.b
            return (a * a + b * b).square
        }

        public var normalized: Vector<T> {
            let modul = self.modul
            return Vector(self.a / modul, self.b / modul)
        }
        
        public func angel(_ vector: Self) -> T {
            let n = self.modul * vector.modul
            if n != .zero {
                let m = vector.a * self.a + vector.b * self.b
                return (m/n).aCos
            }
            return .zero
        }
        
        public func angel360(vector: Vector<T>) -> T {
            let angel1 = self.angel(vector)
            var a = self.a * angel1.cos + self.b * (-angel1.sin)
            var b = self.a * angel1.sin + self.b * angel1.cos
            let delta1 = abs(a - vector.a) + abs(b - vector.b)
            let angel2 = T.pi * 2 - angel1
            a = self.a * angel2.cos + self.b * (-angel2.sin)
            b = self.a * angel2.sin + self.b * angel2.cos
            let delta2 = abs(a - vector.a) + abs(b - vector.b)
            if (delta1 < delta2) {
                return angel1
            }
            return angel2
        }
        
    }
    
    
}

extension STMat.Vector where T == CGFloat {
    
    public init(_ point1: CGPoint, _ point2: CGPoint) {
        self.a = point2.x - point1.x
        self.b = point2.y - point1.y
    }
    
}

extension Double: IMathComponent {
    
    public var square: Self {
        return Darwin.sqrt(self)
    }
    
    public var sin: Self {
        return Darwin.sin(self)
    }
    
    public var aSin: Self {
        return Darwin.asin(self)
    }
    
    public var cos: Self {
        return Darwin.cos(self)
    }
    
    public var aCos: Self {
        return Darwin.acos(self)
    }
    
    public var tan: Self {
        return Darwin.tan(self)
    }
    
    public var aTan: Self {
        return Darwin.atan(self)
    }
    
    public func pow(_ k: Self) -> Self {
        return Darwin.pow(self, k)
    }
    
}

extension Float: IMathComponent {
    
    public var square: Self {
        return Darwin.sqrt(self)
    }
    
    public var sin: Self {
        return Darwin.sin(self)
    }
    
    public var aSin: Self {
        return Darwin.asin(self)
    }
    
    public var cos: Self {
        return Darwin.cos(self)
    }
    
    public var aCos: Self {
        return Darwin.acos(self)
    }
    
    public var tan: Self {
        return Darwin.tan(self)
    }
    
    public var aTan: Self {
        return Darwin.atan(self)
    }
    
    public func pow(_ k: Self) -> Self {
        return Darwin.pow(self, k)
    }
    
}

extension CGFloat: IMathComponent {
    
    public var square: Self {
        return Darwin.sqrt(self)
    }
    
    public var sin: Self {
        return Darwin.sin(self)
    }
    
    public var aSin: Self {
        return Darwin.asin(self)
    }
    
    public var cos: Self {
        return Darwin.cos(self)
    }
    
    public var aCos: Self {
        return Darwin.acos(self)
    }
    
    public var tan: Self {
        return Darwin.tan(self)
    }
    
    public var aTan: Self {
        return Darwin.atan(self)
    }
    
    public func pow(_ k: Self) -> Self {
        return Darwin.pow(self, k)
    }
    
}
