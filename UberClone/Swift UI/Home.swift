//
//  Home.swift
//  UberClone
//
//  Created by Chirag's on 30/04/20.
//  Copyright © 2020 Chirag's. All rights reserved.
//

import SwiftUI
import MapKit
import CoreLocation
import FirebaseFirestore
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

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
