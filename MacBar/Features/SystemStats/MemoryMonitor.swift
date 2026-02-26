import Darwin

struct MemoryUsage {
    let used: UInt64
    let total: UInt64
    let percentage: Double
}

final class MemoryMonitor {
    private let totalMemory: UInt64 = {
        var size: UInt64 = 0
        var sizeOfSize = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &size, &sizeOfSize, nil, 0)
        return size
    }()

    func getUsage() -> MemoryUsage {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryUsage(used: 0, total: totalMemory, percentage: 0)
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let used = active + wired + compressed

        return MemoryUsage(
            used: used,
            total: totalMemory,
            percentage: Double(used) / Double(totalMemory) * 100.0
        )
    }
}
