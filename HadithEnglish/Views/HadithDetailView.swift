import SwiftUI

struct HadithDetailView: View {
    let subject: HadithSubject

    var body: some View {
        List(subject.hadiths) { entry in
            HadithCardView(entry: entry)
        }
        .listStyle(.plain)
        .navigationTitle(subject.trimmedName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
