//
//  CustomAnnotationView.swift
//  Crumbs
//
//  Created by Forrest Zhao on 11/19/16.
//  Copyright © 2016 NY3. All rights reserved.
//

import UIKit

class CustomAnnotationView: UIView {

    @IBOutlet weak var annotationViewImage: UIImageView!
    
    @IBOutlet weak var annotationViewLabel: UILabel!
    
    @IBOutlet weak var descriptionTextView: UITextView!
    
    @IBAction func editDescriptionTapped(_ sender: UIButton) {
    }
}
