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
    private var cities: [CityEntity] = []
    
    private let dataSource = TopDataSource()
    
    private let observableExample = ObservableExample()
    
    // UISearchBarのテキスト変更をRxで取得
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
        // Rxで通知されたテキストを使って検索し、TableViewの表示項目を更新する
        // ここでDriverの設定をすると実行時にWarningが出てしまうが、Rxライブラリの修正待ち
        searchBarChangeText
            .flatMap { [weak self] text -> Driver<[CityEntity]> in
                guard let me = self else { return .just([]) }
                return .just(me.cities.filter { $0.containWord(text) })
            }
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
        let city = cities[indexPath.row]
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
                self.tableView.reloadData()
            },
            onError: { (error) in
                print(error)
            })
    }
    
    func runExamples() {
//        observableExample.start()
        observableExample.startWithMap()
    }
}
