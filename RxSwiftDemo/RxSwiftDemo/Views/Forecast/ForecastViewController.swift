//
//  ForecastViewController.swift
//  RxSwiftDemo
//
//  Created by 宮内 龍之介 on 2019/12/05.
//  Copyright © 2019 宮内 龍之介. All rights reserved.
//

import UIKit
import RxSwift

class ForecastViewController: UIViewController {
    
    @IBOutlet var textView: UITextView!
    
    var cityId: String?
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showForecast()
    }
}

private extension ForecastViewController {
    func showForecast() {
        guard let cityId = cityId else { return }
        
        let weatherClient = WeatherClient()
        
        weatherClient.getForecast(
            cityId: cityId,
            disposeBag: disposeBag,
            onSuccess: { (weatherEntity) in
                // ここはメインスレッドで実行される
                self.textView.text = "\(weatherEntity)"
            },
            onError:{ (error) in
                print(error)
            })
    }
}
