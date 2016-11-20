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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
        cell.crumbCityLabel.text = crumbs[indexPath.row].city
        cell.backgroundColor = UIColor.cyan
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
}

