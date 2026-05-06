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
    @State private var lastAddedExerciseName: String?

    init(initialName: String = "") {
        _name = State(initialValue: initialName)
    }

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
                    nameSection
                    filterSection
                    selectedSummary
                    exerciseList
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

    private var nameSection: some View {
        SectionCard("Workout Name") {
            TextField("Workout name", text: $name)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
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
                if let lastAddedExerciseName {
                    Label("Added \(lastAddedExerciseName)", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Added \(lastAddedExerciseName)")
                }

                ForEach(filteredExercises.prefix(12)) { exercise in
                    ExercisePickerRow(
                        exercise: exercise,
                        isSelected: selectedItems.contains { $0.exercise.id == exercise.id }
                    ) {
                        add(exercise)
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
                        SelectedExerciseRow(item: $item) {
                            selectedItems.removeAll { $0.id == item.id }
                        }
                    }
                }
            }
        }
    }

    private func add(_ exercise: Exercise) {
        guard !selectedItems.contains(where: { $0.exercise.id == exercise.id }) else {
            lastAddedExerciseName = "\(exercise.name) already selected"
            return
        }
        withAnimation(.snappy) {
            selectedItems.append(BuilderItem(exercise: exercise))
            lastAddedExerciseName = exercise.name
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
    let isSelected: Bool
    let add: () -> Void

    var body: some View {
        Button(action: add) {
            HStack(spacing: 12) {
                IconTile(iconName: exercise.iconName, color: isSelected ? AppTheme.muted : AppTheme.green)
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
                Label(isSelected ? "Added" : "Add", systemImage: isSelected ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? AppTheme.muted : AppTheme.green)
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSelected ? "\(exercise.name) already added" : "Add \(exercise.name)")
    }
}

private struct SelectedExerciseRow: View {
    @Binding var item: BuilderItem
    let remove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(item.exercise.name).font(.headline)
                Spacer()
                Button(role: .destructive, action: remove) {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Remove \(item.exercise.name)")
            }
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
