import Flutter
import Photos
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  private var pendingPickResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      registerShotlyChannel(on: controller)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func registerShotlyChannel(on controller: FlutterViewController) {
    let channel = FlutterMethodChannel(name: "shotly/native", binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "requestPhotoPermission":
        self.requestPhotoPermission(result: result)
      case "getScreenshots":
        self.getScreenshots(result: result)
      case "pickImage":
        self.pickImage(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func requestPhotoPermission(result: @escaping FlutterResult) {
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    switch status {
    case .authorized, .limited:
      result(true)
    case .notDetermined:
      PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
        DispatchQueue.main.async {
          result(newStatus == .authorized || newStatus == .limited)
        }
      }
    default:
      result(false)
    }
  }

  private func getScreenshots(result: @escaping FlutterResult) {
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    guard status == .authorized || status == .limited else {
      result(FlutterError(code: "photo_permission_denied", message: "사진 접근 권한이 필요해요.", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let fetchOptions = PHFetchOptions()
      fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      fetchOptions.predicate = NSPredicate(format: "mediaType == %d AND ((mediaSubtypes & %d) != 0)", PHAssetMediaType.image.rawValue, PHAssetMediaSubtype.photoScreenshot.rawValue)
      fetchOptions.fetchLimit = 500

      let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
      var screenshots: [[String: Any]] = []
      assets.enumerateObjects { asset, _, _ in
        screenshots.append(self.mapAsset(asset))
      }

      DispatchQueue.main.async {
        result(screenshots)
      }
    }
  }

  private func pickImage(result: @escaping FlutterResult) {
    guard pendingPickResult == nil else {
      result(FlutterError(code: "picker_busy", message: "이미 이미지 선택 화면이 열려 있어요.", details: nil))
      return
    }
    guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
      result(FlutterError(code: "picker_unavailable", message: "사진 보관함을 열 수 없어요.", details: nil))
      return
    }

    pendingPickResult = result
    let picker = UIImagePickerController()
    picker.sourceType = .photoLibrary
    picker.delegate = self
    picker.mediaTypes = ["public.image"]
    window?.rootViewController?.present(picker, animated: true)
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true) { [weak self] in
      self?.pendingPickResult?(nil)
      self?.pendingPickResult = nil
    }
  }

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    let asset = info[.phAsset] as? PHAsset
    let image = info[.originalImage] as? UIImage
    let mapped: [String: Any]?
    if let asset {
      mapped = mapAsset(asset)
    } else if let image {
      mapped = mapPickedImage(image)
    } else {
      mapped = nil
    }

    picker.dismiss(animated: true) { [weak self] in
      self?.pendingPickResult?(mapped)
      self?.pendingPickResult = nil
    }
  }

  private func mapAsset(_ asset: PHAsset) -> [String: Any] {
    let created = asset.creationDate ?? Date()
    let id = asset.localIdentifier
    return [
      "id": id,
      "displayName": displayName(for: asset),
      "relativePath": "Photos/Screenshots",
      "dateTakenMillis": Int64(created.timeIntervalSince1970 * 1000),
      "appName": "iOS Screenshot",
      "thumbnailPath": thumbnailPath(for: asset) ?? ""
    ]
  }

  private func mapPickedImage(_ image: UIImage) -> [String: Any] {
    let id = "ios-picked-\(UUID().uuidString)"
    let path = writeThumbnail(image: image, id: id) ?? ""
    return [
      "id": id,
      "displayName": "Selected Image",
      "relativePath": "Photos/Selected",
      "dateTakenMillis": Int64(Date().timeIntervalSince1970 * 1000),
      "appName": "Selected",
      "thumbnailPath": path
    ]
  }

  private func displayName(for asset: PHAsset) -> String {
    let resources = PHAssetResource.assetResources(for: asset)
    return resources.first?.originalFilename ?? "Screenshot"
  }

  private func thumbnailPath(for asset: PHAsset) -> String? {
    let cacheDir = thumbnailCacheDirectory()
    let safeId = asset.localIdentifier.replacingOccurrences(of: "/", with: "_")
    let fileUrl = cacheDir.appendingPathComponent("\(safeId).jpg")
    if FileManager.default.fileExists(atPath: fileUrl.path) { return fileUrl.path }

    let options = PHImageRequestOptions()
    options.deliveryMode = .fastFormat
    options.resizeMode = .fast
    options.isSynchronous = true
    options.isNetworkAccessAllowed = false

    var outputPath: String?
    PHImageManager.default().requestImage(
      for: asset,
      targetSize: CGSize(width: 360, height: 640),
      contentMode: .aspectFill,
      options: options
    ) { image, _ in
      guard let image else { return }
      outputPath = self.writeThumbnail(image: image, fileUrl: fileUrl)
    }
    return outputPath
  }

  private func writeThumbnail(image: UIImage, id: String) -> String? {
    let cacheDir = thumbnailCacheDirectory()
    let fileUrl = cacheDir.appendingPathComponent("\(id).jpg")
    return writeThumbnail(image: image, fileUrl: fileUrl)
  }

  private func writeThumbnail(image: UIImage, fileUrl: URL) -> String? {
    guard let data = image.jpegData(compressionQuality: 0.78) else { return nil }
    do {
      try data.write(to: fileUrl, options: .atomic)
      return fileUrl.path
    } catch {
      return nil
    }
  }

  private func thumbnailCacheDirectory() -> URL {
    let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("shotly-thumbnails", isDirectory: true)
    if !FileManager.default.fileExists(atPath: cacheDir.path) {
      try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }
    return cacheDir
  }
}
