import Foundation

struct PluginTechnicalReference: Hashable {
    let title: String
    let identifier: String
}

struct PluginHelpContent: Hashable {
    let summary: String
    let examples: [String]
    let requirements: [String]
    let bundleTargets: [PluginTechnicalReference]
    let executableTargets: [PluginTechnicalReference]

    var hasTechnicalDetails: Bool {
        !requirements.isEmpty || !bundleTargets.isEmpty || !executableTargets.isEmpty
    }
}

private enum PluginTechnicalReferenceKind: String {
    case bundle
    case executable
}

enum PluginHelpCatalog {
    static func tagline(for identifier: String) -> String? {
        localizedString(for: identifier, suffix: "tagline")
    }

    static func content(for metadata: PluginMetadata) -> PluginHelpContent? {
        guard let summary = localizedString(for: metadata.identifier, suffix: "summary") else {
            return nil
        }

        let examples = (1...3).compactMap { localizedString(for: metadata.identifier, suffix: "example.\($0)") }
        return PluginHelpContent(
            summary: summary,
            examples: examples,
            requirements: requirementNotes(for: metadata),
            bundleTargets: technicalReferences(
                from: metadata.injectionTargets.bundles,
                kind: .bundle
            ),
            executableTargets: technicalReferences(
                from: metadata.injectionTargets.executables,
                kind: .executable
            )
        )
    }

    private static func localizedString(for identifier: String, suffix: String) -> String? {
        let key = "plugin.help.\(identifier).\(suffix)"
        let localized = L(key)
        return localized == key ? nil : localized
    }

    private static func requirementNotes(for metadata: PluginMetadata) -> [String] {
        var notes: [String] = []
        if metadata.minimumSystemVersion > 0 {
            notes.append(LF("plugin.help.requirement.ios.minimum", formattedVersion(metadata.minimumSystemVersion)))
        }
        if metadata.maximumSystemVersion > 0 {
            notes.append(LF("plugin.help.requirement.ios.maximum", formattedVersion(metadata.maximumSystemVersion)))
        }
        if metadata.minimumWatchOSVersion > 0 {
            notes.append(LF("plugin.help.requirement.watch.minimum", formattedVersion(metadata.minimumWatchOSVersion)))
        }
        if !metadata.osRestrictions.isEmpty {
            notes.append(L("plugin.help.requirement.osRestrictions"))
        }
        if !metadata.nanoCapabilities.isEmpty {
            notes.append(L("plugin.help.requirement.capability"))
        }
        return notes
    }

    private static func technicalReferences(
        from identifiers: [String],
        kind: PluginTechnicalReferenceKind
    ) -> [PluginTechnicalReference] {
        identifiers.map { identifier in
            PluginTechnicalReference(
                title: localizedTechnicalTitle(for: identifier, kind: kind),
                identifier: identifier
            )
        }
    }

    private static func localizedTechnicalTitle(
        for identifier: String,
        kind: PluginTechnicalReferenceKind
    ) -> String {
        let key = "plugin.tech.\(kind.rawValue).\(identifier)"
        let localized = L(key)
        return localized == key ? identifier : localized
    }

    private static func formattedVersion(_ encodedVersion: Int) -> String {
        let major = (encodedVersion >> 16) & 0xFF
        let minor = (encodedVersion >> 8) & 0xFF
        let patch = encodedVersion & 0xFF
        if patch > 0 {
            return "\(major).\(minor).\(patch)"
        }
        return "\(major).\(minor)"
    }
}
