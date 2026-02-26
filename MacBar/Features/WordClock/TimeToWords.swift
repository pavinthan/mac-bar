import Foundation

enum TimeToWords {
    private static let ones = [
        "", "one", "two", "three", "four", "five",
        "six", "seven", "eight", "nine", "ten",
        "eleven", "twelve", "thirteen", "fourteen", "fifteen",
        "sixteen", "seventeen", "eighteen", "nineteen"
    ]

    private static let tens = [
        "", "", "twenty", "thirty", "forty", "fifty"
    ]

    static func convert(hour: Int, minute: Int) -> String {
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        let nextHour = (displayHour % 12) + 1

        switch minute {
        case 0:
            return "It is \(numberToWords(displayHour)) o'clock"
        case 1...14:
            return "It is \(numberToWords(minute)) past \(numberToWords(displayHour))"
        case 15:
            return "It is quarter past \(numberToWords(displayHour))"
        case 16...29:
            return "It is \(numberToWords(minute)) past \(numberToWords(displayHour))"
        case 30:
            return "It is half past \(numberToWords(displayHour))"
        case 31...44:
            return "It is \(numberToWords(60 - minute)) to \(numberToWords(nextHour))"
        case 45:
            return "It is quarter to \(numberToWords(nextHour))"
        case 46...59:
            return "It is \(numberToWords(60 - minute)) to \(numberToWords(nextHour))"
        default:
            return "It is \(numberToWords(displayHour)) o'clock"
        }
    }

    private static func numberToWords(_ n: Int) -> String {
        if n < 20 {
            return ones[n]
        }
        let t = tens[n / 10]
        let o = ones[n % 10]
        if o.isEmpty {
            return t
        }
        return "\(t)-\(o)"
    }
}
