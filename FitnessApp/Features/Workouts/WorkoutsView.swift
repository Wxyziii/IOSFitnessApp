import SwiftData
import SwiftUI

struct WorkoutsView: View {
    @Query(sort: \WorkoutPlan.createdAt) private var plans: [WorkoutPlan]
    @State private var showingBuilder = false

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
                        showingBuilder = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                    }
                    .accessibilityLabel("Create workout")
                }
            }
            .sheet(isPresented: $showingBuilder) {
                WorkoutBuilderView()
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
                    showingBuilder = true
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
}
