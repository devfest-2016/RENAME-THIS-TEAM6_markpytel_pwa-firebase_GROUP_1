//
//  CrumbsCollectionViewController.swift
//  Crumbs
//
//  Created by Forrest Zhao on 11/19/16.
//  Copyright © 2016 NY3. All rights reserved.
//

import UIKit
import FirebaseDatabase

private let reuseIdentifier = "crumbCell"

class CrumbsCollectionViewController: UICollectionViewController {
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate let itemsPerRow: CGFloat = 1
    
    
    let ref = FIRDatabase.database().reference(withPath: "crumbs")
    var crumbs: [Crumb] = []
    let cityImageDict: [String: UIImage] = ["New York": UIImage(named: "nyc")!,
                                            "Salford": UIImage(named: "manchester")!,
                                            "San Francisco": UIImage(named: "sf")!,
                                            "Seoul": UIImage(named: "seoul")!,
                                            "Shanghai": UIImage(named: "shanghai")!]

    override func viewDidLoad() {
        super.viewDidLoad()

        
        let orangeColor = hexStringToUIColor(hex: "#ffa907")
        
        tabBarController?.tabBar.tintColor = UIColor.white
        tabBarController?.tabBar.barTintColor = orangeColor
        //tabBarController?.tabBar.backgroundColor = orangeColor
        tabBarController?.tabBar.isTranslucent = false
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = false
        ref.observe(.value, with: { snapshot in
            var newCrumbs: [Crumb] = []
            for item in snapshot.children {
                let crumb = Crumb(snapshot: item as! FIRDataSnapshot)
                newCrumbs.append(crumb)
            }
            self.crumbs = newCrumbs
            self.collectionView?.reloadData()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetailCrumb" {
            let dest = segue.destination as! ShowCrumbDetailViewController
            if let cell = sender as? UICollectionViewCell, let indexPath = collectionView?.indexPath(for: cell) {
                print("\(crumbs[indexPath.row].key) crumbDelegate")
                dest.crumbDelegate = crumbs[indexPath.row].key
            }
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return crumbs.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)) as! CrumbCell
        cell.crumbNameLabel.text = crumbs[indexPath.row].name
        let cityName = crumbs[indexPath.row].city
        cell.crumbCityLabel.text = cityName
        cell.buttonStackView.isHidden = true
        let imageView = UIImageView(image: cityImageDict[cityName]!)
        imageView.contentMode = .scaleAspectFit
        cell.backgroundView = imageView
//        cell.cityImage.image = cityImageDict[cityName]
//        cell.backgroundColor = UIColor.cyan
        return cell
        
    }
    
 



}


extension CrumbsCollectionViewController: UICollectionViewDelegateFlowLayout {
    //1
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //2
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    //3
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // 4
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.characters.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
}



