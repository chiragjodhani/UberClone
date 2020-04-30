//
//  MapView.swift
//  UberClone
//
//  Created by Chirag's on 30/04/20.
//  Copyright © 2020 Chirag's. All rights reserved.
//

import SwiftUI
import MapKit
import CoreLocation
struct MapView: UIViewRepresentable {
    func makeCoordinator() -> MapView.Coordinator {
        return MapView.Coordinator(self)
    }
    
    @Binding var map : MKMapView
    @Binding var manager : CLLocationManager
    @Binding var alert: Bool
    @Binding var source: CLLocationCoordinate2D!
    @Binding var destination: CLLocationCoordinate2D!
    @Binding var name: String
    @Binding var distance: String
    @Binding var time: String
    @Binding var show: Bool
    func makeUIView(context: UIViewRepresentableContext<MapView>) -> MKMapView {
        map.delegate = context.coordinator
        manager.delegate = context.coordinator
        map.showsUserLocation = true
        let gesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.tap(ges:)))
        map.addGestureRecognizer(gesture)
        return map
    }
    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<MapView>) {
        
    }
    class Coordinator: NSObject,MKMapViewDelegate,CLLocationManagerDelegate {
        var parent: MapView
        init(_ parent1: MapView) {
            parent = parent1
        }
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            if status == .denied {
                self.parent.alert.toggle()
            }else {
                self.parent.manager.startUpdatingLocation()
            }
        }
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            let region = MKCoordinateRegion(center: locations.last!.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
            self.parent.source = locations.last!.coordinate
            self.parent.map.region = region
        }
        @objc func tap(ges: UITapGestureRecognizer){
            let location = ges.location(in: self.parent.map)
            let mpLocation = self.parent.map.convert(location, toCoordinateFrom: self.parent.map)
            let point = MKPointAnnotation()
            point.subtitle = "Destination"
            
            point.coordinate = mpLocation
            self.parent.destination = mpLocation
            
            let decoder = CLGeocoder()
            decoder.reverseGeocodeLocation(CLLocation(latitude: mpLocation.latitude, longitude: mpLocation.longitude)) { (places, error) in
                if error != nil {
                    print(error?.localizedDescription ?? "")
                    return
                }
                self.parent.name = places?.first?.name ?? ""
                point.title = places?.first?.name ?? ""
                self.parent.show = true
            }
            
            let req = MKDirections.Request()
            req.source = MKMapItem(placemark: MKPlacemark(coordinate: self.parent.source))
            
            req.destination = MKMapItem(placemark: MKPlacemark(coordinate: mpLocation))
            
            let direction = MKDirections(request: req)
            direction.calculate { (dir, error) in
                if error != nil {
                    print(error?.localizedDescription ?? "")
                    return
                }
                let polyLine = dir?.routes[0].polyline
                
                let dis = dir?.routes[0].distance as! Double
                self.parent.distance = String(format: "%.1f", dis / 1000)
                
                let time = dir?.routes[0].expectedTravelTime as! Double
                self.parent.time = String(format: "%.1f", time / 60)
                self.parent.map.removeOverlays(self.parent.map.overlays)
                self.parent.map.addOverlay(polyLine!)
                
                self.parent.map.setRegion(MKCoordinateRegion(polyLine!.boundingMapRect), animated: true)
            }
            self.parent.map.removeAnnotations(self.parent.map.annotations)
            self.parent.map.addAnnotation(point)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let over = MKPolylineRenderer(overlay: overlay)
            over.strokeColor = .red
            over.lineWidth = 3
            return over
        }
    }
}


