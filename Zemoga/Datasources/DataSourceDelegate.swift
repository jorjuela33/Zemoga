//
//  DataSourceDelegate.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import Foundation

protocol DatasourceDelegate: class {
    func dataSource(_ dataSource: DataSource, didInsertItemsAtIndexPaths indexPaths: [IndexPath])
    func dataSource(_ dataSource: DataSource, didLoadContentWithError error: Error?)
    func dataSource(_ dataSource: DataSource, didMoveItemAtIndexPath fromIndexPath: IndexPath, toIndexPath newIndexPath: IndexPath)
    func dataSource(_ dataSource: DataSource, didRefreshItemsAtIndexPaths indexPaths: [IndexPath])
    func dataSource(_ dataSource: DataSource, didRemoveItemsAtIndexPaths indexPaths: [IndexPath])
    func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet, direction: DataSourceSectionDirection)
    func dataSource(_ dataSource: DataSource, didMoveSection section: Int, to newSection: Int, direction: DataSourceSectionDirection)
    func dataSource(_ dataSource: DataSource, performBachUpdate update: BacthUpdateCallback?, completionCallback: BacthUpdateCallback?) -> Bool
    func dataSource(_ dataSource: DataSource, didRefreshSections sections: IndexSet)
    func dataSource(_ dataSource: DataSource, didRemoveSections sections: IndexSet, direction: DataSourceSectionDirection)
    func dataSourceDidReloadData(_ dataSource: DataSource)
    func dataSourceWillLoadContent(_ datasource: DataSource)
}

extension DatasourceDelegate {

    func dataSource(_ dataSource: DataSource, didInsertItemsAtIndexPaths indexPaths: [IndexPath]) {

    }

    func dataSource(_ dataSource: DataSource, didLoadContentWithError error: Error?) {

    }

    func dataSource(_ dataSource: DataSource, didMoveItemAtIndexPath fromIndexPath: IndexPath, toIndexPath newIndexPath: IndexPath) {

    }

    func dataSource(_ dataSource: DataSource, didRefreshItemsAtIndexPaths indexPaths: [IndexPath]) {

    }

    func dataSource(_ dataSource: DataSource, didRemoveItemsAtIndexPaths indexPaths: [IndexPath]) {

    }

    func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet, direction: DataSourceSectionDirection) {

    }

    func dataSource(_ dataSource: DataSource, didMoveSection section: Int, to newSection: Int, direction: DataSourceSectionDirection) {

    }

    func dataSource(_ dataSource: DataSource, performBachUpdate update: BacthUpdateCallback?, completionCallback: BacthUpdateCallback?) -> Bool {
        return false
    }

    func dataSource(_ dataSource: DataSource, didRefreshSections sections: IndexSet) {

    }

    func dataSource(_ dataSource: DataSource, didRemoveSections sections: IndexSet, direction: DataSourceSectionDirection) {

    }

    func dataSourceDidReloadData(_ dataSource: DataSource) {

    }

    func dataSourceWillLoadContent(_ datasource: DataSource) {

    }
}
