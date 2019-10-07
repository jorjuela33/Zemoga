//
//  DataSource.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import UIKit

typealias BacthUpdateCallback = (() -> Void)
let collectionElementKindPlaceholder = "CollectionElementKindPlaceholder"

func abstractMethod() -> Never {
    fatalError("Abstract method")
}

enum DataSourceSectionDirection {
    case none
    case left
    case right
}

protocol DataSourceContent {
    var actionCallback: PlaceHolderActionCallback? { get }
    var actionTitle: String? { get }
    var image: UIImage? { get }
    var message: String { get }
    var title: String { get }
}

struct NoContent: DataSourceContent {
    var actionCallback: PlaceHolderActionCallback?
    let actionTitle: String?
    let image: UIImage?
    let title: String
    let message: String

    // MARK: Initializers

    init(title: String, message: String, image: UIImage? = nil, actionTitle: String? = nil, actionCallback: PlaceHolderActionCallback? = nil) {
        self.actionTitle = actionTitle
        self.actionCallback = actionCallback
        self.image = image
        self.message = message
        self.title = title
    }
}

class DataSource: NSObject, ContentLoading, UICollectionViewDataSource {
    private var headers: [SupplementaryViewMetrics] = []
    private var headersByKeys: [String: SupplementaryViewMetrics] = [:]
    private var loadingInstance: Loading?
    private var loadingStateMachine: LoadingStateMachine?
    private var observers: [NSValue: Observer] = [:]
    private var pendingUpdateCallback: BacthUpdateCallback?
    private var placeholderView: CollectionPlaceholderReusableView?
    private var sectionMetrics: [Int: SectionMetrics] = [:]

    @objc private dynamic var isLoadingComplete = false

    var loadingError: Error?
    var loadingState: ContentLoadingState {
        get {
            return loadingStateMachine?.currentState ?? .initial
        }

        set {
            guard loadingStateMachine?.currentState != newValue else { return }

            loadingStateMachine?.setState(newValue)
        }
    }

    var errorContent: DataSourceContent?
    var noContent: DataSourceContent?

    /// the default metrics for this datasource
    var defaultMetrics = SectionMetrics()

    /// a delegate object that will receive change notifications from this data source.
    weak var delegate: DatasourceDelegate?

    /// the title of this data source. This value is used to populate section headers and the segmented control tab.
    var title: String?

    // MARK: ContentLoading

    func collectionViewCanEditItem(at indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionViewCanMoveItem(from: IndexPath, to indexPath: IndexPath) -> Bool {
        return false
    }

    @objc
    func loadContent() {
        abstractMethod()
    }

    func loadContentWithCallback(_ callback: LoadingCallback) {
        beginLoading()
        let loading = Loading { [weak self] state, error, updateCallback in
            guard state != .ignored else { return }

            self?.endLoadingStateWithState(state, error: error, callback: { [weak self] in
                guard let `self` = self else { return }

                updateCallback?(self)
            })
        }

        loadingInstance?.isCurrent = false
        loadingInstance = loading
        callback(loading)
    }

    func resetContent() {
        loadingStateMachine = nil
        loadingInstance?.isCurrent = false
    }

    // MARK: Instance methods

    /// returns the global index path to an index path relative to the target data source
    func localIndexPathForGlobalIndexPath(_ indexPath: IndexPath) -> IndexPath? {
        return indexPath
    }

    /// measure variable height cells. Variable height cells are not supported when there is more than one column.
    func collectionView(_ collectionView: UICollectionView, sizeFittingSize size: CGSize, forItemAt indexPath: IndexPath) -> CGSize {
        abstractMethod()
    }

    /// find the data source for the given section. Default implementation returns self.
    func dataSourceForSectionAt(_ sectionIndex: Int) -> DataSource {
        return self
    }

    /// returns the placeholder view to be used.
    func dequeuePlaceholderViewForCollectionView(
        _ collectionView: UICollectionView,
        at indexPath: IndexPath
        ) -> CollectionPlaceholderReusableView {

        if placeholderView == nil {
            placeholderView = collectionView.dequeueReusableSupplementaryView(
                ofKind: collectionElementKindPlaceholder,
                withReuseIdentifier: String(describing: CollectionPlaceholderReusableView.self),
                for: indexPath
                ) as? CollectionPlaceholderReusableView
        }

        guard let placeholderView = placeholderView else {
            fatalError("Not healthy")
        }

        updatePlaceholder(placeholderView, notifyVisibility: false)
        return placeholderView
    }

    /// executes the pending updates in the datasource
    func executePendingUpdates() {
        pendingUpdateCallback?()
        pendingUpdateCallback = nil
    }

    /// look up a header by its key
    func header(forKey key: String) -> SupplementaryViewMetrics? {
        return headersByKeys[key]
    }

    /// find the index paths of the specified item in the data source. An item may appear more than once in a given data source.
    func indexPaths<T>(for item: T) -> [IndexPath] {
        abstractMethod()
    }

    /// find the item at the specified index path.
    func item<T>(at indexPath: IndexPath) -> T? {
        abstractMethod()
    }

    /// returns the metrics for the given section if exists.
    func metricsForSection(_ section: Int) -> SectionMetrics? {
        return sectionMetrics[section]
    }

    /// creates a new header and append it to the collection of headers
    func newHeader(forKey key: String, supplementaryViewClass: AnyClass) -> SupplementaryViewMetrics {
        assert(headersByKeys[key] == nil, "Attempting to add a header for a key that already exists \(key)")

        let supplementaryViewMetrics = SupplementaryViewMetrics(supplementaryViewClass: supplementaryViewClass)
        headers.append(supplementaryViewMetrics)
        headersByKeys[key] = supplementaryViewMetrics
        return supplementaryViewMetrics
    }

    /// create a new header for a specific section.
    func newHeaderForSection(_ index: Int, supplementaryViewClass: AnyClass) -> SupplementaryViewMetrics {
        if let metrics = sectionMetrics[index] {
            return metrics.newHeader(ofClass: supplementaryViewClass)
        }

        let metrics = snapshotMetrics(for: index)
        sectionMetrics[index] = metrics
        return metrics.newHeader(ofClass: supplementaryViewClass)
    }

    /// the number of sections in this data source.
    func numberOfSections() -> Int {
        return 1
    }

    /// if this data source is "hidden" by a placeholder.
    func obscuredByPlaceholder() -> Bool {
        if shouldDisplayPlaceholder() {
            return true
        }

        guard let delegate = delegate as? DataSource else {
            return false
        }

        return delegate.obscuredByPlaceholder()
    }

    /// remove a header specified by its key
    func removeHeader(forKey key: String) {
        headersByKeys.removeValue(forKey: key)
    }

    func removeItem(at indexPath: IndexPath) {
        abstractMethod()
    }

    /// sets a custom metrics for the given section.
    func setMetrics(_ metrics: SectionMetrics, forSection section: Int) {
        sectionMetrics[section] = metrics
    }

    /// signal that the datasource SHOULD reload its content
    func setNeedsLoadContent() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(loadContent), object: nil)
        perform(#selector(loadContent), with: nil, afterDelay: 0)
    }

    /// true if the placeholder should be displayed
    func shouldDisplayPlaceholder() -> Bool {
        let loadingState = self.loadingState

        // If we're in the error state & have an error content
        if errorContent != nil && loadingState == .error {
            return true
        }

        // Only display a placeholder when we're loading or have no content
        if noContent != nil && (loadingState == .loadingContent || loadingState == .noContent) {
            return true
        }

        return false
    }

    /// returns the default layout metrics for the sections in the collection view
    func snapshotMetrics() -> [Int: SectionMetrics] {
        let numberOfSections = self.numberOfSections()
        var metrics: [Int: SectionMetrics] = [:]
        metrics[SectionMetrics.globalSection] = snapshotMetrics(for: SectionMetrics.globalSection)
        for index in 0..<numberOfSections {
            metrics[index] = snapshotMetrics(for: index)
        }

        return metrics
    }

    /// returns the layout metrics for the given section
    func snapshotMetrics(for section: Int) -> SectionMetrics {
        let metrics = defaultMetrics.copy()
        if let existingMetrics = sectionMetrics[section] {
            metrics.applyValues(from: existingMetrics)
        }

        if isRootDataSource() && section == SectionMetrics.globalSection {
            metrics.headers = headers
        }

        if section == 0 {
            var headers: [SupplementaryViewMetrics] = []
            if !isRootDataSource() {
                headers.append(contentsOf: self.headers)
            }

            metrics.hasPlaceholder = shouldDisplayPlaceholder()

            if !metrics.headers.isEmpty {
                headers.append(contentsOf: metrics.headers)
            }

            metrics.headers = headers
        }

        return metrics
    }

    func updatePlaceholder(_ placeholderView: CollectionPlaceholderReusableView?, notifyVisibility: Bool) {
        var notifyVisibility = notifyVisibility

        if
            /// placeholder
            let placeholderView = placeholderView,

            /// current loading state
            let currentState = loadingStateMachine?.currentState {

            if currentState == .loadingContent {
                placeholderView.showActivityIndicator(true)
            } else {
                placeholderView.showActivityIndicator(false)
            }

            let showPlaceholderView: (DataSourceContent) -> Bool = { content in
                return placeholderView.showPlaceholderWithTitle(
                    content.title,
                    message: content.message,
                    image: content.image,
                    actionTitle: content.actionTitle,
                    actionCallback: content.actionCallback
                )
            }

            if let errorContent = self.errorContent, currentState == .error {
                notifyVisibility = notifyVisibility && showPlaceholderView(errorContent)
            } else if let noContent = self.noContent, currentState == .noContent {
                notifyVisibility = notifyVisibility && showPlaceholderView(noContent)
            } else {
                placeholderView.hidePlaceholder(animated: true)
            }
        }

        if notifyVisibility && (errorContent != nil || noContent != nil) {
            notifyDidReloadData()
        }
    }

    /// use this method to wait for content to load. The block will be called once the loadingState has
    /// transitioned to the ContentLoaded, NoContent, or Error states.
    func whenLoaded(_ callback: @escaping () -> Void) {
        var completed: Int32 = 0
        let observer = Observer(object: self, keyPath: "isLoadingComplete", options: [.initial, .new]) { [weak self] _, change, token in
            guard let isLoadingComplete = change?[.newKey] as? Bool, isLoadingComplete else {
                return
            }

            let observer = self?.observers.removeValue(forKey: token)
            observer?.invalidate()
            if OSAtomicCompareAndSwap32(0, 1, &completed) {
                callback()
            }
        }

        observer.startObserving()
        observers[observer.token] = observer
    }

    // MARK: Notification methods

    // notifies collection view of changes to the dataSource.
    func notifyBatchUpdate(_ callback: BacthUpdateCallback?, completionCallback: BacthUpdateCallback? = nil) {
        if let processed = delegate?.dataSource(self, performBachUpdate: callback, completionCallback: completionCallback), !processed {
            callback?()
            completionCallback?()
        }
    }

    func notifyDidReloadData() {
        delegate?.dataSourceDidReloadData(self)
    }

    func notifyItemsInserted(at indexPaths: [IndexPath]) {
        if shouldDisplayPlaceholder() {
            enqueuePendingUpdates { [weak self] in
                self?.notifyItemsInserted(at: indexPaths)
            }
        }

        delegate?.dataSource(self, didInsertItemsAtIndexPaths: indexPaths)
    }

    func notifyItemMoved(from indexPath: IndexPath, to newIndexPath: IndexPath) {
        if shouldDisplayPlaceholder() {
            enqueuePendingUpdates { [weak self] in
                self?.notifyItemMoved(from: indexPath, to: newIndexPath)
            }
        }

        delegate?.dataSource(self, didMoveItemAtIndexPath: indexPath, toIndexPath: newIndexPath)
    }

    func notifyItemsRefreshed(at indexPaths: [IndexPath]) {
        if shouldDisplayPlaceholder() {
            enqueuePendingUpdates { [weak self] in
                self?.notifyItemsRefreshed(at: indexPaths)
            }
        }

        delegate?.dataSource(self, didRefreshItemsAtIndexPaths: indexPaths)
    }

    func notifyItemsRemoved(at indexPaths: [IndexPath]) {
        if shouldDisplayPlaceholder() {
            enqueuePendingUpdates { [weak self] in
                self?.notifyItemsRemoved(at: indexPaths)
            }
        }

        delegate?.dataSource(self, didRemoveItemsAtIndexPaths: indexPaths)
    }

    func notifySectionsInserted(_ sections: IndexSet, direction: DataSourceSectionDirection = .none) {
        delegate?.dataSource(self, didInsertSections: sections, direction: direction)
    }

    func notifySectionsRefreshed(_ sections: IndexSet) {
        delegate?.dataSource(self, didRefreshSections: sections)
    }

    func notifySectionsRemoved(_ sections: IndexSet, direction: DataSourceSectionDirection = .none) {
        delegate?.dataSource(self, didRemoveSections: sections, direction: direction)
    }

    func notifyWillLoadContent() {
        delegate?.dataSourceWillLoadContent(self)
    }

    func notifyContentLoadedWithError(_ error: Error?) {
        delegate?.dataSource(self, didLoadContentWithError: error)
    }

    func registerReusableViewsWithCollectionView(_ collectionView: UICollectionView) {
        let numberOfSections = self.numberOfSections()
        let globalMetrics = snapshotMetrics(for: SectionMetrics.globalSection)
        for headerMetrics in globalMetrics.headers {
            collectionView.register(
                headerMetrics.supplementaryViewClass,
                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: headerMetrics.reuseIdentifier
            )
        }

        for sectionIndex in 0..<numberOfSections {
            let metrics = snapshotMetrics(for: sectionIndex)
            for headerMetrics in metrics.headers {
                collectionView.register(
                    headerMetrics.supplementaryViewClass,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: headerMetrics.reuseIdentifier
                )
            }

            for footerMetrics in metrics.footers {
                collectionView.register(
                    footerMetrics.supplementaryViewClass,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                    withReuseIdentifier: footerMetrics.reuseIdentifier
                )
            }
        }

        collectionView.register(
            CollectionPlaceholderReusableView.self,
            forSupplementaryViewOfKind: collectionElementKindPlaceholder,
            withReuseIdentifier: String(describing: CollectionPlaceholderReusableView.self)
        )
    }

    // MARK: Private methods

    private func beginLoading() {
        if loadingStateMachine == nil {
            loadingStateMachine = LoadingStateMachine()
            loadingStateMachine?.delegate = self
        }

        guard let currentState = loadingStateMachine?.currentState else { return }

        let containsCurrentState = [ContentLoadingState.initial, .loadingContent].contains(currentState)
        let loadingSate = containsCurrentState ? ContentLoadingState.loadingContent : .refreshingContent
        isLoadingComplete = false
        setLoadingState(loadingSate)
        notifyWillLoadContent()
    }

    private func endLoadingStateWithState(_ state: ContentLoadingState, error: Error?, callback: BacthUpdateCallback?) {
        loadingError = error
        loadingState = state

        if let callback = callback, shouldDisplayPlaceholder() {
            enqueuePendingUpdates(callback)
        } else {
            notifyBatchUpdate({ [weak self] in
                self?.pendingUpdateCallback?()
                callback?()
            })
        }

        isLoadingComplete = true
        notifyContentLoadedWithError(error)
    }

    private func enqueuePendingUpdates(_ callback: @escaping BacthUpdateCallback) {
        guard let pendingUpdateCallback = pendingUpdateCallback else {
            self.pendingUpdateCallback = callback
            return
        }

        self.pendingUpdateCallback = {
            pendingUpdateCallback()
            callback()
        }
    }

    private func isRootDataSource() -> Bool {
        return !(delegate is DataSource)
    }

    private func setLoadingState(_ loadingState: ContentLoadingState) {
        guard let currentState = loadingStateMachine?.currentState, currentState != loadingState else { return }

        loadingStateMachine?.setState(loadingState)
    }

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return numberOfSections()
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        abstractMethod()
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        abstractMethod()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
        ) -> UICollectionReusableView {

        if kind == collectionElementKindPlaceholder {
            return dequeuePlaceholderViewForCollectionView(collectionView, at: indexPath)
        }

        var section = 0
        var item = 0
        var datasource: DataSource?

        if let newIndexPath = indexPath.firstIndex(of: 0), indexPath.count == 1 {
            datasource = self
            item = newIndexPath
            section = SectionMetrics.globalSection
        } else {
            item = indexPath.item
            section = indexPath.section
            datasource = dataSourceForSectionAt(section)
        }

        let sectionMetrics = snapshotMetrics(for: section)
        var supplementaryViewMetrics: SupplementaryViewMetrics?

        if kind == UICollectionView.elementKindSectionHeader {
            supplementaryViewMetrics = item < sectionMetrics.headers.count ? sectionMetrics.headers[item] : nil
        } else if kind == UICollectionView.elementKindSectionFooter {
            supplementaryViewMetrics = item < sectionMetrics.footers.count ? sectionMetrics.footers[item] : nil
        }

        if
            /// datasource
            let datasource = datasource,

            /// local indexPath
            let localIndexPath = localIndexPathForGlobalIndexPath(indexPath),

            /// supplemnetary view
            let supplementaryViewMetrics = supplementaryViewMetrics {

            let reusableView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: supplementaryViewMetrics.reuseIdentifier,
                for: indexPath
            )

            supplementaryViewMetrics.configurationCallback?(reusableView, datasource, localIndexPath)
            return reusableView
        }

        fatalError("not healthy")
    }
}

extension DataSource: LoadingStateMachineDelegate {

    // MARK: LoadingStateMachineDelegate

    func loadingStateMachine(_ loadingStateMachine: LoadingStateMachine, didEnterInState state: ContentLoadingState) {
        guard [ContentLoadingState.error, .contentLoaded, .loadingContent, .noContent].contains(state) else { return }

        updatePlaceholder(placeholderView, notifyVisibility: true)
    }

    func loadingStateMachine(_ loadingStateMachine: LoadingStateMachine, didExitFromState state: ContentLoadingState) {}
}
