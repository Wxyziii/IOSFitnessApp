import SwiftData
import SwiftUI

struct WorkoutsView: View {
    @Query(sort: \WorkoutPlan.createdAt) private var plans: [WorkoutPlan]
    @State private var activeCreateSheet: CreateSheet?
    @State private var draftWorkoutName = ""
    @State private var builderWorkoutName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    suggested
                    myWorkouts
                    historyLink
                }
                .padding()
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        startCreateWorkout()
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                    }
                    .accessibilityLabel("Create workout")
                }
            }
            .sheet(item: $activeCreateSheet) { sheet in
                switch sheet {
                case .namePrompt:
                    WorkoutNamePromptView(name: $draftWorkoutName) {
                        builderWorkoutName = draftWorkoutName.trimmingCharacters(in: .whitespacesAndNewlines)
                        activeCreateSheet = .builder
                    }
                case .builder:
                    WorkoutBuilderView(initialName: builderWorkoutName)
                }
            }
            .appScreen()
        }
    }

    private var suggested: some View {
        SectionCard("Suggested Workouts") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                ForEach(plans.prefix(2)) { plan in
                    NavigationLink {
                        WorkoutPlanDetailView(plan: plan)
                    } label: {
                        WorkoutCard(plan: plan)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var myWorkouts: some View {
        SectionCard("My Workouts") {
            VStack(spacing: 12) {
                Button {
                    startCreateWorkout()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "plus")
                            .font(.title2.weight(.bold))
                            .frame(width: 54, height: 54)
                            .background(AppTheme.card, in: Circle())
                        VStack(alignment: .leading) {
                            Text("Create New Workout").font(.headline)
                            Text("Build your own workout").font(.subheadline).foregroundStyle(AppTheme.muted)
                        }
                        Spacer()
                    }
                    .padding()
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.cardStroke, style: StrokeStyle(lineWidth: 1, dash: [5]))
                    }
                }
                .buttonStyle(.plain)

                ForEach(plans) { plan in
                    NavigationLink {
                        WorkoutPlanDetailView(plan: plan)
                    } label: {
                        WorkoutPlanRow(plan: plan, accessoryText: nil)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var historyLink: some View {
        NavigationLink {
            WorkoutHistoryView()
        } label: {
            HStack {
                Label("Workout History", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.muted)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private func startCreateWorkout() {
        draftWorkoutName = ""
        builderWorkoutName = ""
        activeCreateSheet = .namePrompt
    }
}

private enum CreateSheet: Identifiable {
    case namePrompt
    case builder

    var id: String {
        switch self {
        case .namePrompt: "namePrompt"
        case .builder: "builder"
        }
    }
}

private struct WorkoutNamePromptView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    let onContinue: () -> Void

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Name your workout before adding exercises.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)

                TextField("Workout name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.continue)
                    .onSubmit {
                        if !trimmedName.isEmpty {
                            onContinue()
                        }
                    }

                PrimaryButton(title: "Continue") {
                    onContinue()
                }
                .disabled(trimmedName.isEmpty)
                .opacity(trimmedName.isEmpty ? 0.45 : 1)

                Spacer()
            }
            .padding()
            .navigationTitle("Create Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .appScreen()
        }
        .presentationDetents([.medium])
    }
}
