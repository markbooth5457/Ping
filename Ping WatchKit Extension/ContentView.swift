//
//  ContentView.swift
//  Ping WatchKit Extension
//
//  Created by Mark Booth on 02/02/2020.
//  Copyright © 2020 Mark Booth. All rights reserved.
//

import SwiftUI
//import Combine

class State: ObservableObject {
    
    @Published var paddlePosition = 0.0
    //@State private var ballDestination = CGPoint(x: 70.5, y: 70.5)
    @Published var ballPosition = CGPoint(x: 0, y: 0)
     @Published var isRunning = false
     @Published var isPaused = false
     @Published var score = 0
     @Published var isBallAtEdge = false
    var radius : CGFloat = 1.0
    var circleCentre = CGPoint(x: 0, y: 0)
    var transitTime = 1.5
    var ballAngle = 0.0 // in: 0.0 ..< (2 * .pi)
    
    var collides : Bool {
        var paddleEnds = paddlePosition + Double.pi / 6
        
        if paddleEnds  < Double.pi * 2
        {
            return (paddlePosition <= ballAngle) && (ballAngle <= paddleEnds)
        }
        paddleEnds = paddleEnds - Double.pi * 2
        return ballAngle > paddlePosition || ballAngle < paddleEnds
         
    }

    func saveGeometry(geometry: GeometryProxy) {
        radius = min(geometry.size.width, geometry.size.height) / 2.0
        circleCentre = CGPoint(x: geometry.frame(in: .local).midX ,y: geometry.frame(in: .local).midY )
    }
    
    func edgePosFromAngle(angle: Double) -> CGPoint{
        ballAngle = angle // in: 0.0 ..< (2 * .pi)
        return CGPoint(x: self.circleCentre.x + (CGFloat(cos(angle)) * self.radius) ,
                       y: self.circleCentre.y + (CGFloat(sin(angle)) * self.radius))
    }
    
}

struct ContentView: View {
    @ObservedObject var state = State()

    
    fileprivate func doTap() {
        if !state.isRunning && !state.isPaused { //ready to start
            // self.isRunning.toggle()
            // pick a random direction and find the pos on the edge to move towards
            let dir = Double.random(in: 0.0 ..< (2 * .pi) )
            let newPos = state.edgePosFromAngle(angle:  dir)
            state.ballPosition = newPos
            print("\(state.collides ? "true" : "false")")
        } else {
            
        }
    }
    var body: some View {
        ZStack {
            VStack {
                Text("ballAngle: \(self.state.ballAngle)")
                Text("paddle: \(self.state.paddlePosition)")
                Text("y: \(self.state.ballPosition.y)")
            }.opacity(0.5)
            ZStack{
                GeometryReader { geometry in
                    Circle()
                        .stroke(style: .init(lineWidth: 1))
                        .opacity(0.5)
                        .onAppear(){
                            self.state.saveGeometry(geometry: geometry)
                            self.state.ballPosition =  self.state.circleCentre
                            
                        } // onappear
                        
                    Arc(startAngle: Angle(radians: self.state.paddlePosition),
                        endAngle: Angle(radians: self.state.paddlePosition + Double.pi / 6),
                    clockwise: true)
                        .stroke(Color.white, lineWidth: CGFloat( 5.0))
                        .focusable()
                        .digitalCrownRotation(self.$state.paddlePosition,
                                              from: 0.0,
                                              through: Double.pi * 2,
                                              by: Double.pi / 90,
                                              isContinuous: true)
                    
                    Ball(state: self.state)
                }// geometry
                
            } // zstack
                .padding(3)
        } // zstack
            .onTapGesture {
                self.doTap()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
//            ContentView()
//            .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 5 - 38mm"))
//            .previewDisplayName("38mm")
//            ContentView()
//            .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 5 - 40mm"))
//            .previewDisplayName("40mm")
//            ContentView()
//            .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 5 - 42mm"))
//            .previewDisplayName("42mm")
            ContentView()
            .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 5 - 44mm"))
            .previewDisplayName("44mm")
        }
    }
}
