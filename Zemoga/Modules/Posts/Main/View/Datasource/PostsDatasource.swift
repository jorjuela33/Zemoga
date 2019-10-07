//
//  PostsDatasource.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import Domain
import RxSwift

class PostsDatasource: BasicDataSource<PostDisplayItem, PostCollectionViewCell> {
    private let disposeBag = DisposeBag()
    private let filter: Filter
    private let postsRepository: PostsRepository

    var deleteCallback: ((PostDisplayItem) -> Void)?

    // MARK: Initializers

    init(postsRepository: PostsRepository, filteringBy filter: Filter) {
        self.filter = filter
        self.postsRepository = postsRepository
        super.init()
        defaultMetrics.rowSize = CGSize(width: UIScreen.main.bounds.width, height: SectionMetrics.variableRowHeight)
        defaultMetrics.separatorInsets = .zero
        observeChanges()
    }

    // MARK: Overriden methods

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as? PostCollectionViewCell else {
            return UICollectionViewCell()
        }

        let deleteAction = Action(title: "Delete", isDestructive: true) { cell in
            guard
                /// indexpath
                let indexPath = collectionView.indexPath(for: cell),

                /// post
                let post: PostDisplayItem = self.item(at: indexPath)  else { return }

            self.deleteCallback?(post)
        }
        
        cell.editActions = [deleteAction]
        return cell
    }

    override func loadContent() {
        loadContentWithCallback { [weak self] loading in
            guard let `self` = self, loading.isCurrent else {
                loading.ignore()
                return
            }

            guard filter != .favorites else {
                loading.update(self.items)
                return
            }

            self.postsRepository.retrievePosts()
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: loading.update, onError: loading.doneWithError)
                .disposed(by: self.disposeBag)
        }
    }

    // MARK: Private methods

    private func observeChanges() {
        postsRepository.observeChanges(filteringBy: filter)
            .map({ $0.map(PostDisplayItem.init) })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] posts in
                self?.setItems(posts)
            })
            .disposed(by: disposeBag)
    }
}
