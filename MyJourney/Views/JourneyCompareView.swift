import SwiftUI

struct JourneyCompareView: View {
    @StateObject private var viewModel: JourneyCompareViewModel

    init(viewModel: JourneyCompareViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if viewModel.canCompare {
                    compareCanvas
                } else {
                    ContentUnavailableView(
                        "Need Two Entries",
                        systemImage: "square.split.2x1",
                        description: Text("Capture at least two entries to use compare mode.")
                    )
                }

                selectors
            }
            .padding()
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var compareCanvas: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                if let afterImage = viewModel.afterImage {
                    Image(uiImage: afterImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }

                if let beforeImage = viewModel.beforeImage {
                    Image(uiImage: beforeImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .mask(alignment: .leading) {
                            Rectangle()
                                .frame(width: geometry.size.width * viewModel.sliderPosition)
                        }
                }

                Rectangle()
                    .fill(Color.white)
                    .frame(width: 3)
                    .position(
                        x: max(0, min(geometry.size.width, geometry.size.width * viewModel.sliderPosition)),
                        y: geometry.size.height / 2
                    )

                VStack {
                    Spacer()

                    Slider(value: $viewModel.sliderPosition, in: 0...1)
                        .tint(.white)
                        .accessibilityLabel("Comparison position")
                        .accessibilityValue(viewModel.sliderPosition.formatted(.percent.precision(.fractionLength(0))))
                        .padding()
                        .background(.black.opacity(0.45), in: Capsule())
                        .padding()
                }

                if viewModel.showsFreeWatermark {
                    FreeWatermarkView()
                        .frame(maxWidth: geometry.size.width * 0.9)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.58)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .frame(height: 420)
    }

    private var selectors: some View {
        VStack(spacing: 16) {
            comparePicker(
                title: "Before",
                selection: viewModel.beforeEntryID,
                action: viewModel.setBeforeEntry
            )

            comparePicker(
                title: "After",
                selection: viewModel.afterEntryID,
                action: viewModel.setAfterEntry
            )
        }
    }

    private func comparePicker(
        title: String,
        selection: UUID?,
        action: @escaping (UUID) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Menu {
                ForEach(viewModel.entryOptions) { option in
                    Button {
                        action(option.id)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(option.title)
                            Text(option.subtitle)
                        }
                    }
                }
            } label: {
                HStack {
                    if let selection, let option = viewModel.entryOptions.first(where: { $0.id == selection }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.title)
                            Text(option.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Choose an entry")
                    }

                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title) entry")
            .accessibilityValue(
                selection.flatMap { selectedID in
                    viewModel.entryOptions.first(where: { $0.id == selectedID })?.title
                } ?? "Not selected"
            )
        }
    }
}
