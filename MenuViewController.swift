//
//  SwiftUIView.swift
//  FlowerShop
//
//  Created by Lucas Saban on 12/07/2021.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import SwiftUI
import SafariServices

@available(iOS 13.0, *)
class MenuViewControler: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, SFSafariViewControllerDelegate{
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    var refToLabel: [String: String]!
    var ids: Array<String> = []
    var filteredId: Array<String> = []
    var ProductID: String!
    var details: Dictionary<String, Any>!
    
    var cameFromRefSRC: Bool = false
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredId.count
    }
    
    @IBAction func paniStats(_ sender: UIButton) {
        if let url = URL(string: "https://panicoupe.fr/societe-panicoupe-distributeur/"){
            let vc = SFSafariViewController(url: url)
                vc.delegate = self

                present(vc, animated: true)}
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = filteredId[indexPath.row]
        return cell
    }
    
    
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true)
    }
    
    fileprivate func showProductInfo(_ identifier: String, cameFromRefSRC: Bool) {
        self.performSegue(withIdentifier: "directProductSegue", sender: ["identifier": identifier, "cameFromRefSRC": cameFromRefSRC])
    }
    
    
     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let productID = self.refToLabel[filteredId[indexPath.row]]!
        showProductInfo(productID, cameFromRefSRC: true)
        }
    
    
    @IBAction func GoToPanicoupeSite(_ sender: UIButton) {
        if let url = URL(string: "http://www.panicoupe.fr"){
            let vc = SFSafariViewController(url: url)
                vc.delegate = self

                present(vc, animated: true) }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Read the product catalog from the plist file into the dictionary.
        if let path = Bundle.main.path(forResource: "refToId", ofType: "plist") {
            self.refToLabel = NSDictionary(contentsOfFile: path) as? [String: String]
        }
    }
        
    override func viewDidLoad() {
        self.tableView.allowsSelection = true

        super.viewDidLoad()
        ids = Array(self.refToLabel.keys)


        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TableCell")
        filteredId = Array(self.refToLabel.keys)
        tableView.dataSource = self
        searchBar.delegate = self

    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // When there is no text, filteredData is the same as the original data
        // When user has entered text into the search box
        // Use the filter method to iterate over all items in the data array
        // For each item, return true if the item should be included and false if the
        // item should NOT be included
        filteredId = searchText.isEmpty ? ids : ids.filter { (item: String) -> Bool in
            // If dataItem matches the searchText, return true to include it
            return item.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        }
        
        tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            self.searchBar.showsCancelButton = true
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.showsCancelButton = false
            searchBar.text = ""
            searchBar.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if let productVC = segue.destination as? ProductViewController, segue.identifier == "directProductSegue" {
            if let details = sender as? Dictionary<String, Any> {
                productVC.details = details
            }
        }

}
}
@IBDesignable extension UIButton {

    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }

    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }

    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}
