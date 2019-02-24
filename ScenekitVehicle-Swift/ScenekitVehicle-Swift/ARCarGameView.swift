//
//  ARCarGameView.swift
//  ScenekitVehicle-Swift
//
//  Created by lianjia on 2019/2/21.
//  Copyright © 2019 liulinzhe. All rights reserved.
//

import UIKit
import SceneKit
import SpriteKit

struct OPERATION_ORIENTATION: OptionSet {
    let rawValue: Int
    
    static let OPERATION_STOP = OPERATION_ORIENTATION(rawValue: 0)
    static let OPERATION_UP = OPERATION_ORIENTATION(rawValue: 1)
    static let OPERATION_DOWN = OPERATION_ORIENTATION(rawValue: 2)
    static let OPERATION_LEFT = OPERATION_ORIENTATION(rawValue: 4)
    static let OPERATION_RIGHT = OPERATION_ORIENTATION(rawValue: 8)
    static let OPERATION_BREAK = OPERATION_ORIENTATION(rawValue: 16)
}

class ARCarGameView : SCNView {
    var touchCount = 0
    var operationOrientation = OPERATION_ORIENTATION.OPERATION_STOP
    var inCarView = false
    
    func changePointOfView() {
        let pointOfViews = scene!.rootNode.childNodes(passingTest: { (child, stop) -> Bool in
            return (child.camera != nil)
        }) as [SCNNode]
        
        let currentPointOfView = self.pointOfView
        
        var index = pointOfViews.firstIndex(of: currentPointOfView!) ?? 0
        
        index += 1
        
        if index >= pointOfViews.count { index = 0 }
        
        inCarView = (index == 0)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.75
        self.pointOfView = pointOfViews[index]
        SCNTransaction.commit()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let scene = overlaySKScene!
        var p = touch.location(in: self)
        p = scene.convertPoint(fromView: p)
        let node = scene.atPoint(p)
        
        if node.name == "camera" {
            node.run(SKAction.playSoundFileNamed("click.caf", waitForCompletion: false))
            changePointOfView()
            return
        }
        else if node.name == "operation_up" {
            operationOrientation = .OPERATION_UP
            return
        }
        else if node.name == "operation_down" {
            operationOrientation = .OPERATION_DOWN
            return
        }
        else if node.name == "operation_left" {
            operationOrientation = .OPERATION_LEFT
            return
        }
        else if node.name == "operation_right" {
            operationOrientation = .OPERATION_RIGHT
            return
        }
        
        let allTouches = event!.allTouches
        touchCount = allTouches!.count
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let scene = overlaySKScene!
            var p = touch.location(in: self)
            p = scene.convertPoint(fromView: p)
            let node = scene.atPoint(p)
            
            if node.name == "camera" {
                node.run(SKAction.playSoundFileNamed("click.caf", waitForCompletion: false))
                changePointOfView()
                return
            }
            else if node.name == "operation_up" {
                operationOrientation = operationOrientation.union(.OPERATION_UP)
                return
            }
            else if node.name == "operation_down" {
                operationOrientation = operationOrientation.union(.OPERATION_DOWN)
                return
            }
            else if node.name == "operation_left" {
                operationOrientation = operationOrientation.union(.OPERATION_LEFT)
                return
            }
            else if node.name == "operation_right" {
                operationOrientation = operationOrientation.union(.OPERATION_RIGHT)
                return
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchCount = 0
        operationOrientation = .OPERATION_STOP
    }
}

