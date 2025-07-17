import Foundation

#if arch(arm64)
    print("Hello from macOS on ARM64 (Apple Silicon)!")
    print("Running optimized code for Apple Silicon")
#elseif arch(x86_64)
    print("Hello from macOS on x86_64 (Intel)!")
    print("Running on Intel architecture")
#else
    print("Hello from macOS on unknown architecture!")
#endif

// Get system information
let process = Process()
process.launchPath = "/usr/sbin/sysctl"
process.arguments = ["-n", "machdep.cpu.brand_string"]
let pipe = Pipe()
process.standardOutput = pipe
process.launch()

let data = pipe.fileHandleForReading.readDataToEndOfFile()
if let cpuInfo = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
    print("CPU: \(cpuInfo)")
}

process.waitUntilExit()