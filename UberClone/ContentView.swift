//
//  ContentView.swift
//  UberClone
//
//  Created by Chirag's on 24/04/20.
//  Copyright © 2020 Chirag's. All rights reserved.
//

import SwiftUI
import MapKit
import CoreLocation
import FirebaseFirestore
struct ContentView: View {
    var body: some View {
        Home()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct Home: View {
    @State var map  = MKMapView()
    @State var manager = CLLocationManager()
    @State var alert: Bool = false
    @State var source: CLLocationCoordinate2D!
    @State var destination: CLLocationCoordinate2D!
    @State var name = ""
    @State var distance = ""
    @State var time = ""
    @State var show = false
    @State var loading = false
    @State var book = false
    @State var doc = ""
    @State var data: Data = .init(count: 0)
    var body: some View {
        ZStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 15) {
                            Text(self.destination != nil ? "Destination" : "Pick a Location").font(.title)
                            if destination != nil {
                                Text(self.name).fontWeight(.bold)
                                
                            }
                        }
                        Spacer()
                    }.padding()
                        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top)
                        .background(Color.white)
                    MapView(map: self.$map, manager: self.$manager, alert: self.$alert, source: self.$source, destination: self.$destination, name: self.$name, distance: self.$distance, time: self.$time, show: self.$show).onAppear {
                        self.manager.requestAlwaysAuthorization()
                    }
                }
                if distance != nil  && self.show {
                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 20) {
                            HStack {
                                VStack(alignment: .leading,spacing: 15){
                                    Text("Distanation").fontWeight(.bold)
                                    Text(self.name)
                                    
                                    Text("Distance - "+self.distance+" KM")
                                    Text("Expexted Time - "+self.time+" Min")
                                }
                                Spacer()
                            }
                            Button(action: {
                                self.loading.toggle()
                                self.Book()
                            }){
                                Text("Book Now")
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .frame(width: UIScreen.main.bounds.width / 2)
                            }
                            .background(Color.red)
                        .clipShape(Capsule())
                        }
                        Button(action: {
                            self.map.removeOverlays(self.map.overlays)
                            self.map.removeAnnotations(self.map.annotations)
                            self.destination = nil
                            self.show.toggle()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom)
                    .background(Color.white)
                }
            }
            if self.loading {
                Loader()
            }
            
            if self.book {
                Booked(data: self.$data, doc: self.$doc, loading: self.$loading, book: self.$book)
            }
        }
        .edgesIgnoringSafeArea(.all)
            .alert(isPresented: self.$alert) { () -> Alert in
                Alert(title: Text("Error"), message: Text("Please Enable your Location in Setting!!!"), dismissButton: .destructive(Text("Ok")))
        }
    }
    func Book(){
        let db = Firestore.firestore()
        let doc = db.collection("Booking").document()
        self.doc = doc.documentID
        let from = GeoPoint(latitude:self.source.latitude, longitude: self.source.longitude)
        let to = GeoPoint(latitude:self.destination.latitude, longitude: self.destination.longitude)
        doc.setData(["name":"Eryushion","from": from, "to": to, "distance": self.distance, "fair": (self.distance as NSString).floatValue * 1.2]) { (error) in
            if error != nil {
                print(error?.localizedDescription)
                return
            }
            let filter = CIFilter(name: "CIQRCodeGenerator")
            filter?.setValue(self.doc.data(using: .ascii), forKey: "inputMessage")
            let image = UIImage(ciImage: (filter?.outputImage?.transformed(by: CGAffineTransform(scaleX: 5, y: 5)))!)
            self.data = image.pngData()!
            self.loading.toggle()
            self.book.toggle()
        }
        
    }
}

struct Loader: View {
    @State var show = false
    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 20) {
                Circle().trim(from: 0, to: 0.7)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 4, lineCap: .round)).frame(width: 30, height: 30)
                    .rotationEffect(.init(degrees: self.show ? 360 : 0)).onAppear {
                        withAnimation(Animation.default.speed(0.5).repeatForever(autoreverses: false)) {
                            self.show.toggle()
                        }
                }
                Text("Please Wait.......")
                    .padding(.bottom, 20)
            }
            .padding(.top, 25)
            .padding(.horizontal, 40)
            .background(Color.white)
            .cornerRadius(12)
        }
        .background(Color.black.opacity(0.25).edgesIgnoringSafeArea(.all))
        
    }
}
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

struct Booked: View {
    @Binding var data: Data
    @Binding var doc: String
    @Binding var loading: Bool
    @Binding var book: Bool
    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 25) {
                Image(uiImage: UIImage(data: self.data)!)
                    .frame(width: UIScreen.main.bounds.width - 64)
                    .padding()
                Button(action: {
                    self.loading.toggle()
                    self.book.toggle()
                    let db = Firestore.firestore()
                    db.collection("Booking").document(self.doc).delete { (error) in
                        if error != nil {
                            print(error?.localizedDescription)
                            return
                        }
                        self.loading.toggle()
                    }
                }) {
                    Text("Cancel")
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .frame(width: UIScreen.main.bounds.width / 2)
                }
                .background(Color.red)
                .clipShape(Capsule())
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }.background(Color.black.opacity(0.25).edgesIgnoringSafeArea(.all))
    }
}
