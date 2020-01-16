//
//  ObservableExample.swift
//  RxSwiftDemo
//
//  Created by 宮内 龍之介 on 2020/01/09.
//  Copyright © 2020 宮内 龍之介. All rights reserved.
//

import Foundation
import RxSwift

struct ObservableEntity {
    let num: Int
}

class ObservableExample {
    private let backgroundThread = ConcurrentDispatchQueueScheduler(qos: .default)
    private let disposeBag = DisposeBag()
    
    func createObservable(_ numberArray: [Int]) -> Observable<ObservableEntity> {
        return Observable<ObservableEntity>.create { (observer) -> Disposable in
            for num in numberArray {
                // 変換処理
                print("\(Thread.current) > \(num)を処理開始")
                let entity = ObservableEntity(num: num)
                observer.onNext(entity)
            }
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func start() {
        print("--- start ---------------")
        
        let observable = createObservable([1, 2, 3, 4, 5])
        observable
            .subscribeOn(backgroundThread) // 変換処理はサブスレッドで実行
            .observeOn(MainScheduler.instance)  // onNext, onError, onCompleteはメインスレッドで実行
            .subscribe(onNext: { (entity) in
                // 一つのデータを処理した後の処理
                print("\(Thread.current) > onNext: \(entity.num)")
            }, onError: { (error) in
                // エラー処理
                print("\(Thread.current) > onError: \(error)")
            }, onCompleted: {
                // 全てのデータを完了した後の処理
                print("\(Thread.current) > onComplete")
                
            }).disposed(by: disposeBag)
    }
    
    func startWithMap() {
        let numArray = [1, 2, 3, 4, 5]
        
        let observable =
            Observable
                .from(numArray)
                .map { ObservableEntity(num: $0) }
        
        observable
            .subscribeOn(backgroundThread) // 変換処理はサブスレッドで実行
            .observeOn(MainScheduler.instance)  // onNext, onError, onCompleteはメインスレッドで実行
            .subscribe(onNext: { (entity) in
                // 一つのデータを処理した後の処理
                print("\(Thread.current) > onNext: \(entity.num)")
            }, onError: { (error) in
                // エラー処理
                print("\(Thread.current) > onError: \(error)")
            }, onCompleted: {
                // 全てのデータを完了した後の処理
                print("\(Thread.current) > onComplete")
                
            }).disposed(by: disposeBag)
    }
    
    func startFilter() {
        print("--- startFilter ---------------")
        
        let observableFilter = createObservable([1, 2, 3, 4, 5])
        observableFilter
        .subscribeOn(backgroundThread)  // 変換処理はサブスレッドで実行
        .filter({ (entity) -> Bool in   // filterで値が偶数のものだけ通知させる
            return entity.num % 2 == 0
        })
        .observeOn(MainScheduler.instance)  // onNext, onError, onCompleteはメインスレッドで実行
        .subscribe(onNext: { (entity) in
            // 一つのデータを処理した後の処理
            print("\(Thread.current) > onNext: \(entity.num)")
        }, onError: { (error) in
            // エラー処理
            print("\(Thread.current) > onError: \(error)")
        }, onCompleted: {
            // 全てのデータを完了した後の処理
            print("\(Thread.current) > onComplete")
        }).disposed(by: disposeBag)
    }
}
