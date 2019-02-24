//
//  GameViewController.swift
//  ScenekitVehicle-Swift
//
//  Created by lianjia on 2019/2/21.
//  Copyright © 2019 liulinzhe. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import SpriteKit
import simd

class GameViewController: UIViewController {
    
    var spotLightNode = SCNNode()
    var cameraNode = SCNNode()
    var vehicleNode = SCNNode()
    
    var _vehicle = SCNPhysicsVehicle()
    var _reactor = SCNParticleSystem()
    
    var _orientation: CGFloat = 0.0
    var reactorDefaultBirthRate: CGFloat = 0.0
    var vehicleSteering: CGFloat = 0.0
    
    lazy var deviceName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {machinePtr in
            String(cString: UnsafeRawPointer(machinePtr).assumingMemoryBound(to: CChar.self))
        }
    }()
    
    var isHighEndDevice: Bool {
        return deviceName.hasPrefix("iPad4")
            || deviceName.hasPrefix("iPhone6")
        
    }
    
    // MARK: - Scene搭建
    func setupEnvironment(scene:SCNScene) {
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light!.type = .ambient
        ambientLight.light!.color = UIColor(white: 0.3, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .spot
        if isHighEndDevice {
            lightNode.light?.castsShadow = true
        }
        lightNode.light?.color = UIColor(white: 0.8, alpha: 1.0)
        lightNode.position = SCNVector3(0, 80, 30)
        lightNode.rotation = SCNVector4Make(1, 0, 0, -.pi/2.8)
        lightNode.light?.spotInnerAngle = 0
        lightNode.light?.spotOuterAngle = 50
        lightNode.light?.shadowColor = SKColor.black
        lightNode.light?.zFar = 500
        lightNode.light?.zNear = 50
        scene.rootNode.addChildNode(lightNode)
        
        spotLightNode = lightNode
        
        let floor = SCNNode()
        floor.geometry = SCNFloor()
        floor.geometry?.firstMaterial?.diffuse.contents = "wood.png"
        floor.geometry?.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(2, 2, 1)
        floor.geometry?.firstMaterial?.locksAmbientWithDiffuse = true
        if isHighEndDevice {
            (floor.geometry as! SCNFloor).reflectionFalloffEnd = 10
        }
        let staticBody = SCNPhysicsBody.static()
        floor.physicsBody = staticBody
        scene.rootNode.addChildNode(floor)
    }
    
    private func addTrainToScene(_ scene: SCNScene, atPosition pos: SCNVector3) {
        let trainScene = SCNScene(named: "train_flat")!
        
        //physicalize the train with simple boxes
        for node in trainScene.rootNode.childNodes as [SCNNode] {
            //let node = obj as! SCNNode
            if node.geometry != nil {
                node.position = SCNVector3Make(node.position.x + pos.x, node.position.y + pos.y, node.position.z + pos.z)
                
                let (min, max) = node.boundingBox
                
                let body = SCNPhysicsBody.dynamic()
                let boxShape = SCNBox(width:CGFloat(max.x - min.x), height:CGFloat(max.y - min.y), length:CGFloat(max.z - min.z), chamferRadius:0.0)
                body.physicsShape = SCNPhysicsShape(geometry: boxShape, options:nil)
                
                node.pivot = SCNMatrix4MakeTranslation(0, -min.y, 0)
                node.physicsBody = body
                scene.rootNode.addChildNode(node)
            }
        }
        
        //add smoke
        let smokeHandle = scene.rootNode.childNode(withName: "Smoke", recursively: true)
        smokeHandle!.addParticleSystem(SCNParticleSystem(named: "smoke", inDirectory: nil)!)
        
        //add physics constraints between engine and wagons
        let engineCar = scene.rootNode.childNode(withName: "EngineCar", recursively: false)
        let wagon1 = scene.rootNode.childNode(withName: "Wagon1", recursively: false)
        let wagon2 = scene.rootNode.childNode(withName: "Wagon2", recursively: false)
        
        let (min, max) = engineCar!.boundingBox
        
        let (wmin, wmax) = wagon1!.boundingBox
        
        // Tie EngineCar & Wagon1
        var joint = SCNPhysicsBallSocketJoint(bodyA: engineCar!.physicsBody!, anchorA: SCNVector3Make(max.x, min.y, 0),
                                              bodyB: wagon1!.physicsBody!, anchorB: SCNVector3Make(wmin.x, wmin.y, 0))
        scene.physicsWorld.addBehavior(joint)
        
        // Wagon1 & Wagon2
        joint = SCNPhysicsBallSocketJoint(bodyA: wagon1!.physicsBody!, anchorA: SCNVector3Make(wmax.x + 0.1, wmin.y, 0),
                                          bodyB: wagon2!.physicsBody!, anchorB: SCNVector3Make(wmin.x - 0.1, wmin.y, 0))
        scene.physicsWorld.addBehavior(joint)
    }
    
    private func addWoodenBlockToScene(_ scene:SCNScene, withImageNamed imageName:NSString, atPosition position:SCNVector3) {
        //create a new node
        let block = SCNNode()
        
        //place it
        block.position = position
        
        //attach a box of 5x5x5
        block.geometry = SCNBox(width: 5, height: 5, length: 5, chamferRadius: 0)
        
        //use the specified images named as the texture
        block.geometry!.firstMaterial!.diffuse.contents = imageName
        
        //turn on mipmapping
        block.geometry!.firstMaterial!.diffuse.mipFilter = .linear
        
        //make it physically based
        block.physicsBody = SCNPhysicsBody.dynamic()
        
        //add to the scene
        scene.rootNode.addChildNode(block)
    }
    
    private func setupSceneElements(_ scene: SCNScene) {
        // add a train
        addTrainToScene(scene, atPosition: SCNVector3Make(-5, 20, -40))
        
        // add wooden blocks
        addWoodenBlockToScene(scene, withImageNamed: "WoodCubeA.jpg", atPosition: SCNVector3Make(-10, 15, 10))
        addWoodenBlockToScene(scene, withImageNamed: "WoodCubeB.jpg", atPosition: SCNVector3Make(-9, 10, 10))
        addWoodenBlockToScene(scene, withImageNamed: "WoodCubeC.jpg", atPosition: SCNVector3Make(20, 15, -11))
        addWoodenBlockToScene(scene, withImageNamed: "WoodCubeA.jpg", atPosition: SCNVector3Make(25 , 5, -20))
        
        // add walls
        let wall = SCNNode(geometry: SCNBox(width: 400, height: 100, length: 4, chamferRadius: 0))
        wall.geometry!.firstMaterial!.diffuse.contents = "wall.jpg"
        wall.geometry!.firstMaterial!.diffuse.contentsTransform = SCNMatrix4Mult(SCNMatrix4MakeScale(24, 2, 1), SCNMatrix4MakeTranslation(0, 1, 0))
        wall.geometry!.firstMaterial!.diffuse.wrapS = .repeat
        wall.geometry!.firstMaterial!.diffuse.wrapT = .mirror
        wall.geometry!.firstMaterial!.isDoubleSided = false
        wall.castsShadow = false
        wall.geometry!.firstMaterial!.locksAmbientWithDiffuse = true
        
        wall.position = SCNVector3Make(0, 50, -92)
        wall.physicsBody = SCNPhysicsBody.static()
        scene.rootNode.addChildNode(wall)
        
        let wallC = wall.clone()
        wallC.position = SCNVector3Make(-202, 50, 0)
        wallC.rotation = SCNVector4Make(0, 1, 0, .pi/2)
        scene.rootNode.addChildNode(wallC)
        
        let wallD = wall.clone()
        wallD.position = SCNVector3Make(202, 50, 0)
        wallD.rotation = SCNVector4Make(0, 1, 0, -Float.pi/2)
        scene.rootNode.addChildNode(wallD)
        
        let backWall = SCNNode(geometry: SCNPlane(width: 400, height: 100))
        backWall.geometry!.firstMaterial = wall.geometry!.firstMaterial
        backWall.position = SCNVector3Make(0, 50, 200)
        backWall.rotation = SCNVector4Make(0, 1, 0, .pi)
        backWall.castsShadow = false
        backWall.physicsBody = SCNPhysicsBody.static()
        scene.rootNode.addChildNode(backWall)
        
        // add ceil
        let ceilNode = SCNNode(geometry: SCNPlane(width: 400, height: 400))
        ceilNode.position = SCNVector3Make(0, 100, 0)
        ceilNode.rotation = SCNVector4Make(1, 0, 0, .pi/2)
        ceilNode.geometry!.firstMaterial!.isDoubleSided = false
        ceilNode.castsShadow = false
        ceilNode.geometry!.firstMaterial!.locksAmbientWithDiffuse = true
        scene.rootNode.addChildNode(ceilNode)
        
        //add more block
        for _ in 0 ..< 4 {
            addWoodenBlockToScene(scene, withImageNamed: "WoodCubeA.jpg", atPosition: SCNVector3Make(Float(arc4random_uniform(60)) - 30, 20, Float(arc4random_uniform(40)) - 20))
            addWoodenBlockToScene(scene, withImageNamed: "WoodCubeB.jpg", atPosition: SCNVector3Make(Float(arc4random_uniform(60)) - 30, 20, Float(arc4random_uniform(40)) - 20))
            addWoodenBlockToScene(scene, withImageNamed: "WoodCubeC.jpg", atPosition: SCNVector3Make(Float(arc4random_uniform(60)) - 30, 20, Float(arc4random_uniform(40)) - 20))
        }
        
        // add cartoon book
        let block = SCNNode()
        block.position = SCNVector3Make(20, 10, -16)
        block.rotation = SCNVector4Make(0, 1, 0, -Float.pi/4)
        block.geometry = SCNBox(width: 22, height: 0.2, length: 34, chamferRadius: 0)
        let frontMat = SCNMaterial()
        frontMat.locksAmbientWithDiffuse = true
        frontMat.diffuse.contents = "book_front.jpg"
        frontMat.diffuse.mipFilter = .linear
        let backMat = SCNMaterial()
        backMat.locksAmbientWithDiffuse = true
        backMat.diffuse.contents = "book_back.jpg"
        backMat.diffuse.mipFilter = .linear
        block.geometry!.materials = [frontMat, backMat]
        block.physicsBody = SCNPhysicsBody.dynamic()
        scene.rootNode.addChildNode(block)
        
        // add carpet
        let rug = SCNNode()
        rug.position = SCNVector3Make(0, 0.01, 0)
        rug.rotation = SCNVector4Make(1, 0, 0, .pi/2)
        let path = UIBezierPath(roundedRect: CGRect(x: -50, y: -30, width: 100, height: 50), cornerRadius: 2.5)
        path.flatness = 0.1
        rug.geometry = SCNShape(path: path, extrusionDepth: 0.05)
        rug.geometry!.firstMaterial!.locksAmbientWithDiffuse = true
        rug.geometry!.firstMaterial!.diffuse.contents = "carpet.jpg"
        scene.rootNode.addChildNode(rug)
        
        // add ball
        let ball = SCNNode()
        ball.position = SCNVector3Make(-5, 5, -18)
        ball.geometry = SCNSphere(radius: 5)
        ball.geometry!.firstMaterial!.locksAmbientWithDiffuse = true
        ball.geometry!.firstMaterial!.diffuse.contents = "ball.jpg"
        ball.geometry!.firstMaterial!.diffuse.contentsTransform = SCNMatrix4MakeScale(2, 1, 1)
        ball.geometry!.firstMaterial!.diffuse.wrapS = .mirror
        ball.physicsBody = SCNPhysicsBody.dynamic()
        ball.physicsBody!.restitution = 0.9
        scene.rootNode.addChildNode(ball)
    }
    
    private func setupVehicle(_ scene: SCNScene) -> SCNNode {
        let carScene = SCNScene(named: "rc_car")!
        let chassisNode = carScene.rootNode.childNode(withName: "rccarBody", recursively: false)
        
        // setup the chassis
        chassisNode!.position = SCNVector3Make(0, 10, 30)
        chassisNode!.rotation = SCNVector4Make(0, 1, 0, .pi)
        
        let body = SCNPhysicsBody.dynamic()
        body.allowsResting = false
        body.mass = 80
        body.restitution = 0.1
        body.friction = 0.5
        body.rollingFriction = 0
        
        chassisNode!.physicsBody = body
        scene.rootNode.addChildNode(chassisNode!)
        
        let pipeNode = chassisNode!.childNode(withName: "pipe", recursively: true)
        _reactor = SCNParticleSystem(named: "reactor", inDirectory: nil)!
        reactorDefaultBirthRate = _reactor.birthRate
        _reactor.birthRate = 0
        pipeNode!.addParticleSystem(_reactor)
        
        //add wheels
        let wheel0Node = chassisNode!.childNode(withName: "wheelLocator_FL", recursively: true)!
        let wheel1Node = chassisNode!.childNode(withName: "wheelLocator_FR", recursively: true)!
        let wheel2Node = chassisNode!.childNode(withName: "wheelLocator_RL", recursively: true)!
        let wheel3Node = chassisNode!.childNode(withName: "wheelLocator_RR", recursively: true)!
        
        let wheel0 = SCNPhysicsVehicleWheel(node: wheel0Node)
        let wheel1 = SCNPhysicsVehicleWheel(node: wheel1Node)
        let wheel2 = SCNPhysicsVehicleWheel(node: wheel2Node)
        let wheel3 = SCNPhysicsVehicleWheel(node: wheel3Node)
        
        let (min, max) = wheel0Node.boundingBox
        let wheelHalfWidth = Float(0.5 * (max.x - min.x))
        
        wheel0.connectionPosition = SCNVector3(float3(wheel0Node.convertPosition(SCNVector3Zero, to: chassisNode)) + float3(wheelHalfWidth, 0, 0))
        wheel1.connectionPosition = SCNVector3(float3(wheel1Node.convertPosition(SCNVector3Zero, to: chassisNode)) - float3(wheelHalfWidth, 0, 0))
        wheel2.connectionPosition = SCNVector3(float3(wheel2Node.convertPosition(SCNVector3Zero, to: chassisNode)) + float3(wheelHalfWidth, 0, 0))
        wheel3.connectionPosition = SCNVector3(float3(wheel3Node.convertPosition(SCNVector3Zero, to: chassisNode)) - float3(wheelHalfWidth, 0, 0))
        
        // create the physics vehicle
        let vehicle = SCNPhysicsVehicle(chassisBody: chassisNode!.physicsBody!, wheels: [wheel0, wheel1, wheel2, wheel3])
        scene.physicsWorld.addBehavior(vehicle)
        
        _vehicle = vehicle
        
        return chassisNode!
    }
    
    private func setupScene() -> SCNScene {
        // create a new scene
        let scene = SCNScene()
        
        //global environment
        setupEnvironment(scene: scene)
        
        //add elements
        setupSceneElements(scene)
        
        //setup vehicle
        vehicleNode = setupVehicle(scene)
        
        //create a main camera
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera!.zFar = 500
        cameraNode.position = SCNVector3Make(0, 60, 50)
        cameraNode.rotation  = SCNVector4Make(1, 0, 0, -Float.pi/4 * 0.75)
        scene.rootNode.addChildNode(cameraNode)
        
        //add a secondary camera to the car
        let frontCameraNode = SCNNode()
        frontCameraNode.position = SCNVector3Make(0, 10, -12)
        frontCameraNode.rotation = SCNVector4Make(0, 1, 0, .pi)
        frontCameraNode.camera = SCNCamera()
        frontCameraNode.camera!.fieldOfView = 75
        frontCameraNode.camera!.zFar = 500
        
        vehicleNode.addChildNode(frontCameraNode)
        
        return scene
    }

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scnView = self.view as! SCNView
        
        scnView.backgroundColor = SKColor.black
        
        let scene = setupScene()
        
        scnView.scene = scene
        
        scnView.scene?.physicsWorld.speed = 4.0
        
        scnView.overlaySKScene = ARCarOverlayScene(size: scnView.bounds.size)
        
        scnView.pointOfView = cameraNode
        
        scnView.delegate = self
        
    }
    
    // MARK: - Private
    
    private func reorientCarIfNeeded() {
        let car = vehicleNode.presentation
        let carPos = car.position
        
        // make sure the car isn't upside down, and fix it if it is
        struct My {
            static var ticks = 0
            static var check = 0
            static var `try` = 0
        }
        func randf() -> Float {
            return Float(arc4random())/Float(UInt32.max)
        }
        My.ticks += 1
        if My.ticks == 30 {
            let t = car.worldTransform
            if t.m22 <= 0.1 {
                My.check += 1
                if My.check == 3 {
                    My.try += 1
                    if My.try == 3 {
                        My.try = 0
                        
                        //hard reset
                        vehicleNode.rotation = SCNVector4Make(0, 0, 0, 0)
                        vehicleNode.position = SCNVector3Make(carPos.x, carPos.y + 10, carPos.z)
                        vehicleNode.physicsBody!.resetTransform()
                    } else {
                        //try to upturn with an random impulse
                        let pos = SCNVector3Make(-10 * (randf() - 0.5), 0, -10 * (randf() - 0.5))
                        vehicleNode.physicsBody!.applyForce(SCNVector3Make(0, 300, 0), at: pos, asImpulse: true)
                    }
                    
                    My.check = 0
                }
            } else {
                My.check = 0
            }
            
            My.ticks = 0
        }
    }
    
    // MARK: - Override
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.landscape
    }

}

// MARK: - Delegate

extension GameViewController : SCNSceneRendererDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        let defaultEngineForce: CGFloat = 300.0
        let defauleBreakingForce: CGFloat = 5.0
        let steeringClamp: CGFloat = 0.6
        let cameraDamping: CGFloat = 0.3
        
        let scnView = view as! ARCarGameView
        
        var engineForce: CGFloat = 0
        var breakingForce: CGFloat = 0
        
        let orientation = _orientation
        
        switch scnView.operationOrientation {
            
        case .OPERATION_UP:
            engineForce = defaultEngineForce
            _reactor.birthRate = reactorDefaultBirthRate
            _orientation = 0
            
        case .OPERATION_DOWN:
            engineForce = -defaultEngineForce
            _reactor.birthRate = 0
            _orientation = 0
            
        case .OPERATION_RIGHT:
            _orientation += 0.05
            
        case .OPERATION_LEFT:
            _orientation -= 0.05
            
        case [.OPERATION_RIGHT, .OPERATION_UP]:
            engineForce = defaultEngineForce
            _reactor.birthRate = reactorDefaultBirthRate
            _orientation += 0.05
    
        case [.OPERATION_RIGHT, .OPERATION_DOWN]:
            engineForce = -defaultEngineForce
            _reactor.birthRate = 0
            _orientation += 0.05
            
        case [.OPERATION_LEFT, .OPERATION_UP]:
            engineForce = defaultEngineForce
            _reactor.birthRate = reactorDefaultBirthRate
            _orientation -= 0.05
            
        case [.OPERATION_LEFT, .OPERATION_DOWN]:
            engineForce = -defaultEngineForce
            _reactor.birthRate = 0
            _orientation -= 0.05
            
        default:
            breakingForce = defauleBreakingForce
            _reactor.birthRate = 0
            _orientation = 0.0
        }
        
        vehicleSteering = -orientation
        if orientation == 0 {
            vehicleSteering *= 0.9
        }
        if vehicleSteering < -steeringClamp {
            vehicleSteering = -steeringClamp
        }
        if vehicleSteering > steeringClamp {
            vehicleSteering = steeringClamp
        }
        
        _vehicle.setSteeringAngle(vehicleSteering, forWheelAt: 0)
        _vehicle.setSteeringAngle(vehicleSteering, forWheelAt: 1)
        
        _vehicle.applyEngineForce(engineForce, forWheelAt: 2)
        _vehicle.applyEngineForce(engineForce, forWheelAt: 3)
        
        _vehicle.applyBrakingForce(breakingForce, forWheelAt: 2)
        _vehicle.applyBrakingForce(breakingForce, forWheelAt: 3)
        
        //check if the car is upside down
        reorientCarIfNeeded()
        
        // make camera follow the car node
        let car = vehicleNode.presentation
        let carPos = car.position
        let targetPos = float3(carPos.x, Float(30), carPos.z + 25)
        var cameraPos = float3(cameraNode.position)
        cameraPos = mix(cameraPos, targetPos, t: Float(cameraDamping))
        cameraNode.position = SCNVector3(cameraPos)
        
        if scnView.inCarView {
            //move spot light in front of the camera
            let frontPosition = scnView.pointOfView!.presentation.convertPosition(SCNVector3Make(0, 0, -30), to:nil)
            spotLightNode.position = SCNVector3Make(frontPosition.x, 80, frontPosition.z)
            spotLightNode.rotation = SCNVector4Make(1,0,0,-Float.pi/2)
        } else {
            //move spot light on top of the car
            spotLightNode.position = SCNVector3Make(carPos.x, 80, carPos.z + 30)
            spotLightNode.rotation = SCNVector4Make(1,0,0,-Float.pi/2.8)
        }
        
        //speed gauge
        let overlayScene = scnView.overlaySKScene as! ARCarOverlayScene
        overlayScene.speedNeedle.zRotation = -(_vehicle.speedInKilometersPerHour * .pi / 250)
    }
}
