import UIKit

/// Postcard-style share backgrounds - procedurally generated abstract/
/// geometric art (gradients, girih-style tessellations, crescent & star,
/// rosette, mosque silhouette), not photography, so there's no licensing
/// question about depicting a real place. Image assets live in
/// HadithEnglish/ShareBackgrounds/.
enum ShareCardBackground: String, CaseIterable, Identifiable {
    case emerald = "share_bg_01_emerald"
    case navyGold = "share_bg_02_navy_gold"
    case charcoalCrescent = "share_bg_03_charcoal_crescent"
    case sandDome = "share_bg_04_sand_dome"
    case roseRosette = "share_bg_05_rose_rosette"
    case tealCrescent = "share_bg_06_teal_crescent"
    case burgundyGeometric = "share_bg_07_burgundy_geometric"
    case sageDome = "share_bg_08_sage_dome"
    case plumGeometric = "share_bg_09_plum_geometric"
    case goldRosette = "share_bg_10_gold_rosette"

    var id: String { rawValue }
    var imageName: String { rawValue }

    /// These PNGs are loose bundle resources (a Resources build phase copy,
    /// not an Asset Catalog imageset), so SwiftUI's `Image(_ name:)` /
    /// `UIImage(named:)` won't reliably find them - same situation as the
    /// hadith .zlib data files elsewhere in this project. Resolve via the
    /// bundle URL instead, same pattern as HadithContentStore.
    var uiImage: UIImage? {
        guard let url = Bundle.main.url(forResource: imageName, withExtension: "png") else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}
