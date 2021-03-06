//
//  Math.swift
//  TweenKit
//
//  Created by Steve Barnegren on 18/03/2017.
//  Copyright © 2017 Steve Barnegren. All rights reserved.
//

import Foundation

func vector2DDistance(v1: (x: Double, y: Double), v2: (x: Double, y: Double)) -> Double {
    
    let xDiff = v2.x - v1.x
    let yDiff = v2.y - v1.y
    
    return sqrt((xDiff * xDiff) + (yDiff * yDiff))
}

extension Comparable {
    
    func constrained(min: Self) -> Self {
        
        if self < min { return min }
        return self
    }

    func constrained(max: Self) -> Self {
        
        if self > max { return max }
        return self
    }

    func constrained(min: Self, max: Self) -> Self {
        
        if self < min { return min }
        if self > max { return max }
        return self
    }
}

extension Double {
    
    var fract: Double {
        return self - Double(Int(self))
    }
}
