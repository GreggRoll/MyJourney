import SwiftUI

struct PrivacyAboutView: View {
    var body: some View {
        List {
            Section("Privacy") {
                Text("My Journey stores your journeys and photos locally and does not upload them to My Journey servers.")
                Text("The app does not require an account and does not include advertising or third-party analytics.")
                Text("Exports are created on your device and shared only when you choose where to send them.")
            }

            Section("About") {
                LabeledContent("App", value: "My Journey")
                LabeledContent("Version", value: "1.1")
                LabeledContent("Focus", value: "Private progress photo journeys")
            }

            Section("What You Can Do") {
                Text("Capture consistent photos, compare two entries, create GIF or MP4 timelines, and schedule optional photo reminders.")
            }
        }
        .navigationTitle("Privacy & About")
    }
}
