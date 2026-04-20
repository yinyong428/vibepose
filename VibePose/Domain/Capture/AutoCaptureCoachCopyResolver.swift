import Foundation

enum AutoCaptureCoachCopyResolver {
    static func resolve(_ state: AutoCaptureState) -> String {
        switch state {
        case .idle:
            return "coach.idle"
        case .noPerson:
            return "coach.no_person"
        case .multiPersonUnsupported:
            return "coach.multi_person_unsupported"
        case .aligning:
            return "coach.aligning"
        case .ready:
            return "coach.ready"
        case .perfect:
            return "coach.perfect"
        case .countdown(let seconds):
            return "coach.countdown_\(seconds)"
        }
    }
}
