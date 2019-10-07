//
//  CollectionViewDelegate.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import UIKit

protocol CollectionViewDelegate: DatasourceDelegate {
    var collectionView: UICollectionView! { get set }
    var swipeStateMachine: SwipeToEditStateMachine! { get set }
}

extension CollectionViewDelegate where Self: UIViewController {

    // MARK: DataSourceDelegate

    func dataSource(_ dataSource: DataSource, didInsertItemsAtIndexPaths indexPaths: [IndexPath]) {
        collectionView.insertItems(at: indexPaths)
    }

    func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet, direction: DataSourceSectionDirection) {
        collectionView.insertSections(sections)
    }

    func dataSource(_ dataSource: DataSource, didLoadContentWithError error: Error?) {
        let refreshControl = collectionView.refreshControl ?? collectionView.subviews.first(where: { $0 is UIRefreshControl })
        refreshControl?.perform(#selector(UIRefreshControl.endRefreshing), with: nil, afterDelay: 0.05)

        guard let error = error else { return }

        showMessage(error.localizedDescription)
    }

    func dataSource(_ dataSource: DataSource, didMoveItemAtIndexPath fromIndexPath: IndexPath, toIndexPath newIndexPath: IndexPath) {
        collectionView.moveItem(at: fromIndexPath, to: newIndexPath)
    }

    func dataSource(_ dataSource: DataSource, didMoveSection section: Int, to newSection: Int, direction: DataSourceSectionDirection) {
        collectionView.moveSection(section, toSection: newSection)
    }

    func dataSource(_ dataSource: DataSource, performBachUpdate update: BacthUpdateCallback?, completionCallback: BacthUpdateCallback?) -> Bool {
        collectionView.performBatchUpdates({
            update?()
        }) { completed in
            if completed {
                completionCallback?()
            }

           // self.collectionView.reloadData()
        }

        return true
    }

    func dataSource(_ dataSource: DataSource, didRefreshItemsAtIndexPaths indexPaths: [IndexPath]) {
        collectionView.reloadItems(at: indexPaths)
    }

    func dataSource(_ dataSource: DataSource, didRefreshSections sections: IndexSet) {
        collectionView.reloadSections(sections)
    }

    func dataSource(_ dataSource: DataSource, didRemoveItemsAtIndexPaths indexPaths: [IndexPath]) {
        if let trackedIndexPath = swipeStateMachine.trackedIndexPath {
            let exists = indexPaths.filter({ $0 == trackedIndexPath }).isEmpty
            if exists {
                swipeStateMachine.shutActionPaneForEditingCell(animated: false)
            }
        }
        collectionView.deleteItems(at: indexPaths)
    }

    func dataSource(_ dataSource: DataSource, didRemoveSections sections: IndexSet, direction: DataSourceSectionDirection) {
        collectionView.deleteSections(sections)
    }

    func dataSourceDidReloadData(_ dataSource: DataSource) {
        swipeStateMachine.shutActionPaneForEditingCell(animated: false)
        collectionView.reloadData()
    }
}
