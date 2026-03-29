import Foundation

protocol QualityPreferenceRepository: AnyObject {
    var globalPreferredQuality: String? { get set }
}
