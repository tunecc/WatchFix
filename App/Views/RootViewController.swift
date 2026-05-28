import Combine
import UIKit

private struct MenuItem {
    let title: String
    let symbolName: String
    let tintColor: UIColor
}

private enum Screen: Int, CaseIterable {
    case compatibility
    case features
    case restart
    case logs
    case debug
    case about

    var item: MenuItem {
        switch self {
        case .compatibility:
            return MenuItem(
                title: L("landing.compatibility.title"),
                symbolName: "checkmark.shield.fill",
                tintColor: .systemGreen
            )
        case .features:
            return MenuItem(
                title: L("landing.features.title"),
                symbolName: "puzzlepiece.extension.fill",
                tintColor: .systemIndigo
            )
        case .restart:
            return MenuItem(
                title: L("landing.restart.title"),
                symbolName: "arrow.clockwise.circle.fill",
                tintColor: .systemOrange
            )
        case .logs:
            return MenuItem(
                title: L("landing.logs.title"),
                symbolName: "doc.text.magnifyingglass",
                tintColor: .systemTeal
            )
        case .debug:
            return MenuItem(
                title: L("landing.debug.title"),
                symbolName: "ladybug.fill",
                tintColor: .systemPink
            )
        case .about:
            return MenuItem(
                title: L("landing.about.title"),
                symbolName: "info.circle.fill",
                tintColor: .systemBlue
            )
        }
    }
}

final class RootViewController: UITableViewController {
    private let store: Store
    private var cancellables = Set<AnyCancellable>()

    init(store: Store) {
        self.store = store
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyLocalizedContent()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MenuCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 76
        tableView.separatorStyle = .none
        bindStore()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyLocalizedContent()
        tableView.reloadData()
    }

    private func applyLocalizedContent() {
        title = L("landing.title")
    }

    private func bindStore() {
        store.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyLocalizedContent()
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        Screen.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 0 ? 10 : 6
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0.01
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        menuCell(for: indexPath)
    }

    private func menuCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)
        let screen = Screen(rawValue: indexPath.section) ?? .compatibility
        let item = screen.item

        var content = UIListContentConfiguration.subtitleCell()
        content.text = item.title
        content.secondaryText = menuDetail(for: screen)
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 12)
        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        content.secondaryTextProperties.font = .preferredFont(forTextStyle: .subheadline)
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.numberOfLines = 0
        content.image = WFMakeIconTileImage(symbolName: item.symbolName, tintColor: item.tintColor)
        content.imageProperties.reservedLayoutSize = CGSize(width: 40, height: 40)
        cell.contentConfiguration = content
        var background = UIBackgroundConfiguration.listGroupedCell()
        background.cornerRadius = WFCardCornerRadius
        cell.backgroundConfiguration = background
        let selectedView = UIView()
        selectedView.backgroundColor = .tertiarySystemGroupedBackground
        selectedView.layer.cornerRadius = WFCardCornerRadius
        selectedView.layer.cornerCurve = .continuous
        selectedView.clipsToBounds = true
        cell.selectedBackgroundView = selectedView
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let screen = Screen(rawValue: indexPath.section) ?? .compatibility
        let controller: UIViewController
        switch screen {
        case .compatibility:
            controller = CompatibilityViewController(store: store)
        case .features:
            controller = FeatureViewController(store: store)
        case .restart:
            controller = RestartViewController(store: store)
        case .logs:
            controller = LogsViewController(store: store)
        case .debug:
            controller = DebugViewController(store: store)
        case .about:
            controller = AboutViewController(store: store)
        }

        navigationController?.pushViewController(controller, animated: true)
    }

    private func menuDetail(for screen: Screen) -> String {
        switch screen {
        case .compatibility:
            return compatibilityDetail()
        case .features:
            return L("landing.features.detail")
        case .restart:
            return L("landing.restart.detail")
        case .logs:
            return logsDetail()
        case .debug:
            return debugDetail()
        case .about:
            return aboutDetail()
        }
    }

    private func aboutDetail() -> String {
        L("landing.about.detail")
    }

    private func debugDetail() -> String {
        L("landing.debug.detail")
    }

    private func compatibilityDetail() -> String {
        if let report = store.currentReport, report.hasActiveWatch {
            if let watchOSVersion = report.watchOSVersion {
                return LF("landing.compatibility.status.watchVersion", report.watchName, watchOSVersion)
            }
            return LF("landing.compatibility.status.watch", report.watchName)
        }

        if store.isRefreshingCompatibility {
            return L("landing.compatibility.status.loading")
        }

        return L("landing.compatibility.status.empty")
    }

    private func logsDetail() -> String {
        if store.isLoadingLogs {
            return L("landing.logs.status.loading")
        }

        return store.isPluginLoggingEnabled
            ? L("landing.logs.status.enabled")
            : L("landing.logs.status.disabled")
    }
}
