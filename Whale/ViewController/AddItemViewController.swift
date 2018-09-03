//
//  AddItemViewController.swift
//  Whale
//
//  Created by Christian Braun on 02.09.18.
//  Copyright © 2018 KURZ Digital Solutions GmbH & Co. KG. All rights reserved.
//

import UIKit

class AddItemViewController: UIViewController {

    @IBOutlet weak var itemTextField: UITextField!


    fileprivate var items = Item.items()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Actions
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        guard let itemText = itemTextField.text, !itemText.isEmpty else {
            return
        }

        let item = Item(value: itemText)
        items.append(item)
        Item.save(items)

        dismiss(animated: true, completion: nil)
    }

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
