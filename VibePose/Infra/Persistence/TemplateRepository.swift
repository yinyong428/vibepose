import Foundation

struct TemplateRepository {
    func loadStarterPack() throws -> [PoseTemplate] {
        guard let url = Bundle.main.url(
            forResource: AppConfig.starterPackFileName,
            withExtension: AppConfig.starterPackFileExtension
        ) else {
            return []
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([PoseTemplate].self, from: data)
    }
}

