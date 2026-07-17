import SwiftUI

enum PlantIcon: String, CaseIterable, Codable {
    case flower = "ph-flower"
    case leaf = "ph-leaf"
    case plant = "ph-plant"
    case pottedPlant = "ph-potted-plant"
    case cactus = "ph-cactus"
    case flowerTulip = "ph-flower-tulip"
    case flowerLotus = "ph-flower-lotus"
    case grains = "ph-grains"
    case clover = "ph-clover"
    case treePalm = "ph-tree-palm"
    case tree = "ph-tree"
    case treeEvergreen = "ph-tree-evergreen"
    case acorn = "ph-acorn"
    case cherries = "ph-cherries"
    case carrot = "ph-carrot"
    case pepper = "ph-pepper"

    var image: Image {
        Image(rawValue).renderingMode(.template)
    }

    static func `default`(forSpecies species: String) -> PlantIcon {
        let lowerSpecies = species.lowercased()

        if lowerSpecies.contains("cact") || lowerSpecies.contains("euphorb") {
            return .cactus
        }
        if lowerSpecies.contains("citrus") || lowerSpecies.contains("lemon") || lowerSpecies.contains("lime") || lowerSpecies.contains("cherry") {
            return .cherries
        }
        if lowerSpecies.contains("palm") {
            return .treePalm
        }
        if lowerSpecies.contains("fern") {
            return .leaf
        }
        if lowerSpecies.contains("orchid") || lowerSpecies.contains("lotus") {
            return .flowerLotus
        }
        if lowerSpecies.contains("tulip") {
            return .flowerTulip
        }
        if lowerSpecies.contains("violet") || lowerSpecies.contains("cyclamen") || lowerSpecies.contains("begonia") {
            return .flower
        }
        if lowerSpecies.contains("pine") || lowerSpecies.contains("conifer") {
            return .treeEvergreen
        }
        if lowerSpecies.contains("ficus") || lowerSpecies.contains("tree") {
            return .tree
        }
        if lowerSpecies.contains("herb") || lowerSpecies.contains("basil") || lowerSpecies.contains("mint") {
            return .grains
        }
        if lowerSpecies.contains("carrot") {
            return .carrot
        }
        if lowerSpecies.contains("pepper") || lowerSpecies.contains("chili") {
            return .pepper
        }
        if lowerSpecies.contains("clover") || lowerSpecies.contains("oxalis") {
            return .clover
        }
        if lowerSpecies.contains("succulent") || lowerSpecies.contains("echeveria") || lowerSpecies.contains("crassula") || lowerSpecies.contains("aloe") || lowerSpecies.contains("haworthia") {
            return .pottedPlant
        }

        return .plant
    }
}

enum ChromeIcon: String, CaseIterable {
    case seedling = "fa-seedling"
    case gear = "fa-gear"
    case bell = "fa-bell"
    case bellSlash = "fa-bell-slash"
    case droplet = "fa-droplet"
    case plus = "fa-plus"
    case listCheck = "fa-list-check"
    case chevronLeft = "fa-chevron-left"
    case chevronRight = "fa-chevron-right"
    case pencil = "fa-pencil"
    case trash = "fa-trash"
    case house = "fa-house"
    case couch = "fa-couch"
    case bed = "fa-bed"
    case bath = "fa-bath"
    case sun = "fa-sun"
    case arrowTrendUp = "fa-arrow-trend-up"
    case magnifyingGlass = "fa-magnifying-glass"
    case circlePlus = "fa-circle-plus"
    case shuffle = "fa-shuffle"
    case camera = "fa-camera"
    case circleCheck = "fa-circle-check"
    case check = "fa-check"
    case arrowRight = "fa-arrow-right"
    case lock = "fa-lock"
    case arrowsRotate = "fa-arrows-rotate"
    case arrowUpFromBracket = "fa-arrow-up-from-bracket"
    case copy = "fa-copy"
    case fileLines = "fa-file-lines"
    case circleInfo = "fa-circle-info"
    case xmark = "fa-xmark"
    case utensils = "fa-utensils"
    case mugSaucer = "fa-mug-saucer"

    var image: Image {
        Image(rawValue).renderingMode(.template)
    }
}
