import SwiftUI

struct RemoteView: View {
    @EnvironmentObject var bridge: AppleTVBridge
    @State private var pressedButton: String?
    @State private var pinText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            headerView
            contentView
        }
        .padding(.vertical, 12)
        .frame(width: 260)
        .background(Color(.windowBackgroundColor))
        .onChange(of: bridge.showPinEntry) { _, show in
            if show { pinText = "" }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        Group {
            if bridge.isScanning {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.7)
                    Text("Looking for Apple TVs...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
            } else if let name = bridge.connectedDeviceName {
                connectedHeader(name)
            } else if bridge.showPinEntry {
                pinEntryView
            } else if let msg = bridge.pairingMessage, !bridge.showPinEntry {
                pairingRequiredView(msg)
            } else if !bridge.devices.isEmpty && bridge.connectedDeviceName == nil {
                devicePicker
            } else if bridge.devices.isEmpty && !bridge.isScanning {
                emptyState
            }

            if let error = bridge.errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    private func connectedHeader(_ name: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "appletv.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.accentColor)
                Text(name)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.top, 4)

            Button("Disconnect") {
                bridge.disconnect()
                bridge.scan()
            }
            .buttonStyle(.link)
            .font(.system(size: 11))
        }
    }

    private func pairingRequiredView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                Button("Pair") { bridge.beginPairing() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                Button("Rescan") { bridge.scan() }
                    .buttonStyle(.link).font(.system(size: 11))
            }
        }
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "appletv.slash")
                .font(.system(size: 20)).foregroundColor(.secondary)
            Text("No Apple TVs found")
                .font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
            Button("Scan Again") { bridge.scan() }
                .buttonStyle(.link).font(.system(size: 12))
        }
        .padding(.vertical, 10)
    }

    private var devicePicker: some View {
        VStack(spacing: 4) {
            Text("Select Apple TV")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            ForEach(bridge.devices) { device in
                Button(action: { bridge.connect(to: device) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "appletv.fill").font(.system(size: 12))
                        Text(device.name).font(.system(size: 13))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            Button("Rescan") { bridge.scan() }
                .buttonStyle(.link).font(.system(size: 11))
        }
        .padding(.horizontal)
    }

    // MARK: - PIN Entry

    private var pinEntryView: some View {
        VStack(spacing: 10) {
            if let msg = bridge.pairingMessage {
                Text(msg)
                    .font(.system(size: 12, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                TextField("PIN code", text: $pinText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .onSubmit { submitPin() }

                Button("Pair") { submitPin() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(pinText.isEmpty)
            }

            Button("Cancel") {
                bridge.showPinEntry = false
                bridge.pairingMessage = nil
                bridge.scan()
            }
            .buttonStyle(.link)
            .font(.system(size: 11))
        }
        .padding(.vertical, 8)
    }

    private func submitPin() {
        guard !pinText.isEmpty else { return }
        bridge.submitPin(pinText)
        pinText = ""
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if bridge.connectedDeviceName != nil {
            remoteControls
        }
    }

    // MARK: - Remote Controls

    private var remoteControls: some View {
        VStack(spacing: 0) {
            Divider().padding(.horizontal)
            dpadView.padding(.vertical, 14)
            Divider().padding(.horizontal)
            playbackView.padding(.vertical, 10)
            Divider().padding(.horizontal)
            bottomButtons.padding(.vertical, 10)
        }
    }

    // MARK: - D-Pad

    private var dpadView: some View {
        VStack(spacing: 2) {
            DpadButton(id: "up", icon: "chevron.up", pressedButton: $pressedButton, bridge: bridge)
            HStack(spacing: 2) {
                DpadButton(id: "left", icon: "chevron.left", pressedButton: $pressedButton, bridge: bridge)
                DpadButton(id: "select", icon: "circle.fill", pressedButton: $pressedButton, bridge: bridge, size: 52, fontWeight: .bold)
                DpadButton(id: "right", icon: "chevron.right", pressedButton: $pressedButton, bridge: bridge)
            }
            DpadButton(id: "down", icon: "chevron.down", pressedButton: $pressedButton, bridge: bridge)
        }
    }

    // MARK: - Playback

    private var playbackView: some View {
        HStack(spacing: 20) {
            PlaybackButton(id: "previous", icon: "backward.fill", pressedButton: $pressedButton, bridge: bridge)
            PlaybackButton(id: "playPause", icon: "playpause.fill", pressedButton: $pressedButton, bridge: bridge, size: 48, fontSize: 22)
            PlaybackButton(id: "next", icon: "forward.fill", pressedButton: $pressedButton, bridge: bridge)
        }
    }

    // MARK: - Bottom

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                LabeledButton(id: "menu", icon: "line.3.horizontal", label: "Menu", pressedButton: $pressedButton, bridge: bridge)
                LabeledButton(id: "home", icon: "tv.fill", label: "Home", pressedButton: $pressedButton, bridge: bridge)
            }
            HStack(spacing: 24) {
                LabeledButton(id: "volumeDown", icon: "speaker.minus.fill", label: "Vol -", pressedButton: $pressedButton, bridge: bridge, size: 38, fontSize: 14)
                LabeledButton(id: "volumeUp", icon: "speaker.plus.fill", label: "Vol +", pressedButton: $pressedButton, bridge: bridge, size: 38, fontSize: 14)
                LabeledButton(id: "power", icon: "power", label: "Sleep", pressedButton: $pressedButton, bridge: bridge, size: 38, fontSize: 14)
            }
        }
    }
}

// MARK: - Reusable Button Components

struct RemoteButtonStyle {
    let size: CGFloat
    let fontSize: CGFloat
    let isPressed: Bool

    func background() -> some View {
        Circle()
            .fill(isPressed ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.06))
    }

    func border() -> some View {
        Circle()
            .stroke(isPressed ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.12), lineWidth: isPressed ? 1.5 : 1)
    }
}

struct DpadButton: View {
    let id: String
    let icon: String
    @Binding var pressedButton: String?
    var bridge: AppleTVBridge
    var size: CGFloat = 44
    var fontWeight: Font.Weight = .regular

    // Track long press to avoid double-firing
    @State private var longPressFired = false

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size == 52 ? 20 : 16, weight: fontWeight))
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(pressedButton == id ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.06))
            )
            .overlay(
                Circle()
                    .stroke(pressedButton == id ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.12), lineWidth: pressedButton == id ? 1.5 : 1)
            )
            .scaleEffect(pressedButton == id ? 0.93 : 1.0)
            .animation(.easeOut(duration: 0.12), value: pressedButton)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if pressedButton != id {
                            pressedButton = id
                            longPressFired = false
                            // Schedule hold command after threshold
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                if pressedButton == id && !longPressFired {
                                    let cmd = remoteCommand(for: id)
                                    bridge.sendHoldCommand(cmd)
                                    longPressFired = true
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        if !longPressFired {
                            // Short press — send tap
                            let cmd = remoteCommand(for: id)
                            bridge.sendCommand(cmd)
                        }
                        if pressedButton == id {
                            pressedButton = nil
                        }
                        longPressFired = false
                    }
            )
    }

    private func remoteCommand(for id: String) -> RemoteCommand {
        switch id {
        case "up": return .up
        case "down": return .down
        case "left": return .left
        case "right": return .right
        case "select": return .select
        default: return .select
        }
    }
}

struct PlaybackButton: View {
    let id: String
    let icon: String
    @Binding var pressedButton: String?
    var bridge: AppleTVBridge
    var size: CGFloat = 40
    var fontSize: CGFloat = 16

    @State private var longPressFired = false

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: fontSize))
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(pressedButton == id ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.06))
            )
            .overlay(
                Circle()
                    .stroke(pressedButton == id ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.12), lineWidth: pressedButton == id ? 1.5 : 1)
            )
            .scaleEffect(pressedButton == id ? 0.93 : 1.0)
            .animation(.easeOut(duration: 0.12), value: pressedButton)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if pressedButton != id {
                            pressedButton = id
                            longPressFired = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                if pressedButton == id && !longPressFired {
                                    bridge.sendHoldCommand(playbackCommand(for: id))
                                    longPressFired = true
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        if !longPressFired {
                            bridge.sendCommand(playbackCommand(for: id))
                        }
                        if pressedButton == id {
                            pressedButton = nil
                        }
                        longPressFired = false
                    }
            )
    }

    private func playbackCommand(for id: String) -> RemoteCommand {
        switch id {
        case "previous": return .previous
        case "next": return .next
        default: return .playPause
        }
    }
}

struct LabeledButton: View {
    let id: String
    let icon: String
    let label: String
    @Binding var pressedButton: String?
    var bridge: AppleTVBridge
    var size: CGFloat = 40
    var fontSize: CGFloat = 16

    @State private var longPressFired = false

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: fontSize))
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(pressedButton == id ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.06))
                )
                .overlay(
                    Circle()
                        .stroke(pressedButton == id ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.12), lineWidth: pressedButton == id ? 1.5 : 1)
                )
                .scaleEffect(pressedButton == id ? 0.93 : 1.0)
                .animation(.easeOut(duration: 0.12), value: pressedButton)
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if pressedButton != id {
                                pressedButton = id
                                longPressFired = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    if pressedButton == id && !longPressFired {
                                        bridge.sendHoldCommand(actionCommand(for: id))
                                        longPressFired = true
                                    }
                                }
                            }
                        }
                        .onEnded { _ in
                            if !longPressFired {
                                bridge.sendCommand(actionCommand(for: id))
                            }
                            if pressedButton == id {
                                pressedButton = nil
                            }
                            longPressFired = false
                        }
                )

            Text(label)
                .font(.system(size: 10)).foregroundColor(.secondary)
        }
    }

    private func actionCommand(for id: String) -> RemoteCommand {
        switch id {
        case "volumeDown": return .volumeDown
        case "volumeUp": return .volumeUp
        case "power": return .power
        case "home": return .home
        case "menu": return .menu
        default: return .menu
        }
    }
}
