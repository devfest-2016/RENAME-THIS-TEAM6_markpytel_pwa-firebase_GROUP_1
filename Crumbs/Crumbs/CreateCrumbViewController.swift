//
//  CreateCrumbViewController.swift
//  Crumbs
//
//  Created by Forrest Zhao on 11/19/16.
//  Copyright © 2016 NY3. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseDatabase

class CreateCrumbViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    let store = DataStore.sharedInstance
    
    var locationManager: CLLocationManager!
    var placeInLineCounter = 1
    var locationList: [Location] = []
    var mapItemList: [MKMapItem] = []
    var city = ""
    var crumbKey = ""
    
    var searchController: UISearchController!
    var localSearchRequest: MKLocalSearchRequest!
    var localSearch: MKLocalSearch!
    var localSearchResponse: MKLocalSearchResponse!
    var error: NSError!
    var pointAnnotation: MKPointAnnotation!
    var pinAnnotationView:MKPinAnnotationView!
    
    let locationsRef = FIRDatabase.database().reference(withPath: "locations")
    let crumbsRef = FIRDatabase.database().reference(withPath: "crumbs")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placeInLineCounter = 1
        initGestures()
        setupLocationManager()
        mapView.delegate = self
        // Do any additional setup after loading the view.
        let orangeColor = hexStringToUIColor(hex: "#ffa907")
        navigationController?.navigationItem.leftBarButtonItem?.tintColor = orangeColor
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
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
    

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = true
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        saveCrumb()
    }
    
    @IBAction func routeButtonTapped(_ sender: UIBarButtonItem) {
        if mapItemList.count > 1 {
            //activityIndicator.startAnimating()
            calculateSegmentDirections(index: 0, time: 0, routes: [])
        }
    }

    @IBAction func trashButtonTapped(_ sender: UIBarButtonItem) {
        clearPins()
    }
    
    // MARK: - Firebase related methods
    
    func saveLocationToList(annotation: MKAnnotation) {
        var locationName = ""
        if let name = annotation.title {
            if let unwrappedName = name {
                locationName = unwrappedName
            }
        }
        let location = Location(crumbKey: crumbKey, name: locationName, latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, placeInLine: placeInLineCounter)
        placeInLineCounter += 1
        locationList.append(location)
    }
    
    func saveCrumb() {
        
        let saveAlert = UIAlertController(title: "New Bread Crumb", message: "Save your trail!", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let textField = saveAlert.textFields?.first, let text = textField.text else { return }
            let crumb = Crumb(name: text, userKey: self.store.uid, city: self.city)
            let childCrumbsRef = self.crumbsRef.childByAutoId()
            self.crumbKey = childCrumbsRef.key
            childCrumbsRef.setValue(crumb.toAnyObject())
            
            for (index, _) in self.locationList.enumerated() {
                print("index is \(index)")
                self.locationList[index].crumbKey = self.crumbKey
                let childLocationRef = self.locationsRef.childByAutoId()
                childLocationRef.setValue(self.locationList[index].toAnyObject())
            }
            
            let alertController = UIAlertController(title: nil, message: "Crumb saved", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
            self.present(alertController, animated: true, completion: {
                self.clearPins()
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        saveAlert.addTextField()
        saveAlert.addAction(saveAction)
        saveAlert.addAction(cancelAction)
        present(saveAlert, animated: true, completion: nil)
        
    }
    
}

// MARK: -  Location methods and setup

extension CreateCrumbViewController: CLLocationManagerDelegate {
    
    func setupLocationManager(){
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        centerMapOnCurrentLocation(location: location)
    }
    
    func centerMapOnCurrentLocation(location: CLLocation) {
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let span = MKCoordinateSpanMake(0.1, 0.1) //arbitrary span (about 2X2 miles i think)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }
    
}

// MARK: - MapView methods

extension CreateCrumbViewController: MKMapViewDelegate {
    
    func addAnnotation(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizerState.began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude), completionHandler: {(placemarks, error) -> Void in
                if error != nil {
                    print("Reverse geocoder failed with error" + (error?.localizedDescription)!)
                    return
                }
                
                if (placemarks?.count)! > 0 {
                    let pm = (placemarks?[0])!
                    // not all places have thoroughfare & subThoroughfare so validate those values
                    if let thoroughfare = pm.thoroughfare, let subThoroughfare = pm.subThoroughfare {
                        annotation.title = thoroughfare + ", " + subThoroughfare
                    }
                    else {
                        annotation.title = "Info not available"
                    }
                    annotation.subtitle = pm.subLocality
                    if let city = pm.locality {
                        self.city = city
                    }
                    self.mapView.addAnnotation(annotation)
                }
                else {
                    annotation.title = "Unknown Place"
                    self.mapView.addAnnotation(annotation)
                    print("Problem with the data received from geocoder")
                }
                let placemark = MKPlacemark(coordinate: annotation.coordinate)
                self.mapItemList.append(MKMapItem(placemark: placemark))
                self.saveLocationToList(annotation: annotation)
            })
        }
    }
    
    func clearPins() {
        mapView.removeAnnotations(mapView.annotations)
        locationList.removeAll()
        mapItemList.removeAll()
        mapView.removeOverlays(mapView.overlays)
    }
    
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
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
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

// MARK: - Gestures

extension CreateCrumbViewController {
    
    func initGestures() {
        let longPressMapGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.addAnnotation(_ :)) )
        mapView.addGestureRecognizer(longPressMapGesture)
    }

}

// MARK: - Search methods

extension CreateCrumbViewController: UISearchBarDelegate {
    
    @IBAction func showSearchBar(_ sender: AnyObject) {
        searchController = UISearchController(searchResultsController: nil)
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        present(searchController, animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        localSearchRequest = MKLocalSearchRequest()
        localSearchRequest.naturalLanguageQuery = searchBar.text
        localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.start { (localSearchResponse, error) -> Void in
            
            if localSearchResponse == nil {
                let alertController = UIAlertController(title: nil, message: "Place Not Found", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
            self.pointAnnotation = MKPointAnnotation()
            self.pointAnnotation.title = searchBar.text
            self.pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: localSearchResponse!.boundingRegion.center.latitude, longitude: localSearchResponse!.boundingRegion.center.longitude)
            
            self.pinAnnotationView = MKPinAnnotationView(annotation: self.pointAnnotation, reuseIdentifier: nil)
            self.mapView.centerCoordinate = self.pointAnnotation.coordinate
            self.mapView.addAnnotation(self.pinAnnotationView.annotation!)
            
            let placemark = MKPlacemark(coordinate: self.pointAnnotation.coordinate)
            self.mapItemList.append(MKMapItem(placemark: placemark))
            self.saveLocationToList(annotation: self.pointAnnotation)
        }
    }
}

extension CreateCrumbViewController {
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
}
