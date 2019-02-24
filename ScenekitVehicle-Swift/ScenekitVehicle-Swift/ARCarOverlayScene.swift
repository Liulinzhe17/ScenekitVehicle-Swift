//
//  ARCarOverlayScene.swift
//  ScenekitVehicle-Swift
//
//  Created by lianjia on 2019/2/21.
//  Copyright © 2019 liulinzhe. All rights reserved.
//

import Foundation
import SpriteKit
import UIKit

class ARCarOverlayScene : SKScene {
    
    var speedNeedle = SKNode()
    
    override init(size: CGSize) {
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        scaleMode = .resizeFill
        
        let iPad = UIDevice.current.userInterfaceIdiom == .pad
        let scale = iPad ? 1.5 : 1
        
        let myImage = SKSpriteNode.init(imageNamed: "speedGauge.png")
        myImage.anchorPoint = CGPoint(x: 0.5, y: 0)
        myImage.position = CGPoint(x: size.width * 0.33, y: -size.height * 0.5)
        myImage.xScale = CGFloat(0.8 * scale)
        myImage.yScale = CGFloat(0.8 * scale)
        addChild(myImage)
        
        let needleHandle = SKNode()
        let needle = SKSpriteNode(imageNamed: "needle.png")
        needleHandle.position = CGPoint(x: 0, y: 16)
        needle.anchorPoint = CGPoint(x: 0.5, y: 0)
        needle.xScale = 0.7
        needle.yScale = 0.7
        needle.zRotation = .pi/2
        needleHandle.addChild(needle)
        myImage.addChild(needleHandle)
        
        speedNeedle = needleHandle
        
        let cameraImage = SKSpriteNode(imageNamed: "video_camera.png")
        cameraImage.position = CGPoint(x: -size.width * 0.4, y: size.height * 0.4)
        cameraImage.name = "camera"
        cameraImage.xScale = CGFloat(0.6 * scale)
        cameraImage.yScale = CGFloat(0.6 * scale)
        addChild(cameraImage)
        
        let upImage = SKSpriteNode(imageNamed: "operation_up.png")
        upImage.position = CGPoint(x: size.width * 0.3, y: -size.height * 0.2)
        upImage.name = "operation_up"
        upImage.xScale = CGFloat(0.6 * scale)
        upImage.yScale = CGFloat(0.6 * scale)
        addChild(upImage)
        
        let downImage = SKSpriteNode(imageNamed: "operation_down.png")
        downImage.position = CGPoint(x: size.width * 0.3, y: -size.height * 0.3)
        downImage.name = "operation_down"
        downImage.xScale = CGFloat(0.6 * scale)
        downImage.yScale = CGFloat(0.6 * scale)
        addChild(downImage)
        
        let leftImage = SKSpriteNode(imageNamed: "operation_left.png")
        leftImage.position = CGPoint(x: -size.width * 0.4, y: -size.height * 0.25)
        leftImage.name = "operation_left"
        leftImage.xScale = CGFloat(0.6 * scale)
        leftImage.yScale = CGFloat(0.6 * scale)
        addChild(leftImage)
        
        let rightImage = SKSpriteNode(imageNamed: "operation_right.png")
        rightImage.position = CGPoint(x: -size.width * 0.3, y: -size.height * 0.25)
        rightImage.name = "operation_right"
        rightImage.xScale = CGFloat(0.6 * scale)
        rightImage.yScale = CGFloat(0.6 * scale)
        addChild(rightImage)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
