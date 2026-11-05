//
//  PhotosView.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import SwiftUI
import PhotosUI

struct PhotosView: View {
    @EnvironmentObject var vm: OnboardingViewModel
    @State private var showPicker = false
    @State private var selectedSlot = 0
    @State private var pickerItem: PhotosPickerItem?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add your photos")
                .font(.largeTitle.bold())
            Text("Add at least \(OnboardingViewModel.minPhotos). Gym shots and lifting pics work great. (\(vm.uploadedPhotoCount) added)")
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<6, id: \.self) { slot in
                    PhotoSlotView(
                        preview: vm.photoPreviews[slot],
                        url: vm.photoURLs[slot],
                        isUploading: vm.uploadingSlots.contains(slot),
                        onTap: {
                            guard vm.photoURLs[slot] == nil, vm.photoPreviews[slot] == nil else { return }
                            selectedSlot = slot
                            showPicker = true
                        },
                        onRemove: { vm.removePhoto(slot: slot) }
                    )
                }
            }

            if let error = vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }

            Spacer()

            PrimaryButton(title: vm.primaryTitle,
                          isLoading: vm.isLoading,
                          isEnabled: vm.canContinueFromPhotos) {
                Task { await vm.next() }
            }
        }
        .padding(24)
        .photosPicker(isPresented: $showPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            let slot = selectedSlot
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await vm.addPhoto(image, slot: slot)
                }
                pickerItem = nil
            }
        }
    }
}

struct PhotoSlotView: View {
    let preview: UIImage?
    let url: String?
    let isUploading: Bool
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        Color.clear
            .aspectRatio(3 / 4, contentMode: .fit)
            .background(Color.primary.opacity(0.06))
            .overlay {
                if let preview {
                    Image(uiImage: preview).resizable().scaledToFill()
                } else if let url, let remote = URL(string: url) {
                    AsyncImage(url: remote) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Image(systemName: "plus").font(.title2).foregroundStyle(.secondary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                if isUploading {
                    ZStack {
                        Color.black.opacity(0.4)
                        ProgressView().tint(.white)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .overlay(alignment: .topTrailing) {
                if (preview != nil || url != nil) && !isUploading {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white, .black.opacity(0.6))
                    }
                    .padding(6)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
    }
}
