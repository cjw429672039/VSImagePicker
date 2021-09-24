//
//  LLJImageEditViewController.swift
//  TakePhoto
//
//  Created by EtekCity-刘廉俊 on 2020/11/26.
//

import UIKit

protocol LLJImageEditViewControllerDelegate: NSObjectProtocol {
    func selectPicture(with image: UIImage?)
}

enum LLJImageEditType {
    case customCamera
    case systemCamera
    case systemPhoto
}

class LLJImageEditViewController: UIViewController {
    
    private var canEdit: Bool
    private var image: UIImage?
    private var sourceType: LLJImageEditType
    private weak var delegate: LLJImageEditViewControllerDelegate?
    
    // 初始化
    init(with image: UIImage?, type: LLJImageEditType, canEdit: Bool, delegate: LLJImageEditViewControllerDelegate?) {
        self.sourceType = type
        self.image = image
        self.delegate = delegate
        self.canEdit = canEdit
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.createSubView()
    }
    
    // MARK: 点击事件
    @objc private func click(_ sender: UIButton) {
        // 防止重复点击
        sender.avoidReclick()
        let type = LLJButtonClick(rawValue: sender.tag)
        switch type {
        case .cancel:
            if self.sourceType == .customCamera {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.dismiss(with: nil)
            }
        default:
            self.dismiss(with: self.captureImage())
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func createSubView() {
        
        self.view.backgroundColor = .black
        self.navigationController?.delegate = self
        
        let space = (LLJConfig.Size.kScreenHeight - LLJConfig.Size.kScreenWidth) / 2.0
        var safeBottom: CGFloat = 0.0
        if #available(iOS 11.0, *) { safeBottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0 }
        
        let buttonHeight: CGFloat = 73
        let buttonWidth: CGFloat = 90
        let scrollView = LLJZoomScrollView(frame: view.bounds, image: image)
        self.view.addSubview(scrollView)
        let bottomView = UIView.view(with: CGRect(x: 0,
                                                  y: LLJConfig.Size.kScreenHeight - safeBottom - buttonHeight,
                                                  width: LLJConfig.Size.kScreenWidth,
                                                  height: safeBottom + buttonHeight),
                                     backgroundColor: LLJConfig.Color.kBottomBarBackgroundColor,
                                     userEnable: true,
                                     superView: self.view)
        if self.canEdit {
            _ = UIView.view(with: CGRect(x: 0, y: space, width: LLJConfig.Size.kScreenWidth, height: LLJConfig.Size.kScreenWidth),
                            backgroundColor: UIColor.clear,
                            userEnable: false,
                            superView: self.view)
//            squareView.layer.borderColor = UIColor.lightGray.cgColor
//            squareView.layer.borderWidth = 1
        }
        
        var titleArr = [String]()
        switch self.sourceType {
        case .customCamera:
            titleArr = [VSImagePicker.cameraReplayTitle, VSImagePicker.cameraUseTitle]
        case .systemCamera:
            titleArr = [VSImagePicker.cancelImageTitle, VSImagePicker.cameraUseTitle]
        case .systemPhoto:
            titleArr = [VSImagePicker.cancelImageTitle, VSImagePicker.photoUseTitle]
        }
        for index in 0..<titleArr.count {
            if self.canEdit {
                let tmpView: UIView = UIView.view(with: CGRect(x: 0, y: CGFloat(index) * (space + LLJConfig.Size.kScreenWidth), width: LLJConfig.Size.kScreenWidth, height: space),
                                                  backgroundColor: UIColor.black.withAlphaComponent(0.6),
                                                  userEnable: false,
                                                  superView: nil)
                self.view.insertSubview(tmpView, aboveSubview: scrollView)
            }
            let button = UIButton.button(with: CGRect(x: (LLJConfig.Size.kScreenWidth - buttonWidth) * CGFloat(index), y: 0, width: buttonWidth, height: buttonHeight),
                                         title: titleArr[index],
                                         image: nil,
                                         tag: index,
                                         target: self,
                                         action: #selector(self.click(_:)),
                                         superView: bottomView)
            switch index {
            case 0:
                button.contentHorizontalAlignment = .left
                var rect = button.frame
                rect.origin.x = 20
                button.frame = rect
            default:
                button.contentHorizontalAlignment = .right
                var rect = button.frame
                rect.origin.x = LLJConfig.Size.kScreenWidth - 20 - rect.size.width
                button.frame = rect
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LLJImageEditViewController {
    // 获取选取的图片
    private func captureImage() -> UIImage? {
        if self.canEdit {
            let size = UIScreen.main.bounds.size
            UIGraphicsBeginImageContext(size)
            guard let context = UIGraphicsGetCurrentContext() else { return nil }
            view.layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            guard let imageRef = image?.cgImage?.cropping(to: CGRect(x: 0,
                                                                     y: (size.height - size.width) / 2.0,
                                                                     width: size.width,
                                                                     height: size.width)) else { return nil }
            return UIImage(cgImage: imageRef, scale: size.width / 200, orientation: .up)
        } else {
            return self.image
        }
    }
    // 退出当前控制器 并返回图片
    private func dismiss(with image: UIImage?) {
        self.dismiss(animated: true, completion: nil)
        self.delegate?.selectPicture(with: image)
    }
}

extension LLJImageEditViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
