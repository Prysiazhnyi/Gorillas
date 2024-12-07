//
//  GameScene.swift
//  Project-29-SpriteKit-Gorillas
//
//  Created by Serhii Prysiazhnyi on 06.12.2024.
//

import SpriteKit
import GameplayKit

enum CollisionTypes: UInt32 {
    case banana = 1
    case building = 2
    case player = 4
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var buildings = [BuildingNode]()
    
    weak var viewController: GameViewController!
    
    var player1: SKSpriteNode!
    var player2: SKSpriteNode!
    var banana: SKSpriteNode!
    
    var currentPlayer = 1
    
    var gameScorePlayerOne: SKLabelNode!
    var scorePlayerOne = 0 {
        didSet {
            gameScorePlayerOne.text = "Score: \(scorePlayerOne)"
        }
    }
    
    var gameScorePlayerTwo: SKLabelNode!
    var scorePlayerTwo = 0 {
        didSet {
            gameScorePlayerTwo.text = "Score: \(scorePlayerTwo)"
        }
    }
    
    var angleSlider: UISlider!
    var velocitySlider: UISlider!
    var angleLabel: UILabel!
    var velocityLabel: UILabel!
    
    
    override func didMove(to view: SKView) {
        
        backgroundColor = UIColor(hue: 0.669, saturation: 0.99, brightness: 0.67, alpha: 1)
        
        createBuildings()
        createPlayers()
        
        physicsWorld.contactDelegate = self
        
        createScore() // Вызываем перед использованием gameScore
        
        //gameScore.position = CGPoint(x: self.size.width * 0.02, y: self.size.height * 0.02) // Размеры сцены
    }
    
    func createBuildings() {
        var currentX: CGFloat = -15
        
        while currentX < 1024 {
            let size = CGSize(width: Int.random(in: 2...4) * 40, height: Int.random(in: 300...600))
            currentX += size.width + 2
            
            let building = BuildingNode(color: UIColor.red, size: size)
            building.position = CGPoint(x: currentX - (size.width / 2), y: size.height / 2)
            building.setup()
            addChild(building)
            
            buildings.append(building)
        }
    }
    
    func launch(angle: Int, velocity: Int) {
        // 1
        let speed = Double(velocity) / 10.0
        
        // 2
        let radians = deg2rad(degrees: angle)
        
        // 3
        if banana != nil {
            banana.removeFromParent()
            banana = nil
        }
        
        banana = SKSpriteNode(imageNamed: "banana")
        banana.name = "banana"
        banana.physicsBody = SKPhysicsBody(circleOfRadius: banana.size.width / 2)
        banana.physicsBody?.categoryBitMask = CollisionTypes.banana.rawValue
        banana.physicsBody?.collisionBitMask = CollisionTypes.building.rawValue | CollisionTypes.player.rawValue
        banana.physicsBody?.contactTestBitMask = CollisionTypes.building.rawValue | CollisionTypes.player.rawValue
        banana.physicsBody?.usesPreciseCollisionDetection = true
        addChild(banana)
        
        if currentPlayer == 1 {
            // 4
            banana.position = CGPoint(x: player1.position.x - 30, y: player1.position.y + 40)
            banana.physicsBody?.angularVelocity = -20
            
            // 5
            let raiseArm = SKAction.setTexture(SKTexture(imageNamed: "player1Throw"))
            let lowerArm = SKAction.setTexture(SKTexture(imageNamed: "player"))
            let pause = SKAction.wait(forDuration: 0.15)
            let sequence = SKAction.sequence([raiseArm, pause, lowerArm])
            player1.run(sequence)
            
            // 6
            let impulse = CGVector(dx: cos(radians) * speed, dy: sin(radians) * speed)
            banana.physicsBody?.applyImpulse(impulse)
        } else {
            // 7
            banana.position = CGPoint(x: player2.position.x + 30, y: player2.position.y + 40)
            banana.physicsBody?.angularVelocity = 20
            
            let raiseArm = SKAction.setTexture(SKTexture(imageNamed: "player2Throw"))
            let lowerArm = SKAction.setTexture(SKTexture(imageNamed: "player"))
            let pause = SKAction.wait(forDuration: 0.15)
            let sequence = SKAction.sequence([raiseArm, pause, lowerArm])
            player2.run(sequence)
            
            let impulse = CGVector(dx: cos(radians) * -speed, dy: sin(radians) * speed)
            banana.physicsBody?.applyImpulse(impulse)
        }
    }
    
    func createPlayers() {
        player1 = SKSpriteNode(imageNamed: "player")
        player1.name = "player1"
        player1.physicsBody = SKPhysicsBody(circleOfRadius: player1.size.width / 2)
        player1.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player1.physicsBody?.collisionBitMask = CollisionTypes.banana.rawValue
        player1.physicsBody?.contactTestBitMask = CollisionTypes.banana.rawValue
        player1.physicsBody?.isDynamic = false
        
        let player1Building = buildings[1]
        player1.position = CGPoint(x: player1Building.position.x, y: player1Building.position.y + ((player1Building.size.height + player1.size.height) / 2))
        addChild(player1)
        
        player2 = SKSpriteNode(imageNamed: "player")
        player2.name = "player2"
        player2.physicsBody = SKPhysicsBody(circleOfRadius: player2.size.width / 2)
        player2.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player2.physicsBody?.collisionBitMask = CollisionTypes.banana.rawValue
        player2.physicsBody?.contactTestBitMask = CollisionTypes.banana.rawValue
        player2.physicsBody?.isDynamic = false
        
        let player2Building = buildings[buildings.count - 2]
        player2.position = CGPoint(x: player2Building.position.x, y: player2Building.position.y + ((player2Building.size.height + player2.size.height) / 2))
        addChild(player2)
    }
    
    func deg2rad(degrees: Int) -> Double {
        return Double(degrees) * Double.pi / 180
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody: SKPhysicsBody
        let secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        guard let firstNode = firstBody.node else { return }
        guard let secondNode = secondBody.node else { return }
        
        if firstNode.name == "banana" && secondNode.name == "building" {
            bananaHit(building: secondNode, atPoint: contact.contactPoint)
        }
        
        if firstNode.name == "banana" && secondNode.name == "player1" {
            scorePlayerTwo += 1
            destroy(player: player1)
            if scorePlayerTwo > 2 {
                showAlert(player: "Player 2")
                newGame(player: player1)
            }
        }
        
        if firstNode.name == "banana" && secondNode.name == "player2" {
            scorePlayerOne += 1
            destroy(player: player2)
            if scorePlayerOne > 2 {
                showAlert(player: "Player 1")
                newGame(player: player2)
            }
        }
    }
    
    func destroy(player: SKSpriteNode) {
        if let explosion = SKEmitterNode(fileNamed: "hitPlayer") {
            explosion.position = player.position
            addChild(explosion)
        }
        banana.removeFromParent()
        self.changePlayer()
        /// Генерация случайных значений для угла и скорости
        let randomAngle = Int.random(in: 0...90)  // случайный угол от 0 до 90 градусов
        let randomVelocity = Int.random(in: 50...250)  // случайная скорость от 50 до 250
        
        // Установка значений в слайдеры
        angleSlider.value = Float(randomAngle)  // Установить случайное значение для угла
        velocitySlider.value = Float(randomVelocity)  // Установить случайное значение для скорости
        
        // Обновление меток, чтобы отобразить новые значения
        angleLabel.text = "Angle: \(randomAngle)°"
        velocityLabel.text = "Velocity: \(randomVelocity)"
        
        print ("angleSlider.value  - \(angleSlider.value ) velocitySlider.value - \(velocitySlider.value)")
    }
    
    func newGame(player: SKSpriteNode) {
        player.removeFromParent()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let newGame = GameScene(size: self.size)
            newGame.viewController = self.viewController
            self.viewController.currentGame = newGame
            
            self.changePlayer()
            newGame.currentPlayer = self.currentPlayer
            
            let transition = SKTransition.doorway(withDuration: 1.5)
            self.view?.presentScene(newGame, transition: transition)
        }
    }
    
    func changePlayer() {
        
        if currentPlayer == 1 {
            currentPlayer = 2
        } else {
            currentPlayer = 1
        }
        
        viewController.activatePlayer(number: currentPlayer)
    }
    
    func bananaHit(building: SKNode, atPoint contactPoint: CGPoint) {
        guard let building = building as? BuildingNode else { return }
        let buildingLocation = convert(contactPoint, to: building)
        building.hit(at: buildingLocation)
        
        if let explosion = SKEmitterNode(fileNamed: "hitBuilding") {
            explosion.position = contactPoint
            addChild(explosion)
        }
        
        banana.name = ""
        banana.removeFromParent()
        banana = nil
        
        changePlayer()
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard banana != nil else { return }
        
        if abs(banana.position.y) > 1000 {
            banana.removeFromParent()
            banana = nil
            changePlayer()
        }
    }
    
    func createScore() {
        gameScorePlayerOne = SKLabelNode(fontNamed: "Chalkduster")
        gameScorePlayerOne.horizontalAlignmentMode = .left
        gameScorePlayerOne.zPosition = 100 // Установите zPosition выше других элементов
        gameScorePlayerOne.fontSize = 24
        addChild(gameScorePlayerOne)
        
        gameScorePlayerOne.position = CGPoint(x: 8, y: self.size.height - 100)
        scorePlayerOne = 0
        
        gameScorePlayerTwo = SKLabelNode(fontNamed: "Chalkduster")
        gameScorePlayerTwo.horizontalAlignmentMode = .right
        gameScorePlayerTwo.zPosition = 100 // Установите zPosition выше других элементов
        gameScorePlayerTwo.fontSize = 24
        addChild(gameScorePlayerTwo)
        
        gameScorePlayerTwo.position = CGPoint(x: self.size.width - 8, y: self.size.height - 100)
        scorePlayerTwo = 0
    }
    
    func showAlert(player: String) {
        // Создаем лейбл для текста
        let alertLabel = SKLabelNode(fontNamed: "Chalkduster")
        alertLabel.text = "\(player) win!"
        alertLabel.fontSize = 48
        alertLabel.fontColor = .yellow
        alertLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        alertLabel.alpha = 0  // Начальная прозрачность 0, чтобы скрыть лейбл
        addChild(alertLabel)
        
        // Анимация появления (увеличение прозрачности)
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let wait = SKAction.wait(forDuration: 3)  // Ждем 3 секунды
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)  // Анимация исчезновения
        
        // Выполнение анимаций
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut])
        alertLabel.run(sequence) {
            alertLabel.removeFromParent()  // Удаляем лейбл после анимации
        }
    }

}
