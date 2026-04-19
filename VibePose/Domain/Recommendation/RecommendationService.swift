import Foundation

struct RecommendationService {
    func recommend(
        currentPose: CanonicalPose19?,
        selectedTemplate: PoseTemplate?,
        templates: [PoseTemplate],
        limit: Int = 3
    ) -> [PoseTemplate] {
        guard !templates.isEmpty else { return [] }

        let filtered = templates.filter { $0.status == .released && $0.subjectCount == 1 }
        guard let currentPose else {
            return Array(filtered.sorted { $0.difficulty == .easy && $1.difficulty != .easy }.prefix(limit))
        }

        let scored = filtered.map { template in
            let diff = poseDistance(lhs: currentPose, rhs: template.pose)
            return (template, diff)
        }
        .sorted { $0.1 < $1.1 }
        .map(\.0)
        .filter { $0.id != selectedTemplate?.id }

        return Array(scored.prefix(limit))
    }

    private func poseDistance(lhs: CanonicalPose19, rhs: CanonicalPose19) -> Double {
        var distance = 0.0
        var count = 0.0

        for joint in JointName.allCases {
            guard let a = lhs.points[joint], let b = rhs.points[joint] else { continue }
            let dx = a.x - b.x
            let dy = a.y - b.y
            distance += sqrt(dx * dx + dy * dy)
            count += 1
        }

        return count == 0 ? 1 : distance / count
    }
}

