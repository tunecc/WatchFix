import UIKit

final class FeatureViewController: WFScrollStackViewController {
    init(store: Store) {
        super.init(store: store, title: L("landing.features.title"))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func localizedNavigationTitle() -> String? {
        L("landing.features.title")
    }

    override func render() {
        resetContent()

        let installedPlugins = store.plugins
            .filter { $0.available && !$0.isTool }
            .sorted { lhs, rhs in
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        let unavailablePlugins = store.plugins
            .filter { !$0.available && !$0.isTool && $0.canInstall }
            .sorted { lhs, rhs in
                lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        let unsupportedPlugins = store.plugins
            .filter { !$0.available && !$0.canInstall }
            .sorted { lhs, rhs in
                lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        let toolPlugins = store.plugins
            .filter { $0.isTool && ($0.available || $0.canInstall) }
            .sorted { lhs, rhs in
                if lhs.available != rhs.available {
                    return lhs.available && !rhs.available
                }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        let knownFixCount = installedPlugins.count + unavailablePlugins.count + unsupportedPlugins.filter { !$0.isTool }.count
        let installedPluginIDs = installedPlugins.map(\.id)
        let installablePluginIDs = unavailablePlugins.map(\.id)
        let installedToolIDs = toolPlugins.filter(\.available).map(\.id)
        let installableToolIDs = toolPlugins.filter { !$0.available && $0.canInstall }.map(\.id)
        let isDeletingInstalledPlugins = installedPluginIDs.contains { store.isPluginBusy($0) }
        let isInstallingUnavailablePlugins = installablePluginIDs.contains { store.isPluginBusy($0) }
        let isInstallingTools = installableToolIDs.contains { store.isPluginBusy($0) }
        let isDeletingTools = installedToolIDs.contains { store.isPluginBusy($0) }

        var installedContents: [UIView] = [
            WFMakeCompactInfoRow(
                text: unavailablePlugins.isEmpty
                    ? LF("features.plugins.summary", installedPlugins.count, knownFixCount)
                    : [
                        LF("features.plugins.summary", installedPlugins.count, knownFixCount),
                        LF("features.plugins.unavailable.summary", unavailablePlugins.count),
                    ].joined(separator: " "),
                symbolName: "checkmark.circle"
            ),
        ]

        if !installedPluginIDs.isEmpty {
            installedContents.append(
                WFMakeActionRowCard([
                    WFMakeActionButton(
                        title: L("common.deleteAll"),
                        systemImage: "trash",
                        isPrimary: false,
                        isLoading: isDeletingInstalledPlugins,
                        isEnabled: !installedPluginIDs.isEmpty,
                        buttonSize: .medium,
                        tintColor: .systemRed
                    ) { [weak self] in
                        self?.store.removePlugins(identifiers: installedPluginIDs)
                    },
                ])
            )
        }

        if installedPlugins.isEmpty {
            installedContents.append(WFMakeInfoCard(text: L("features.plugins.empty")))
        }

        installedContents.append(contentsOf: installedPlugins.map { plugin in
            makePluginCard(for: plugin)
        })

        contentStack.addArrangedSubview(
            WFMakeSection(
                title: L("features.plugins.installed.title"),
                footer: L("features.plugins.footer"),
                contents: installedContents
            )
        )

        if !unavailablePlugins.isEmpty {
            var unavailableContents: [UIView] = [
                WFMakeCompactInfoRow(
                    text: LF("features.plugins.unavailable.summary", unavailablePlugins.count),
                    symbolName: "tray.and.arrow.down",
                    tintColor: .systemOrange
                ),
                WFMakeActionRowCard([
                    WFMakeActionButton(
                        title: L("common.installAll"),
                        systemImage: "square.and.arrow.down",
                        isLoading: isInstallingUnavailablePlugins,
                        isEnabled: !installablePluginIDs.isEmpty,
                        buttonSize: .medium
                    ) { [weak self] in
                        self?.store.installPlugins(identifiers: installablePluginIDs)
                    },
                ]),
            ]

            unavailableContents.append(contentsOf: unavailablePlugins.map { plugin in
                makePluginCard(for: plugin)
            })

            contentStack.addArrangedSubview(
                WFMakeSection(
                    title: L("features.plugins.unavailable.title"),
                    footer: L("features.plugins.unavailable.footer"),
                    contents: unavailableContents
                )
            )
        }

        if !toolPlugins.isEmpty {
            var toolContents: [UIView] = []
            var toolActionButtons: [UIButton] = []
            if !installableToolIDs.isEmpty {
                toolActionButtons.append(
                    WFMakeActionButton(
                        title: L("common.installAll"),
                        systemImage: "square.and.arrow.down",
                        isLoading: isInstallingTools,
                        isEnabled: !installableToolIDs.isEmpty,
                        buttonSize: .medium
                    ) { [weak self] in
                        self?.store.installPlugins(identifiers: installableToolIDs)
                    }
                )
            }
            if !installedToolIDs.isEmpty {
                toolActionButtons.append(
                    WFMakeActionButton(
                        title: L("common.deleteAll"),
                        systemImage: "trash",
                        isPrimary: false,
                        isLoading: isDeletingTools,
                        isEnabled: !installedToolIDs.isEmpty,
                        buttonSize: .medium,
                        tintColor: .systemRed
                    ) { [weak self] in
                        self?.store.removePlugins(identifiers: installedToolIDs)
                    }
                )
            }
            if !toolActionButtons.isEmpty {
                toolContents.append(WFMakeActionRowCard(toolActionButtons))
            }

            toolContents.append(contentsOf: toolPlugins.map { plugin in
                makePluginCard(for: plugin)
            })

            contentStack.addArrangedSubview(
                WFMakeSection(
                    title: L("features.tools.title"),
                    footer: L("features.tools.footer"),
                    contents: toolContents
                )
            )
        }

        if !unsupportedPlugins.isEmpty {
            var unsupportedContents: [UIView] = [
                WFMakeCompactInfoRow(
                    text: LF("features.plugins.unsupported.summary", unsupportedPlugins.count),
                    symbolName: "exclamationmark.triangle",
                    tintColor: .systemRed
                ),
            ]

            unsupportedContents.append(contentsOf: unsupportedPlugins.map { plugin in
                makePluginCard(
                    for: plugin,
                    actionTitle: L("features.plugins.unsupported.action"),
                    systemImage: "nosign",
                    isPrimary: false,
                    tintColor: .systemGray,
                    isActionEnabled: false
                )
            })

            contentStack.addArrangedSubview(
                WFMakeSection(
                    title: L("features.plugins.unsupported.title"),
                    footer: L("features.plugins.unsupported.footer"),
                    contents: unsupportedContents
                )
            )
        }
    }

    private func makePluginCard(
        for plugin: PluginState,
        actionTitle: String? = nil,
        systemImage: String? = nil,
        isPrimary: Bool? = nil,
        tintColor: UIColor? = nil,
        isActionEnabled: Bool? = nil
    ) -> UIView {
        return WFMakePluginCard(
            plugin: plugin,
            isBusy: store.isPluginBusy(plugin.id),
            actionTitle: actionTitle,
            systemImage: systemImage,
            isPrimary: isPrimary,
            tintColor: tintColor,
            isActionEnabled: isActionEnabled,
            configurationTitle: L("features.plugins.details"),
            configurationSystemImage: "info.circle",
            isConfigurationEnabled: !store.isPluginBusy(plugin.id),
            onConfiguration: { [weak self] in
                self?.openPluginConfiguration(for: plugin)
            }
        ) { [weak self] in
            self?.performPluginAction(for: plugin)
        }
    }

    private func performPluginAction(for plugin: PluginState) {
        if plugin.available {
            store.removePlugin(identifier: plugin.id)
        } else {
            store.installPlugin(identifier: plugin.id)
        }
    }

    private func openPluginConfiguration(for plugin: PluginState) {
        if let controller = try? WFPluginBridge.configurationViewController(forPluginNamed: plugin.id) {
            if controller.title?.isEmpty ?? true {
                controller.title = plugin.title
            }
            navigationController?.pushViewController(controller, animated: true)
            return
        }

        navigationController?.pushViewController(
            PluginConfigurationViewController(store: store, plugin: plugin),
            animated: true
        )
    }
}
