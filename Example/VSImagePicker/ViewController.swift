//
//  ViewController.swift
//  VSImagePicker
//
//  Created by cjw429672039 on 11/06/2020.
//  Copyright (c) 2020 cjw429672039. All rights reserved.
//

import UIKit
import VSImagePicker

class ViewController: UIViewController, VSImagePickerProtocol {
    func getImage(image: UIImage) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func camera(_ sender: UIButton) {
        self.imagePicker.takeCameraImage()
    }
    
    @IBAction func photos(_ sender: UIButton) {
        self.imagePicker.takePhotosImage()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
