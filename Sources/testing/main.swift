import Foundation

class Base {
    var chambers: [Chamber] = []
    var radiators: Int = 0
}

class Chamber {
    var id: Int
    var pineapples: Int = 0
    var heat: Int = 0
    var nodeChambers: [Int] = []
    var hasRadiator = false

    init(id: Int) {
        self.id = id
    }
}
    
let contents = try String(contentsOfFile: "/Users/bryanacaragay/Desktop/bases.txt", encoding: .utf8)

var base: Base?
var radiatorChambers: [Chamber] = []

// The current chamber we are building
var currentChamber: Chamber?
var currentScore = 0
var currentRadiatorChambers: [Int] = []
var bestRadiatorChambers: [Int] = []

// Returns the chamber for this ID
func getChamberForID(_ id: Int) -> Chamber? {
    return base?.chambers.first(where: { $0.id == id })
}

// Adds the radiator to the chamber and adjusts it's values and it's child values.
func addRadiatorToChamber(chamber: Chamber) {
    chamber.heat += 5
    chamber.hasRadiator = true
    currentRadiatorChambers.append(chamber.id)
    for nodeID in chamber.nodeChambers {
        if let nodeChamber = getChamberForID(nodeID) {
            nodeChamber.heat += 3
            let strippedIds = nodeChamber.nodeChambers.filter { $0 != chamber.id }
            strippedIds.forEach { id in
                if let nodeChildChamber = getChamberForID(id) {
                    nodeChildChamber.heat += 1
                }
            }
        }
    }
}

// Validates the radiator and resets it if it's not valid (any values over 11 in the tree)
func validateRadiator(chamber: Chamber) {
    if chamber.heat > 10 {
        resetChamber(chamber)
    }
    
    for nodeID in chamber.nodeChambers {
        if let nodeChamber = getChamberForID(nodeID) {
            if nodeChamber.heat > 10 {
                resetChamber(chamber)
            }
            let strippedIds = nodeChamber.nodeChambers.filter { $0 != chamber.id }
            strippedIds.forEach { id in
                if let nodeChildChamber = getChamberForID(id) {
                    if nodeChildChamber.heat > 10 {
                        resetChamber(chamber)
                    }
                }
            }
        }
    }
}

// Checks for heat values over 11
func isBaseValid() -> Bool {
    guard let base = base else { return false }
    for chamber in base.chambers {
        if chamber.heat >= 11 {
            print("overheated")
            return false // Overheated
        }
    }
    
    // Doesn't mean anything except we didn't break the base. Score is not a consideration here.
    return true
}

// Returns the current score of pineapples we're able to make.
func getPineappleScore() -> Int {
    guard let base = base else { return 0 }
    var pineapples = 0
    for chamber in base.chambers {
        // Valid heat, add pineapples.
        if chamber.heat >= 4 && chamber.heat <= 6 {
            pineapples += chamber.pineapples
        }
    }
    return pineapples
}

// We have a valid configuration, update the score if it's higher than the previous one.
func saveScoreIfNeeded() {
    let newScore = getPineappleScore()
    if newScore > currentScore {
        currentScore = newScore
        bestRadiatorChambers = currentRadiatorChambers
    }
}

// Checks the configuration and saves the score if it's valid.
func checkConfiguration() {
    if isBaseValid() {
        saveScoreIfNeeded()
    }
}

// Resets the last radiator values added to the chamber.
func resetChamber(_ chamber: Chamber) {
    chamber.heat -= 5
    chamber.hasRadiator = false
    currentRadiatorChambers.removeLast()
    
    for nodeID in chamber.nodeChambers {
        if let nodeChamber = getChamberForID(nodeID) {
            nodeChamber.heat -= 3
            let strippedIds = nodeChamber.nodeChambers.filter { $0 != chamber.id }
            strippedIds.forEach { id in
                if let nodeChildChamber = getChamberForID(id) {
                    nodeChildChamber.heat -= 1
                }
            }
        }
    }
}

// Attempts to place the radiators in the base such that we get the highest score. We randomly try 100 combinations of random starting points, in hopes to hit a lot of use cases without repeating attempts.
func placeRadiators() {
    guard let base = base else { return }
    
    // Try 100 variations starting with different nodes each time. Not a huge fan of this, but it works.
    for index in 0...99 {
        if index == 0 {
            // First try ordering the chambers so the ones with the most pineapples are tried first.
            let chambers = base.chambers.sorted{ $0.pineapples > $1.pineapples }
            
            chambers.forEach { chamber in
                if currentRadiatorChambers.count < base.radiators {
                    addRadiatorToChamber(chamber: chamber)
                    validateRadiator(chamber: chamber)
                }
            }
        } else {
            // Now try random sorted
            base.chambers.forEach { chamber in
                if currentRadiatorChambers.count < base.radiators {
                    addRadiatorToChamber(chamber: chamber)
                    validateRadiator(chamber: chamber)
                }
            }
        }
        
        checkConfiguration()
        currentRadiatorChambers = []
        base.chambers.shuffle()
    }
    
    var finalOutput = ""
    for (index, id) in bestRadiatorChambers.enumerated() {
        if index == 0 {
            finalOutput += "\(id)"
        } else {
            finalOutput += ",\(id)"
        }
    }
    
    print(finalOutput)
    
    bestRadiatorChambers = []
    currentRadiatorChambers = []
    currentScore = 0
}

// Method to construct the bases from the text file.
func buildBase() {
    let lines = contents.components(separatedBy: "\n")
    for (index, line) in lines.enumerated() {
        if line.contains("Pineapple Moon Base") {
            // We have a current base, we hit a new one.
            if base != nil {
                // Main app logic
                placeRadiators()
            }
            
            // Reset the base after we configure the last one
            base = Base()
            base?.radiators = 0
        }
        
        // Assign radiator count to the base
        
        if line.contains("Radiators") {
            let radiatorsString = line.components(separatedBy: "Radiators: ")[1]
            if let newRadiators = Int(radiatorsString) {
                base?.radiators += newRadiators
            }
        }
        
        // Build chambers
        
        if line.contains("Chamber") {
            // We hit a new chamber
            if let chamber = currentChamber {
                base?.chambers.append(chamber)
            }
            
            currentChamber = nil
            
            let chamberIdString = line.components(separatedBy: "Chamber ")[1]
            if let chamberID = Int(chamberIdString) {
                let chamber = Chamber(id: chamberID)
                currentChamber = chamber
            }
        }
        
        // Add pineapples
        
        if line.contains("Pineapples") {
            let pinappleValueString = line.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
            if let pineapples = Int(pinappleValueString) {
                currentChamber?.pineapples = pineapples
            }
        }
        
        // Create nodes
        
        if line.contains("North") || line.contains("South") || line.contains("East") || line.contains("West") {
            let idString = line.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
            
            if let id = Int(idString) {
                currentChamber?.nodeChambers.append(id)
            }
        }
        
        // End of the file
        if index >= lines.count - 1 {
            // Main app logic
            placeRadiators()
        }
    }
}

buildBase()
