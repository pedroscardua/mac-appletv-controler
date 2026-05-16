import Foundation
import Combine

class AppleTVBridge: ObservableObject {
    @Published var devices: [AppleTVDevice] = []
    @Published var connectedDeviceName: String?
    @Published var isScanning = false
    @Published var errorMessage: String?
    @Published var pairingMessage: String?
    @Published var showPinEntry = false
    @Published var pairingIdentifier: String?

    private var process: Process?
    private var stdin: FileHandle?
    private var stdoutTask: Task<Void, Never>?

    // MARK: - Lifecycle

    func start() {
        guard let bridgePath = findBridgeScript() else {
            errorMessage = "bridge.py not found"
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [bridgePath]
        process.environment = ProcessInfo.processInfo.environment

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = FileHandle.nullDevice

        self.process = process
        self.stdin = stdinPipe.fileHandleForWriting

        stdoutTask = Task.detached { [weak self] in
            let handle = stdoutPipe.fileHandleForReading
            var buffer = Data()
            while true {
                let data = handle.availableData
                if data.isEmpty { break }
                buffer.append(data)
                while let newline = buffer.firstIndex(of: 10) {
                    let lineData = buffer[..<newline]
                    buffer.removeSubrange(...newline)
                    if let line = String(data: lineData, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines), !line.isEmpty {
                        await self?.handleResponse(line)
                    }
                }
            }
        }

        do {
            try process.run()
        } catch {
            errorMessage = "Failed to start bridge: \(error.localizedDescription)"
        }
    }

    func stop() {
        send(json: #"{"action": "quit"}"#)
        stdin?.closeFile()
        process?.terminate()
        stdoutTask?.cancel()
        process = nil
        stdin = nil
    }

    // MARK: - Actions

    func scan() {
        isScanning = true
        errorMessage = nil
        pairingMessage = nil
        showPinEntry = false
        send(json: #"{"action": "scan"}"#)
    }

    func connect(to device: AppleTVDevice) {
        errorMessage = nil
        pairingMessage = nil
        showPinEntry = false
        pairingIdentifier = device.identifier
        send(json: #"{"action": "connect", "identifier": "\#(device.identifier)"}"#)
    }

    func beginPairing() {
        errorMessage = nil
        showPinEntry = false
        send(json: #"{"action": "begin_pairing"}"#)
    }

    func submitPin(_ pin: String) {
        errorMessage = nil
        showPinEntry = false
        pairingMessage = "Pairing..."
        send(json: #"{"action": "submit_pin", "pin": "\#(pin)"}"#)
    }

    func sendCommand(_ command: RemoteCommand) {
        send(json: #"{"action": "command", "command": "\#(command.rawValue)"}"#)
    }

    func sendHoldCommand(_ command: RemoteCommand) {
        send(json: #"{"action": "hold_command", "command": "\#(command.rawValue)"}"#)
    }

    func disconnect() {
        send(json: #"{"action": "disconnect"}"#)
        connectedDeviceName = nil
        showPinEntry = false
        pairingMessage = nil
        pairingIdentifier = nil
    }

    // MARK: - Internal

    private func send(json: String) {
        guard let stdin = stdin else { return }
        let line = json + "\n"
        if let data = line.data(using: .utf8) {
            stdin.write(data)
        }
    }

    private func handleResponse(_ line: String) async {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        await MainActor.run {
            switch type {
            case "scan_result":
                if let arr = json["devices"] as? [[String: Any]] {
                    devices = arr.compactMap { dict in
                        guard let name = dict["name"] as? String,
                              let identifier = dict["identifier"] as? String,
                              let address = dict["address"] as? String
                        else { return nil }
                        return AppleTVDevice(
                            name: name,
                            identifier: identifier,
                            address: address,
                            deviceInfo: dict["device_info"] as? String,
                            paired: dict["paired"] as? Bool ?? false
                        )
                    }
                }
                isScanning = false
                // Auto-connect if only one device
                if devices.count == 1, connectedDeviceName == nil {
                    connect(to: devices[0])
                }

            case "pairing_required":
                pairingMessage = json["message"] as? String
                showPinEntry = false
                if let ident = json["identifier"] as? String {
                    pairingIdentifier = ident
                }

            case "pairing_started":
                pairingMessage = json["message"] as? String
                showPinEntry = true

            case "pairing_success":
                pairingMessage = json["message"] as? String
                showPinEntry = false

            case "connected":
                connectedDeviceName = json["name"] as? String
                errorMessage = nil
                pairingMessage = nil
                showPinEntry = false

            case "disconnected":
                connectedDeviceName = nil

            case "ok":
                break

            case "error":
                errorMessage = json["message"] as? String

            case "bye":
                break

            default:
                break
            }
        }
    }

    private func findBridgeScript() -> String? {
        let exeDir = Bundle.main.executableURL?.deletingLastPathComponent()
        let searchPaths = [
            Bundle.main.path(forResource: "bridge", ofType: "py"),
            exeDir?.appendingPathComponent("../Resources/bridge.py").path,
            exeDir?.appendingPathComponent("../../../Scripts/bridge.py").path,
            exeDir?.appendingPathComponent("../../../../Scripts/bridge.py").path,
            NSHomeDirectory() + "/Documents/labs/appletv_control/Scripts/bridge.py",
        ]
        for path in searchPaths {
            if let p = path, FileManager.default.fileExists(atPath: p) {
                return p
            }
        }
        return nil
    }
}
