//
//  PostPresenter.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/6/19.
//

import Domain
import RxCocoa
import RxSwift

class PostPresenter {
    private let datasource: PostDatasource
    private let disposeBag = DisposeBag()
    private var post: Post
    private let postsRepository: PostsRepository
    private let usersRepository: UsersRepository
    private let wireframe: PostWireframeInterface?

    struct Input {
        let favorite: Driver<Void>
        let pullDownToRefresh: Driver<Void>
    }

    struct Output {
        let datasource: PostDatasource
        let error: Driver<Message>
        let favoriteImage: Driver<UIImage>
        let postInfo: Driver<PostInfo>
    }

    // MARK: Initializers

    init(post: Post,
         postsRepository: PostsRepository,
         commentsRepository: CommentsRepository,
         usersRepository: UsersRepository,
         wireframe: PostWireframeInterface
    ) {

        self.datasource = PostDatasource(post: post, commentsRepository: commentsRepository)
        self.post = post
        self.postsRepository = postsRepository
        self.usersRepository = usersRepository
        self.wireframe = wireframe
    }

    // MARK: Instance methods

    func transform(_ input: Input) -> Output {
        let errorTracker = ErrorTracker()
        let favoriteImage = BehaviorRelay<UIImage>(value: post.isFavorite ? #imageLiteral(resourceName: "icFavoriteActive").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "icFavoriteInactive"))
        let postInfo = BehaviorRelay<PostInfo>(value: PostInfo(body: post.body, email: "", name: "", phone: "", website: ""))

        func retrieveUser() {
            usersRepository.retrieveUser(withID: post.userID)
            .trackError(errorTracker)
            .subscribe()
            .disposed(by: disposeBag)
        }

        input.favorite
            .flatMapLatest {
                return self.postsRepository.markPost(self.post, asFavorite: !self.post.isFavorite)
                    .asObservable()
                    .asDriverOnErrorJustComplete()
            }
            .drive()
            .disposed(by: disposeBag)

        input.pullDownToRefresh
            .drive(onNext: { [weak self] in
                retrieveUser()
                self?.datasource.setNeedsLoadContent()
            })
            .disposed(by: disposeBag)

        retrieveUser()

        postsRepository.observeChanges(forPostWithID: post.id)
            .subscribe(onNext: { [weak self] posts in
                guard
                    /// self
                    let `self` = self,

                    /// current post
                    let post = posts.first else { return }

                self.post = post
                favoriteImage.accept(post.isFavorite ? #imageLiteral(resourceName: "icFavoriteActive").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "icFavoriteInactive"))
            })
            .disposed(by: disposeBag)

        usersRepository.observeChanges(forUserWithID: post.userID)
            .subscribe(onNext: { [weak self] users in
                guard
                    /// self
                    let `self` = self,

                    /// user owner of the post
                    let user = users.first else { return }

                postInfo.accept(PostInfo(body: self.post.body, email: user.email, name: user.name, phone: user.phone, website: user.website))
            })
            .disposed(by: disposeBag)

        return Output(
            datasource: datasource,
            error: errorTracker.map(ErrorBuilder.create),
            favoriteImage: favoriteImage.asDriver(),
            postInfo: postInfo.asDriver()
        )
    }
}
