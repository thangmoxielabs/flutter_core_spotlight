import Flutter
import UIKit
import CoreSpotlight
import MobileCoreServices

public class SwiftFlutterCoreSpotlightPlugin: NSObject, FlutterPlugin {
  
  var channel: FlutterMethodChannel?
  let searchableIndex = CSSearchableIndex(name: "EM_INDEX")
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_core_spotlight", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterCoreSpotlightPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "index_searchable_items":
      guard let arguments = call.arguments as? [[String: Any]] else {
        result(FlutterError())
        break
      }
      let searchableItems = arguments.map { itemMap -> CSSearchableItem in
        return createSearchableItem(from: itemMap)
      }
      searchableIndex.indexSearchableItems(searchableItems) { error in
        if let error = error {
          result(FlutterError(code: "500", message: error.localizedDescription, details: nil))
        } else {
          result("success")
        }
      }
      break
    case "delete_searchable_items":
      guard let arguments = call.arguments as? [String] else {
        result(FlutterError())
        break
      }
      searchableIndex.deleteSearchableItems(withIdentifiers: arguments) { error in
        if let error = error {
          result(FlutterError(code: "500", message: error.localizedDescription, details: nil))
        } else {
          result("success")
        }
      }
      break
    case "delete_all_searchable_items":
      searchableIndex.deleteAllSearchableItems { error in
        if let error = error {
          result(FlutterError(code: "500", message: error.localizedDescription, details: nil))
        } else {
          result("success")
        }
      }
      break
    default:
      result(FlutterError())
      break
    }
  }
   
  public func application(_ application: UIApplication,
                         continue userActivity: NSUserActivity,
                         restorationHandler: @escaping ([Any]) -> Void) -> Bool {
    if userActivity.activityType == CSSearchableItemActionType {
      userActivity.resignCurrent()
      userActivity.invalidate()
      channel?.invokeMethod("onSearchableItemSelected",
                            arguments: [
                              "key": userActivity.activityType,
                              "uniqueIdentifier": userActivity.userInfo?[CSSearchableItemActivityIdentifier],
                              "userInfo": userActivity.userInfo
                            ])
    }
    return true
  }

  private func createSearchableItem(from itemMap: [String: Any]) -> CSSearchableItem {
    let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.text)
    attributeSet.identifier = itemMap["uniqueIdentifier"] as? String
    attributeSet.title = itemMap["attributeTitle"] as? String
    attributeSet.displayName = itemMap["attributeDisplayName"] as? String
    attributeSet.contentDescription = itemMap["attributeDescription"] as? String
    
    if let addedDateString = itemMap["addedDate"] as? String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let addedDate = dateFormatter.date(from: addedDateString) {
            attributeSet.addedDate = addedDate
        } else {
            attributeSet.addedDate = Date()
        }
    } else {
        attributeSet.addedDate = Date()
    }
    
    if let keywords = itemMap["keywords"] as? [String] {
        attributeSet.keywords = keywords
    }
    
    let item = CSSearchableItem(uniqueIdentifier: "\(itemMap["uniqueIdentifier"] as? String ?? "")",
                                domainIdentifier: itemMap["domainIdentifier"] as? String ?? "",
                                attributeSet: attributeSet)
    return item
  }
}
