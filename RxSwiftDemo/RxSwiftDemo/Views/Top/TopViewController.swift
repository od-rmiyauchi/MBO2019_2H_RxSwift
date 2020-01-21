//
//  ViewController.swift
//  RxSwiftDemo
//
//  Created by 宮内 龍之介 on 2019/12/03.
//  Copyright © 2019 宮内 龍之介. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

struct TopConstant {
    static let showForecastSeque = "showForecast"
    static let cellIdentifier = "cityCell"
}

class TopViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private let disposeBag = DisposeBag()
    
    // 市リスト
    private var cities: [CityEntity] = []
    // TableViewに表示する市リストの検索結果
    private var searchedCities = BehaviorRelay<[CityEntity]>(value: [])
    
    private let dataSource = TopDataSource()
    
    private let observableExample = ObservableExample()
    
    // UISearchBarのテキスト変更イベントをRxで取得
    // 入力完了まで200msまで待つ、ということもRxで実装できる
    private var searchBarChangeText: Driver<String> {
        return rx
            .methodInvoked(#selector(UISearchBarDelegate.searchBar(_:shouldChangeTextIn:replacementText:)))
            .debounce(.milliseconds(200), scheduler: MainScheduler.instance)
            .flatMap { [weak self] _ -> Observable<String> in .just(self?.searchBar.text ?? "") }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // インクリメントサーチ処理
        // ここでは1.SearchBar--(バインド)-->searchedCities, 2.searchedCities--(バインド)-->tableViewを実施
        // ※ viewDidLoadでDriverの設定をすると実行時にWarningが出てしまうが、Rxライブラリの修正待ち
        // 1. Rxで通知されたテキストを使って検索し、searchedCitiesをRxで書き換える
        //     flatMapで検索条件に合った市リストのDriverに変換し、driveでsearchCitiesにバインド
        searchBarChangeText
            .flatMap { [weak self] text -> Driver<[CityEntity]> in
                guard let me = self else { return .just([]) }
                if text.isEmpty {
                    return .just(me.cities)
                }
                return .just(me.cities.filter { $0.containWord(text) })
            }
            .drive(searchedCities)
            .disposed(by: disposeBag)
        // 2. ここでは検索結果リストとTableViewをバインド
        //    こうすることで、searchCitiesの値を直接変更してもTableViewが更新するようになる
        searchedCities
            .asDriver()
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setCities()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        runExamples()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == TopConstant.showForecastSeque {
            guard let forecastViewController = segue.destination as? ForecastViewController else { return }
            guard let city = sender as? CityEntity else { return }
            forecastViewController.cityId = city.id
            forecastViewController.title = city.name
        }
    }
}

extension TopViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let city = searchedCities.value[indexPath.row]
        self.performSegue(withIdentifier: TopConstant.showForecastSeque, sender: city)
    }
}

extension TopViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar,
                   shouldChangeTextIn range: NSRange,
                   replacementText text: String) -> Bool {
        return true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

private extension TopViewController {
    func setCities() {
        let cityModel = CityAssets()
        cityModel.getCity(
            disposeBag: disposeBag,
            onSuccess: { (cities) in
                self.cities = cities
                // TableViewに全件表示したいので、tableViewにバインドしているsearchedCitiesを更新
                self.searchedCities.accept(cities)
            },
            onError: { (error) in
                print(error)
            })
    }
    
    func runExamples() {
        observableExample.start()
//        observableExample.startWithMap()
    }
}
