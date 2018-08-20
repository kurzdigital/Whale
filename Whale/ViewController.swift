//
//  ViewController.swift
//  Whale
//
//  Created by Christian Braun on 20.08.18.
//  Copyright © 2018 KURZ Digital Solutions GmbH & Co. KG. All rights reserved.
//

import UIKit
import WAL

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        WebRTCConnection().test()
    }
}

