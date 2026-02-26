import Foundation

@Observable
final class SystemStatsManager {
    var cpuUsage: Double = 0
    var memoryUsage: Double = 0
    var memoryUsedGB: Double = 0
    var memoryTotalGB: Double = 0
    var diskUsage: Double = 0
    var diskUsedGB: Double = 0
    var diskTotalGB: Double = 0
    var networkInRate: Double = 0
    var networkOutRate: Double = 0

    private var timer: Timer?
    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private let diskMonitor = DiskMonitor()
    private let networkMonitor = NetworkMonitor()

    func startMonitoring() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func update() {
        cpuUsage = cpuMonitor.getUsage()

        let mem = memoryMonitor.getUsage()
        memoryUsage = mem.percentage
        memoryUsedGB = Double(mem.used) / 1_073_741_824
        memoryTotalGB = Double(mem.total) / 1_073_741_824

        let disk = diskMonitor.getUsage()
        diskUsage = disk.percentage
        diskUsedGB = Double(disk.used) / 1_073_741_824
        diskTotalGB = Double(disk.total) / 1_073_741_824

        let net = networkMonitor.getUsage()
        networkInRate = net.rateIn
        networkOutRate = net.rateOut
    }
}
