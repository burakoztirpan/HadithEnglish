import SwiftUI

struct SubjectsListView: View {
    let subjects: [HadithSubject]
    @EnvironmentObject private var languageStore: LanguageStore
    @State private var searchText = ""

    private var filteredSubjects: [HadithSubject] {
        guard !searchText.isEmpty else { return subjects }
        return subjects.filter {
            $0.trimmedName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            List(filteredSubjects) { subject in
                NavigationLink(destination: HadithDetailView(subject: subject)) {
                    HStack(spacing: 10) {
                        Image(systemName: subject.icon)
                            .foregroundColor(Color("AccentColor"))
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(subject.trimmedName)
                                .font(.body)
                            Text(verbatim: "\(subject.hadiths.count) \(languageStore.strings.hadithsSuffix)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground").ignoresSafeArea())
            .navigationTitle(languageStore.strings.hadithSubjectsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: languageStore.strings.searchSubjectsPrompt)
        }
        .navigationViewStyle(.stack)
    }
}
