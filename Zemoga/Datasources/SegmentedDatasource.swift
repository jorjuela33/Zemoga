//
//  SegmentedDatasource.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/6/19.
//

import UIKit

class SegmentedDatasource: DataSource {
    private let segmentedDataSourceHeaderKey = "segmentedDataSourceHeaderKey"

    /// The collection of data sources contained within this segmented data source.
    private(set) var datasources: [DataSource] = []

    /// The index of the selected data source in the collection.
    var selectedIndex: Int {
        return datasources.firstIndex(of: selectedDatasource) ?? NSNotFound
    }

    /// A reference to the selected data source.
    private(set) var selectedDatasource: DataSource!

    /// Should the data source display a default header that allows switching between the data sources.
    /// Set to NO if switching is accomplished through some other means. Default value is YES.
    var shouldDisplayDefaultHeader = true

    // MARK: Initializers

    init(datasources: [DataSource]) {
        selectedDatasource = datasources.first
        super.init()
        datasources.forEach(addDatasource)
    }

    // MARK: Actions

    @IBAction private func selectedSegmentIndexChanged(_ sender: UISegmentedControl) {
        let datasource = datasources[sender.selectedSegmentIndex]
        setSelectedDataSource(datasource)
    }

    // MARK: Instance methods

    /// Add a data source to the end of the collection.
    func addDatasource(_ datasource: DataSource) {
        if datasources.isEmpty {
            selectedDatasource = datasource
        }
        datasource.delegate = self
        datasources.append(datasource)
    }

    /// Clear the collection of data sources.
    func removeAllDatasources() {
        for datasource in datasources where datasource.delegate === self {
            datasource.delegate = nil
        }
        datasources.removeAll()
    }

    /// Remove the data source from the collection.
    func removeDatasource(_ datasource: DataSource) {
        datasources.removeAll(where: { $0 === datasource })
        if datasource.delegate === self {
            datasource.delegate = nil
        }
    }

    /// Set the selected data source.
    func setSelectedDataSource(_ datasource: DataSource) {
        guard selectedDatasource !== datasource else { return }

        willChangeValue(forKey: "selectedDataSource")
        willChangeValue(forKey: "selectedDataSourceIndex")
        assert(datasources.contains(datasource), "selected data source must be contained in this data source")

        let numberOfOldSections = selectedDatasource.numberOfSections()
        let numberOfNewSections = datasource.numberOfSections()
        let removedSet = IndexSet(integersIn: 0..<numberOfOldSections)
        let insertedSet = IndexSet(integersIn: 0..<numberOfNewSections)

        selectedDatasource = datasource

        didChangeValue(forKey: "selectedDataSource")
        didChangeValue(forKey: "selectedDataSourceIndex")

        notifyBatchUpdate({
            if !removedSet.isEmpty {
                self.notifySectionsRemoved(removedSet)
            }

            if !insertedSet.isEmpty {
                self.notifySectionsInserted(insertedSet)
            }
        })

        if selectedDatasource.loadingState == .initial {
            selectedDatasource.setNeedsLoadContent()
        }
    }

    /// Set the index of the selected data source.
    func setSelectedDataSource(at index: Int) {
        guard index < datasources.count else { return }

        let datasource = datasources[index]
        setSelectedDataSource(datasource)
    }

    // MARK: Overriden methods

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if shouldDisplayPlaceholder() {
            return 0
        }

        return selectedDatasource.collectionView(collectionView, numberOfItemsInSection: section)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return selectedDatasource.collectionView(collectionView, cellForItemAt: indexPath)
    }

    override func collectionView(_ collectionView: UICollectionView, sizeFittingSize size: CGSize, forItemAt indexPath: IndexPath) -> CGSize {
        return selectedDatasource.collectionView(collectionView, sizeFittingSize: size, forItemAt: indexPath)
    }

    override func dataSourceForSectionAt(_ sectionIndex: Int) -> DataSource {
        return selectedDatasource.dataSourceForSectionAt(sectionIndex)
    }

    override func dequeuePlaceholderViewForCollectionView(
        _ collectionView: UICollectionView,
        at indexPath: IndexPath
        ) -> CollectionPlaceholderReusableView {
        return selectedDatasource.dequeuePlaceholderViewForCollectionView(collectionView, at: indexPath)
    }

    override func loadContent() {
        selectedDatasource.loadContent()
    }

    override func localIndexPathForGlobalIndexPath(_ indexPath: IndexPath) -> IndexPath? {
        return selectedDatasource.localIndexPathForGlobalIndexPath(indexPath)
    }

    override func indexPaths<T>(for item: T) -> [IndexPath] {
       return selectedDatasource.indexPaths(for: item)
    }

    override func item<T>(at indexPath: IndexPath) -> T? {
        return selectedDatasource.item(at: indexPath) as T?
    }

    override func numberOfSections() -> Int {
        return selectedDatasource.numberOfSections()
    }

    override func registerReusableViewsWithCollectionView(_ collectionView: UICollectionView) {
        super.registerReusableViewsWithCollectionView(collectionView)
        datasources.forEach({ $0.registerReusableViewsWithCollectionView(collectionView) })
    }

    override func resetContent() {
        datasources.forEach({ $0.resetContent() })
        super.resetContent()
    }

    override func shouldDisplayPlaceholder() -> Bool {
        if super.shouldDisplayPlaceholder() {
            return true
        }

        return selectedDatasource.shouldDisplayPlaceholder()
    }

    override func snapshotMetrics(for section: Int) -> SectionMetrics {
        if header(forKey: segmentedDataSourceHeaderKey) == nil {
            navigationHeader()
        }

        let metrics = selectedDatasource.snapshotMetrics(for: section)
        let enclosingMetrics = super.snapshotMetrics(for: section)
        enclosingMetrics.applyValues(from: metrics)
        return enclosingMetrics
    }

    override func updatePlaceholder(_ placeholderView: CollectionPlaceholderReusableView?, notifyVisibility: Bool) {
        selectedDatasource.updatePlaceholder(placeholderView, notifyVisibility: notifyVisibility)
    }

    // MARK: Private methods

    @discardableResult
    private func navigationHeader() -> SupplementaryViewMetrics? {
        guard shouldDisplayDefaultHeader else { return nil }
        if let defaultHeader = header(forKey: segmentedDataSourceHeaderKey) {
            return defaultHeader
        }

        let header = newHeader(forKey: segmentedDataSourceHeaderKey, supplementaryViewClass: SegmentedControlCollectionReusableView.self)
        header.shouldPin = true
        header.configurationCallback = { [weak self] reusableView, _, _ in
            guard
                /// self
                let `self` = self,

                /// segmented header view
                let segmentedControlCollectionReusableView = reusableView as? SegmentedControlCollectionReusableView else { return  }

            let segmentedControl = segmentedControlCollectionReusableView.segmentedControl
            let titles = self.datasources.map({ $0.title ?? "" })
            segmentedControl.removeAllSegments()
            segmentedControl.addTarget(self, action: #selector(self.selectedSegmentIndexChanged(_:)), for: .valueChanged)
            for (index, title) in titles.enumerated() {
                segmentedControl.insertSegment(withTitle: title, at: index, animated: false)
            }
            segmentedControl.selectedSegmentIndex = self.selectedIndex
        }
        return header
    }
}

extension SegmentedDatasource: DatasourceDelegate {

    // MARK: DatasourceDelegate

    func dataSourceDidReloadData(_ dataSource: DataSource) {
        guard dataSource === selectedDatasource else { return }

        notifyDidReloadData()
    }

    func dataSource(_ dataSource: DataSource, didInsertItemsAtIndexPaths indexPaths: [IndexPath]) {
        guard dataSource === selectedDatasource else { return }

        notifyItemsInserted(at: indexPaths)
    }

    func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet, direction: DataSourceSectionDirection) {
        guard dataSource === selectedDatasource else { return }

        notifySectionsInserted(sections)
    }

    func dataSource(_ dataSource: DataSource, didLoadContentWithError error: Error?) {
        guard dataSource === selectedDatasource else { return }

        notifyContentLoadedWithError(error)
    }

    func dataSource(_ dataSource: DataSource, didMoveItemAtIndexPath fromIndexPath: IndexPath, toIndexPath newIndexPath: IndexPath) {
        guard dataSource === selectedDatasource else { return }

        notifyItemMoved(from: fromIndexPath, to: newIndexPath)
    }

    func dataSource(_ dataSource: DataSource, didRefreshItemsAtIndexPaths indexPaths: [IndexPath]) {
        guard dataSource === selectedDatasource else { return }

        notifyItemsRefreshed(at: indexPaths)
    }

    func dataSource(_ dataSource: DataSource, didRefreshSections sections: IndexSet) {
        guard dataSource === selectedDatasource else { return }

        notifySectionsRefreshed(sections)
    }

    func dataSource(_ dataSource: DataSource, didRemoveItemsAtIndexPaths indexPaths: [IndexPath]) {
        guard dataSource === selectedDatasource else { return }

        notifyItemsRemoved(at: indexPaths)
    }

    func dataSource(_ dataSource: DataSource, didRemoveSections sections: IndexSet, direction: DataSourceSectionDirection) {
        guard dataSource === selectedDatasource else { return }

        notifySectionsRemoved(sections, direction: direction)
    }

    func dataSource(_ dataSource: DataSource, performBachUpdate update: BacthUpdateCallback?, completionCallback: BacthUpdateCallback?) -> Bool {
         guard dataSource === selectedDatasource else {
            update?()
            completionCallback?()
            return true
        }

        notifyBatchUpdate(update, completionCallback: completionCallback)
        return true
    }

    func dataSourceWillLoadContent(_ datasource: DataSource) {
        guard datasource === selectedDatasource else { return }

        notifyWillLoadContent()
    }
}
