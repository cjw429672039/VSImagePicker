//
//  LLJZoomScrollView.swift
//  TakePhoto
//
//  Created by EtekCity-刘廉俊 on 2020/11/26.
//

import UIKit

class LLJZoomScrollView: UIScrollView {
    
    private lazy var imageView: UIImageView = {
        let imageV = UIImageView()
        imageV.contentMode = .scaleAspectFit
        imageV.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(imageV)
        return imageV
    }()
    
    // 初始化
    init(frame: CGRect, image: UIImage?) {
        super.init(frame: frame)
        
        self.initialize()
        self.createSubView(image)
    }
    
    private func initialize() {
        self.delegate = self
        self.minimumZoomScale = 1
        self.maximumZoomScale = 3
        self.backgroundColor = .clear
        self.alwaysBounceVertical = true
        self.alwaysBounceHorizontal = true
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if #available(iOS 11.0, *) { contentInsetAdjustmentBehavior = .never }
    }

    private func createSubView(_ image: UIImage?) {
        guard let tempImage = image else { return }
        
        let rate = tempImage.size.width / tempImage.size.height
        let height = self.frame.size.width / rate
        
        self.imageView.image = tempImage
        self.imageView.frame = CGRect(x: 0, y: rate >= 1.0 ? (frame.size.width - height) / 2.0 : 0, width: frame.size.width, height: height)
        
        self.contentSize = self.imageView.frame.size
        self.contentInset = UIEdgeInsets(top: (frame.size.height - frame.size.width) / 2.0, left: 0, bottom: (frame.size.height - frame.size.width) / 2.0, right: 0)
        if rate < 1.0 { self.contentOffset = CGPoint(x: 0, y: (height - frame.size.height) / 2.0) }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented")
    }
}

extension LLJZoomScrollView: UIScrollViewDelegate {
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        var imageViewRect = self.imageView.frame
        let imageViewWidth = self.imageView.frame.size.width
        let imageViewHeight = self.imageView.frame.size.height
        let scrollWidth = frame.size.width - contentInset.left - contentInset.right
        let scrollHeight = frame.size.height - contentInset.top - contentInset.bottom
        imageViewRect.origin.x = max((scrollWidth - imageViewWidth) / 2, 0)
        imageViewRect.origin.y = max((scrollHeight - imageViewHeight) / 2, 0)
        self.imageView.frame = imageViewRect
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}
