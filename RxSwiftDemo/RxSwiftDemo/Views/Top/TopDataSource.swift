//
//  TopDataSource.swift
//  RxSwiftDemo
//
//  Created by 宮内 龍之介 on 2019/12/09.
//  Copyright © 2019 宮内 龍之介. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class TopDataSource: NSObject, UITableViewDataSource, RxTableViewDataSourceType {

    typealias  Element = [CityEntity]

    private var items: Element = []

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TopConstant.cellIdentifier, for: indexPath)
        cell.textLabel?.text = items[indexPath.row].name
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, observedEvent: Event<Element>) {
        Binder(self) { (dataSource, items) in
            dataSource.items = items
            tableView.reloadData()
        }
        .on(observedEvent)
    }
}
