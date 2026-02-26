import Foundation

struct DiskUsage {
    let used: UInt64
    let total: UInt64
    let percentage: Double
}

final class DiskMonitor {
    func getUsage() -> DiskUsage {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/") else {
            return DiskUsage(used: 0, total: 0, percentage: 0)
        }

        let total = attrs[.systemSize] as? UInt64 ?? 0
        let free = attrs[.systemFreeSize] as? UInt64 ?? 0
        let used = total - free

        return DiskUsage(
            used: used,
            total: total,
            percentage: total > 0 ? Double(used) / Double(total) * 100.0 : 0
        )
    }
}
