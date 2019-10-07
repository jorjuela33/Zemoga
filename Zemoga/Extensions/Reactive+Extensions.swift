//
//  Reactive+Extensions.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import Domain
import RxCocoa
import RxSwift

extension UICollectionReusableView: Reusable {}
extension UITableViewCell: Reusable {}

private struct AssociatedKeys {
    static var reuseBag = "Reactive.Reusable.DisposeBag"
}

@objc
protocol Reusable: class {
    func prepareForReuse()
}

extension ObservableType where Element == Bool {
    func not() -> Observable<Bool> {
        return self.map(!)
    }
}

extension SharedSequenceConvertibleType {
    func mapToVoid() -> SharedSequence<SharingStrategy, Void> {
        return map { _ in }
    }
}

extension ObservableType {
    func asDriverOnErrorJustComplete() -> Driver<Element> {
        return asDriver { _ in
            return Driver.empty()
        }
    }

    func catchErrorJustComplete() -> RxSwift.Observable<Element> {
        return catchError { _ in
            return Observable.empty()
        }
    }

    func mapToVoid() -> RxSwift.Observable<Void> {
        return map { _ in }
    }
}

extension Reactive where Base: UIViewController {
    var message: Binder<Message> {
        return Binder(self.base) { viewController, message in
            let alertController = UIAlertController(title: message.title, message: message.message, preferredStyle: message.preferedStyle)
            message.actions.forEach(alertController.addAction)
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
}

extension Reactive where Base: LoadingIndicator {
     var state: Binder<ActivityState> {
           return Binder(self.base) { loadingIndicator, state in
               guard state == .loading else {
                   loadingIndicator.hide(animated: true)
                   return
               }

               loadingIndicator.show(animated: true)
           }
       }
 }

extension Reactive where Base: Reusable {
    var prepareForReuse: RxSwift.Observable<Void> {
        return RxSwift.Observable.of(sentMessage(#selector(Base.prepareForReuse)).mapToVoid(), deallocated).merge()
    }

    var reuseBag: DisposeBag {
        MainScheduler.ensureExecutingOnScheduler()
        if let disposeBag = objc_getAssociatedObject(base, &AssociatedKeys.reuseBag) as? DisposeBag {
            return disposeBag
        } else {
            let disposeBag = DisposeBag()
            objc_setAssociatedObject(base, &AssociatedKeys.reuseBag, disposeBag, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            _ = sentMessage(#selector(Base.prepareForReuse)).subscribe(onNext: { [weak base] _ in
                guard let strongBase = base else { return }

                objc_setAssociatedObject(strongBase, &AssociatedKeys.reuseBag, DisposeBag(), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            })

            return disposeBag
        }
    }
}
