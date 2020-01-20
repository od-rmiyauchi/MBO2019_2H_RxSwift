//
//  BindExample.swift
//  RxSwiftDemo
//
//  Created by 宮内 龍之介 on 2020/01/09.
//  Copyright © 2020 宮内 龍之介. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxKeyboard

class BindViewModel {
    var count = BehaviorRelay<Int>(value: 0)
}

class BindExample: UIViewController {
    @IBOutlet weak var tapButton: UIButton!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var notificationButton: UIButton!
    @IBOutlet weak var bindingTextField: UITextField!
    @IBOutlet weak var bindingLabel: UILabel!
    @IBOutlet weak var bindingFirstNameTextField: UITextField!
    @IBOutlet weak var bindingLastNameTextField: UITextField!
    @IBOutlet weak var bindingNameLabel: UILabel!
    @IBOutlet weak var bindCountUpButton: UIButton!
    @IBOutlet weak var bindCountUpLabel: UILabel!
    
    @IBOutlet weak var stacktViewBottomConstraint: NSLayoutConstraint!
    
    private let disposeBag = DisposeBag()
    
    private let viewModel = BindViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUIEvents()
        setBinding()
        setRxKeyboard()
    }
}

private extension BindExample {
    /// UIイベントを設定
    func setUIEvents() {
        // ボタンタップ時のイベントを設定
        tapButton.rx.tap
            .subscribe { _ in
                print("tapButton tapped")
            }.disposed(by: disposeBag)
        
        // テキストが変わったときのイベントを設定
        inputTextField.rx.text
            .subscribe { event in
                guard let text = event.element else { return }
                print("inputText > \(text ?? "")")
            }.disposed(by: disposeBag)
        
        // Notification通知を設定
        let notificationName = Notification.Name(rawValue: "NotificationSend")
        NotificationCenter.default.rx.notification(notificationName)
            .subscribe { event in
                guard let notification = event.element else { return }
                if let message = notification.object as? String {
                    print("\(message)が通知されました")
                }
            }.disposed(by: disposeBag)
        // 通知するためのイベントを設定
        notificationButton.rx.tap
            .subscribe { _ in
                NotificationCenter.default.post(name: notificationName, object: "テスト")
            }.disposed(by: disposeBag)
    }
    
    /// バインディングを設定
    func setBinding() {
        // 実際にUIとバインディングするのなら、コメントアウト箇所のようにDriverを使用したほうが良い
        
        // UIの値同士をバインド
        bindingTextField.rx.text.orEmpty
            .bind(to: bindingLabel.rx.text)
            .disposed(by: disposeBag)
        /*
        bindingTextField.rx.text.orEmpty.asDriver()
            .drive(bindingLabel.rx.text)
            .disposed(by: disposeBag)
        */
        
        // 二つのTextFieldをバインド
        Observable
            // combineLatestで二つのTextFieldを監視し、文字列を連結する
            .combineLatest(bindingFirstNameTextField.rx.text,
                           bindingLastNameTextField.rx.text) { "\($0 ?? "") \($1 ?? "")" }
            // ↑で連結した文字列をmapで変換する
            .map { "Greetings, \($0)" }
            .bind(to: bindingNameLabel.rx.text)
            .disposed(by: disposeBag)
        /*
        Driver
            // combineLatestで二つのTextFieldを監視し、文字列を連結する
            .combineLatest(
                bindingFirstNameTextField.rx.text.asDriver(),
                bindingLastNameTextField.rx.text.asDriver()) { "\($0 ?? "") \($1 ?? "")" }
            // ↑で連結した文字列をmapで変換する
            .map { "Greetings, \($0)" }
            .drive(bindingNameLabel.rx.text)
            .disposed(by: disposeBag)
        */
        
        // 変数のUIにバインド
        viewModel.count
            // 0の場合は表示しない
            .filter { $0 != 0 }
            // count変数が整数なので、Labelにバインドするために文字列に変換
            .map { "\($0)に変わりました" }
            .bind(to: bindCountUpLabel.rx.text)
            .disposed(by: disposeBag)
        /*
        // 以下ではエラー発生時は0を返すようにする
        viewModel.count
            .asDriver(onErrorJustReturn: 0)
            .filter { $0 != 0 }
            .map { "\($0)に変わりました" }
            .drive(bindCountUpLabel.rx.text)
            .disposed(by: disposeBag)
        */
        // 今回はUIButtonのイベントにしていますが、Modelで値を変更することを想定（MVVM）
        bindCountUpButton.rx.tap
            .subscribe { [unowned self] _ in
                self.viewModel.count.accept(self.viewModel.count.value + 1)
            }.disposed(by: disposeBag)
    }
    
    // RxKeyboardでStackViewの高さ調整
    func setRxKeyboard() {
        RxKeyboard.instance.visibleHeight
        .drive(onNext: { [weak self] keyBoardHeight in
            self?.stacktViewBottomConstraint.constant = keyBoardHeight
            self?.view.layoutIfNeeded()
        })
        .disposed(by: disposeBag)
    }
}
