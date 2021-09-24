//
//  LLJImageManager.swift
//  TakePhoto
//
//  Created by EtekCity-刘廉俊 on 2020/11/30.
//

import UIKit
import AVFoundation

typealias LLJImageCallBack = (_ image: UIImage?) -> Void

// 按钮点击事件枚举
enum LLJButtonClick: Int {
    // 取消 拍照 切换前后摄像头
    case cancel, capture, transform
}

struct LLJConfig {
    struct Size {
        static let kScreenWidth = UIScreen.main.bounds.size.width     // 设备宽
        static let kScreenHeight = UIScreen.main.bounds.size.height   // 设备高
    }
    struct Color {
        static let kBottomBarBackgroundColor = UIColor(red: 20 / 225.0, green: 20 / 225.0, blue: 20 / 225.0, alpha: 1).withAlphaComponent(0.85) // 底部工具栏色值
    }
    struct Const {
        static let kBottonReclickDuration = 1.0 // 防止按钮重复点击时间间隔
    }
}

extension UIView {
    static func view(with frame: CGRect, backgroundColor: UIColor?, userEnable: Bool, superView: UIView?) -> UIView {
        let view = UIView(frame: frame)
        view.backgroundColor = backgroundColor
        view.isUserInteractionEnabled = userEnable
        superView?.addSubview(view)
        return view
    }
    static func button(with frame: CGRect, title: String?, image: UIImage?, tag: Int, target: Any?, action: Selector, superView: UIView?) -> UIButton {
        let button = UIButton(type: .custom)
        button.frame = frame
        button.setTitle(title, for: .normal)
        button.setImage(image, for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.tag = tag
        superView?.addSubview(button)
        return button
    }
    static func label(with text: String?, font: UIFont?, textColor: UIColor?, superView: UIView?) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = textColor
        label.sizeToFit()
        superView?.addSubview(label)
        return label
    }
    // 防止按钮重复点击
    func avoidReclick() {
        self.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + LLJConfig.Const.kBottonReclickDuration) {
            self.isUserInteractionEnabled = true
        }
    }
}

extension NSObject {
    // 获取bundle资源库图片
    static func getImage(name: String) -> UIImage? {
        var useBundle: Bundle?
        if let path = Bundle(for: LLJTakePhotoViewController.self).resourcePath?.appending("/TakePhotoBundle.bundle"),
            let bundle = Bundle(path: path) {
            useBundle = bundle
        } else if let path = Bundle(for: LLJTakePhotoViewController.self).resourcePath?.appending("/Frameworks/TakePhoto.framework/TakePhotoBundle.bundle"),
            let bundle = Bundle(path: path) {
            useBundle = bundle
        }
        guard let bundle = useBundle else { return nil }
        
        guard let image = UIImage(named: name, in: bundle, compatibleWith: nil) else {
            if let image = UIImage(named: name + ".jpg", in: bundle, compatibleWith: nil) {
                return image
            } else if let image = UIImage(named: name + ".png", in: bundle, compatibleWith: nil) {
                return image
            } else if let image = UIImage(named: name + ".jpeg", in: bundle, compatibleWith: nil) {
                return image
            }
            return nil
        }
        return image
    }
}

class LLJImageManager: NSObject {
    
    var block: LLJImageCallBack?
    
    private var canEdit: Bool
    private weak var fromVc: UIViewController?
    private var sourceType: UIImagePickerController.SourceType
    private lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = sourceType
        picker.modalPresentationStyle = .fullScreen
        return picker
    }()
    
    init(with sourceType: UIImagePickerController.SourceType, canEdit: Bool, fromVc: UIViewController) {
        self.fromVc = fromVc
        self.canEdit = canEdit
        self.sourceType = sourceType
        super.init()
        self.initialize()
    }
    
    private func initialize() {
        switch sourceType {
        case .photoLibrary:
            self.fromVc?.present(imagePicker, animated: true, completion: nil)
        case .camera:
            let vc = LLJTakePhotoViewController(with: self, self.canEdit)
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            self.fromVc?.present(nav, animated: true, completion: nil)
        default:
            break
        }
    }
}

extension LLJImageManager {
    // 获取图片回调
    func getImage(with callBack: LLJImageCallBack?) {
        self.block = callBack
    }
}

extension LLJImageManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let vc = LLJImageEditViewController(with: info[.originalImage] as? UIImage, type: .systemPhoto, canEdit: self.canEdit, delegate: self)
        imagePicker.pushViewController(vc, animated: true)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.imagePicker.dismiss(animated: true, completion: nil)
        self.block = nil
    }
}

extension LLJImageManager: LLJImageEditViewControllerDelegate {
    func selectPicture(with image: UIImage?) {
        self.block?(image)
        self.block = nil
    }
}
