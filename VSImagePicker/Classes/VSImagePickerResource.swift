//
//  UIButton+ECRx.swift
//
//
//  Created by HarveyChen on 2020/4/20.
//  Copyright © 2020 . All rights reserved.
//

import Foundation

class VSImagePickerResource {
    static func picture_close() -> UIImage? {
        return self.getImage(name: "picture_close")
    }
    
    static func picture_shoot() -> UIImage? {
        return self.getImage(name: "picture_shoot")
    }
    
    static func picture_swap() -> UIImage? {
        return self.getImage(name: "picture_swap")
    }
    
    static func getImage(name: String) -> UIImage? {
        var useBundle: Bundle?
        if let path = Bundle(for: VSImagePicker.self).resourcePath?.appending("/VSImagePickerResource.bundle"),
            let bundle = Bundle(path: path) {
            useBundle = bundle
        } else if let path = Bundle(for: VSImagePicker.self).resourcePath?.appending("/Frameworks/VSImagePicker.framework/VSImagePickerResource.bundle"),
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
