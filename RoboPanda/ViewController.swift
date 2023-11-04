//
//  ViewController.swift
//  RoboPanda
//
//  Created by 윤범태 on 2023/11/03.
//

import UIKit
import SceneKit
import ARKit

extension float4x4 {
    var translation: SIMD3<Float> {
        let translation = self.columns.3
        return SIMD3<Float>(translation.x, translation.y, translation.z)
    }
}

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var currentPlanePosition: SCNVector3 = .init()
    let sunNode = SCNNode()
    var floorNode: SCNNode?

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // // Create a new scene
        // let scene = SCNScene(named: "RoboPanda1.scn")!
        // 
        // // Set the scene to the view
        // sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setARTrackingConfiguration()
        addTapGestureToSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func setARTrackingConfiguration() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        sceneView.scene.lightingEnvironment.contents = .none
        // sceneView.scene.background.contents = .none
        
        sceneView.backgroundColor = .black
        // sceneView.allowsCameraControl = true
        
        sunNode.light = SCNLight()
        sunNode.light?.type = .directional
        sceneView.scene.rootNode.addChildNode(sunNode)
    }
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addNodeToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func addNodeToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        // let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        let hitTestResults = sceneView.raycastQuery(from: tapLocation, allowing: .existingPlaneGeometry, alignment: .horizontal)
        
        // guard let hitTestResult = hitTestResults.first else { return }
        // let translation = hitTestResult.worldTransform.translation // Float3
        
        let translation = hitTestResults!.direction
      
        let x = translation.x
        let y = translation.y
        let z = translation.z
        print("translation:", x, y, z   )
        
        let name: String = "RoboPanda2.usdz" //you can add node whatever
        
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self else {
                return
            }
            print("This is run on the background queue")
            
            let pandaScene = SCNScene(named: name)!
            pandaScene.rootNode.childNodes.enumerated().forEach { (i, node) in
                for (j, child) in node.childNodes.enumerated() {
                    print(i, j, child)
                    print("geometry: \(child.geometry)")
                    if child.name == "PandaBleat01" {
                        
                    }
                    if !child.childNodes.isEmpty {
                        for y in child.childNodes {
                            print("cc:", y)
                            print("geometry: \(y.geometry)")
                        }
                    }
                }
            }
            
            // self.sceneView.scene = pandaScene
            print(sceneView.scene)
            let node = pandaScene.rootNode.childNodes[0]
            if let floorPosition = floorNode?.position {
                // node.position = floorNode!.position
                node.position = SCNVector3(x, y, z)
            } else {
                node.position = SCNVector3(x, y, z)
            }
            
            print(node.hasActions)
            
            sceneView.scene.rootNode.addChildNode(node)
            floorNode?.removeFromParentNode()
            // configureLighting()
            
            // sceneView.scene.rootNode.addChildNode(<#T##child: SCNNode##SCNNode#>)
            
            
            // sceneView.scene.rootNode.childNode(withName: "Group", recursively: true)?.position = currentPlanePosition
            // pandaScene.rootNode.position = SCNVector3(x, y, z)
            // pandaScene.rootNode.position = .init(currentPlanePosition.x, y, currentPlanePosition.z)
            // pandaScene.rootNode.eulerAngles.x = -.pi / 2
            
            // if let geometry = pandaScene.rootNode.childNode(withName: "Body", recursively: true)?.geometry {
            //     print("g")
            //     // self.sceneView.scene = pandaScene
            //     var boxNode: SCNNode = SCNNode(geometry: geometry)
            //     pandaScene.rootNode.position = SCNVector3(x, y, z)
            //     self.sceneView.scene.rootNode.addChildNode(boxNode)
            // }

            // if var geom: SCNGeometry = pandaScene.rootNode.geometry {
            //     
            //     
            //     print("Geom is not nil.")
            //     var boxNode: SCNNode = SCNNode(geometry: geom)
            //     
            // } else {
            //     print("Geom is nil.")
            //     // Create a new scene
            //     let scene = SCNScene(named: "RoboPanda1.scn")!
            //     
            //     // Set the scene to the view
            //     self.sceneView.scene = scene
            // }
            // 
            
            
            group.leave()
            
        }
        group.notify(queue: .main){
            //Here you know that the node is has been put
        }
    }
    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // 2
        let width = CGFloat(planeAnchor.planeExtent.width)
        let height = CGFloat(planeAnchor.planeExtent.height)
        let plane = SCNPlane(width: width, height: height)
        
        // 3
        plane.materials.first?.diffuse.contents = UIColor(red: 0, green: 1, blue: 0, alpha: 0.7)
        
        // 4
        let planeNode = SCNNode(geometry: plane)
        
        // 5
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
        currentPlanePosition = planeNode.position
        print("planeNode:", x, y, z)
        planeNode.eulerAngles.x = -.pi / 2
        
        // 6
        floorNode = node
        node.addChildNode(planeNode)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
              let planeNode = node.childNodes.first,
              let plane = planeNode.geometry as? SCNPlane
        else { return }
        
        // 2
        let width = CGFloat(planeAnchor.planeExtent.width)
        let height = CGFloat(planeAnchor.planeExtent.height)
        plane.width = width
        plane.height = height
        
        // 3
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        sunNode.transform = (sceneView?.pointOfView?.worldTransform)!
        
        // let cameraAngles = (self.sceneView?.pointOfView?.eulerAngles)!
        // let lightAngles = self.sunNode.eulerAngles
        // 
        // print("Camera: " + String(format: "%.2f, %.2f, %.2f", cameraAngles.x,
        //                           cameraAngles.y,
        //                           cameraAngles.z))
        // 
        // print("Light: " + String(format: "%.2f, %.2f, %.2f", lightAngles.x,
        //                          lightAngles.y,
        //                          lightAngles.z))
    }
    
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
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
