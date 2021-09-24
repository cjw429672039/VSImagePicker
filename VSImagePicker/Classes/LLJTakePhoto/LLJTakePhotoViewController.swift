//
//  LLJTakePhotoViewController.swift
//  TakePhoto
//
//  Created by EtekCity-刘廉俊 on 2020/11/30.
//

import UIKit
import AVFoundation

class LLJTakePhotoViewController: UIViewController {
    
    private var canEdit: Bool
    private var device: AVCaptureDevice?
    private var session: AVCaptureSession?
    private var input: AVCaptureDeviceInput?
    private var photoOutput: AVCaptureOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private weak var delegate: LLJImageEditViewControllerDelegate?
    
    private lazy var animation: CATransition = {
        let animation = CATransition()
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.type = CATransitionType(rawValue: "oglFlip")
        return animation
    }()
    
    private lazy var focusView: UIView = {
        let view = UIView.view(with: CGRect(x: 0, y: 0, width: 80, height: 80), backgroundColor: .clear, userEnable: false, superView: self.view)
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemYellow.cgColor
        view.isHidden = true
        return view
    }()
    
    private lazy var alertLab: UILabel = {
        let lab = UILabel.label(with: "未获取相机权限", font: UIFont.systemFont(ofSize: 16), textColor: .white, superView: self.view)
        lab.center = CGPoint(x: LLJConfig.Size.kScreenWidth / 2.0, y: (LLJConfig.Size.kScreenHeight - 100) / 2.0)
        return lab
    }()
    
    init(with delegate: LLJImageEditViewControllerDelegate?, _ canEdit: Bool) {
        self.delegate = delegate
        self.canEdit = canEdit
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initialize()
        self.createSubView()
        self.addTapGesture()
        
        guard self.isCameraDeviceAvailable() else {
            self.alertLab.text = "暂无可用摄像头"
            self.alertLab.sizeToFit()
            let center = CGPoint(x: LLJConfig.Size.kScreenWidth / 2.0, y: self.alertLab.center.y)
            self.alertLab.center = center
            return
        }
        
        AVCaptureDevice.requestAccess(for: .video) { (granted) in
            DispatchQueue.main.async {
                if granted == false {
                    _ = self.alertLab
                }
            }
        }
    }
    
    // MARK: 事件处理相关
    // 点击事件
    @objc private func clickBtn(_ sender: UIButton) {
        // 防止按钮重复点击
        sender.avoidReclick()
        let type = LLJButtonClick(rawValue: sender.tag)
        switch type {
        case .cancel:
            self.dismiss(animated: true, completion: nil)
        case .capture:
            self.capturePhoto()
        default:
            self.transformCamera()
        }
    }
    
    // 相机对焦
    @objc private func focusTap(_ tap: UITapGestureRecognizer) {
        
        guard let device = self.device else { return }
        if ((try? device.lockForConfiguration()) == nil) { return }
        let location = tap.location(in: tap.view)
        guard let size = previewLayer?.bounds.size else { return }
        let focusPoint = CGPoint(x: location.y / size.height, y: 1 - location.x / size.width)
        device.focusPointOfInterest = focusPoint
        device.exposurePointOfInterest = focusPoint
        if device.isExposureModeSupported(.autoExpose) {
            device.exposureMode = .autoExpose
        }
        if device.isFocusModeSupported(.autoFocus) {
            device.focusMode = .autoFocus
        }
        device.unlockForConfiguration()
        self.focusView.center = location
        self.focusView.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }, completion: { (_) in
            UIView.animate(withDuration: 0.45, animations: {
                self.focusView.transform = .identity
            }, completion: { (_) in
                self.focusView.isHidden = true
            })
        })
    }
    
    // 初始化
    private func initialize() {
        let session = AVCaptureSession()
        if UIDevice.current.userInterfaceIdiom == .phone {
            session.sessionPreset = AVCaptureSession.Preset.vga640x480
        } else {
            session.sessionPreset = AVCaptureSession.Preset.photo
        }
        // 设置为高分辨率
        if session.canSetSessionPreset(AVCaptureSession.Preset(rawValue: "AVCaptureSessionPreset1280x720")) {
            session.sessionPreset = AVCaptureSession.Preset(rawValue: "AVCaptureSessionPreset1280x720")
        }
        
        if #available(iOS 10.0, *) {
            photoOutput = AVCapturePhotoOutput()
        } else {
            photoOutput = AVCaptureStillImageOutput()
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        if UIImagePickerController.isCameraDeviceAvailable(.rear) {
            self.device = camera(with: .back)
        } else {
            self.device = camera(with: .front)
        }
        
        guard let device = self.device else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if #available(iOS 10.0, *) {
            guard let photoOutput = self.photoOutput as? AVCapturePhotoOutput else { return }
            photoOutput.photoSettingsForSceneMonitoring = self.getSettings()
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
        } else {
            guard let photoOutput = self.photoOutput as? AVCaptureStillImageOutput else { return }
            photoOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
        }
        session.startRunning()
        switch isPad() {
        case true:
            previewLayer.frame = CGRect(x: 0, y: 0, width: LLJConfig.Size.kScreenWidth, height: LLJConfig.Size.kScreenHeight)
        default:
            let layerHeight = LLJConfig.Size.kScreenWidth * 4 / 3
            let layerFrame = CGRect(x: 0,
                                    y: LLJConfig.Size.kScreenHeight/2 - layerHeight/2 - 12,
                                    width: LLJConfig.Size.kScreenWidth,
                                    height: layerHeight)
            previewLayer.frame = layerFrame
        }
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)
        
        self.input = input
        self.session = session
        self.previewLayer = previewLayer
    }
    
    func isPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(focusTap(_:)))
        self.view.addGestureRecognizer(tap)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // 创建子视图
    private func createSubView() {
        let layerHeight = LLJConfig.Size.kScreenWidth * 4 / 3
        let layerY = LLJConfig.Size.kScreenHeight/2 - layerHeight/2 - 12
        
        self.navigationController?.delegate = self
        self.view.backgroundColor = .black
        let buttonWidth: CGFloat = 80
        var safeBottom: CGFloat = 0.0
        if #available(iOS 11.0, *) { safeBottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0 }
        let buttonHeight: CGFloat = isPad() ? 180 : LLJConfig.Size.kScreenHeight - (layerY + layerHeight) - safeBottom
        let tmpV = UIView.view(with: CGRect(x: 0,
                                            y: LLJConfig.Size.kScreenHeight - (safeBottom + buttonHeight),
                                            width: LLJConfig.Size.kScreenWidth,
                                            height: safeBottom + buttonHeight),
                               backgroundColor: LLJConfig.Color.kBottomBarBackgroundColor,
                               userEnable: true,
                               superView: self.view)
        
        let arr = [VSImagePickerResource.picture_close(), VSImagePickerResource.picture_shoot(), VSImagePickerResource.picture_swap()]
        for index in 0..<arr.count {
            let space: CGFloat = (LLJConfig.Size.kScreenWidth - buttonWidth * 3) / 2.0
            _ = UIButton.button(with: CGRect(x: (space + buttonWidth) * CGFloat(index),
                                             y: 0,
                                             width: buttonWidth,
                                             height: buttonHeight),
                                title: nil,
                                image: arr[index],
                                tag: index,
                                target: self,
                                action: #selector(clickBtn(_:)),
                                superView: tmpV)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LLJTakePhotoViewController {
   
    // 拍照
    private func capturePhoto() {
        if !self.authorizationAvailable() || !self.isCameraDeviceAvailable() { return }
        if #available(iOS 10.0, *) {
            guard let photoOutput = self.photoOutput as? AVCapturePhotoOutput else { return }
            photoOutput.capturePhoto(with: self.getSettings(), delegate: self)
        } else {
            guard let photoOutput = self.photoOutput as? AVCaptureStillImageOutput else { return }
            guard let connection = photoOutput.connection(with: .video) else { return }
            photoOutput.captureStillImageAsynchronously(from: connection) {[weak self] (sampleBuffer, _) in
                guard let self = self else { return }
                guard let sampleBuffer = sampleBuffer else { return }
                guard let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer) else { return }
                let vc = LLJImageEditViewController(with: self.isPad() ? UIImage(data: data) : UIImage(data: data)?.crop(ratio: 3/4.0),
                                                    type: .customCamera,
                                                    canEdit: self.canEdit,
                                                    delegate: self.delegate)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    // 切换摄像头
    private func transformCamera() {
        var newDevice: AVCaptureDevice?
        
        guard let position = self.input?.device.position else { return }
        
        if position == .front && !UIImagePickerController.isCameraDeviceAvailable(.front) { return }
        if position == .back && !UIImagePickerController.isCameraDeviceAvailable(.rear) { return }
        if position == .front {
            newDevice = camera(with: .back)
            self.animation.subtype = .fromLeft
        } else {
            newDevice = camera(with: .front)
            self.animation.subtype = .fromRight
        }
        
        guard let device = newDevice else { return }
        guard let newInput = try? AVCaptureDeviceInput(device: device) else { return }
        guard let session = self.session else {  return }
        
        self.previewLayer?.add(self.animation, forKey: nil)
        session.beginConfiguration()
        guard let input = self.input else { return }
        session.removeInput(input)
        if session.canAddInput(newInput) {
            session.addInput(newInput)
        }
        self.input = newInput
        session.commitConfiguration()
    }
    // 相机设置相关
    @available(iOS 10.0, *)
    private func getSettings() -> AVCapturePhotoSettings {
        return AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])
    }
    // 是否已经授权
    private func authorizationAvailable() -> Bool {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized { return true }
        return false
    }
    // 摄像头是否可用
    private func isCameraDeviceAvailable() -> Bool {
        if !UIImagePickerController.isCameraDeviceAvailable(.front) && !UIImagePickerController.isCameraDeviceAvailable(.rear) { return false }
        return true
    }
    // 返回设备信息
    private func camera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if #available(iOS 10.0, *) {
            let deviceSession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: .video, position: position)
            for device in deviceSession.devices {
                if device.position == position { return device }
            }
        } else {
            let devices = AVCaptureDevice.devices(for: .video)
            for device in devices {
                if device.position == position { return device }
            }
        }
        return nil
    }
}

extension LLJTakePhotoViewController: AVCapturePhotoCaptureDelegate {
    @available(iOS 10.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
                     previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                     resolvedSettings: AVCaptureResolvedPhotoSettings,
                     bracketSettings: AVCaptureBracketedStillImageSettings?,
                     error: Error?) {
        guard let photoBuffer = photoSampleBuffer else { return }
        guard let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoBuffer,
                                                                          previewPhotoSampleBuffer: previewPhotoSampleBuffer) else { return }
        let vc = LLJImageEditViewController(with: isPad() ? UIImage(data: data) : UIImage(data: data)?.crop(ratio: 3/4.0),
                                            type: .customCamera,
                                            canEdit: self.canEdit,
                                            delegate: self.delegate)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension LLJTakePhotoViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

extension UIImage {
    func crop(ratio: CGFloat) -> UIImage {
        //计算最终尺寸
        var newSize: CGSize
        if size.width/size.height > ratio {
            newSize = CGSize(width: size.height * ratio, height: size.height)
        } else {
            newSize = CGSize(width: size.width, height: size.width / ratio)
        }
        
        ////图片绘制区域
        var rect = CGRect.zero
        rect.size.width  = size.width
        rect.size.height = size.height
        rect.origin.x    = (newSize.width - size.width ) / 2.0
        rect.origin.y    = (newSize.height - size.height ) / 2.0
        
        //绘制并获取最终图片
        UIGraphicsBeginImageContext(newSize)
        draw(in: rect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
}
