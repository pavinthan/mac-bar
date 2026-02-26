import Darwin
import Foundation

struct NetworkUsage {
    let bytesIn: UInt64
    let bytesOut: UInt64
    let rateIn: Double
    let rateOut: Double
}

final class NetworkMonitor {
    private var previousIn: UInt64 = 0
    private var previousOut: UInt64 = 0
    private var previousTime: Date = .now

    func getUsage() -> NetworkUsage {
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else {
            return NetworkUsage(bytesIn: 0, bytesOut: 0, rateIn: 0, rateOut: 0)
        }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            let flags = Int32(ptr!.pointee.ifa_flags)
            if (flags & IFF_UP) != 0 && (flags & IFF_LOOPBACK) == 0 {
                if ptr!.pointee.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                    if let data = ptr!.pointee.ifa_data {
                        let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                        totalIn += UInt64(networkData.ifi_ibytes)
                        totalOut += UInt64(networkData.ifi_obytes)
                    }
                }
            }
            ptr = ptr!.pointee.ifa_next
        }

        let now = Date()
        let elapsed = now.timeIntervalSince(previousTime)

        var rateIn = 0.0
        var rateOut = 0.0

        if elapsed > 0 && previousIn > 0 {
            rateIn = Double(totalIn &- previousIn) / elapsed
            rateOut = Double(totalOut &- previousOut) / elapsed
        }

        previousIn = totalIn
        previousOut = totalOut
        previousTime = now

        return NetworkUsage(
            bytesIn: totalIn,
            bytesOut: totalOut,
            rateIn: max(0, rateIn),
            rateOut: max(0, rateOut)
        )
    }

    static func formatRate(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return String(format: "%.0f B/s", bytesPerSecond)
        } else if bytesPerSecond < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1024)
        } else {
            return String(format: "%.1f MB/s", bytesPerSecond / (1024 * 1024))
        }
    }
}
