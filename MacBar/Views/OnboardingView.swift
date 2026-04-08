import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    @State private var hasAccessibility = false
    @State private var hasMicrophone = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "macwindow.on.rectangle")
                .font(.system(size: 36))
                .foregroundStyle(.blue)

            Text("Welcome to MacBar")
                .font(.headline)

            Text("MacBar needs a few permissions to work its best.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()

            // Accessibility
            permissionRow(
                icon: "hand.raised.fill",
                title: "Accessibility",
                description: "Required for keyboard shortcuts, lockdown mode, and voice commands",
                granted: hasAccessibility
            ) {
                requestAccessibility()
            }

            // Microphone
            permissionRow(
                icon: "mic.fill",
                title: "Microphone",
                description: "Required for Voice Mode speech recognition",
                granted: hasMicrophone
            ) {
                Task {
                    await requestMicrophone()
                }
            }

            Divider()

            HStack {
                Button("Skip") {
                    appState.completeOnboarding()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)

                Spacer()

                Button("Continue") {
                    appState.completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(20)
        .frame(width: 340)
        .onAppear {
            refreshPermissions()
        }
    }

    private func permissionRow(
        icon: String,
        title: String,
        description: String,
        granted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(granted ? .green : .orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 14))
            } else {
                Button("Grant") {
                    action()
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        // Re-check after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            refreshPermissions()
        }
    }

    private func requestMicrophone() async {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        await MainActor.run {
            hasMicrophone = granted
        }
    }

    private func refreshPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false] as CFDictionary
        hasAccessibility = AXIsProcessTrustedWithOptions(options)
        hasMicrophone = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
}

import AVFoundation
