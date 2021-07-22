/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements a view controller introducing each flower product.
*/

import UIKit
import AVFoundation
import Vision
import SafariServices

class ProductViewController: UIViewController, SFSafariViewControllerDelegate {
    @IBOutlet weak var misClass: UIButton!
    
    @IBOutlet var productView: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var productPhoto: UIImageView!
    @IBOutlet weak var descriptionText: UITextView!
    
    var url_input: String!
    var cameFromRefSRC: Bool = true
    
    @IBAction func Command(_ sender: Any) {
        if let url = URL(string: url_input){
            let vc = SFSafariViewController(url: url)
                vc.delegate = self

                present(vc, animated: true)
        }}
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true)
    }
    var details: Dictionary<String, Any>!
    var productID: String!

    var productCatalog: [String: [String: Any]]!
    
    @IBAction func dismissProductView(_ sender: Any) {
        dismiss(animated: true) {
            
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Read the product catalog from the plist file into the dictionary.
        if let path = Bundle.main.path(forResource: "ProductCatalog", ofType: "plist") {
            productCatalog = NSDictionary(contentsOfFile: path) as? [String: [String: Any]]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Give the view rounded corners.
        productView.layer.cornerRadius = 10
        productView.layer.masksToBounds = true
        
        if details.count == 2 {
            self.productID = details["identifier"] as? String
            self.cameFromRefSRC = details["cameFromRefSRC"] as! Bool
        }
        
        misClass.isHidden = cameFromRefSRC
        
        if productID != nil {
            guard productCatalog[productID] != nil else {
                return
            }
            label.text = productCatalog[productID]?["label"] as? String
            descriptionText.text = productCatalog[productID]?["description"] as? String
            if let productImage = UIImage(named: productID + ".jpg") {
                productPhoto.image = productImage
            }
            
            url_input = productCatalog[productID]?["url"] as? String
        }
    }
}
