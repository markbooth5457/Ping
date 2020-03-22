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
    enum RunState : String {
        case ready = "Ready"
        case running = "Running"
        case paused = "Paused"
        case ended = "Ended"
    }
    @Published var paddlePosition = 0.0
    //@State private var ballDestination = CGPoint(x: 70.5, y: 70.5)
    @Published var ballPosition = CGPoint(x: 0, y: 0)
   var score = 0 {
        willSet {
            objectWillChange.send()
        }
    }
    var runState = RunState.ready
    var radius : CGFloat = 1.0
    var circleCentre = CGPoint(x: 0, y: 0)
    var transitTime = 2.0
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
    func reschedule() {
        DispatchQueue.main.asyncAfter(deadline: .now() + transitTime, execute: {
            if self.collides {
                self.score += 1
                self.transitTime -= 0.01
                self.ballPosition = self.edgePosFromAngle(angle: abs(self.ballAngle - Double.pi))
                self.reschedule()
            } else {
                self.score = 0
                self.runState = .ended
            }
        })
    }
}

class ReadySetGo: ObservableObject {
    var rsg = "" {
        willSet {
            objectWillChange.send()
        }
    }
    init() {

    }
    func runRSG() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {self.rsg = "Ready"})
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {self.rsg = "Set"})
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {self.rsg = "Go"})
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: {
            self.rsg = ""
        })
    }
}


struct ContentView: View {
    @ObservedObject var state = State()
    @ObservedObject var rsg = ReadySetGo()
    
    fileprivate func doTap() {
        let dir = Double.random(in: 0.0 ..< (2 * .pi) )
        let newPos = state.edgePosFromAngle(angle:  dir)
        switch state.runState {
        case .ready:
            // countdown to get ready, set, go
            
        // pick a random direction and find the pos on the edge to move towards
            state.runState = .running
            state.transitTime = 0
            state.ballPosition = state.circleCentre
            state.transitTime = 2.0
            rsg.runRSG()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: {
                self.state.ballPosition = newPos
                self.state.reschedule()
            })
        case .running:
            state.runState = .paused
            let saved = state.transitTime
            state.transitTime = 0
            state.ballPosition = state.circleCentre
            state.transitTime = saved
        case .paused:
            state.runState = .running
            state.ballPosition = newPos
        default:
            state.ballPosition = state.circleCentre
            state.runState = .ready
        }
    }
    var body: some View {
        ZStack {
            VStack {
                Text(" \(self.state.score == 0 ? "Ready" : self.state.score.description )")
                Text(rsg.rsg)
                Text("paddle: \(self.state.paddlePosition)")
                Text("\(self.state.runState.rawValue )")
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
                                              by: Double.pi / 360,
                                              sensitivity: .low,
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
//            .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 5 - 42mm"))
//            .previewDisplayName("42mm")
            ContentView()
            .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 5 - 44mm"))
            .previewDisplayName("44mm")
        }
    }
}
