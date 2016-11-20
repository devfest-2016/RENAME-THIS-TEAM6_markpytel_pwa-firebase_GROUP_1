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
            if self.mapItemList.count > 1 {
                //activityIndicator.startAnimating()
                self.calculateSegmentDirections(index: 0, time: 0, routes: [])
            }
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
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationReuseId = "Place"
        var anView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationReuseId)
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationReuseId)
        } else {
            anView?.annotation = annotation
        }
        let pinImage = UIImage(named: "crumb")
        let size = CGSize(width: 30, height: 30)
        UIGraphicsBeginImageContext(size)
        pinImage!.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        anView?.image = resizedImage
        anView?.backgroundColor = UIColor.clear
        anView?.canShowCallout = false
        return anView
    }
   
}

extension ShowCrumbDetailViewController {
    
    func calculateSegmentDirections(index: Int, time: TimeInterval, routes: [MKRoute]) {
        let request: MKDirectionsRequest = MKDirectionsRequest()
        request.source = mapItemList[index]
        request.destination = mapItemList[index+1]
        request.requestsAlternateRoutes = true
        request.transportType = .walking
        let directions = MKDirections(request: request)
        
        directions.calculate { (response, error) in
            if let routeResponse = response?.routes {
                let quickestRouteForSegment: MKRoute = routeResponse.sorted(by: {$0.expectedTravelTime < $1.expectedTravelTime})[0]
                
                var timeVar = time
                var routesVar = routes
                
                routesVar.append(quickestRouteForSegment)
                timeVar += quickestRouteForSegment.expectedTravelTime
                
                if index+2 < self.mapItemList.count {
                    self.calculateSegmentDirections(index: index+1, time: timeVar, routes: routesVar)
                }
                else {
                    //self.activityIndicator.stopAnimating()
                    self.showRoute(routes: routesVar)
                }
            }
            else if let _ = error{
                let alert = UIAlertController(title: nil,
                                              message: "Directions not available.", preferredStyle: .alert)
                let okButton = UIAlertAction(title: "OK", style: .cancel)
                alert.addAction(okButton)
                self.present(alert, animated: true,
                             completion: nil)
            }
        }
        
    }
    
    func showRoute(routes: [MKRoute]) {
        for i in 0..<routes.count {
            print("plotting route # \(i)")
            plotPolyline(route: routes[i])
        }
    }
    
    func plotPolyline(route: MKRoute) {
        mapView.add(route.polyline)
        if mapView.overlays.count == 1 {
            mapView.setVisibleMapRect(route.polyline.boundingMapRect,
                                      edgePadding: UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0),
                                      animated: false)
        }
        else {
            let polylineBoundingRect =  MKMapRectUnion(mapView.visibleMapRect,
                                                       route.polyline.boundingMapRect)
            mapView.setVisibleMapRect(polylineBoundingRect,
                                      edgePadding: UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0),
                                      animated: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        if (overlay is MKPolyline) {
            if mapView.overlays.count == 1 {
                polylineRenderer.strokeColor =
                    UIColor.blue.withAlphaComponent(0.75)
            } else if mapView.overlays.count == 2 {
                polylineRenderer.strokeColor =
                    UIColor.green.withAlphaComponent(0.75)
            } else if mapView.overlays.count == 3 {
                polylineRenderer.strokeColor =
                    UIColor.red.withAlphaComponent(0.75)
            }
            polylineRenderer.lineWidth = 5
        }
        return polylineRenderer
    }
    

}
