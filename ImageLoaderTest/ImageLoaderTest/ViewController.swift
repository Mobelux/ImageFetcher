//
//  ViewController.swift
//  ImageLoaderTest
//
//  Created by Jeremy Greenwood on 3/22/18.
//  Copyright © 2018 Mobelux. All rights reserved.
//

import UIKit
import ImageLoader

class ViewController: UIViewController {
    let imageLoader = ImageLoader()
    let imageURLs = [URL(string: "https://via.placeholder.com/50x50")!,
                     URL(string: "https://via.placeholder.com/100x100")!,
                     URL(string: "https://via.placeholder.com/150x150")!,
                     URL(string: "https://via.placeholder.com/200x200")!,
                     URL(string: "https://via.placeholder.com/250x250")!]

    override func viewDidLoad() {
        super.viewDidLoad()

        let imageConfigurations: [ImageConfiguration] = imageURLs.map {
            return ImageConfiguration(url: $0)
        }

        imageConfigurations.forEach { configuration in
            self.imageLoader.load(configuration, handler: nil)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            let task = self.imageLoader[imageConfigurations[0]]
            print(task)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

