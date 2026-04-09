# iPad App Scaffold

このフォルダは `preview.html` を `WKWebView` で表示する `iPad` 向け土台です。

## 前提

- Mac に `Xcode` 本体が必要
- 配布はまず `TestFlight` が現実的
- `App Store` 公開しなくても、知っている人に配る形で進められる

## 最短手順

1. `Xcode` で `App` テンプレートの新規 `iOS App` を作成
2. Product Name を `SmartMotionAnalysis` にする
3. Interface は `SwiftUI`
4. Language は `Swift`
5. この `ios/SmartMotionAnalysis/` 配下の `.swift` ファイルをプロジェクトへ追加
6. `ios/SmartMotionAnalysis/Resources/preview.html` を `Copy Bundle Resources` に入れる
7. iPad シミュレータまたは実機で起動

## 配布

- 知っている人に配るなら `TestFlight` が一番扱いやすい
- オフライン利用は可能
- 今の構成はアプリ内に `HTML` を同梱するので、インターネット不要

## 注意

- 現在の `Share Video` / `Share View` は試作導線です
- 実際の共有や画像書き出しは次の段階で `Swift` 側に寄せるのが安全です
- `HTML` を更新したら、この `Resources/preview.html` も同期してください
