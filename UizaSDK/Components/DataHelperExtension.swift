//
//  DataHelperExtension.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 5/10/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import Foundation

public extension Date {
    // MARK: Date for...
    
    func dateFor(_ type: DateForType, calendar: Calendar = Calendar.current) -> Date {
        switch type {
        case .startOfDay:
            return adjust(hour: 0, minute: 0, second: 0)
        case .endOfDay:
            return adjust(hour: 23, minute: 59, second: 59)
        case .startOfWeek:
            return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
        case .endOfWeek:
            let offset = 7 - component(.weekday)!
            return adjust(.day, offset: offset)
        case .startOfMonth:
            return adjust(hour: 0, minute: 0, second: 0, day: 1)
        case .endOfMonth:
            let month = (component(.month) ?? 0) + 1
            return adjust(hour: 0, minute: 0, second: 0, day: 0, month: month)
        case .tomorrow:
            return adjust(.day, offset:1)
        case .yesterday:
            return adjust(.day, offset:-1)
        case .nearestMinute(let nearest):
            let minutes = (component(.minute)! + nearest/2) / nearest * nearest
            return adjust(hour: nil, minute: minutes, second: nil)
        case .nearestHour(let nearest):
            let hours = (component(.hour)! + nearest/2) / nearest * nearest
            return adjust(hour: hours, minute: 0, second: nil)
        }
    }
    
    // MARK: Time since...
    
    func since(_ date: Date, in component: DateComponentType) -> Int64 {
        switch component {
        case .second:
            return Int64(timeIntervalSince(date))
        case .minute:
            let interval = timeIntervalSince(date)
            return Int64(interval / Date.minuteInSeconds)
        case .hour:
            let interval = timeIntervalSince(date)
            return Int64(interval / Date.hourInSeconds)
        case .day:
            let calendar = Calendar.current
            let end = calendar.ordinality(of: .day, in: .era, for: self)
            let start = calendar.ordinality(of: .day, in: .era, for: date)
            return Int64(end! - start!)
        case .weekday:
            let calendar = Calendar.current
            let end = calendar.ordinality(of: .weekday, in: .era, for: self)
            let start = calendar.ordinality(of: .weekday, in: .era, for: date)
            return Int64(end! - start!)
        case .nthWeekday:
            let calendar = Calendar.current
            let end = calendar.ordinality(of: .weekdayOrdinal, in: .era, for: self)
            let start = calendar.ordinality(of: .weekdayOrdinal, in: .era, for: date)
            return Int64(end! - start!)
        case .week:
            let calendar = Calendar.current
            let end = calendar.ordinality(of: .weekOfYear, in: .era, for: self)
            let start = calendar.ordinality(of: .weekOfYear, in: .era, for: date)
            return Int64(end! - start!)
        case .month:
            let calendar = Calendar.current
            let end = calendar.ordinality(of: .month, in: .era, for: self)
            let start = calendar.ordinality(of: .month, in: .era, for: date)
            return Int64(end! - start!)
        case .year:
            let calendar = Calendar.current
            let end = calendar.ordinality(of: .year, in: .era, for: self)
            let start = calendar.ordinality(of: .year, in: .era, for: date)
            return Int64(end! - start!)
        }
    }
    
    // MARK: Extracting components
    
    func component(_ component: DateComponentType) -> Int? {
        let components = Date.components(self)
        switch component {
        case .second:
            return components.second
        case .minute:
            return components.minute
        case .hour:
            return components.hour
        case .day:
            return components.day
        case .weekday:
            return components.weekday
        case .nthWeekday:
            return components.weekdayOrdinal
        case .week:
            return components.weekOfYear
        case .month:
            return components.month
        case .year:
            return components.year
        }
    }
    
    func numberOfDaysInMonth() -> Int {
        let range = Calendar.current.range(of: Calendar.Component.day, in: Calendar.Component.month, for: self)!
        return range.upperBound - range.lowerBound
    }
    
    func firstDayOfWeek() -> Int {
        let distanceToStartOfWeek = Date.dayInSeconds * Double(self.component(.weekday)! - 1)
        let interval: TimeInterval = self.timeIntervalSinceReferenceDate - distanceToStartOfWeek
        return Date(timeIntervalSinceReferenceDate: interval).component(.day)!
    }
    
    func lastDayOfWeek() -> Int {
        let distanceToStartOfWeek = Date.dayInSeconds * Double(self.component(.weekday)! - 1)
        let distanceToEndOfWeek = Date.dayInSeconds * Double(7)
        let interval: TimeInterval = self.timeIntervalSinceReferenceDate - distanceToStartOfWeek + distanceToEndOfWeek
        return Date(timeIntervalSinceReferenceDate: interval).component(.day)!
    }
}
// MARK: Enums used


/**
 The string format used for date string conversion.
 
 ````
 case isoYear: i.e. 1997
 case isoYearMonth: i.e. 1997-07
 case isoDate: i.e. 1997-07-16
 case isoDateTime: i.e. 1997-07-16T19:20+01:00
 case isoDateTimeSec: i.e. 1997-07-16T19:20:30+01:00
 case isoDateTimeMilliSec: i.e. 1997-07-16T19:20:30.45+01:00
 case dotNet: i.e. "/Date(1268123281843)/"
 case rss: i.e. "Fri, 09 Sep 2011 15:26:08 +0200"
 case altRSS: i.e. "09 Sep 2011 15:26:08 +0200"
 case httpHeader: i.e. "Tue, 15 Nov 1994 12:45:26 GMT"
 case standard: "EEE MMM dd HH:mm:ss Z yyyy"
 case custom(String): a custom date format string
 ````
 
 */
public enum DateFormatType {
    
    /// The ISO8601 formatted year "yyyy" i.e. 1997
    case isoYear
    
    /// The ISO8601 formatted year and month "yyyy-MM" i.e. 1997-07
    case isoYearMonth
    
    /// The ISO8601 formatted date "yyyy-MM-dd" i.e. 1997-07-16
    case isoDate
    
    /// The ISO8601 formatted date and time "yyyy-MM-dd'T'HH:mmZ" i.e. 1997-07-16T19:20+01:00
    case isoDateTime
    
    /// The ISO8601 formatted date, time and sec "yyyy-MM-dd'T'HH:mm:ssZ" i.e. 1997-07-16T19:20:30+01:00
    case isoDateTimeSec
    
    /// The ISO8601 formatted date, time and millisec "yyyy-MM-dd'T'HH:mm:ss.SSSZ" i.e. 1997-07-16T19:20:30.45+01:00
    case isoDateTimeMilliSec
    
    /// The dotNet formatted date "/Date(%d%d)/" i.e. "/Date(1268123281843)/"
    case dotNet
    
    /// The RSS formatted date "EEE, d MMM yyyy HH:mm:ss ZZZ" i.e. "Fri, 09 Sep 2011 15:26:08 +0200"
    case rss
    
    /// The Alternative RSS formatted date "d MMM yyyy HH:mm:ss ZZZ" i.e. "09 Sep 2011 15:26:08 +0200"
    case altRSS
    
    /// The http header formatted date "EEE, dd MM yyyy HH:mm:ss ZZZ" i.e. "Tue, 15 Nov 1994 12:45:26 GMT"
    case httpHeader
    
    /// A generic standard format date i.e. "EEE MMM dd HH:mm:ss Z yyyy"
    case standard
    
    /// A custom date format string
    case custom(String)
    
    var stringFormat:String {
        switch self {
        case .isoYear: return "yyyy"
        case .isoYearMonth: return "yyyy-MM"
        case .isoDate: return "yyyy-MM-dd"
        case .isoDateTime: return "yyyy-MM-dd'T'HH:mmZ"
        case .isoDateTimeSec: return "yyyy-MM-dd'T'HH:mm:ssZ"
        case .isoDateTimeMilliSec: return "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        case .dotNet: return "/Date(%d%f)/"
        case .rss: return "EEE, d MMM yyyy HH:mm:ss ZZZ"
        case .altRSS: return "d MMM yyyy HH:mm:ss ZZZ"
        case .httpHeader: return "EEE, dd MM yyyy HH:mm:ss ZZZ"
        case .standard: return "EEE MMM dd HH:mm:ss Z yyyy"
        case .custom(let customFormat): return customFormat
        }
    }
}

extension DateFormatType: Equatable {
    public static func ==(lhs: DateFormatType, rhs: DateFormatType) -> Bool {
        switch (lhs, rhs) {
        case (.custom(let lhsString), .custom(let rhsString)):
            return lhsString == rhsString
        default:
            return lhs == rhs
        }
    }
}

/// The time zone to be used for date conversion
public enum TimeZoneType {
    case local, `default`, utc, custom(Int)
    var timeZone:TimeZone {
        switch self {
        case .local: return NSTimeZone.local
        case .default: return NSTimeZone.default
        case .utc: return TimeZone(secondsFromGMT: 0)!
        case let .custom(gmt): return TimeZone(secondsFromGMT: gmt)!
        }
    }
}

// The string keys to modify the strings in relative format
public enum RelativeTimeStringType {
    case nowPast, nowFuture, secondsPast, secondsFuture, oneMinutePast, oneMinuteFuture, minutesPast, minutesFuture, oneHourPast, oneHourFuture, hoursPast, hoursFuture, oneDayPast, oneDayFuture, daysPast, daysFuture, oneWeekPast, oneWeekFuture, weeksPast, weeksFuture, oneMonthPast, oneMonthFuture, monthsPast, monthsFuture, oneYearPast, oneYearFuture, yearsPast, yearsFuture
}

// The type of comparison to do against today's date or with the suplied date.
public enum DateComparisonType {
    
    // Days
    
    /// Checks if date today.
    case isToday
    /// Checks if date is tomorrow.
    case isTomorrow
    /// Checks if date is yesterday.
    case isYesterday
    /// Compares date days
    case isSameDay(as:Date)
    
    // Weeks
    
    /// Checks if date is in this week.
    case isThisWeek
    /// Checks if date is in next week.
    case isNextWeek
    /// Checks if date is in last week.
    case isLastWeek
    /// Compares date weeks
    case isSameWeek(as:Date)
    
    // Months
    
    /// Checks if date is in this month.
    case isThisMonth
    /// Checks if date is in next month.
    case isNextMonth
    /// Checks if date is in last month.
    case isLastMonth
    /// Compares date months
    case isSameMonth(as:Date)
    
    // Years
    
    /// Checks if date is in this year.
    case isThisYear
    /// Checks if date is in next year.
    case isNextYear
    /// Checks if date is in last year.
    case isLastYear
    /// Compare date years
    case isSameYear(as:Date)
    
    // Relative Time
    
    /// Checks if it's a future date
    case isInTheFuture
    /// Checks if the date has passed
    case isInThePast
    /// Checks if earlier than date
    case isEarlier(than:Date)
    /// Checks if later than date
    case isLater(than:Date)
    /// Checks if it's a weekday
    case isWeekday
    /// Checks if it's a weekend
    case isWeekend
    
}

// The date components available to be retrieved or modifed
public enum DateComponentType {
    case second, minute, hour, day, weekday, nthWeekday, week, month, year
}


// The type of date that can be used for the dateFor function.
public enum DateForType {
    case startOfDay, endOfDay, startOfWeek, endOfWeek, startOfMonth, endOfMonth, tomorrow, yesterday, nearestMinute(minute:Int), nearestHour(hour:Int)
}

// Convenience types for date to string conversion
public enum DateStyleType {
    /// Short style: "2/27/17, 2:22 PM"
    case short
    /// Medium style: "Feb 27, 2017, 2:22:06 PM"
    case medium
    /// Long style: "February 27, 2017 at 2:22:06 PM EST"
    case long
    /// Full style: "Monday, February 27, 2017 at 2:22:06 PM Eastern Standard Time"
    case full
    /// Ordinal day: "27th"
    case ordinalDay
    /// Weekday: "Monday"
    case weekday
    /// Short week day: "Mon"
    case shortWeekday
    /// Very short weekday: "M"
    case veryShortWeekday
    /// Month: "February"
    case month
    /// Short month: "Feb"
    case shortMonth
    /// Very short month: "F"
    case veryShortMonth
}
