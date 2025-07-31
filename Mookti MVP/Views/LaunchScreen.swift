import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {

            VStack {
                Spacer()


                VStack(alignment: .leading, spacing: 4) {
                    Text("mookti")
                        .font(.largeTitle).bold()
                        .frame(maxWidth: .infinity,
                               alignment: .leading)

                    Text("education for the future")
                        .font(.headline)
                        .frame(maxWidth: .infinity,
                               alignment: .leading)

                    Text("alpha 0.0")
                        .font(.caption)
                        .frame(maxWidth: .infinity,
                               alignment: .trailing)
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 96)            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
