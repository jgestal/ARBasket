//
//  ViewController.swift
//  ARBasket
//
//  Created by Juan Gestal Romani on 7/8/18.
//  Copyright © 2018 Juan Gestal Romani. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var currentNode: SCNNode!
    @IBOutlet weak var addHoopBtn: UIButton!
    @IBOutlet weak var permissionToCameraView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        // sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        checkCameraPermission()
        registerGestureRecognizer()
    }
    
    func checkCameraPermission() {
        let cameraMediaType = AVMediaType.video
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: cameraMediaType)
        
        switch cameraAuthorizationStatus {
        case .denied:
            print("*** Camera Denied")
            break
        case .authorized:
            print("*** Camera Authorized")
            permissionToCameraView.isHidden = true
            break
        case .restricted:
            print("*** Camera Restricted")
            break
            
        case .notDetermined:
            // Prompting user for the permission to use the camera.
            AVCaptureDevice.requestAccess(for: cameraMediaType) { granted in
                if granted {
                    print("Granted access to \(cameraMediaType)")
                    self.permissionToCameraView.isHidden = true
                } else {
                    print("Denied access to \(cameraMediaType)")
                }
            }
        }
    }
    
    
    func addBackboard() {
        
        guard
            let backboardScene = SCNScene(named: "art.scnassets/hoop.scn"),
            let backboardNode = backboardScene.rootNode.childNode(withName: "backboard", recursively: false)
        else { return }
        
        backboardNode.position = SCNVector3(x: 0, y: 0.5, z: -3)
        
        let physicsShape = SCNPhysicsShape(node: backboardNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron])
        let physicsBody = SCNPhysicsBody(type: .static, shape: physicsShape)
        backboardNode.physicsBody = physicsBody
        
        sceneView.scene.rootNode.addChildNode(backboardNode)
        currentNode = backboardNode
    }
    
    func addBall(at position: SCNVector3, impulseOrientation: SCNVector3) {
        let ball = SCNSphere(radius: 0.15)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "basketballSkin")
        ball.materials = [material]
        let ballNode = SCNNode(geometry: ball)
        ballNode.position = position
        
        let physicsShape = SCNPhysicsShape(node: ballNode, options: nil)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        
        ballNode.physicsBody = physicsBody
        
        let forceVector:Float = 6.5
        
        ballNode.physicsBody?.applyForce(SCNVector3(x: impulseOrientation.x * forceVector,
                                                    y: impulseOrientation.y * forceVector * 2,
                                                    z: impulseOrientation.z * forceVector), asImpulse: true)

        sceneView.scene.rootNode.addChildNode(ballNode)
    }
    
    
    func registerGestureRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tap)
    }
    
    @objc func handleTap(gestureRecognizer: UIGestureRecognizer) {
        
        guard
            let sceneView = gestureRecognizer.view as? ARSCNView,
            let centerPoint = sceneView.pointOfView
        else { return }
        
        let cameraTransform = centerPoint.transform
        let cameraLocation = SCNVector3(x: cameraTransform.m41, y: cameraTransform.m42, z: cameraTransform.m43)
        let cameraOrientation = SCNVector3(x: -cameraTransform.m31, y: -cameraTransform.m32, z: -cameraTransform.m33)
        
        let cameraPosition = SCNVector3Make(cameraLocation.x + cameraOrientation.x, cameraLocation.y + cameraOrientation.y, cameraLocation.z + cameraOrientation.z)
        
        addBall(at: cameraPosition, impulseOrientation: cameraOrientation)
    }
    
    func horizontalAction(node: SCNNode) {
        
        let leftAction = SCNAction.move(by: SCNVector3(x: -1,y: 0,z: 0), duration: 3)
        let rightAction = SCNAction.move(by: SCNVector3(x: 1, y: 0, z: 0), duration: 3)
        
        let actionSequence = SCNAction.sequence([leftAction,rightAction])
        
        node.runAction(SCNAction.repeat(actionSequence, count: 4))
    }
    
    func roundAction(node: SCNNode) {
        
        let upLeft = SCNAction.move(by: SCNVector3(x: 1, y: 1, z: 0), duration: 2)
        let downRight = SCNAction.move(by: SCNVector3(x: 1, y: -1, z: 0), duration: 2)
        let downLeft = SCNAction.move(by: SCNVector3(x: -1, y: -1, z: 0), duration: 2)
        let upRight = SCNAction.move(by: SCNVector3(x: -1, y: 1, z: 0), duration: 2)

        let actionSequence = SCNAction.sequence([upLeft,downRight,downLeft,upRight])
        
        node.runAction(SCNAction.repeat(actionSequence, count: 2))
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    @IBAction func startRoundAction(_ sender: Any) {
        roundAction(node: currentNode)
    }
    
    @IBAction func stopAllActions(_ sender: Any) {
        currentNode.removeAllActions()
    }
    
    @IBAction func startHorizontalAction(_ sender: Any) {
        horizontalAction(node: currentNode)
    }
    
    @IBAction func addHoop(_ sender: Any) {
        addBackboard()
        addHoopBtn.isHidden = true
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}
