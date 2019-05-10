//
//  AFDateHelper.swift
//  https://github.com/melvitax/DateHelper
//  Version 4.2.8
//
//  Created by Melvin Rivera on 7/15/14.
//  Copyright (c) 2014. All rights reserved.
//

import Foundation


public extension Date {
    
    // MARK: Convert from String
    
    /*
        Initializes a new Date() objext based on a date string, format, optional timezone and optional locale.
     
        - Returns: A Date() object if successfully converted from string or nil.
    */
    init?(fromString string: String, format: DateFormatType, timeZone: TimeZoneType = .local, locale: Locale = Foundation.Locale.current) {
        guard !string.isEmpty else {
            return nil
        }
        var string = string
        switch format {
            case .dotNet:
                let pattern = "\\\\?/Date\\((\\d+)(([+-]\\d{2})(\\d{2}))?\\)\\\\?/"
                let regex = try! NSRegularExpression(pattern: pattern)
                guard let match = regex.firstMatch(in: string, range: NSRange(location: 0, length: string.utf16.count)) else {
                    return nil
                }
                 #if swift(>=4.0)
                let dateString = (string as NSString).substring(with: match.range(at: 1))
                #else
                let dateString = (string as NSString).substring(with: match.rangeAt(1))
                #endif
                let interval = Double(dateString)! / 1000.0
                self.init(timeIntervalSince1970: interval)
                return
            case .rss, .altRSS:
                if string.hasSuffix("Z") {
                    string = string[..<string.index(string.endIndex, offsetBy: -1)].appending("GMT")
                }
            default:
                break
        }
        let formatter = Date.cachedFormatter(format.stringFormat, timeZone: timeZone.timeZone, locale: locale)
        guard let date = formatter.date(from: string) else {
            return nil
        }
        self.init(timeInterval:0, since:date)
    }
    
    // MARK: Convert to String
    
    
    /// Converts the date to string using the short date and time style.
    func toString(style: DateStyleType = .short) -> String {
        switch style {
        case .short:
            return self.toString(dateStyle: .short, timeStyle: .short, isRelative: false)
        case .medium:
            return self.toString(dateStyle: .medium, timeStyle: .medium, isRelative: false)
        case .long:
            return self.toString(dateStyle: .long, timeStyle: .long, isRelative: false)
        case .full:
            return self.toString(dateStyle: .full, timeStyle: .full, isRelative: false)
        case .ordinalDay:
            let formatter = Date.cachedOrdinalNumberFormatter
            if #available(iOSApplicationExtension 9.0, *) {
				if #available(iOS 9.0, *) {
					formatter.numberStyle = .ordinal
				} else {
					// Fallback on earlier versions
				}
            }
            return formatter.string(from: component(.day)! as NSNumber)!
        case .weekday:
            let weekdaySymbols = Date.cachedFormatter().weekdaySymbols!
            let string = weekdaySymbols[component(.weekday)!-1] as String
            return string
        case .shortWeekday:
            let shortWeekdaySymbols = Date.cachedFormatter().shortWeekdaySymbols!
            return shortWeekdaySymbols[component(.weekday)!-1] as String
        case .veryShortWeekday:
            let veryShortWeekdaySymbols = Date.cachedFormatter().veryShortWeekdaySymbols!
            return veryShortWeekdaySymbols[component(.weekday)!-1] as String
        case .month:
            let monthSymbols = Date.cachedFormatter().monthSymbols!
            return monthSymbols[component(.month)!-1] as String
        case .shortMonth:
            let shortMonthSymbols = Date.cachedFormatter().shortMonthSymbols!
            return shortMonthSymbols[component(.month)!-1] as String
        case .veryShortMonth:
            let veryShortMonthSymbols = Date.cachedFormatter().veryShortMonthSymbols!
            return veryShortMonthSymbols[component(.month)!-1] as String
        }
    }
    
    /// Converts the date to string based on a date format, optional timezone and optional locale.
    func toString(format: DateFormatType, timeZone: TimeZoneType = .local, locale: Locale = Locale.current) -> String {
        switch format {
        case .dotNet:
            let offset = Foundation.NSTimeZone.default.secondsFromGMT() / 3600
            let nowMillis = 1000 * self.timeIntervalSince1970
            return String(format: format.stringFormat, nowMillis, offset)
        default:
            break
        }
        let formatter = Date.cachedFormatter(format.stringFormat, timeZone: timeZone.timeZone, locale: locale)
        return formatter.string(from: self)
    }
    
    /// Converts the date to string based on DateFormatter's date style and time style with optional relative date formatting, optional time zone and optional locale.
    func toString(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style, isRelative: Bool = false, timeZone: Foundation.TimeZone = Foundation.NSTimeZone.local, locale: Locale = Locale.current) -> String {
        let formatter = Date.cachedFormatter(dateStyle, timeStyle: timeStyle, doesRelativeDateFormatting: isRelative, timeZone: timeZone, locale: locale)
        return formatter.string(from: self)
    }
    
    /// Converts the date to string based on a relative time language. i.e. just now, 1 minute ago etc...
    func toStringWithRelativeTime(strings:[RelativeTimeStringType: String]? = nil) -> String {
        
        let time = self.timeIntervalSince1970
        let now = Date().timeIntervalSince1970
        let isPast = now - time > 0
        
        let sec:Double = abs(now - time)
        let min:Double = round(sec/60)
        let hr:Double = round(min/60)
        let d:Double = round(hr/24)
        
        if sec < 60 {
            if sec < 10 {
                if isPast {
                    return strings?[.nowPast] ?? NSLocalizedString("just now", comment: "Date format")
                } else {
                    return strings?[.nowFuture] ?? NSLocalizedString("in a few seconds", comment: "Date format")
                }
            } else {
                let string:String
                if isPast {
                    string = strings?[.secondsPast] ?? NSLocalizedString("%.f seconds ago", comment: "Date format")
                } else {
                    string = strings?[.secondsFuture] ?? NSLocalizedString("in %.f seconds", comment: "Date format")
                }
                return String(format: string, sec)
            }
        }
        if min < 60 {
            if min == 1 {
                if isPast {
                    return strings?[.oneMinutePast] ?? NSLocalizedString("1 minute ago", comment: "Date format")
                } else {
                    return strings?[.oneMinuteFuture] ?? NSLocalizedString("in 1 minute", comment: "Date format")
                }
            } else {
                let string:String
                if isPast {
                    string = strings?[.minutesPast] ?? NSLocalizedString("%.f minutes ago", comment: "Date format")
                } else {
                    string = strings?[.minutesFuture] ?? NSLocalizedString("in %.f minutes", comment: "Date format")
                }
                return String(format: string, min)
            }
        }
        if hr < 24 {
            if hr == 1 {
                if isPast {
                    return strings?[.oneHourPast] ?? NSLocalizedString("last hour", comment: "Date format")
                } else {
                    return strings?[.oneHourFuture] ?? NSLocalizedString("next hour", comment: "Date format")
                }
            } else {
                let string:String
                if isPast {
                    string = strings?[.hoursPast] ?? NSLocalizedString("%.f hours ago", comment: "Date format")
                } else {
                    string = strings?[.hoursFuture] ?? NSLocalizedString("in %.f hours", comment: "Date format")
                }
                return String(format: string, hr)
            }
        }
        if d < 7 {
            if d == 1 {
                if isPast {
                    return strings?[.oneDayPast] ?? NSLocalizedString("yesterday", comment: "Date format")
                } else {
                    return strings?[.oneDayFuture] ?? NSLocalizedString("tomorrow", comment: "Date format")
                }
            } else {
                let string:String
                if isPast {
                    string = strings?[.daysPast] ?? NSLocalizedString("%.f days ago", comment: "Date format")
                } else {
                    string = strings?[.daysFuture] ?? NSLocalizedString("in %.f days", comment: "Date format")
                }
                return String(format: string, d)
            }
        }
        if d < 28 {
            if isPast {
                if compare(.isLastWeek) {
                    return strings?[.oneWeekPast] ?? NSLocalizedString("last week", comment: "Date format")
                } else {
                    let string = strings?[.weeksPast] ?? NSLocalizedString("%.f weeks ago", comment: "Date format")
                    return String(format: string, Double(abs(since(Date(), in: .week))))
                }
            } else {
                if compare(.isNextWeek) {
                    return strings?[.oneWeekFuture] ?? NSLocalizedString("next week", comment: "Date format")
                } else {
                    let string = strings?[.weeksFuture] ?? NSLocalizedString("in %.f weeks", comment: "Date format")
                    return String(format: string, Double(abs(since(Date(), in: .week))))
                }
            }
        }
        if compare(.isThisYear) {
            if isPast {
                if compare(.isLastMonth) {
                    return strings?[.oneMonthPast] ?? NSLocalizedString("last month", comment: "Date format")
                } else {
                    let string = strings?[.monthsPast] ?? NSLocalizedString("%.f months ago", comment: "Date format")
                    return String(format: string, Double(abs(since(Date(), in: .month))))
                }
            } else {
                if compare(.isNextMonth) {
                    return strings?[.oneMonthFuture] ?? NSLocalizedString("next month", comment: "Date format")
                } else {
                    let string = strings?[.monthsFuture] ?? NSLocalizedString("in %.f months", comment: "Date format")
                    return String(format: string, Double(abs(since(Date(), in: .month))))
                }
            }
        }
        if isPast {
            if compare(.isLastYear) {
                return strings?[.oneYearPast] ?? NSLocalizedString("last year", comment: "Date format")
            } else {
                let string = strings?[.yearsPast] ?? NSLocalizedString("%.f years ago", comment: "Date format")
                return String(format: string, Double(abs(since(Date(), in: .year))))
            }
        } else {
            if compare(.isNextYear) {
                return strings?[.oneYearFuture] ?? NSLocalizedString("next year", comment: "Date format")
            } else {
                let string = strings?[.yearsFuture] ?? NSLocalizedString("in %.f years", comment: "Date format")
                return String(format: string, Double(abs(since(Date(), in: .year))))
            }
        }
    }
    
    
    // MARK: Compare Dates
    
    /// Compares dates to see if they are equal while ignoring time.
    func compare(_ comparison: DateComparisonType) -> Bool {
        switch comparison {
            case .isToday:
                return compare(.isSameDay(as: Date()))
            case .isTomorrow:
                let comparison = Date().adjust(.day, offset:1)
                return compare(.isSameDay(as: comparison))
            case .isYesterday:
                let comparison = Date().adjust(.day, offset: -1)
                return compare(.isSameDay(as: comparison))
            case .isSameDay(let date):
                return component(.year) == date.component(.year)
                    && component(.month) == date.component(.month)
                    && component(.day) == date.component(.day)
            case .isThisWeek:
                return self.compare(.isSameWeek(as: Date()))
            case .isNextWeek:
                let comparison = Date().adjust(.week, offset:1)
                return compare(.isSameWeek(as: comparison))
            case .isLastWeek:
                let comparison = Date().adjust(.week, offset:-1)
                return compare(.isSameWeek(as: comparison))
            case .isSameWeek(let date):
                if component(.week) != date.component(.week) {
                    return false
                }
                // Ensure time interval is under 1 week
                return abs(self.timeIntervalSince(date)) < Date.weekInSeconds
            case .isThisMonth:
                return self.compare(.isSameMonth(as: Date()))
            case .isNextMonth:
                let comparison = Date().adjust(.month, offset:1)
                return compare(.isSameMonth(as: comparison))
            case .isLastMonth:
                let comparison = Date().adjust(.month, offset:-1)
                return compare(.isSameMonth(as: comparison))
            case .isSameMonth(let date):
                return component(.year) == date.component(.year) && component(.month) == date.component(.month)
            case .isThisYear:
                return self.compare(.isSameYear(as: Date()))
            case .isNextYear:
                let comparison = Date().adjust(.year, offset:1)
                return compare(.isSameYear(as: comparison))
            case .isLastYear:
                let comparison = Date().adjust(.year, offset:-1)
                return compare(.isSameYear(as: comparison))
            case .isSameYear(let date):
                return component(.year) == date.component(.year)
            case .isInTheFuture:
                return self.compare(.isLater(than: Date()))
            case .isInThePast:
                return self.compare(.isEarlier(than: Date()))
            case .isEarlier(let date):
                return (self as NSDate).earlierDate(date) == self
            case .isLater(let date):
                return (self as NSDate).laterDate(date) == self
        case .isWeekday:
            return !compare(.isWeekend)
        case .isWeekend:
            let range = Calendar.current.maximumRange(of: Calendar.Component.weekday)!
            return (component(.weekday) == range.lowerBound || component(.weekday) == range.upperBound - range.lowerBound)
        }
        
    }
 

    // MARK: Adjust dates
    
    /// Creates a new date with adjusted components
    
    func adjust(_ component: DateComponentType, offset:Int) -> Date {
        var dateComp = DateComponents()
        switch component {
            case .second:
                dateComp.second = offset
            case .minute:
                dateComp.minute = offset
            case .hour:
                dateComp.hour = offset
            case .day:
                dateComp.day = offset
            case .weekday:
                dateComp.weekday = offset
            case .nthWeekday:
                dateComp.weekdayOrdinal = offset
            case .week:
                dateComp.weekOfYear = offset
            case .month:
                dateComp.month = offset
            case .year:
                dateComp.year = offset
        }
        return Calendar.current.date(byAdding: dateComp, to: self)!
    }
    
    /// Return a new Date object with the new hour, minute and seconds values.
    func adjust(hour: Int?, minute: Int?, second: Int?, day: Int? = nil, month: Int? = nil) -> Date {
        var comp = Date.components(self)
        comp.month = month ?? comp.month
        comp.day = day ?? comp.day
        comp.hour = hour ?? comp.hour
        comp.minute = minute ?? comp.minute
        comp.second = second ?? comp.second
        return Calendar.current.date(from: comp)!
    }
    
    // MARK: Internal Components
    
    internal static func componentFlags() -> Set<Calendar.Component> { return [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day, Calendar.Component.weekOfYear, Calendar.Component.hour, Calendar.Component.minute, Calendar.Component.second, Calendar.Component.weekday, Calendar.Component.weekdayOrdinal, Calendar.Component.weekOfYear] }
    internal static func components(_ fromDate: Date) -> DateComponents {
        return Calendar.current.dateComponents(Date.componentFlags(), from: fromDate)
    }
    
    // MARK: Static Cached Formatters
    
    /// A cached static array of DateFormatters so that thy are only created once.
    private static var cachedDateFormatters = [String: DateFormatter]()
    private static var cachedOrdinalNumberFormatter = NumberFormatter()
    
    /// Generates a cached formatter based on the specified format, timeZone and locale. Formatters are cached in a singleton array using hashkeys.
    private static func cachedFormatter(_ format:String = DateFormatType.standard.stringFormat, timeZone: Foundation.TimeZone = Foundation.TimeZone.current, locale: Locale = Locale.current) -> DateFormatter {
        let hashKey = "\(format.hashValue)\(timeZone.hashValue)\(locale.hashValue)"
        if Date.cachedDateFormatters[hashKey] == nil {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.timeZone = timeZone
            formatter.locale = locale
            formatter.isLenient = true
            Date.cachedDateFormatters[hashKey] = formatter
        }
        return Date.cachedDateFormatters[hashKey]!
    }
    
    /// Generates a cached formatter based on the provided date style, time style and relative date. Formatters are cached in a singleton array using hashkeys.
    private static func cachedFormatter(_ dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style, doesRelativeDateFormatting: Bool, timeZone: Foundation.TimeZone = Foundation.NSTimeZone.local, locale: Locale = Locale.current) -> DateFormatter {
        let hashKey = "\(dateStyle.hashValue)\(timeStyle.hashValue)\(doesRelativeDateFormatting.hashValue)\(timeZone.hashValue)\(locale.hashValue)"
        if Date.cachedDateFormatters[hashKey] == nil {
            let formatter = DateFormatter()
            formatter.dateStyle = dateStyle
            formatter.timeStyle = timeStyle
            formatter.doesRelativeDateFormatting = doesRelativeDateFormatting
            formatter.timeZone = timeZone
            formatter.locale = locale
            formatter.isLenient = true
            Date.cachedDateFormatters[hashKey] = formatter
        }
        return Date.cachedDateFormatters[hashKey]!
    }
    
    // MARK: Intervals In Seconds
    internal static let minuteInSeconds:Double = 60
    internal static let hourInSeconds:Double = 3600
    internal static let dayInSeconds:Double = 86400
    internal static let weekInSeconds:Double = 604800
    internal static let yearInSeconds:Double = 31556926
    
}
