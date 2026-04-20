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
            let sorted = filtered.enumerated()
                .sorted { lhs, rhs in
                    let lhsRank = difficultyRank(lhs.element.difficulty)
                    let rhsRank = difficultyRank(rhs.element.difficulty)
                    if lhsRank != rhsRank {
                        return lhsRank < rhsRank
                    }
                    return lhs.offset < rhs.offset
                }
                .map(\.element)

            return Array(sorted.prefix(limit))
        }

        let scored = filtered.enumerated()
            .map { item in
                let diff = poseDistance(lhs: currentPose, rhs: item.element.pose)
                return (item.offset, item.element, diff)
            }
            .sorted { lhs, rhs in
                if lhs.2 != rhs.2 {
                    return lhs.2 < rhs.2
                }
                return lhs.0 < rhs.0
            }
            .map(\.1)
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

    private func difficultyRank(_ difficulty: PoseDifficulty) -> Int {
        switch difficulty {
        case .easy:
            return 0
        case .medium:
            return 1
        case .hard:
            return 2
        }
    }
}
