//
//  undefineView.swift
//  FlowerShop
//
//  Created by Lucas Saban on 15/07/2021.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class UndecidedViewController: UIViewController {

    var class_product: String!
    var productID: String!
    
    @IBOutlet weak var left_img: UIImageView!
    @IBOutlet weak var right_img: UIImageView!
    
    @IBOutlet weak var left_button: UIButton!
    @IBOutlet weak var right_button: UIButton!
    
    @IBOutlet weak var question: UILabel!
    
    var UndefinedProductCatalog: [String: [String: Any]]!
    var left: String!
    var right: String!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Read the product catalog from the plist file into the dictionary.
        if let path = Bundle.main.path(forResource: "UndefinedProductCatalog", ofType: "plist") {
            UndefinedProductCatalog = NSDictionary(contentsOfFile: path) as? [String: [String: Any]]
        }
    }
    
    fileprivate func showProductInfo(_ details: Dictionary<String, Any>) {
        // Perform all UI updates on the main queue.
        DispatchQueue.main.async(execute: {
            self.performSegue(withIdentifier: "UndecidedShowProductSegue", sender: details)

            
            
        })
        
    }
    
    @IBAction func left_answer(_ sender: UIButton) {
        self.productID = self.left
        self.showProductInfo(["identifier": self.productID, "cameFromRefSRC": false])
    }
    
    @IBAction func right_answer(_ sender: UIButton) {
        self.productID = self.right
        self.showProductInfo(["identifier": self.productID, "cameFromRefSRC": false])
    }


    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(class_product)
        self.question.text = UndefinedProductCatalog[self.class_product]?["question"] as? String
        self.left =  UndefinedProductCatalog[self.class_product]?["left"] as? String
        self.right =  UndefinedProductCatalog[self.class_product]?["right"] as? String
        if let productImage = UIImage(named: left + "_question.jpg") {
            self.left_img.image = productImage
        }
        
        if let productImage = UIImage(named: right + "_question.jpg") {
            self.right_img.image = productImage
    }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let productVC = segue.destination as? ProductViewController, segue.identifier == "UndecidedShowProductSegue" {
            if let details = sender as? Dictionary<String, Any> {
                productVC.details = details
            }
        }
}
}
