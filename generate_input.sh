
function clone() {
  if [ ! -d "downloads/$2" ]; then
    git clone "git@github.com:$1/$2.git" "downloads/$2"
  else
    echo "Reuse $2"
  fi
}

# mail-ios
clone frnde mail-ios
cd downloads/mail-ios
git reset --hard "origin/widget"
bundle install
bundle exec fastlane bootstrap
sourcekitten doc -- -project Mail.xcodeproj -scheme Mail -configuration Debug -sdk iphoneos > "../../input/mail-ios.json"
cd ../..



# # Alamofire
# clone Alamofire Alamofire
# cd downloads/Alamofire
# git reset --hard 5.4.0
# sourcekitten doc > "../../input/alamofire.json"
# cd ../..

# # ReactiveCocoa
# clone ReactiveCocoa ReactiveSwift
# cd downloads/ReactiveSwift
# git reset --hard 11.0.0
# carthage bootstrap --platform macOS
# sourcekitten doc -- -workspace ReactiveSwift.xcworkspace -scheme ReactiveSwift-macOS > "../../input/reactive_swift.json"
# cd ../..

# # Vapor
# clone Vapor Vapor
# cd downloads/Vapor
# git reset --hard 4.36.0
# swift package generate-xcodeproj
# sourcekitten doc > "../../input/vapor.json"
# cd ../..


# # Kingfisher
# clone onevcat Kingfisher
# cd downloads/Kingfisher
# git reset --hard 5.15.8
# sourcekitten doc -- -workspace Kingfisher.xcworkspace -scheme Kingfisher > "../../input/kingfisher.json"
# cd ../..


# # SnapKit
# clone SnapKit SnapKit
# cd downloads/SnapKit
# git reset --hard 5.0.1
# sourcekitten doc -- -workspace SnapKit.xcworkspace -scheme SnapKit > "../../input/snapkit.json"
# cd ../..