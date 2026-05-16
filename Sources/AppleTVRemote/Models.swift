import Foundation

struct AppleTVDevice: Identifiable, Codable {
    let name: String
    let identifier: String
    let address: String
    let deviceInfo: String?
    let paired: Bool

    var id: String { identifier }
}

enum RemoteCommand: String, CaseIterable {
    case up, down, left, right, select
    case menu, home
    case playPause = "play_pause"
    case previous, next
    case volumeUp = "volume_up"
    case volumeDown = "volume_down"
    case power = "suspend"
    case wake = "wakeup"
}

enum BridgeState {
    case idle
    case scanning
    case deviceList([AppleTVDevice])
    case pairingRequired(deviceName: String, identifier: String, message: String)
    case pairingStarted(message: String)
    case pairingSuccess(message: String)
    case connected(deviceName: String)
    case error(String)
}

enum BridgeMessage {
    case scanResult([AppleTVDevice])
    case connected(String)
    case disconnected
    case ok
    case error(String)
    case bye
}
