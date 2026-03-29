import Foundation

final class StoreBackedQualityPreferenceRepository: QualityPreferenceRepository {
    var globalPreferredQuality: String? {
        get { SeriesPickerStore.shared.globalPreferredQuality }
        set { SeriesPickerStore.shared.globalPreferredQuality = newValue }
    }
}
