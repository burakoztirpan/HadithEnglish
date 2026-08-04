import SwiftUI

struct SubjectsListView: View {
    let subjects: [HadithSubject]
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
                    Text(subject.trimmedName)
                        .font(.body)
                        .padding(.vertical, 6)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Hadith Subjects")
            .searchable(text: $searchText, prompt: "Search subjects")
        }
        .navigationViewStyle(.stack)
    }
}
