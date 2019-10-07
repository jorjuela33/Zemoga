//
//  PostDatasource.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/6/19.
//

import Domain
import RxSwift

class PostDatasource: BasicDataSource<CommentDisplayItem, CommentCollectionViewCell> {
    private let disposeBag = DisposeBag()
    private let commentsRepository: CommentsRepository
    private let post: Post

    // MARK: Initializers

    init(post: Post, commentsRepository: CommentsRepository) {
        self.commentsRepository = commentsRepository
        self.post = post
        super.init()
        noContent = NoContent(title: "No comments.", message: "This post doesn't have any comments yet.", image: #imageLiteral(resourceName: "imgNoResults"))
        observeChanges()
    }

    // MARK: Overriden methods

    override func loadContent() {
        loadContentWithCallback { [weak self] loading in
            guard let `self` = self, loading.isCurrent else {
                loading.ignore()
                return
            }

            self.commentsRepository.retrieveComments(forPostWithID: self.post.id)
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: loading.update, onError: loading.doneWithError)
                .disposed(by: self.disposeBag)
        }
    }

    // MARK: Private methods

    private func observeChanges() {
        commentsRepository.observeChanges(forPostWithID: post.id)
            .map({ $0.map(CommentDisplayItem.init) })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] comments in
                self?.setItems(comments)
            })
            .disposed(by: disposeBag)
    }
}

