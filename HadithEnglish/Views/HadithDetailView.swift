import SwiftUI

struct HadithDetailView: View {
    let subject: HadithSubject
    @EnvironmentObject private var lastRead: LastReadStore

    var body: some View {
        List(subject.hadiths) { entry in
            HadithCardView(entry: entry)
                .listRowBackground(Color("CardBackground"))
        }
        .listStyle(.plain)
        .navigationTitle(subject.trimmedName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { lastRead.recordVisit(to: subject) }
    }
}
