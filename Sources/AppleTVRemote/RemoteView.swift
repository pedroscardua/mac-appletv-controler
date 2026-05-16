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

    // MARK: - Content (Remote or PIN)

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

    private var dpadView: some View {
        VStack(spacing: 2) {
            dpadButton("up", icon: "chevron.up")
            HStack(spacing: 2) {
                dpadButton("left", icon: "chevron.left")
                dpadButton("select", icon: "circle.fill", size: 52, fontWeight: .bold)
                dpadButton("right", icon: "chevron.right")
            }
            dpadButton("down", icon: "chevron.down")
        }
    }

    private func dpadButton(_ id: String, icon: String, size: CGFloat = 44, fontWeight: Font.Weight = .regular) -> some View {
        Button {
            bridge.sendCommand(RemoteCommand(rawValue: id)!)
            flashButton(id)
        } label: {
            Image(systemName: icon)
                .font(.system(size: size == 52 ? 20 : 16, weight: fontWeight))
                .frame(width: size, height: size)
                .background(Circle().fill(
                    pressedButton == id ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.06)
                ))
                .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .scaleEffect(pressedButton == id ? 0.93 : 1.0)
        .animation(.easeOut(duration: 0.12), value: pressedButton)
    }

    // MARK: - Playback

    private var playbackView: some View {
        HStack(spacing: 20) {
            playbackButton("previous", icon: "backward.fill")
            playbackButton("playPause", icon: "playpause.fill", size: 48, fontSize: 22)
            playbackButton("next", icon: "forward.fill")
        }
    }

    private func playbackButton(_ id: String, icon: String, size: CGFloat = 40, fontSize: CGFloat = 16) -> some View {
        Button {
            let cmd: RemoteCommand = switch id {
            case "previous": .previous
            case "next": .next
            default: .playPause
            }
            bridge.sendCommand(cmd)
            flashButton(id)
        } label: {
            Image(systemName: icon)
                .font(.system(size: fontSize))
                .frame(width: size, height: size)
                .background(Circle().fill(
                    pressedButton == id ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.06)
                ))
                .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .scaleEffect(pressedButton == id ? 0.93 : 1.0)
        .animation(.easeOut(duration: 0.12), value: pressedButton)
    }

    // MARK: - Bottom

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                labeledButton("menu", icon: "line.3.horizontal", label: "Menu")
                labeledButton("home", icon: "tv.fill", label: "Home")
            }
            HStack(spacing: 24) {
                labeledButton("volumeDown", icon: "speaker.minus.fill", label: "Vol -", size: 38, fontSize: 14)
                labeledButton("volumeUp", icon: "speaker.plus.fill", label: "Vol +", size: 38, fontSize: 14)
                labeledButton("power", icon: "power", label: "Sleep", size: 38, fontSize: 14)
            }
        }
    }

    private func labeledButton(_ id: String, icon: String, label: String, size: CGFloat = 40, fontSize: CGFloat = 16) -> some View {
        VStack(spacing: 3) {
            Button {
                let cmd: RemoteCommand = switch id {
                case "volumeDown": .volumeDown
                case "volumeUp": .volumeUp
                case "power": .power
                case "home": .home
                case "menu": .menu
                default: .menu
                }
                bridge.sendCommand(cmd)
                flashButton(id)
            } label: {
                Image(systemName: icon)
                    .font(.system(size: fontSize))
                    .frame(width: size, height: size)
                    .background(Circle().fill(
                        pressedButton == id ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.06)
                    ))
                    .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .scaleEffect(pressedButton == id ? 0.93 : 1.0)
            .animation(.easeOut(duration: 0.12), value: pressedButton)

            Text(label)
                .font(.system(size: 10)).foregroundColor(.secondary)
        }
    }

    private func flashButton(_ id: String) {
        pressedButton = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
            if pressedButton == id { pressedButton = nil }
        }
    }
}
