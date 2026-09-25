import SwiftUI

struct CompletionView: View {
    let completion: SessionCompletion
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.success)
                    .accessibilityHidden(true)

                Text("Routine Complete")
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.foregroundPrimary)

                Text("\(completion.configuration.numberOfSets) set\(completion.configuration.numberOfSets == 1 ? "" : "s") in \(completion.configuration.formattedTotalDuration).")
                    .font(.body)
                    .foregroundStyle(Color.foregroundSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                Button(action: onDismiss) {
                    Text("Done")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.foregroundPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 26)
                        .background(Color.buttonSurface, in: Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .padding()
        }
    }
}
