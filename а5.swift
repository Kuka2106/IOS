// =============================================================
//  Station ALMA-7, Part III: The Repair Fleet
//  iOS Mobile Development · Module 5 · Lab Assignment
//
//  How to use:
//   • Xcode: File → New → Playground → Blank, replace everything
//     with this file's contents.
//   • Terminal: swift ALMA7_Part3_Starter.swift
//
//  Rules:
//   • Do NOT modify the STARTER DATA section. LegacyBeacon in
//     particular must be reached with an extension, not edited.
//   • `!` (force unwrap) is forbidden: −0.5 points each.
//   • No map / filter / reduce / compactMap.
//   • The Health Rule must exist in exactly ONE place in this file.
// =============================================================


// MARK: - =================== STARTER DATA ===================
// MARK: - Do not modify anything in this section

/// Drone records recovered from the fleet registry.
/// One `kind` does not correspond to any drone type you will build.
let fleetData: [(kind: String, id: String, charge: Int)] = [
    (kind: "welder",  id: "W-1", charge: 80),
    (kind: "scanner", id: "S-1", charge: 45),
    (kind: "cargo",   id: "C-1", charge: 100),
    (kind: "welder",  id: "W-2", charge: 15),
    (kind: "scanner", id: "S-2", charge: 60),
    (kind: "tug",     id: "T-1", charge: 50)
]

/// Hull sensors. These are NOT drones — they never move and never work a shift.
let sensorData: [(id: String, charge: Int)] = [
    (id: "hull-cam", charge: 12),
    (id: "thermal",  charge: 77)
]

/// Hardware from the original station. You may not add anything to this
/// declaration — no methods, no protocols, no properties.
struct LegacyBeacon {
    let name: String
    let signalStrength: Int
}

let beacon = LegacyBeacon(name: "ALMA-BEACON", signalStrength: 8)

print("Fleet registry online: \(fleetData.count) drone records, \(sensorData.count) sensors, beacon \(beacon.name).")

// MARK: - ================= END OF STARTER DATA =================


// MARK: - =================== YOUR SOLUTION ===================


// MARK: Level 1 · The Power Cell

// Why a class and not a struct here?  -> A drone and anyone holding it must share ONE
// battery whose charge changes over time, so it needs reference semantics (one identity),
// not independent copies.
final class PowerCell {
    private var charge: Int

    /// Clamps the starting value into 0...100.
    init(charge: Int) {
        self.charge = max(0, min(charge, 100))
    }

    func level() -> Int {
        return charge
    }

    /// false and no change if amount <= 0 or not enough charge.
    func spend(_ amount: Int) -> Bool {
        guard amount > 0, amount <= charge else { return false }
        charge -= amount
        return true
    }

    /// Ignores non-positive amounts, never goes above 100.
    func recharge(by amount: Int) {
        guard amount > 0 else { return }
        charge = min(100, charge + amount)
    }
}

print("\n=== Level 1 ===")
let cell = PowerCell(charge: 150)
print("PowerCell(charge: 150) clamped -> \(cell.level())")
print("spend(30): \(cell.spend(30)), level \(cell.level())")
print("spend(0): \(cell.spend(0)), spend(-5): \(cell.spend(-5)), spend(500): \(cell.spend(500)), level \(cell.level())")
cell.recharge(by: -10)
print("recharge(by: -10) ignored -> \(cell.level())")
cell.recharge(by: 90)
print("recharge(by: 90) capped -> \(cell.level())")
print("PowerCell(charge: -20) clamped -> \(PowerCell(charge: -20).level())")

// Encapsulation proof (leave this commented, with the compiler error):
// cell.charge = 100
// error: 'charge' is inaccessible due to 'private' protection level


// MARK: Level 2 · The Fleet

// 2.1  What does `final` on runOnce() buy you?  -> No subclass can override the shift ritual,
// so every drone, present or future, must pay its power cost before it is allowed to work.
class Drone {
    let id: String
    let cell: PowerCell

    init(id: String, cell: PowerCell) {
        self.id = id
        self.cell = cell
    }

    var powerCost: Int { 10 }

    var statusLine: String {
        let level = cell.level()
        return "\(id): \(level)% \(level.powerBar)"
    }

    /// Work units produced. A bare drone does nothing.
    func performTask() -> Int { 0 }

    /// The shift ritual: pay first, then work. Cannot be overridden.
    final func runOnce() -> Int {
        guard cell.spend(powerCost) else { return 0 }
        return performTask()
    }

    /// Enough charge for one more task?
    var canRunAnotherTask: Bool {
        return cell.level() >= powerCost
    }
}

// 2.2
final class WelderDrone: Drone {
    override var powerCost: Int { 25 }
    override func performTask() -> Int { 40 }

    func weldSeam() -> String {
        return "\(id) welds a hull seam"
    }
}

class ScannerDrone: Drone {
    override var powerCost: Int { 10 }
    override func performTask() -> Int { 15 }

    override var statusLine: String {
        return super.statusLine + " [scanner]"
    }
}

final class CargoDrone: Drone {
    override var powerCost: Int { 20 }
    override func performTask() -> Int { 25 }
}

// 2.3
func makeDrone(kind: String, id: String, charge: Int) -> Drone? {
    let cell = PowerCell(charge: charge)
    switch kind {
    case "welder":  return WelderDrone(id: id, cell: cell)
    case "scanner": return ScannerDrone(id: id, cell: cell)
    case "cargo":   return CargoDrone(id: id, cell: cell)
    default:        return nil
    }
}

func buildFleet() -> [Drone] {
    var result: [Drone] = []
    for record in fleetData {
        if let drone = makeDrone(kind: record.kind, id: record.id, charge: record.charge) {
            result.append(drone)
        } else {
            print("WARNING: unknown drone kind \"\(record.kind)\" for \(record.id) — skipped")
        }
    }
    return result
}

print("\n=== Level 2 ===")
let fleet: [Drone] = buildFleet()
for drone in fleet {
    print("Before shift: \(drone.statusLine), cost \(drone.powerCost)")
}
let demoWelder = WelderDrone(id: "W-DEMO", cell: PowerCell(charge: 50))
print(demoWelder.weldSeam())
print("A bare Drone produces \(Drone(id: "X-0", cell: PowerCell(charge: 100)).performTask()) work units")


// MARK: Level 3 · The Shift

func runShift(_ fleet: [Drone], rounds: Int) -> Int {
    var total = 0
    var round = 0
    while round < rounds {
        for drone in fleet {
            total += drone.runOnce()     // one call, different behaviour per object
        }
        round += 1
    }
    return total
}

print("\n=== Level 3 ===")
let totalWork = runShift(fleet, rounds: 3)
print("Total work units after 3 rounds: \(totalWork)")

var remainingCharge = 0
var readyDrones = 0
for drone in fleet {
    print("After shift: \(drone.statusLine)")
    remainingCharge += drone.cell.level()
    if drone.canRunAnotherTask {
        readyDrones += 1
    }
}
print("Remaining charge: \(remainingCharge), drones ready for one more task: \(readyDrones)")

let A = totalWork
let B = remainingCharge
let C = readyDrones


// MARK: Level 4 · Diagnostics

// 4.1
protocol Diagnosable {
    var componentID: String { get }
    var statusCode: Int { get }
    func diagnose() -> String
}

// 4.2
protocol Rechargeable {
    mutating func recharge(by amount: Int)
}

// Why does Drone implement recharge(by:) without `mutating`?  -> Drone is a class: `self` is a
// reference, so changing the object never changes the reference; `mutating` exists only for
// value types, and a non-mutating method still satisfies a mutating requirement.
extension Drone: Diagnosable, Rechargeable {
    var componentID: String { id }
    var statusCode: Int { healthCode(for: cell.level()) }

    func recharge(by amount: Int) {
        cell.recharge(by: amount)
    }
}

struct SensorModule: Diagnosable, Rechargeable {
    let id: String
    var chargeLevel: Int

    var componentID: String { id }
    var statusCode: Int { healthCode(for: chargeLevel) }

    mutating func recharge(by amount: Int) {
        guard amount > 0 else { return }
        chargeLevel = min(100, chargeLevel + amount)
    }
}

func buildSensors() -> [SensorModule] {
    var result: [SensorModule] = []
    for record in sensorData {
        result.append(SensorModule(id: record.id, chargeLevel: record.charge))
    }
    return result
}

let sensors = buildSensors()

// 4.3
// Why could [Drone] never have held the sensors?  -> SensorModule is a struct, not a subclass of
// Drone (structs can't inherit at all), so only a protocol type can hold both.
func diagnosticsReport(_ components: [Diagnosable]) -> String {
    var report = "---- DIAGNOSTICS (\(components.count) components) ----\n"
    for component in components {
        report += component.diagnose() + "\n"
    }
    return report
}

print("\n=== Level 4 ===")
var components: [Diagnosable] = []
for drone in fleet { components.append(drone) }
for sensor in sensors { components.append(sensor) }
print(diagnosticsReport(components), terminator: "")

// Rechargeable demo on SEPARATE objects, so the mission numbers stay untouched:
var spareSensor = SensorModule(id: "spare", chargeLevel: 10)
spareSensor.recharge(by: 50)
print("Spare sensor after recharge(by: 50): \(spareSensor.chargeLevel), code \(spareSensor.statusCode)")
let spareDrone = CargoDrone(id: "C-SPARE", cell: PowerCell(charge: 5))
spareDrone.recharge(by: 200)
print("Spare drone after recharge(by: 200): \(spareDrone.statusLine), code \(spareDrone.statusCode)")


// MARK: Level 5 · Shared Behaviour

// 5.1 · default diagnose() + the single home of the Health Rule
extension Diagnosable {
    func diagnose() -> String {
        return "\(componentID): code \(statusCode)"
    }

    /// THE Health Rule — the only place in this file where the thresholds live.
    /// below 20 -> 2 (critical), 20...49 -> 1 (warning), 50+ -> 0 (nominal)
    func healthCode(for level: Int) -> Int {
        if level < 20 { return 2 }
        if level < 50 { return 1 }
        return 0
    }
}

// 5.2 · the beacon you cannot edit
extension LegacyBeacon: Diagnosable {
    var componentID: String { name }
    var statusCode: Int { healthCode(for: signalStrength) }

    func diagnose() -> String {
        return "*** LEGACY HARDWARE *** \(name) | signal \(signalStrength) | code \(statusCode) | manual check required"
    }
}

print("\n=== Level 5 ===")
components.append(beacon)
print(diagnosticsReport(components), terminator: "")

var statusSum = 0
for component in components {
    statusSum += component.statusCode
}
print("Sum of status codes: \(statusSum)")
let D = statusSum

// 5.3
extension Int {
    /// 42 -> "####......" ; clamped so -5 and 250 still give 10 characters.
    var powerBar: String {
        let filled = Swift.max(0, Swift.min(self / 10, 10))
        var bar = ""
        var position = 0
        while position < 10 {
            bar += position < filled ? "#" : "."
            position += 1
        }
        return bar
    }
}

print("42.powerBar  = \(42.powerBar)")
print("-5.powerBar  = \((-5).powerBar)")
print("250.powerBar = \(250.powerBar)")


// MARK: Level 6 · Incident Reports
// NOTE: in real Swift Reports 1, 2 and 3 all fail to compile; Report 4 compiles and lies.

/*
// Report 1
class PatchDrone: Drone {
    func performTask() -> Int {
        return 30
    }
}

// Report 2
final class HeavyWelder: WelderDrone {
    override func runOnce() -> Int {
        return 999
    }
}

// Report 3
let reportFleet: [Drone] = [WelderDrone(id: "W-9", cell: PowerCell(charge: 100))]
let first = reportFleet[0]
print(first.weldSeam())

// Report 4
protocol Labelled {
    var componentID: String { get }
}

extension Labelled {
    func label() -> String { "generic component" }
}

struct Thruster: Labelled {
    let componentID: String
    func label() -> String { "thruster \(componentID)" }
}

let parts: [Labelled] = [Thruster(componentID: "T-1")]
print(parts[0].label())
*/

/*
 Report 1
   Expected: PatchDrone produces 30 work units per task.
   Actual:   does not compile — "overriding declaration requires an 'override' keyword".
   Rule:     a subclass method with the same signature as a superclass method must be
             marked `override`, so accidental overrides are impossible.
   Fix:      `override func performTask() -> Int { 30 }`.

 Report 2
   Expected: a welder that yields 999 work units for free.
   Actual:   does not compile — "inheritance from a final class 'WelderDrone'" and
             "instance method overrides a 'final' instance method".
   Rule:     a final class can't be subclassed; a final method can't be overridden.
   Fix:      subclass Drone and change only cost/work; the ritual stays untouched.

 Report 3
   Expected: prints the weld message.
   Actual:   does not compile — "value of type 'Drone' has no member 'weldSeam'".
   Rule:     the compiler checks members by the STATIC type (Drone), even though the
             object at runtime is a WelderDrone.
   Fix:      downcast with `as?`. It returns an optional because the cast can fail at
             runtime — the element might be a scanner, and then the result is nil.

 Report 4
   Expected: "thruster T-1".
   Actual:   prints "generic component".
   Rule:     label() is NOT a protocol requirement, it only lives in the extension.
             Calls through the protocol type `Labelled` are dispatched statically to the
             extension; the struct's method merely shadows it and is only used when the
             static type is Thruster. Requirements are dispatched dynamically.
   Fix:      add `func label() -> String` to the protocol (one line) — see LabelledFixed.
*/

class PatchDrone: Drone {                       // Report 1 fixed
    override func performTask() -> Int { 30 }
}

class HeavyWelder: Drone {                      // Report 2 fixed
    override var powerCost: Int { 40 }
    override func performTask() -> Int { 70 }
}

protocol LabelledFixed {                        // Report 4 fixed
    var componentID: String { get }
    func label() -> String                      // <- the one line that changes the output
}

extension LabelledFixed {
    func label() -> String { "generic component" }
}

struct ThrusterFixed: LabelledFixed {
    let componentID: String
    func label() -> String { "thruster \(componentID)" }
}

print("\n=== Level 6 (fixed versions) ===")
let patch = PatchDrone(id: "P-9", cell: PowerCell(charge: 50))
print("Report 1 fixed: PatchDrone runOnce -> \(patch.runOnce())")
let heavy = HeavyWelder(id: "H-9", cell: PowerCell(charge: 50))
print("Report 2 fixed: HeavyWelder runOnce -> \(heavy.runOnce()), second run -> \(heavy.runOnce()) (out of charge)")

let reportFleet: [Drone] = [WelderDrone(id: "W-9", cell: PowerCell(charge: 100))]
for member in reportFleet {                     // Report 3 fixed
    if let welder = member as? WelderDrone {
        print("Report 3 fixed: \(welder.weldSeam())")
    } else {
        print("Report 3 fixed: \(member.id) is not a welder")
    }
}

let fixedParts: [LabelledFixed] = [ThrusterFixed(componentID: "T-1")]
for part in fixedParts {
    print("Report 4 fixed: \(part.label())")
}


// MARK: Finale · Mission Code

let missionCode = "\(A)-\(B)-\(C)-\(D)"
print("\nMISSION CODE: \(missionCode)")


// MARK: Bonus

// 1a. Runtime: a base method that traps if a subclass forgets to override it.
//     Instantiating is allowed, but calling performTask() on a bare base crashes.
class RuntimeAbstractDrone {
    func performTask() -> Int {
        fatalError("RuntimeAbstractDrone is abstract: subclasses must override performTask()")
    }
}
// RuntimeAbstractDrone().performTask()   // compiles, crashes at runtime

// 1b. Compile time: make the base a PROTOCOL. A protocol can't be instantiated at all,
//     and a conforming type that forgets performTask() does not compile.
//     DroneUnit()   // error: 'any DroneUnit' cannot be constructed because it has no accessible initializers

// 2. Protocol-based redesign
protocol DroneUnit {
    var id: String { get }
    var cell: PowerCell { get }
    var powerCost: Int { get }
    func performTask() -> Int
}

extension DroneUnit {
    /// Same ritual, written once. Not a requirement, so conforming types can't
    /// replace it through the protocol (closest thing to `final`).
    func runOnce() -> Int {
        guard cell.spend(powerCost) else { return 0 }
        return performTask()
    }
}

struct WelderUnit: DroneUnit {
    let id: String
    let cell: PowerCell
    var powerCost: Int { 25 }
    func performTask() -> Int { 40 }
}

struct ScannerUnit: DroneUnit {
    let id: String
    let cell: PowerCell
    var powerCost: Int { 10 }
    func performTask() -> Int { 15 }
}

func runUnitShift(_ units: [DroneUnit], rounds: Int) -> Int {
    var total = 0
    var round = 0
    while round < rounds {
        for unit in units {
            total += unit.runOnce()
        }
        round += 1
    }
    return total
}

print("\n=== Bonus ===")
let units: [DroneUnit] = [
    WelderUnit(id: "WU-1", cell: PowerCell(charge: 80)),
    ScannerUnit(id: "SU-1", cell: PowerCell(charge: 45))
]
print("Protocol-based fleet, 3 rounds: \(runUnitShift(units, rounds: 3)) work units")
for unit in units {
    print("\(unit.id): \(unit.cell.level())%")
}

// 3. Comparison:
// The class design gives shared stored properties, one init and a truly `final` ritual,
// at the cost of allowing a meaningless bare Drone and allowing only classes. The protocol
// design forbids a bare drone at compile time and lets structs (and even types we can't
// edit) join the fleet, but the ritual is only "final by convention". For this station I'd
// pick the protocol design; if drones had to share mutable state (a common battery or a
// shared counter), that state must live in a class — here it already does (PowerCell), and
// more shared state would push toward the class hierarchy or more reference-type members.


// MARK: - ================= DEFENSE QUESTIONS =================
/*
 1. Why does a class satisfy a `mutating` protocol requirement without the
    keyword, while a struct must write it?
    `mutating` lets a method change `self`. For a struct, self IS the value, so changing
    chargeLevel changes self and needs mutating (self becomes inout). For a class, self is a
    reference; recharge changes the object it points to, never the reference itself, so no
    keyword is needed. A mutating requirement is a permission, not an obligation.

 2. One thing inheritance does that protocols cannot, and one thing
    protocols do that inheritance cannot:
    Inheritance: shares stored properties and implementation (id, cell, init, the final
    runOnce ritual) and lets a subclass call super (ScannerDrone.statusLine).
    Protocols: unite unrelated types — classes, structs, even a type we can't edit
    (LegacyBeacon via extension) — and a type can conform to many protocols.

 3. What does `final` prevent, and what did it protect in runOnce()?
    On a method it prevents overriding; on a class it prevents subclassing. In runOnce()
    it protects the rule "spend power first, work only if paid": no subclass (like
    HeavyWelder in Report 2) can skip the energy check and produce free work.

 4. In Report 4, why did the protocol extension's method win?
    label() is not a requirement of Labelled, so it has no entry in the protocol's witness
    table. Calling it on a value of type Labelled is resolved statically to the extension
    version; Thruster's label() only shadows it and is used when the static type is
    Thruster. Declaring label() in the protocol makes the call dynamic, and the struct wins.
*/