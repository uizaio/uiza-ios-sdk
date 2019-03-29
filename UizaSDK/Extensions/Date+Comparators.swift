//
//  Date+Comparators.swift
//  DateToolsTests
//
//  Created by Matthew York on 8/26/16.
//  Copyright © 2016 Matthew York. All rights reserved.
//

import Foundation

/**
 *  Extends the Date class by adding methods for calculating the chunk
 *  of time between two dates and providing many variables and functions
 *  that compare the ordinality of two dates and the space between two dates
 *  for a given unit of time.
 */
public extension Date {
	
    // MARK: - Comparisons
	
    /**
     *  Returns a true if receiver is equal to provided comparison date, otherwise returns false
     *
     *  - parameter date: Provided date for comparison
     *
     *  - returns: Bool representing comparison result
     */
	func equals(_ date: Date) -> Bool {
		return self.compare(date) == .orderedSame
	}
	
    /**
     *  Returns a true if receiver is later than provided comparison date, otherwise
     *  returns false
     *
     *  - parameter date: Provided date for comparison
     *
     *  - returns: Bool representing comparison result
     */
	func isLater(than date: Date) -> Bool {
		return self.compare(date) == .orderedDescending
	}
    
    /**
     *  Returns a true if receiver is later than or equal to provided comparison date,
     *  otherwise returns false
     *
     *  - parameter date: Provided date for comparison
     *
     *  - returns: Bool representing comparison result
     */
    func isLaterThanOrEqual(to date: Date) -> Bool {
        return self.compare(date) == .orderedDescending || self.compare(date) == .orderedSame
    }
	
    /**
     *  Returns a true if receiver is earlier than provided comparison date, otherwise
     *  returns false
     *
     *  - parameter date: Provided date for comparison
     *
     *  - returns: Bool representing comparison result
     */
	func isEarlier(than date: Date) -> Bool {
		return self.compare(date) == .orderedAscending
	}
    
    /**
     *  Returns a true if receiver is earlier than or equal to the provided comparison date,
     *  otherwise returns false
     *
     *  - parameter date: Provided date for comparison
     *
     *  - returns:  Bool representing comparison result
     */
    func isEarlierThanOrEqual(to date: Date) -> Bool {
        return self.compare(date) == .orderedAscending || self.compare(date) == .orderedSame
    }
    
    /**
     *  Returns whether two dates fall on the same day.
     *
     *  - parameter date: Date to compare with sender
     *
     *  - returns: True if both paramter dates fall on the same day, false otherwise
     */
    func isSameDay(date : Date ) -> Bool {
        return Date.isSameDay(date: self, as: date)
    }
    
    /**
     *  Returns whether two dates fall on the same day.
     *
     *  - parameter date: First date to compare
     *  - parameter compareDate: Second date to compare
     *
     *  - returns: True if both paramter dates fall on the same day, false otherwise
     */
	static func isSameDay(date: Date, as compareDate: Date) -> Bool {
        let calendar = Calendar.autoupdatingCurrent
        var components = calendar.dateComponents([.era, .year, .month, .day], from: date)
        let dateOne = calendar.date(from: components)
        
        components = calendar.dateComponents([.era, .year, .month, .day], from: compareDate)
        let dateTwo = calendar.date(from: components)
        
        return (dateOne?.equals(dateTwo!))!
    }
	
    
}
