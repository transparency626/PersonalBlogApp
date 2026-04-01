import SwiftUI

struct ProfileStatCard: View {
    let stat: ProfileStat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stat.value)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text(stat.label)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 8)
    }
}
