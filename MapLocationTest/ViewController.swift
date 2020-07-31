//
//  ViewController.swift
//  MapLocationTest
//
//  Created by Abdulaziz Alharbi on 03/12/1441 AH.
//  Copyright © 1441 Abdulaziz Alharbi. All rights reserved.
//

import UIKit
import MapKit


class ViewController: UIViewController{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    var goButton: UIButton!
    
    var centerMaplOcationDot: UIView!
    
    var locationManager = CLLocationManager()
    
    var userCurrentLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        centerMaplOcationDot = UIView(frame: CGRect(x: self.mapView.bounds.width / 2, y: (self.mapView.bounds.height / 2) - 70, width: self.mapView.frame.width / 40, height: self.mapView.frame.height / 80))
//        centerMaplOcationDot = UIView(frame: CGRect(x: Int(self.mapView.frame.width / 2), y: Int(self.mapView.frame.height / 2), width: Int(self.mapView.frame.width / 40), height: Int(self.mapView.frame.height / 80)))
        centerMaplOcationDot.backgroundColor = .red
        centerMaplOcationDot.layer.cornerRadius = centerMaplOcationDot.frame.width / 2
        addressLabel.numberOfLines = 0
        
        goButton = UIButton(frame: CGRect(x: self.view.frame.width - 100, y: self.view.frame.height / 10, width: 80, height: 80))
        
        goButton.setTitle("Go", for: .normal) // what si .normal
        goButton.setTitleColor(.white, for: .normal)
        goButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        goButton.layer.cornerRadius = 40
        goButton.backgroundColor = .systemBlue
        goButton.addTarget(self, action: #selector(goToPressed), for: .touchUpInside)
        
        self.view.addSubview(goButton)
        self.view.addSubview(centerMaplOcationDot)
        
        checkLocationAuth()
        // Do any additional setup after loading the view.
    }
 
    
    func checkLocationAuth(){
        
        if CLLocationManager.locationServicesEnabled(){
           checkLocationStatus()
        }else{
            alertFunction(title: "Location is not avalible", locationStatus: LocationStatusCases.phoneLocationUnavaiable)
        }
    }
    
    
    func checkLocationStatus(){
        
        switch CLLocationManager.authorizationStatus(){
            
        case .authorizedAlways:
            userCurrentLocation = locationManager.location
            mapView.showsUserLocation = true
            
        break
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        break
        case .restricted:
            alertFunction(title: "Location Unavailable", locationStatus: LocationStatusCases.restricted)
        break
        case .denied:
            alertFunction(title: "Location Unavailable", locationStatus: LocationStatusCases.denied)
        break
        case .authorizedWhenInUse:
            userCurrentLocation = locationManager.location
            let center:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: userCurrentLocation!.coordinate.latitude, longitude: userCurrentLocation!.coordinate.longitude)
            mapView.showsUserLocation = true
            mapView.region = MKCoordinateRegion(center: center, latitudinalMeters: 1000, longitudinalMeters: 1000)
            locationManager.startUpdatingLocation()
            
            
        break
        @unknown default:
            print("the location status is not handeled which is \(CLLocationManager.authorizationStatus().rawValue)")
        }
        
    }
    
    func alertFunction(title: String, locationStatus: LocationStatusCases){
        
        let alert = UIAlertController(title: title, message: locationStatus.rawValue, preferredStyle: .alert)
        
        let alertActionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let alertActionAllow = UIAlertAction(title: "Allow", style: .default) { (AA) in
            print(AA)
        }
        alert.addAction(alertActionCancel)
        alert.addAction(alertActionAllow)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func getMapCenterLocation(map: MKMapView)-> CLLocation{
        
        let mapLat = map.centerCoordinate.latitude
        let mapLong = map.centerCoordinate.longitude

        return CLLocation(latitude: mapLat, longitude: mapLong)
    }
    
    func coordinateToAddress(location: CLLocation){
        
        let geoCoder = CLGeocoder()
        
        geoCoder.reverseGeocodeLocation(location, preferredLocale: nil) { (placeMark, error) in
            
            if let error = error {
                print("error while fetching data")
            }
            
            if let NewPlaceMark = placeMark?.first {
                
                let buildingNumber = NewPlaceMark.subThoroughfare ?? ""
                let streetName = NewPlaceMark.thoroughfare ?? ""
//                let placeName = NewPlaceMark. ?? ""
                
                DispatchQueue.main.async {
                    self.addressLabel.text = "\( buildingNumber ) \(streetName)"
                }
                
                
            }
            
            
        }
    
        
    }
    
    
    @objc func goToPressed(){
        startDirection()
    }
    
    func startDirection(){
        
        var request: MKDirections.Request = MKDirections.Request()
        
        let source = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: userCurrentLocation!.coordinate.latitude, longitude: userCurrentLocation!.coordinate.longitude))
        
        let destination = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude))

        request.source = MKMapItem(placemark: source)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        var direction: MKDirections = MKDirections(request: request)
        
        direction.calculate { (response, error) in
            
            guard error == nil else {
                print("error while calculating the route")
                print(error.debugDescription)
                return
            }
            
            guard (response?.routes) != nil else{
                print("unable to get the route")
                return
            }
            
            for route in response!.routes{
                self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                var boundary = route.polyline.boundingMapRect
                self.mapView.setVisibleMapRect(boundary, animated: true)
                
            }
            
            
        }
        
    }


}

// see if I can override the real location status and associate them with messages

enum LocationStatusCases: String {
    case phoneLocationUnavaiable = "plaese go to your phone settings and allow the location service"
    case restricted = "your location is restricted"
    case denied = "you have denied location auth"
}

extension ViewController: CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {return}
        
        userCurrentLocation = location
        let center = CLLocationCoordinate2D(latitude: userCurrentLocation!.coordinate.latitude, longitude: userCurrentLocation!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
    }
    
}

extension ViewController: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let mapCenterLocation = getMapCenterLocation(map: mapView)
        coordinateToAddress(location: mapCenterLocation)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        var overLayRender1 = MKPolygonRenderer(overlay: overlay)
        overLayRender1.strokeColor = .systemBlue
        overLayRender1.lineWidth = 1
        return overLayRender1
    }
    
    
    
}

