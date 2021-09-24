//
//  TakePhotoSheet.swift
//  VSCLogin
//
//  Created by HET on 2020/6/28.
//

import UIKit
import Photos
import AVFoundation

public protocol VSImagePickerProtocol: NSObject {
    func getImage(image: UIImage)
}

private var VSImagePickerContext: UInt8 = 0
public extension VSImagePickerProtocol {
    var imagePicker: VSImagePicker {
        get {
            if let disposeObject = objc_getAssociatedObject(self, &VSImagePickerContext) as? VSImagePicker {
                return disposeObject
            }
            let disposeObject = VSImagePicker(delegate: self)
            objc_setAssociatedObject(self, &VSImagePickerContext, disposeObject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return disposeObject
        }
        
        set {
            objc_setAssociatedObject(self, &VSImagePickerContext, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

public struct VSTakePhoto {
    public enum Camera {
        case system(edit: Bool = true)
        case custom(edit: Bool = true)
    }
    
    public enum Photo {
        case system(edit: Bool = true)
    }
}

///需持有这个对象
open class VSImagePicker: NSObject {
    public static var alertCameraTitle = "无法使用您的相机"
    public static var alertCameraMessage = "app没有获得相机的使用权限，请在设置中开启“相机”权限"
    public static var alertPhotosTitle = "无法使用您的相册"
    public static var alertPhotosMessage = "APP没有获得相册的使用权限，请在设置中开启“相册”权限"
    public static var alertCancel = "取消"
    public static var alertSetting = "开启权限"
    public static var cancelImageTitle = "取消"
    public static var cameraUseTitle = "使用照片"
    public static var cameraReplayTitle = "重拍"
    public static var photoUseTitle = "使用照片"
    
    weak var delegate: VSImagePickerProtocol?
    private var imagePicker = UIImagePickerController()
    private var imageManager: LLJImageManager?
    
    public init(delegate: VSImagePickerProtocol) {
        self.delegate = delegate
    }
    
    public func takeCameraImage(type: VSTakePhoto.Camera = .custom(edit: true)) {
        let status = self.isOpenCamera()
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (_: Bool) in
                self.takeCameraImage()
            })
        } else if status == .denied {
            DispatchQueue.main.async {
                //Please allow camera access
                self.alert(title: VSImagePicker.alertCameraTitle, message: VSImagePicker.alertCameraMessage)
            }
        } else if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            DispatchQueue.main.async {
                guard let currentVC = self.currentViewController() else { return }
                switch type {
                case let .custom(edit):
                    self.imageManager = LLJImageManager(with: .camera, canEdit: edit, fromVc: currentVC)
                    self.imageManager?.getImage(with: {[weak self] (image) in
                        guard let self = self else { return }
                        guard let image = image else { return }
                        self.delegate?.getImage(image: image)
                    })
                case .system:
                    self.imagePicker.sourceType = UIImagePickerController.SourceType.camera
                    //If you dont want to edit the photo then you can set allowsEditing to false
                    self.imagePicker.delegate = self
                    currentVC.present(self.imagePicker, animated: true, completion: nil)
                }
            }
        } else {
            DispatchQueue.main.async {
                //You don't have camera authorization
            }
        }
    }
    
    public func takePhotosImage(type: VSTakePhoto.Photo = .system(edit: true)) {
        if !self.isOpenAlbum() {
            DispatchQueue.main.async {
                //Please allow photo access
                self.alert(title: VSImagePicker.alertCameraTitle, message: VSImagePicker.alertCameraMessage)
            }
        } else {
            guard let currentVC = self.currentViewController() else { return }
            switch type {
            case let .system(edit):
                self.imageManager = LLJImageManager(with: .photoLibrary, canEdit: edit, fromVc: currentVC)
                self.imageManager?.getImage(with: {[weak self] (image) in
                    guard let self = self else { return }
                    guard let image = image else { return }
                    self.delegate?.getImage(image: image)
                })
            }
        }
    }
    
    private func currentViewController() -> UIViewController? {
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
            return getCurrentVC(from: rootVC)
        }
        return nil
    }
    
    private func getCurrentVC(from rootVC: UIViewController) -> UIViewController {
        var currentVC: UIViewController = rootVC
        if let presentVC = rootVC.presentedViewController {
            currentVC = presentVC
        }
        
        if let tabbarVC = currentVC as? UITabBarController, let selectVC = tabbarVC.selectedViewController {
            currentVC = getCurrentVC(from: selectVC)
        } else if let naviVC = currentVC as? UINavigationController, let visiVC = naviVC.visibleViewController {
            currentVC = getCurrentVC(from: visiVC)
        }
        return currentVC
    }
}

extension VSImagePicker: LLJImageEditViewControllerDelegate {
    func selectPicture(with image: UIImage?) {
        guard let image = image else { return }
        self.delegate?.getImage(image: image)
    }
}

extension VSImagePicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if #available(iOS 11, *) {
            if let classPhoto = NSClassFromString("PUPhotoPickerHostViewController"), viewController.isKind(of: classPhoto) {
                viewController.view.subviews.forEach { (view) in
                    if view.frame.size.width < 42 {
                        viewController.view.sendSubviewToBack(view)
                    }
                }
            }
        }
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let vc = LLJImageEditViewController(with: info[.originalImage] as? UIImage,
                                            type: .systemCamera,
                                            canEdit: true,
                                            delegate: self)
        picker.pushViewController(vc, animated: true)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        guard let currentVC = self.currentViewController() else { return }
        picker.isNavigationBarHidden = false
        currentVC.dismiss(animated: true, completion: nil)
    }
    
    private func isOpenCamera() -> AVAuthorizationStatus {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        return authStatus
    }
    
    private func isOpenAlbum() -> Bool {
        let authStatus = PHPhotoLibrary.authorizationStatus()
        return authStatus != .restricted && authStatus != .denied
    }
    
    private func alert(title: String, message: String) {
        guard let currentVC = self.currentViewController() else { return }
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: VSImagePicker.alertCancel, style: .cancel) { (_) in
            
        }
        
        let settingAction = UIAlertAction(title: VSImagePicker.alertSetting, style: .default) { (_) in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
        alert.addAction(cancelAction)
        alert.addAction(settingAction)
        currentVC.present(alert, animated: true, completion: nil)
    }
}
