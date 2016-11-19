//
//  ShowCrumbDetailViewController.swift
//  Crumbs
//
//  Created by Forrest Zhao on 11/19/16.
//  Copyright © 2016 NY3. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import FirebaseDatabase

class ShowCrumbDetailViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    let ref = FIRDatabase.database().reference(withPath: "locations")
    var crumbKey : String?
    var crumbDelegate : String?
    var locations: [Location] = []
    var mapItemList: [MKMapItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        queryForLocations {
            self.convertLocationsToMapItem()
            self.addAnnotationsToMap()
        }
        
    }
    
    //From CrumbsCollectionController get crumbKey, only identified by key. Then search through that,
    
    
    func queryForLocations(completion: @escaping () -> Void) {
        print("\(crumbDelegate) crumbKey =====")
        let query = ref.queryOrdered(byChild: "crumbKey").queryEqual(toValue: crumbDelegate)
        
        query.observe(.value, with: { snapshot in
            print(snapshot)
            var newLocations: [Location] = []
            for item in snapshot.children {
                let location = Location(snapshot: item as! FIRDataSnapshot)
                newLocations.append(location)
            }
            self.locations = newLocations
            completion()
            
        })
        
        
    }
    
    func convertLocationsToMapItem() {
        print("location called")
        print(locations)
        for location in locations {
            print("location called")
            let placemark = MKPlacemark(coordinate: CLLocationCoordinate2DMake(location.latitude, location.longitude))
            mapItemList.append(MKMapItem(placemark: placemark))
        }
    }
    
    func addAnnotationsToMap() {
        var annotations: [MKAnnotation] = []
        for item in mapItemList {
            let annotation = MKPointAnnotation()
            annotation.coordinate = item.placemark.coordinate
            annotations.append(annotation)
            print("Annotations: \(annotations)")
        }
        print("Annotations: \(annotations)")
        let region = MKCoordinateRegion(center: annotations[0].coordinate, span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04))
        mapView.setRegion(region, animated: true)
        mapView.addAnnotations(annotations)
    }
   

}
