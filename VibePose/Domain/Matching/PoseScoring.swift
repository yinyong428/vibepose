import Foundation

struct PoseScore: Hashable {
    let value: Double
    let matchedJoints: Int
    let coverage: Double
}

actor ScoringActor {
    func score(current: CanonicalPose19?, target: PoseTemplate?) -> PoseScore {
        guard let current, let target else {
            return PoseScore(value: 0, matchedJoints: 0, coverage: 0)
        }

        let weights = target.matching.jointWeights
        var weightedDistance = 0.0
        var totalWeight = 0.0
        var matched = 0

        for joint in JointName.allCases {
            guard
                let currentPoint = current.points[joint],
                let targetPoint = target.pose.points[joint]
            else { continue }

            let weight = weights[joint] ?? 1.0
            let dx = currentPoint.x - targetPoint.x
            let dy = currentPoint.y - targetPoint.y
            let distance = sqrt(dx * dx + dy * dy)
            weightedDistance += distance * weight
            totalWeight += weight
            matched += 1
        }

        guard totalWeight > 0 else {
            return PoseScore(value: 0, matchedJoints: 0, coverage: 0)
        }

        let normalizedDistance = min(weightedDistance / totalWeight, 1.0)
        let score = max(0, 1 - normalizedDistance * 1.8)
        let coverage = min(current.coverage, target.pose.coverage)
        return PoseScore(value: score, matchedJoints: matched, coverage: coverage)
    }
}

