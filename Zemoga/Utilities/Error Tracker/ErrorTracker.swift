//
//  ErrorTracker.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import RxCocoa
import RxSwift

class ErrorTracker {
    typealias SharingStrategy = DriverSharingStrategy

    private let subject = PublishSubject<Error>()

    deinit {
        subject.onCompleted()
    }

    // MARK: Private methods

    private func onError(_ error: Error) {
        subject.onNext(error)
    }
}

extension ErrorTracker: SharedSequenceConvertibleType {

    // MARK: SharedSequenceConvertibleType

    func asObservable() -> Observable<Error> {
        return subject.asObservable()
    }

    func asSharedSequence() -> SharedSequence<SharingStrategy, Error> {
        return subject.asObservable().asDriverOnErrorJustComplete()
    }

    func trackError<O: ObservableConvertibleType>(from source: O) -> Observable<O.Element> {
        return source.asObservable().do(onError: onError)
    }
}

extension ObservableConvertibleType {
    func trackError(_ errorTracker: ErrorTracker) -> Observable<Element> {
        return errorTracker.trackError(from: self)
    }
}
