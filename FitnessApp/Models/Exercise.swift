import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var primaryMuscleRaw: String
    var secondaryMuscles: [String]
    var equipmentRaw: String
    var instructions: String
    var iconName: String

    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscle: MuscleGroup,
        secondaryMuscles: [MuscleGroup] = [],
        equipment: EquipmentType,
        instructions: String,
        iconName: String = "dumbbell.fill"
    ) {
        self.id = id
        self.name = name
        self.primaryMuscleRaw = primaryMuscle.rawValue
        self.secondaryMuscles = secondaryMuscles.map(\.rawValue)
        self.equipmentRaw = equipment.rawValue
        self.instructions = instructions
        self.iconName = iconName
    }

    var primaryMuscle: MuscleGroup {
        MuscleGroup(rawValue: primaryMuscleRaw) ?? .chest
    }

    var equipment: EquipmentType {
        EquipmentType(rawValue: equipmentRaw) ?? .bodyweight
    }
}
