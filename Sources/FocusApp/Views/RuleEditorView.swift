import FamilyControls
import SwiftUI

/// Formulier voor het maken of wijzigen van een limiet of schema.
struct RuleEditorView: View {
    @EnvironmentObject private var manager: ScreenTimeManager
    @Environment(\.dismiss) private var dismiss

    @State private var rule: FocusRule
    @State private var showPicker = false

    init(rule: FocusRule) {
        _rule = State(initialValue: rule)
    }

    private var isValid: Bool {
        guard rule.hasSelection, !rule.name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        if rule.kind == .schedule { return !rule.weekdays.isEmpty }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Naam") {
                    TextField("Bijvoorbeeld: Social media", text: $rule.name)
                }

                if rule.kind == .schedule {
                    Section {
                        TextField("Bijv. weekplanning maken", text: $rule.task)
                    } header: {
                        Text("Taak (optioneel)")
                    } footer: {
                        Text("Een vaste studietijd start vanzelf, ook als FocusBlok dicht is. Na afloop krijg je je beloning zodra je de app opent.")
                    }
                }

                Section {
                    Button {
                        showPicker = true
                    } label: {
                        Label("Apps en websites kiezen", systemImage: "apps.iphone")
                    }
                    Text(rule.selectionSummary).foregroundStyle(.secondary)
                    ForEach(Array(rule.selection.applicationTokens), id: \.self) { token in
                        Label(token)
                    }
                } header: {
                    Text("Apps")
                } footer: {
                    if !manager.isAuthorized {
                        Text("Geef eerst Schermtijd-toestemming, anders blijft de appkiezer leeg.")
                    }
                }

                switch rule.kind {
                case .dailyLimit:
                    Section("Dagelijkse limiet") {
                        Stepper(value: $rule.dailyLimitMinutes, in: 5...240, step: 5) {
                            Text("\(rule.dailyLimitMinutes) minuten per dag")
                        }
                    }
                case .schedule:
                    Section("Tijdvak") {
                        DatePicker("Van", selection: timeBinding(hour: $rule.startHour, minute: $rule.startMinute),
                                   displayedComponents: .hourAndMinute)
                        DatePicker("Tot", selection: timeBinding(hour: $rule.endHour, minute: $rule.endMinute),
                                   displayedComponents: .hourAndMinute)
                        if rule.crossesMidnight {
                            Text("Loopt door tot de volgende dag.").font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    Section("Dagen") {
                        WeekdayPicker(selection: $rule.weekdays)
                    }
                }

                Section {
                    Toggle("Regel actief", isOn: $rule.isEnabled)
                }
            }
            .navigationTitle(rule.kind == .dailyLimit ? "Limiet" : "Vaste studietijd")
            .navigationBarTitleDisplayMode(.inline)
            .familyActivityPicker(isPresented: $showPicker, selection: $rule.selection)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") {
                        manager.save(rule)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private func timeBinding(hour: Binding<Int>, minute: Binding<Int>) -> Binding<Date> {
        Binding<Date>(
            get: {
                Calendar.current.date(from: DateComponents(hour: hour.wrappedValue, minute: minute.wrappedValue)) ?? Date()
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                hour.wrappedValue = parts.hour ?? 0
                minute.wrappedValue = parts.minute ?? 0
            }
        )
    }
}

private struct WeekdayPicker: View {
    @Binding var selection: Set<Int>

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Weekday.ordered) { day in
                let isOn = selection.contains(day.rawValue)
                Button {
                    if isOn { selection.remove(day.rawValue) } else { selection.insert(day.rawValue) }
                } label: {
                    Text(day.shortName)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(isOn ? Color.accentColor : Color.secondary.opacity(0.15),
                                    in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(isOn ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
