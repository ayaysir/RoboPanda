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

class ViewController: UIViewController {
    var pandaScene: SCNScene?
    let sunNode = SCNNode()
    var floorNodes: [SCNNode] = []

    var isShowFloorGuide = true {
        didSet {
            if !isShowFloorGuide {
                floorNodes.forEach { node in
                    node.removeFromParentNode()
                }
            }
        }
    }
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
         //you can add node whatever
        pandaScene = SCNScene(named: randomPandaName)
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
        // sceneView.debugOptions = [.showFeaturePoints]
        
        sceneView.scene.lightingEnvironment.contents = .none
        // sceneView.scene.background.contents = .none
        
        sceneView.backgroundColor = .black
        // sceneView.allowsCameraControl = true
        
        sunNode.light = SCNLight()
        sunNode.light?.type = .directional
        // sunNode.light?.castsShadow = true
        // sunNode.eulerAngles.x = -.pi/4
        
        sceneView.scene.rootNode.addChildNode(sunNode)
        
        
    }
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addNodeToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func addNodeToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        // let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        let raycastResults = sceneView.raycastQuery(from: tapLocation, allowing: .existingPlaneGeometry, alignment: .horizontal)
        
        // let hitTestResults = sceneView.hitTest(tapLocation)
        // hitTestResults.forEach { result in
        //     print("hitTest:", result.node)
        // }
        
        let translation = raycastResults!.direction
      
        let x = translation.x
        let y = translation.y
        let z = translation.z
        print("translation:", x, y, z )
        
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self, let pandaScene else {
                return
            }
            // print("This is run on the background queue")
            
            // self.sceneView.scene = pandaScene
            let node = {
                if pandaScene.rootNode.childNodes.isEmpty {
                    return SCNScene(named: self.randomPandaName)!.rootNode.childNodes[0]
                }
                return pandaScene.rootNode.childNodes[0]
            }()
            
            node.position = SCNVector3(x, y, z)
            node.name = "Panda"
            
            sceneView.scene.rootNode.addChildNode(node)
            
            floorNodes.forEach { floorNode in
                floorNode.removeFromParentNode()
            }
            
            // add the audio player only after adding the node to scene. if we reverse, audio never plays
            node.addAudioPlayer(randomPandaBleatSound)
            
            // let action = SCNAction.move(by: .init(x + 0.001, y + 0.001, z + 0.001), duration: 0.5)
            // node.runAction(action)
            
            // 그림자
            // node.geometry?.firstMaterial?.lightingModel = .blinn
            // node.eulerAngles.y = -.pi
            
            group.leave()
            var whileFirst = true
            
            Task {
                var whileCount = 0
                while whileCount <= 30 {
                    if whileCount == 30 {
                        node.removeAllActions()
                        node.removeAllAnimations()
                        node.removeAllAudioPlayers()
                        node.removeFromParentNode()
                        break
                    }
                    
                    whileCount += 1
                    
                    // Random Jump
                    if Double.random(in: 0.0...1.0) < 0.2 && !whileFirst {
                        node.addAudioPlayer(self.randomPandaSound)
                        let jumpY = CGFloat.random(in: 0.2...0.7)
                        await node.runAction(.moveBy(x: 0, y: jumpY, z: 0, duration: 0.6))
                        await node.runAction(.moveBy(x: 0, y: -jumpY, z: 0, duration: 0.5))
                        await node.runAction(.moveBy(x: 0, y: 0, z: 0, duration: 0.1))
                        continue
                    }
                    
                    let prevStepXDir = node.position.x.sign
                    let prevStepZDir = node.position.z.sign
                    let prevQuadrant = self.findQuadrantDegree(stepXSign: prevStepXDir, stepZSign: prevStepZDir)
                    
                    let stepXDir: CGFloat = Bool.random() ? 1 : -1
                    let stepZDir: CGFloat = Bool.random() ? 1 : -1
                    let afterQuadrant = self.findQuadrantDegree(stepXSign: stepXDir.sign, stepZSign: stepZDir.sign)
                    
                    // let degree = self.findShortestDegree(prevQuadrant, afterQuadrant)
                    
                    let stepX: CGFloat = .random(in: 0.0...0.5) * stepXDir
                    let stepZ: CGFloat = .random(in: 0.0...0.5) * stepZDir
                    
                    let duration: TimeInterval = .random(in: 2.5...6.0)
                    
                    // node.eulerAngles.y = -.pi / 1.3
                    
                    // 회전: 마지막 단계로 이것을 연구
                    // degTorad(x): + 방향으로 가면 반시계방향으로 움직임
                    let rotateY = self.degToRad(self.findQuadrantDegree(stepXSign: stepXDir.sign, stepZSign: stepZDir.sign))
                    if whileFirst {
                        node.eulerAngles = .init(node.eulerAngles.x, Float(rotateY), node.eulerAngles.z)
                    } else {
                        await node.runAction(.rotateTo(x: 0, y: rotateY, z: 0, duration: .random(in: 0.3...0.4), usesShortestUnitArc: true))
                    }
                    
                    
                    // 움직임
                    let elapsedX = stepX * 5/6
                    let elapsedZ = stepZ * 5/6
                    let elapsedDuration = duration * 5/6
                    let stepY = 0.025
                    
                    for i in 0..<5 {
                        await node.runAction(.moveBy(x: stepX / 6, y: i % 2 == 0 ? stepY : -stepY, z: stepZ / 6, duration: duration / 6))
                    }
                    await node.runAction(.moveBy(x: stepX - elapsedX, y: -stepY, z: stepZ - elapsedZ, duration: duration - elapsedDuration))
                    
                    // node.rotation = .init(node.rotation.x, Float(rotateY), node.rotation.z, node.rotation.w)
                    // 부유
                    whileFirst = false
                    
                    // print("where:", stepX, stepZ)
                    /*
                     -, + : 좌하
                     -, - : 좌상
                     +, + : 우상
                     +, - : 우하
                     
                     0: 정면
                     -pi / 1.3 : 좌상
                     -pi / 1.7 : 좌
                     -pi / 4 : 좌하
                     -Pi / 8 : 하 (정면)
                     +pi / 2 : 우상
                     +pi / 4 : 우하
                     */
                }
            }
            
        }
        group.notify(queue: .main){
            //Here you know that the node is has been put
            // print("notify")
            
        }
    }
    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    func radTodeg(_ radian: Double) -> Double {
        return radian * 180 / .pi
    }
    
    func degToRad(_ degree: Double) -> Double {
        return degree * .pi / 180
    }
    
    func findQuadrantDegree(stepXSign: FloatingPointSign, stepZSign: FloatingPointSign) -> Double {
        return switch (stepXSign, stepZSign) {
        case (.minus, .plus): // 좌하 (4)
            Double.random(in:315-15...315+15)
        case (.minus, .minus): // 좌상 (3)
            Double.random(in:225-15...225+15)
        case (.plus, .plus): // 우상 (2)
            Double.random(in:45-15...45+15)
        case (.plus, .minus): // 우하 (1)
            Double.random(in:135-15...135+15)
        }
    }
    
    func findShortestDegree(_ beforeQuadrant: Int, _ afterQuadrant: Int) -> Double {
        return switch (beforeQuadrant, afterQuadrant) {
        case (1, 2), (2, 3), (3, 4), (4, 1):
            // Double.random(in: 30...70) 
            90
        case (1, 4), (4, 3), (3, 2), (2, 1):
            // Double.random(in: (-70.0)...(-30.0)) 
            -90
        case (1, 3), (2, 4), (3, 1), (4, 2):
            Bool.random() ? +1.0 : -1.0 * 180
            // * Double.random(in: 165...195)
        default:
            0
        }
    }
    
    @IBAction func swtActFloorGuide(_ sender: UISwitch) {
        isShowFloorGuide = sender.isOn
    }
    
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as? ARPlaneAnchor, isShowFloorGuide else { return }
        
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
        print("planeNode:", x, y, z)
        planeNode.eulerAngles.x = -.pi / 2
        
        // 6
        floorNodes.append(node)
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

extension ViewController {
    var randomPandaBleatSound: SCNAudioPlayer {
        let number = Int.random(in: 1...2)
        let source = SCNAudioSource(fileNamed: "PandaBleat0\(number).caf")!
        source.load()
        return SCNAudioPlayer(source: source)
    }
    
    var randomPandaSound: SCNAudioPlayer {
        let number = Int.random(in: 3...8)
        let source = SCNAudioSource(fileNamed: "Panda\(number).mp3")!
        source.load()
        return SCNAudioPlayer(source: source)
    }
    
    var randomPandaName: String {
        let fileNameArray = [
            "Bamboo",
            "Doll",
            "Pan",
            "BigApple",
        ]
        
        return "Panda+\(fileNameArray.randomElement()!).scn"
    }
    
    func printChildNodes(scene: SCNScene) {
        scene.rootNode.childNodes.enumerated().forEach { (i, node) in
            for (j, child) in node.childNodes.enumerated() {
                print(i, j, child)
                print("geometry: \(child.geometry as Any)")
                if child.name == "PandaBleat01" {
                }
                if !child.childNodes.isEmpty {
                    for y in child.childNodes {
                        print("cc:", y)
                        print("geometry: \(y.geometry as Any)")
                    }
                }
            }
        }
    }
}
