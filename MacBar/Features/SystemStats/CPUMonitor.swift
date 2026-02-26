import Darwin

final class CPUMonitor {
    private var previousTicks: (user: Int64, system: Int64, idle: Int64)?

    func getUsage() -> Double {
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCPUInfo
        )

        guard result == KERN_SUCCESS, let info = cpuInfo else {
            return 0
        }

        var totalUser: Int64 = 0
        var totalSystem: Int64 = 0
        var totalIdle: Int64 = 0

        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            totalUser += Int64(info[offset + Int(CPU_STATE_USER)])
            totalSystem += Int64(info[offset + Int(CPU_STATE_SYSTEM)])
            totalIdle += Int64(info[offset + Int(CPU_STATE_IDLE)])
        }

        let size = vm_size_t(numCPUInfo) * vm_size_t(MemoryLayout<integer_t>.size)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), size)

        defer {
            previousTicks = (user: totalUser, system: totalSystem, idle: totalIdle)
        }

        guard let prev = previousTicks else {
            return 0
        }

        let deltaUser = totalUser - prev.user
        let deltaSystem = totalSystem - prev.system
        let deltaIdle = totalIdle - prev.idle
        let deltaTotal = deltaUser + deltaSystem + deltaIdle

        if deltaTotal <= 0 {
            return 0
        }

        return Double(deltaUser + deltaSystem) / Double(deltaTotal) * 100.0
    }
}
