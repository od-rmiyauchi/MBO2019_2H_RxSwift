# RxSwiftまとめ

## RxSwiftとは？
Reactive ExtensionsをSwiftのライブラリであり、データバインドが簡単に書け、非同期処理も実装しやすい特徴があります。  
例えばDelegateやKVOで記述していた箇所がRxSwiftで実装できるようになります。  
　https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Why.md  
※ Xcode11に導入されたCombineがありますが、対象がiOS13以降なので現状はRxSwiftが良いと思われます。  

今回はReactive Extensionsの説明を省略し、RxSwiftの基本的な使い方に焦点を当てて説明します。  
※ 説明に使用したソースは、全て"RxSwiftDemo"プロジェクトにございます。

また、イベント処理やデータバインドをRxSwiftで行うときはRxCocoaを使用すると簡単に実装できます。  
このようにRxSwiftだけではなく、他のライブラリも併用すると開発効率が向上します。

## 購読解除  
モバイルアプリ開発では画面破棄時など、オブジェクト破棄時に購読中の処理を解除したいシーンが多いです。 
基本的にはObservableごとにdisposeメソッドを呼ぶことで購読解除できます（実行中の処理を停止）が、
画面破棄時の購読解除を画面ごと、購読処理ごとに実装することは冗長となってしまいます。
そこでRxSwiftではオブジェクトの破棄時にまとめて購読解除する仕組みが用意されており、それがDisposeBagです。  
画面破棄時に購読終了させる場合は、ViewControllerのクラス定数としてdisposeBagを宣言し、それをObservableに指定します。  
ただしDisposeBagを所持しているクラスがメモリに残り続ける場合（Singletonなど）は、自動で購読解除されないので注意が必要です。  

## イベント処理
### Button
ボタンタップイベント
```
tapButton.rx.tap
	.subscribe { _ in
		print("tapButton tapped")
	}.disposed(by: disposeBag)
```

### TextField
TextField.txtのKVO
```
inputTextField.rx.text
	.subscribe { event in
		guard let text = event.element else { return }
		print("inputText > \(text ?? "")")
	}.disposed(by: disposeBag)
```

### Notification
Notificationの受信設定
```
let notificationName = Notification.Name(rawValue: "NotificationSend")
NotificationCenter.default.rx.notification(notificationName)
	.subscribe { event in
		guard let notification = event.element else { return }
		if let message = notification.object as? String {
			print("\(message)が通知されました")
		}
	}.disposed(by: disposeBag)

NotificationCenter.default.post(name: notificationName, object: "テスト")
```

### RxKeyboard
RxKeyboardライブラリを使用すると、キーボードの表示時のViewのサイズや位置調整を簡単に実現できます。  
下記では、キーボード表示時にViewの高さをキーボードのサイズだけ縮小します。  
※ サードパーティキーボードの動作は未確認
```
// サイズ調整したいViewのAutoLayout制約
@IBOutlet weak var stacktViewBottomConstraint: NSLayoutConstraint!

// ViewDidLoadでこの関数を呼ぶ
func setRxKeyboard() {
	RxKeyboard.instance.visibleHeight
		.drive(onNext: { [weak self] keyBoardHeight in
			self?.stacktViewBottomConstraint.constant = keyBoardHeight
			self?.view.layoutIfNeeded()
		})
		.disposed(by: disposeBag)
}
```

## データバインド
### UI同士
TextField.txtとLabel.txtをバインド  
orEmptyでTextFieldのテキストが空でない条件を追加できます  
```
bindingTextField.rx.text.orEmpty
	.bind(to: bindingLabel.rx.text)
	.disposed(by: disposeBag)
```

二つのUIを監視することも可能  
下記では、二つのTextFieldの値を連結し(combine)、1つの文字列に変換した(map)後に、Labelに表示しています(bind)
```
Observable
	// combineLatestで二つのTextFieldを監視し、文字列を連結します
	.combineLatest(
		bindingFirstNameTextField.rx.text,
		bindingLastNameTextField.rx.text) { "\($0 ?? "") \($1 ?? "")" }
	// ↑で連結した文字列をmapで変換する
	.map { "Greetings, \($0)" }
	.bind(to: bindingNameLabel.rx.text)
	.disposed(by: disposeBag)
```

### 変数をUIにバインド
変数をバインドすることも可能  
下記では、ViewModel.count変数の値(0以外)をLabelにバインドしています
```
viewModel.count
	// 0の場合は表示しない
	.filter { $0 != 0 }
	// count変数が整数なので、Labelにバインドするために文字列に変換
	.map { "\($0)に変わりました" }
	.bind(to: bindCountUpLabel.rx.text)
	.disposed(by: disposeBag)
```

## 非同期処理
### Hot / Cold
これまでのイベント処理やデータバインドは、値が変化したら購読処理が即実行されます。  
このように処理が自動的に実行されるものをHot Observableと呼びます。  
逆に 購読処理を始める明示的な関数(subscribe)を呼んでから処理が始まるものをCold Observableと呼びます。  
通信やDB関連の非同期処理は、処理開始を明示的に指定した方が扱いやすいため、Cold Observableで作成します。  

### 非同期処理の例（Observable）
ここではObservableを使った簡単な非同期処理の例を用いて説明します。  
例では、整数リスト[1, 2, 3, 4, 5]の各要素をEntityオブジェクトに変換することとします。  
```
1 -> ObservableEntity (num=1)
2 -> ObservableEntity (num=2)
…
5 -> ObservableEntity (num=5)
```
この変換処理をサブスレッドで動作させ、結果をメインスレッドで出力させます。  
※ 本来はリスト作成をfrom関数、変換処理をmap関数で十分ですが（下記別解を参照）、今回はあえてObservable生成から実装します。  

```
class ObservableExample {
    private let backgroundThread = ConcurrentDispatchQueueScheduler(qos: .default)
    private let disposeBag = DisposeBag()
    
    // ①
    func createObservable(_ numberArray: [Int]) -> Observable<ObservableEntity> {
        return Observable<ObservableEntity>.create { (observer) -> Disposable in
            // 受け取ったリストのデータを全て処理する
            for num in numberArray {
                // ② 変換処理
                print("\(Thread.current) > \(num)を処理開始")
                let entity = ObservableEntity(num: num)
                // ③ 変換処理が終わったら、observerにonNextに通知して、次の変換処理へ
                observer.onNext(entity)
            }
            // ④ リスト内の全データの処理が完了したことを通知
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func start() {
        let observable = createObservable([1, 2, 3, 4, 5])
        observable
            .subscribeOn(backgroundThread) // ⑤ 変換処理はサブスレッドで実行
            .observeOn(MainScheduler.instance)  // ⑥ onNext, onError, onCompleteはメインスレッドで実行
            .subscribe(onNext: { (entity) in
                // ⑦ 一つのデータを処理した後の処理
                print("\(Thread.current) > onNext: \(entity.num)")
            }, onError: { (error) in
                // エラー処理
                print("\(Thread.current) > onError: \(error)")
            }, onCompleted: {
                // ⑧ 全てのデータを完了した後の処理
                print("\(Thread.current) > onComplete")
                
            }).disposed(by: disposeBag)
    }
}
```

実行結果
```
<NSThread: 0x600002749140>{number = 4, name = (null)} > 1を処理開始
<NSThread: 0x600002749140>{number = 4, name = (null)} > 2を処理開始
<NSThread: 0x600002749140>{number = 4, name = (null)} > 3を処理開始
<NSThread: 0x600002749140>{number = 4, name = (null)} > 4を処理開始
<NSThread: 0x600002749140>{number = 4, name = (null)} > 5を処理開始
<NSThread: 0x600002752c80>{number = 1, name = main} > onNext: 1
<NSThread: 0x600002752c80>{number = 1, name = main} > onNext: 2
<NSThread: 0x600002752c80>{number = 1, name = main} > onNext: 3
<NSThread: 0x600002752c80>{number = 1, name = main} > onNext: 4
<NSThread: 0x600002752c80>{number = 1, name = main} > onNext: 5
<NSThread: 0x600002752c80>{number = 1, name = main} > onComplete
```

- Observable側の実装  
① createObservable関数ではObservableを作成しており、Observable.createに非同期にしたい処理を記述します。  
② ここでは関数の引数で受け取ったリスト内の整数をEntityオブジェクトに変換する処理を非同期にしています。  
③ 一つの要素に対して処理が完了するたびに、onNextを呼びます。こうすることでObserverに1つの要素の処理が完了したことが通知されます。  
④ 最後に全要素の処理が完了したことをonCompletedでObserverに通知します。  
また、ソースに記述しておりませんが、エラーが生じた場合はonErrorで通知します。  

- Observer側の実装  
⑤ Observable側の処理（今回はObservable.createで実装した変換処理）のスレッドをサブスレッドに指定  
⑥ Observaer側の処理（onNextやonComplete内の処理）のスレッドをメインスレッドに指定  
⑦ onNextは一つの要素について処理した後に呼ばれます  
⑧ onCompleteは全ての要素について処理した後に呼ばれます  

別解
```
// createObservable関数を下記で置き換えるイメージ
return Observable.from(numArray)
                 .map { ObservableEntity(num: $0) }
```

### 通信処理の例（Single）
今回は連続でリクエストを投げない場合、ObservableよりもSIngleが適しています。  
ObservableはonNextが複数回実行されることを想定していますが、SingleはonSuccess/onErrorの２パターンのみです。  
そのために１回だけリクエストを投げるようなAPIでは、SingleのほうがonNextを書かなくて済むので実装が簡単です。  

以下は天気予報APIを非同期で実行し、結果をTextViewに表示する例です。  
1. まずWeatherAPI.createForecastObservableでSingleの生成を実装します。  
 そしてこのSingleに対して非同期で実行したいWebAPI処理を実装します。  

```
class WeatherAPI {
    static func createForecastObservable(_ url: String, _ parameters: [String:Any]) -> Single<WeatherEntity> {
        return Single<WeatherEntity>.create { (observer) -> Disposable in
			// ここに非同期で実行したい処理を記述
            Alamofire
                .request(url, method: .get, parameters: parameters)
                .response(completionHandler: { (response) in
                    // 通信に失敗した場合は、observerにエラーを通知する
                    if let error = response.error {
                        observer(.error(error))
                    }
                    
                    guard let data = response.data else {
                        observer(.error(WeatherAPIError.emptyData))
                        return;
                    }
                    
                    let decoder = JSONDecoder()
                    if let weatherEntity = try? decoder.decode(WeatherEntity.self, from: data) {
                        // 通信に成功した場合は、observerに通知する
                        // Singleなのでsuccess or errorの2パターン（onNextがない）
                        observer(.success(weatherEntity))
                    } else {
                        observer(.error(WeatherAPIError.parseJson))
                    }
                    
                })
            return Disposables.create()
        }
    }
}
```

2. WeatherClient.getForecastに、1で実装したSingleの購読処理を実装します。  
 購読処理をViewController側に実装すると冗長的になってしまい、可読性が下がると思われます。  
 そこで、成功と失敗用のクロージャを引数とする関数を用意し、その中で購読処理を実行するようにしました。  

 subscribeOnでObservable側（WebAPI処理）のスレッドを指定し、  
 observerOnでObserver側（onSuccess, onError）のスレッドを指定します。  
 今回はTextViewに通信結果を表示させるため、observerOnにメインスレッドを指定します。  

 WeatherClient.getForecastではdisposeBagを引数で取得している目的は、  
 これはメソッドの呼び出し元（ViewController）のデストラクタ時に、購読解除させるためです。  
　
```
class WeatherClient {
    // サブスレッドで実行するためにスケジューラ
    private let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .default)
    
    func getForecast(cityId: String,
                     disposeBag: DisposeBag,	// 購読解除タイミングを呼び出し元に委ねる
                     onSuccess: @escaping (WeatherEntity) -> Void,
                     onError: @escaping (Error) -> Void) {

        let parameters = ["city": cityId]
        
		// Observableを取得
        let observable = WeatherAPI.createForecastObservable(WeatherConstant.forecastUrl,
                                                             parameters)

        // subscribeで購読を開始する
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
```

3. 通信処理を呼び出すViewController  
 WeatherClientでワンクッション挟むことで、RxSwiftの購読処理の流れを意識せずにコーディングできます。  
 また、クロージャがメインスレッドで実行することで、ViewControllerではスレッドを意識する必要がありません。  
 それによりサブスレッドでUIを参照するリスクが下がり、品質が向上すると考えられます。  

```
class TopViewController: UIViewController {
// 略
	private let disposeBag = DisposeBag()
// 略
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
```

