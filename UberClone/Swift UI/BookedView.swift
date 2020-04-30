//
//  BookedView.swift
//  UberClone
//
//  Created by Chirag's on 30/04/20.
//  Copyright © 2020 Chirag's. All rights reserved.
//

import SwiftUI
import CoreLocation
import FirebaseFirestore
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
