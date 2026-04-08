import Foundation

enum VoicePipelineState: Equatable {
    case idle
    case listening
    case transcribing
    case processing
    case executing
    case error(String)

    var isActive: Bool {
        if case .idle = self {
            return false
        }
        return true
    }
}
