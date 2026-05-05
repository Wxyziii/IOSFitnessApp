import Foundation
import SwiftData

enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case chest = "Chest"
    case upperBack = "Upper Back"
    case lats = "Lats"
    case traps = "Traps"
    case frontDelts = "Front Delts"
    case sideDelts = "Side Delts"
    case rearDelts = "Rear Delts"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case abs = "Abs"
    case obliques = "Obliques"
    case glutes = "Glutes"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case calves = "Calves"
    case cardio = "Cardio"

    var id: String { rawValue }

    static let visibleFilters: [MuscleGroup] = [.chest, .upperBack, .quads, .frontDelts, .biceps, .abs, .cardio]
    static let chartGroups: [MuscleGroup] = [.chest, .upperBack, .lats, .quads, .hamstrings, .frontDelts, .sideDelts, .biceps, .triceps, .abs]

    var legacyBucket: String {
        switch self {
        case .upperBack, .lats, .traps: "Back"
        case .frontDelts, .sideDelts, .rearDelts: "Shoulders"
        case .biceps, .triceps, .forearms: "Arms"
        case .glutes, .quads, .hamstrings, .calves: "Legs"
        default: rawValue
        }
    }

    var mapColorName: String {
        rawValue
    }
}

enum MuscleMapSide: String, CaseIterable, Identifiable {
    case front = "Front"
    case back = "Back"

    var id: String { rawValue }
}

struct MuscleMapRegion: Identifiable, Hashable {
    let id: String
    let muscleGroup: MuscleGroup
    let side: MuscleMapSide
    let displayName: String
    let svgRegionID: String
    let assetRegionName: String
}

enum MuscleMapRegionCatalog {
    static let primaryActivation = 1.0
    static let secondaryActivation = 0.35

    static let regions: [MuscleMapRegion] = [
        r("front_chest_left", .chest, .front), r("front_chest_right", .chest, .front), r("front_upper_chest_left", .chest, .front), r("front_upper_chest_right", .chest, .front),
        r("back_upper_back_left", .upperBack, .back), r("back_upper_back_right", .upperBack, .back), r("back_rhomboids_left", .upperBack, .back), r("back_rhomboids_left-1", .upperBack, .back),
        r("back_lats", .lats, .back), r("back_trap_left", .traps, .back), r("back_trap_right", .traps, .back),
        r("front_shoulder_left", .frontDelts, .front), r("front_shoulder_right", .frontDelts, .front), r("back_shoulder_right", .rearDelts, .back), r("back_shoulder_right-1", .rearDelts, .back),
        r("front_biceps_left", .biceps, .front), r("front_biceps_right", .biceps, .front), r("back_triceps_left", .triceps, .back), r("back_triceps_right", .triceps, .back), r("back_triceps_left-1", .triceps, .back), r("back_triceps_right-1", .triceps, .back),
        r("front_forearm_inner_left", .forearms, .front), r("front_forearm_inner_right", .forearms, .front), r("front_forearm_outer_left", .forearms, .front), r("front_forearm_outer_right", .forearms, .front), r("back_forearm_inner_left", .forearms, .back), r("back_forearm_inner_left-1", .forearms, .back), r("back_forearm_outer_left", .forearms, .back), r("back_forearm_outer_right", .forearms, .back),
        r("front_abs_row1_left", .abs, .front), r("front_abs_row1_right", .abs, .front), r("front_abs_row2_left", .abs, .front), r("front_abs_row2_right", .abs, .front), r("front_abs_row3_left", .abs, .front), r("front_abs_row3_right", .abs, .front), r("front_abs_row4_left", .abs, .front), r("front_abs_row4_right", .abs, .front),
        r("front_oblique_left", .obliques, .front), r("front_oblique_right", .obliques, .front), r("front_serratus_left1", .obliques, .front), r("front_serratus_left2", .obliques, .front), r("front_serratus_left3", .obliques, .front), r("front_serratus_right1", .obliques, .front), r("front_serratus_right2", .obliques, .front), r("front_serratus_right3", .obliques, .front),
        r("back_glutes_left", .glutes, .back), r("back_glutes_right", .glutes, .back),
        r("front_quad_left", .quads, .front), r("front_quad_right", .quads, .front), r("front_quad_left-1", .quads, .front), r("front_quad_right-1", .quads, .front), r("front_adductor_left", .quads, .front), r("front_adductor_right", .quads, .front), r("front_hip_flexor_left", .quads, .front), r("front_hip_flexor_right", .quads, .front), r("front_knee_left", .quads, .front), r("front_knee_right", .quads, .front),
        r("back_hamstring_left", .hamstrings, .back), r("back_hamstring_right", .hamstrings, .back), r("back_hamstring_inner_left", .hamstrings, .back), r("back_hamstring_inner_right", .hamstrings, .back), r("back_hamstring_outer_left", .hamstrings, .back), r("back_hamstring_outer_right", .hamstrings, .back),
        r("front_calf_inner_left", .calves, .front), r("front_calf_inner_right", .calves, .front), r("front_calf_outer_left", .calves, .front), r("front_calf_outer_right", .calves, .front), r("back_calf_inner_left", .calves, .back), r("back_calf_inner_right", .calves, .back), r("back_calf_outer_left", .calves, .back), r("back_calf_outer_right", .calves, .back), r("back_achilles_left", .calves, .back), r("back_achilles_right", .calves, .back)
    ]

    static let muscleByRegionID = Dictionary(uniqueKeysWithValues: regions.map { ($0.svgRegionID, $0.muscleGroup) })

    static func regions(for side: MuscleMapSide) -> [MuscleMapRegion] {
        regions.filter { $0.side == side }
    }

    private static func r(_ asset: String, _ muscle: MuscleGroup, _ side: MuscleMapSide) -> MuscleMapRegion {
        MuscleMapRegion(id: asset, muscleGroup: muscle, side: side, displayName: muscle.rawValue, svgRegionID: asset, assetRegionName: asset)
    }
}

enum EquipmentType: String, CaseIterable, Codable, Identifiable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case cable = "Cable"
    case machine = "Machine"
    case bodyweight = "Bodyweight"

    var id: String { rawValue }
}

enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        Exercise.self,
        WorkoutPlan.self,
        WorkoutPlanExercise.self,
        WorkoutSession.self,
        ExerciseSet.self,
        Achievement.self
    ]

    static let schema = Schema(models)
}
