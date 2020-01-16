//
//  WeatherNetworkManager.swift
//  RxSwiftDemo
//
//  Created by 宮内 龍之介 on 2019/12/04.
//  Copyright © 2019 宮内 龍之介. All rights reserved.
//

import Foundation
import RxSwift

enum WeatherAPIError: Error {
    case emptyData
    case parseJson
}

class WeatherClient {
    // サブスレッドで実行するためにスケジューラ
    private let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .default)
    
    func getForecast(cityId: String,
                     disposeBag: DisposeBag,    // 購読解除タイミングを呼び出し元に委ねる
                     onSuccess: @escaping (WeatherEntity) -> Void,
                     onError: @escaping (Error) -> Void) {
        let parameters = ["city": cityId]
        
        // Observableを取得
        let observable = WeatherAPI.createForecastObservable(WeatherConstant.forecastUrl,
                                                             parameters)
        
        // subscribeで購読（通信処理）を開始する
        observable
            // Observable側（WebAPIクラスで作った通信処理）はサブスレッドで実行するように指定
            .subscribeOn(backgroundScheduler)
            // Observer側（subscribe処理）はメインスレッドで実行するように指定
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { (weatherEntity) in
                // ObservableからonSuccessが通知された場合の処理
                onSuccess(weatherEntity)
            }) { (error) in
                // ObservableからonErrorが通知された場合の処理
                onError(error)
        }.disposed(by: disposeBag)
    }
    
}
