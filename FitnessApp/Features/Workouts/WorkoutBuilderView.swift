import SwiftData
import SwiftUI

struct WorkoutBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var name = ""
    @State private var query = ""
    @State private var selectedMuscle: MuscleGroup?
    @State private var selectedEquipment: EquipmentType?
    @State private var selectedItems: [BuilderItem] = []

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesQuery = query.isEmpty || exercise.name.localizedCaseInsensitiveContains(query)
            let matchesMuscle = selectedMuscle == nil || exercise.primaryMuscle == selectedMuscle
            let matchesEquipment = selectedEquipment == nil || exercise.equipment == selectedEquipment
            return matchesQuery && matchesMuscle && matchesEquipment
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    TextField("Workout name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.words)

                    filterSection
                    exerciseList
                    selectedSummary
                    PrimaryButton(title: "Save workout plan", action: save)
                        .disabled(selectedItems.isEmpty || name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(selectedItems.isEmpty || name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.45 : 1)
                }
                .padding()
            }
            .navigationTitle("Create Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .appScreen()
        }
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Search exercises...", text: $query)
                .textFieldStyle(.roundedBorder)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    FilterChip(title: "All", isSelected: selectedMuscle == nil) { selectedMuscle = nil }
                    ForEach(MuscleGroup.visibleFilters) { group in
                        FilterChip(title: group.rawValue, isSelected: selectedMuscle == group) { selectedMuscle = group }
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    FilterChip(title: "Any Equipment", isSelected: selectedEquipment == nil) { selectedEquipment = nil }
                    ForEach(EquipmentType.allCases) { equipment in
                        FilterChip(title: equipment.rawValue, isSelected: selectedEquipment == equipment) { selectedEquipment = equipment }
                    }
                }
            }
        }
    }

    private var exerciseList: some View {
        SectionCard("Exercises") {
            VStack(spacing: 10) {
                ForEach(filteredExercises.prefix(12)) { exercise in
                    ExercisePickerRow(exercise: exercise) {
                        selectedItems.append(BuilderItem(exercise: exercise))
                    }
                }
            }
        }
    }

    private var selectedSummary: some View {
        SectionCard("Selected Exercises") {
            if selectedItems.isEmpty {
                Text("Add exercises to configure sets, reps, and rest.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            } else {
                VStack(spacing: 12) {
                    ForEach($selectedItems) { $item in
                        SelectedExerciseRow(item: $item)
                    }
                }
            }
        }
    }

    private func save() {
        let plan = WorkoutPlan(
            name: name.trimmingCharacters(in: .whitespaces),
            subtitle: selectedItems.map { $0.exercise.primaryMuscle.rawValue }.uniqued().joined(separator: " • "),
            iconName: "dumbbell.fill",
            colorToken: "green"
        )
        plan.exercises = selectedItems.enumerated().map { index, item in
            WorkoutPlanExercise(exercise: item.exercise, sets: item.sets, repsText: item.repsText, restSeconds: item.restSeconds, orderIndex: index)
        }
        modelContext.insert(plan)
        try? modelContext.save()
        dismiss()
    }
}

struct BuilderItem: Identifiable {
    let id = UUID()
    let exercise: Exercise
    var sets = 3
    var repsText = "8-12"
    var restSeconds = 90
}

private struct ExercisePickerRow: View {
    let exercise: Exercise
    let add: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            IconTile(iconName: exercise.iconName, color: AppTheme.green)
            VStack(alignment: .leading, spacing: 5) {
                Text(exercise.name).font(.headline)
                Text("\(exercise.primaryMuscle.rawValue) • \(exercise.equipment.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
                HStack {
                    MuscleTag(title: exercise.primaryMuscle.rawValue)
                    ForEach(exercise.secondaryMuscles.prefix(2), id: \.self) { MuscleTag(title: $0) }
                }
            }
            Spacer()
            Button(action: add) {
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundStyle(AppTheme.green)
            }
            .accessibilityLabel("Add \(exercise.name)")
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct SelectedExerciseRow: View {
    @Binding var item: BuilderItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.exercise.name).font(.headline)
            HStack {
                Stepper("Sets \(item.sets)", value: $item.sets, in: 1...8)
                Spacer()
            }
            TextField("Reps", text: $item.repsText)
                .textFieldStyle(.roundedBorder)
            Stepper("Rest \(item.restSeconds) sec", value: $item.restSeconds, in: 30...240, step: 15)
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
