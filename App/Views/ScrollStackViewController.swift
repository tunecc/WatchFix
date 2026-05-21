import Combine
import UIKit

class WFScrollStackViewController: UIViewController {
    let store: Store
    let scrollView = UIScrollView()
    let contentStack = UIStackView()

    fileprivate var cancellables = Set<AnyCancellable>()
    private var renderScheduled = false

    init(store: Store, title: String) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        bindStore()
        applyLocalizedTitleIfNeeded()
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyLocalizedTitleIfNeeded()
        render()
    }

    func bindStore() {
        store.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.scheduleRender()
            }
            .store(in: &cancellables)
    }

    func localizedNavigationTitle() -> String? { nil }

    func render() {}

    func resetContent() {
        for arrangedSubview in contentStack.arrangedSubviews {
            contentStack.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    private func scheduleRender() {
        guard isViewLoaded, !renderScheduled else {
            return
        }

        renderScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            self.renderScheduled = false
            self.applyLocalizedTitleIfNeeded()
            self.render()
        }
    }

    private func applyLocalizedTitleIfNeeded() {
        guard let localizedTitle = localizedNavigationTitle() else {
            return
        }
        title = localizedTitle
    }
}
