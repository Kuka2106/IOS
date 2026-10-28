// =============================================================
//  Station ALMA-7, Part II: The Teleporter Incident
//  iOS Mobile Development · Module 4 · Lab Assignment
//
//  How to use:
//   • Xcode: File → New → Playground → Blank, replace everything
//     with this file's contents.
//   • Terminal: swift ALMA7_Part2_Starter.swift
//
//  Rules:
//   • Do NOT modify the STARTER DATA section.
//   • `!` (force unwrap) is forbidden: −0.5 points each.
//   • No map / filter / reduce / compactMap.
//   • Default to struct. Use class only where the task says so.
// =============================================================


// MARK: - =================== STARTER DATA ===================
// MARK: - Do not modify anything in this section

/// Splits a line into fields.
/// fields("crate:101:120")            -> ["crate", "101", "120"]
/// fields("livestock:lab mice:12:2")  -> ["livestock", "lab mice", "12", "2"]
/// fields("junk")                     -> ["junk"]
func fields(_ line: String, separatedBy separator: Character = ":") -> [String] {
    var result: [String] = []
    var current = ""
    for character in line {
        if character == separator {
            result.append(current)
            current = ""
        } else {
            current.append(character)
        }
    }
    result.append(current)
    return result
}

/// Cargo manifest as recovered from the damaged recorder.
let rawManifest = [
    "crate:101:120",
    "container:KZ-ALM-7:340",
    "livestock:lab mice:12:2",
    "???-corrupted-line",
    "crate:102:75",
    "container:KZ-ALM-9:410",
    "livestock:ficus:3:5",
    "crate:103:260",
    "crate:104:abc",
    ""
]

/// Oxygen readings. One of these deck names is not a real deck.
let deckReadings: [(deck: String, oxygen: Int)] = [
    (deck: "bridge",     oxygen: 78),
    (deck: "lab",        oxygen: 64),
    (deck: "greenhouse", oxygen: 55),
    (deck: "cargo",      oxygen: 12),
    (deck: "medbay",     oxygen: 90),
    (deck: "engine",     oxygen: 41)
]

/// Crew records, straight from the personnel file.
let crewData: [(name: String, deck: String, oxygen: Int)] = [
    (name: "Timur",   deck: "engine", oxygen: 62),
    (name: "Dana",    deck: "lab",    oxygen: 48),
    (name: "Aigerim", deck: "bridge", oxygen: 91),
    (name: "Nurlan",  deck: "cargo",  oxygen: 17)
]

print("ALMA-7 recorder online: \(rawManifest.count) manifest lines, \(deckReadings.count) readings, \(crewData.count) crew records.")

// MARK: - ================= END OF STARTER DATA =================


// MARK: - =================== YOUR SOLUTION ===================


// MARK: Level 1 · The Deck Register

// 1.1
enum Deck: String, CaseIterable {
    case bridge, lab, cargo, medbay, engine

    var evacuationPriority: Int {
        switch self {
        case .bridge: return 1
        case .medbay: return 2
        case .lab:    return 3
        case .engine: return 4
        case .cargo:  return 5
        }
    }
}

print("\n=== Level 1 ===")
for deck in Deck.allCases {
    print("Deck \(deck.rawValue) -> evacuation priority \(deck.evacuationPriority)")
}

// 1.2
enum AlarmLevel: Int {
    case green = 0
    case yellow, orange, red

    /// Every full 500 kg raises the alarm one step; 1500+ kg is red.
    static func level(forTotalMass mass: Int) -> AlarmLevel {
        let step = max(0, min(mass / 500, AlarmLevel.red.rawValue))
        return AlarmLevel(rawValue: step) ?? .red
    }
}

print("AlarmLevel for 0 kg:    \(AlarmLevel.level(forTotalMass: 0))")
print("AlarmLevel for 940 kg:  \(AlarmLevel.level(forTotalMass: 940))")
print("AlarmLevel for 4000 kg: \(AlarmLevel.level(forTotalMass: 4000))")


// MARK: Level 2 · The Manifest

// 2.1
enum ManifestEntry {
    case crate(id: Int, massKg: Int)
    case container(code: String, massKg: Int)
    case livestock(species: String, count: Int, massPerUnitKg: Int)
    case unknown(raw: String)
}

// 2.2
func parseEntry(_ line: String) -> ManifestEntry {
    let parts = fields(line)
    guard let tag = parts.first else { return .unknown(raw: line) }

    switch tag {
    case "crate":
        if parts.count == 3, let id = Int(parts[1]), let massKg = Int(parts[2]) {
            return .crate(id: id, massKg: massKg)
        }
    case "container":
        if parts.count == 3, let massKg = Int(parts[2]) {
            return .container(code: parts[1], massKg: massKg)
        }
    case "livestock":
        if parts.count == 4, let count = Int(parts[2]), let perUnit = Int(parts[3]) {
            return .livestock(species: parts[1], count: count, massPerUnitKg: perUnit)
        }
    default:
        break
    }
    return .unknown(raw: line)
}

// 2.3
func mass(of entry: ManifestEntry) -> Int {
    switch entry {
    case .crate(_, let massKg):
        return massKg
    case .container(_, let massKg):
        return massKg
    case .livestock(_, let count, let massPerUnitKg):
        return count * massPerUnitKg
    case .unknown:
        return 0
    }
}

print("\n=== Level 2 ===")
var totalManifestMass = 0
var unknownCount = 0
for line in rawManifest {
    let entry = parseEntry(line)
    if case .unknown = entry {
        unknownCount += 1
    }
    let entryMass = mass(of: entry)
    totalManifestMass += entryMass
    print("\"\(line)\" -> \(entry) -> \(entryMass) kg")
}
print("Unknown (corrupted) lines: \(unknownCount)")
print("Total manifest mass: \(totalManifestMass) kg")

let A = totalManifestMass


// MARK: Level 3 · Crew Snapshots

// 3.1
struct CrewSnapshot {
    let name: String
    var deck: Deck
    var oxygen: Int

    mutating func breathe(_ amount: Int) {
        oxygen = max(0, oxygen - amount)
    }

    mutating func move(to deck: Deck) {
        self.deck = deck
    }

    mutating func reviveInMedbay() {
        // A brand-new value replaces self entirely.
        self = CrewSnapshot(name: name, deck: .medbay, oxygen: 100)
    }

    static func rookie(named name: String) -> CrewSnapshot {
        return CrewSnapshot(name: name, deck: .bridge, oxygen: 100)
    }
}

// 3.2
func buildRoster() -> [CrewSnapshot] {
    var result: [CrewSnapshot] = []
    for record in crewData {
        if let deck = Deck(rawValue: record.deck) {
            result.append(CrewSnapshot(name: record.name, deck: deck, oxygen: record.oxygen))
        } else {
            print("WARNING: \(record.name) is assigned to unknown deck \"\(record.deck)\" — skipped")
        }
    }
    return result
}

print("\n=== Level 3 ===")
let crewRoster: [CrewSnapshot] = buildRoster()
for member in crewRoster {
    print("Crew: \(member.name) on \(member.deck.rawValue), oxygen \(member.oxygen)")
}

/// Finds a crew member by name without force unwrapping.
func crewMember(named name: String) -> CrewSnapshot? {
    for member in crewRoster where member.name == name {
        return member
    }
    return nil
}

var rookie = CrewSnapshot.rookie(named: "Aliya")
print("Rookie: \(rookie)")
rookie.breathe(130)
print("Rookie after breathe(130), clamped at 0: oxygen \(rookie.oxygen)")
rookie.move(to: .engine)
print("Rookie after move(to: .engine): deck \(rookie.deck.rawValue)")
rookie.reviveInMedbay()
print("Rookie after reviveInMedbay(): \(rookie)")

// 3.3 · Value-semantics demonstration (copy / plain parameter / inout)

// (1) Copy
var original = CrewSnapshot.rookie(named: "Arman")
print("[copy] before: original.oxygen = \(original.oxygen)")
var copy = original
copy.breathe(40)
print("[copy] after:  copy.oxygen = \(copy.oxygen), original.oxygen = \(original.oxygen)  (original unchanged)")

// (2) Plain parameter: the function only gets its own copy
func drainPlain(_ snapshot: CrewSnapshot) {
    var local = snapshot          // parameters are constants; change a local copy
    local.breathe(50)
    print("[plain] inside function: local.oxygen = \(local.oxygen)")
}
print("[plain] before: original.oxygen = \(original.oxygen)")
drainPlain(original)
print("[plain] after:  original.oxygen = \(original.oxygen)  (original unchanged)")

// (3) inout: the change is written back to the caller's variable
func drainInout(_ snapshot: inout CrewSnapshot) {
    snapshot.breathe(50)
}
print("[inout] before: original.oxygen = \(original.oxygen)")
drainInout(&original)
print("[inout] after:  original.oxygen = \(original.oxygen)  (original CHANGED)")


// MARK: Level 4 · The Teleport Pod

// 4.1
// CrewSnapshot (a struct) got a free memberwise initializer. Classes never get
// one: TeleportPod has stored properties without default values (id, chargeLevel),
// so we must write a designated initializer ourselves.
final class TeleportPod {
    let id: String
    var chargeLevel: Int
    var occupant: CrewSnapshot?

    init(id: String, chargeLevel: Int) {
        self.id = id
        self.chargeLevel = chargeLevel
        self.occupant = nil
    }

    /// Fails if the pod is occupied or charge < 20.
    func load(_ crew: CrewSnapshot) -> Bool {
        guard occupant == nil, chargeLevel >= 20 else { return false }
        occupant = crew
        return true
    }

    /// No occupant -> nil and no charge spent. Success costs 20 charge.
    func fire() -> CrewSnapshot? {
        guard let crew = occupant else { return nil }
        chargeLevel -= 20
        occupant = nil
        return crew
    }

    // Bonus 1
    deinit {
        print("deinit: TeleportPod \(id) destroyed")
    }
}

// 4.2 · Charge ledger
print("\n=== Level 4 ===")
let pod = TeleportPod(id: "P-1", chargeLevel: 100)
print("P-1 start: charge \(pod.chargeLevel)")

for name in ["Timur", "Dana", "Nurlan"] {
    if let member = crewMember(named: name) {
        let loaded = pod.load(member)
        let arrived = pod.fire()
        print("load \(name): \(loaded), fire -> \(arrived?.name ?? "nobody"), charge \(pod.chargeLevel)")
    } else {
        print("\(name) is not on the roster — step skipped, charge \(pod.chargeLevel)")
    }
}
let emptyShot = pod.fire()
print("fire empty pod -> \(emptyShot?.name ?? "nil"), charge \(pod.chargeLevel)")

let C = pod.chargeLevel

// 4.3 · Reference-semantics demonstration
let podAlias = pod
print("[class] before: pod = \(pod.chargeLevel), podAlias = \(podAlias.chargeLevel)")
podAlias.chargeLevel = 5
print("[class] after podAlias.chargeLevel = 5: pod = \(pod.chargeLevel), podAlias = \(podAlias.chargeLevel)  (both changed)")
pod.chargeLevel = C   // restore the ledger value

var snapA = CrewSnapshot.rookie(named: "Bota")
var snapB = snapA
print("[struct] before: snapA = \(snapA.oxygen), snapB = \(snapB.oxygen)")
snapB.oxygen = 5
print("[struct] after snapB.oxygen = 5: snapA = \(snapA.oxygen), snapB = \(snapB.oxygen)  (only snapB changed)")
// Rule: assigning a class instance copies the REFERENCE (both names point to one
// object); assigning a struct copies the VALUE (two independent instances).


// MARK: Level 5 · Station Systems

// 5.1
final class Station {
    // Stored let
    let callSign: String

    // Stored var
    var oxygenByDeck: [Deck: Int]

    // Stored var with observers
    var hullIntegrity: Int {
        willSet {
            print("hullIntegrity: \(hullIntegrity) -> \(newValue)")
        }
        didSet {
            // Assigning to the property inside its own didSet does NOT call the
            // observers again, so this clamp cannot loop forever.
            hullIntegrity = max(0, min(hullIntegrity, 100))
        }
    }

    // Lazy stored
    lazy var fullDiagnostics: String = {
        print("Running full scan...")
        var report = "Diagnostics for \(self.callSign): "
        for deck in Deck.allCases {
            if let level = self.oxygenByDeck[deck] {
                report += "\(deck.rawValue)=\(level) "
            }
        }
        report += "| hull \(self.hullIntegrity)"
        return report
    }()

    // Computed, read-only (no `get` keyword)
    var totalOxygen: Int {
        var sum = 0
        for (_, level) in oxygenByDeck {
            sum += level
        }
        return sum
    }

    // Computed, get + set (default `newValue`)
    var averageOxygen: Int {
        get {
            guard oxygenByDeck.count > 0 else { return 0 }
            return totalOxygen / oxygenByDeck.count
        }
        set {
            for deck in Deck.allCases where oxygenByDeck[deck] != nil {
                oxygenByDeck[deck] = newValue
            }
        }
    }

    init(callSign: String) {
        self.callSign = callSign
        var readings: [Deck: Int] = [:]
        for reading in deckReadings {
            if let deck = Deck(rawValue: reading.deck) {
                readings[deck] = reading.oxygen
            } else {
                print("Station: skipping reading for unknown deck \"\(reading.deck)\"")
            }
        }
        self.oxygenByDeck = readings
        self.hullIntegrity = 100   // observers are not called during init
    }
}

print("\n=== Level 5 ===")
let station = Station(callSign: "ALMA-7")
let B = station.averageOxygen
print("\(station.callSign): totalOxygen \(station.totalOxygen), averageOxygen \(B) over \(station.oxygenByDeck.count) decks")

print("-- accessing fullDiagnostics for the first time:")
print(station.fullDiagnostics)
print("-- accessing fullDiagnostics again (no scan message expected):")
print(station.fullDiagnostics)

let spareStation = Station(callSign: "ALMA-SPARE")
print("\(spareStation.callSign) created; its fullDiagnostics is never touched, so no \"Running full scan...\" for it.")

station.averageOxygen = 70
print("After averageOxygen = 70: \(station.oxygenByDeck.count) decks, total \(station.totalOxygen), average \(station.averageOxygen)")

// 5.2 · The clamp trap
station.hullIntegrity = 130
print("hullIntegrity after 130: \(station.hullIntegrity)")
station.hullIntegrity = -40
print("hullIntegrity after -40: \(station.hullIntegrity)")
station.hullIntegrity = 55
print("hullIntegrity after 55: \(station.hullIntegrity)")
// Why no infinite loop: Swift does not trigger willSet/didSet when a property
// is assigned from inside its own observer, so the clamp writes the value directly.


// MARK: Level 6 · Incident Reports
// NOTE: Reports 1 and 2 compile and are wrong. Report 3 does not compile, and in
// Report 4 the first assignment does not compile (the second one is fine).

/*
// Report 1
var roster = crewRoster
for var member in roster {
    member.oxygen -= 10
}
print(roster[0].oxygen)   // author expected the crew to have lost oxygen

// Report 2
let podA = TeleportPod(id: "A", chargeLevel: 100)
let podB = podA
podB.chargeLevel = 0
print(podA.chargeLevel)   // author expected 100

// Report 3
struct Logbook {
    var entries: [String] = []
    func add(_ entry: String) {
        entries.append(entry)
    }
}

// Report 4
let snapshot = CrewSnapshot.rookie(named: "Dana")
snapshot.oxygen = 40

let pod = TeleportPod(id: "B", chargeLevel: 50)
pod.chargeLevel = 10
*/

/*
 Report 1
   Expected: every crew member loses 10 oxygen; prints 52.
   Actual:   prints 62. `member` is a COPY of each struct element; the copy is
             changed and thrown away, the array is untouched.
   Rule:     structs are value types; `for var x in array` iterates over copies.
   Fix:      modify the elements in place through their indices (below).

 Report 2
   Expected: 100 (author thought podB is a separate pod).
   Actual:   prints 0. `let podB = podA` copies the reference — one object, two names.
   Rule:     classes are reference types; assignment shares the instance.
   Fix:      create a real, separate pod (below), or make the pod a struct if
             shared identity is not wanted.

 Report 3
   Does not compile: "cannot use mutating member on immutable value: 'self' is immutable".
   Rule:     inside a non-mutating struct method `self` is a constant, so its
             stored properties cannot be changed.
   Fix:      mark the method `mutating`.

 Report 4
   `snapshot.oxygen = 40` does not compile: "cannot assign to property: 'snapshot'
   is a 'let' constant". `pod.chargeLevel = 10` compiles fine.
   Rule:     `let` on a struct freezes the whole value, including every property.
             `let` on a class freezes only the reference (pod must always point to
             the same object); the object's `var` properties stay mutable.
   Fix:      declare `var snapshot`.
*/

print("\n=== Level 6 (fixed versions) ===")
do {   // Report 1 fixed
    var roster = crewRoster
    for index in roster.indices {
        roster[index].breathe(10)
    }
    print("Report 1 fixed: \(roster[0].name) oxygen \(roster[0].oxygen) (was \(crewRoster[0].oxygen))")
}
do {   // Report 2 fixed
    let podA = TeleportPod(id: "A", chargeLevel: 100)
    let podB = TeleportPod(id: "A-copy", chargeLevel: podA.chargeLevel)
    podB.chargeLevel = 0
    print("Report 2 fixed: podA \(podA.chargeLevel), podB \(podB.chargeLevel)")
}
do {   // Report 3 fixed
    struct Logbook {
        var entries: [String] = []
        mutating func add(_ entry: String) {
            entries.append(entry)
        }
    }
    var log = Logbook()
    log.add("day 10: teleporter incident")
    print("Report 3 fixed: logbook has \(log.entries.count) entry")
}
do {   // Report 4 fixed
    var snapshot = CrewSnapshot.rookie(named: "Dana")
    snapshot.oxygen = 40
    let pod = TeleportPod(id: "B", chargeLevel: 50)
    pod.chargeLevel = 10
    print("Report 4 fixed: snapshot oxygen \(snapshot.oxygen), pod B charge \(pod.chargeLevel)")
}


// MARK: Level 7 · Sealing the Black Box

final class FlightRecorder {
    // private: nobody outside the class can replace, clear or edit the list directly.
    private var entries: [String] = []

    // private(set): outside code can READ isSealed but never set it (so never back to false).
    private(set) var isSealed = false

    // internal: anyone in the module may read how many entries exist.
    internal var entryCount: Int {
        return entries.count
    }

    // internal: anyone may read the formatted transcript (read-only copy).
    internal var transcript: String {
        var text = ""
        for (index, entry) in entries.enumerated() {
            text += "#\(index + 1) \(entry)\n"
        }
        return text
    }

    // internal: anyone may add an entry — but the method refuses once sealed.
    internal func add(_ entry: String) -> Bool {
        guard isSealed == false else { return false }
        entries.append(entry)
        return true
    }

    // internal: anyone may seal; there is no method that unseals.
    internal func seal() {
        isSealed = true
    }

    // fileprivate: visible to code in THIS file (auditTranscript), hidden from other files.
    fileprivate func rawEntriesForAudit() -> [String] {
        return entries
    }
}

/// Free function in the same file: uses the fileprivate helper.
func auditTranscript(of recorder: FlightRecorder) -> String {
    var characters = 0
    for entry in recorder.rawEntriesForAudit() {
        characters += entry.count
    }
    return "AUDIT: \(recorder.entryCount) entries, \(characters) characters, sealed: \(recorder.isSealed)"
}

print("\n=== Level 7 ===")
let recorder = FlightRecorder()
print("add before seal: \(recorder.add("Pod P-1 fired with Timur"))")
print("add before seal: \(recorder.add("Pod P-1 fired with Dana"))")
recorder.seal()
print("add after seal:  \(recorder.add("Nothing happened, honest"))")
print("entryCount: \(recorder.entryCount), isSealed: \(recorder.isSealed)")
print(recorder.transcript, terminator: "")
print(auditTranscript(of: recorder))

// Trying to break the recorder from outside the type:
// recorder.entries = []
// error: 'entries' is inaccessible due to 'private' protection level
// recorder.isSealed = false
// error: cannot assign to property: 'isSealed' setter is inaccessible


// MARK: Finale · Integrity Code

let D = AlarmLevel.level(forTotalMass: A).rawValue
let integrityCode = "\(A)-\(B)-\(C)-\(D)"
print("\nINTEGRITY CODE: \(integrityCode)")


// MARK: Bonus

print("\n=== Bonus ===")
// 2. Lifetime experiment
var survivingReference: TeleportPod? = nil
do {
    let tempPod = TeleportPod(id: "TMP", chargeLevel: 30)
    survivingReference = tempPod
    print("inside do-block: tempPod \(tempPod.id) created, 2 strong references")
}
print("after do-block: pod still alive? \(survivingReference?.id ?? "no")  (tempPod is gone, survivingReference keeps it)")
survivingReference = nil   // <- deinit fires on THIS line: the last strong reference is removed
print("after survivingReference = nil")

// 3. Identity vs equal contents
func comparePods(_ first: TeleportPod, _ second: TeleportPod) -> String {
    if first === second {
        return "same pod (one object, two references)"
    }
    if first.id == second.id,
       first.chargeLevel == second.chargeLevel,
       first.occupant?.name == second.occupant?.name {
        return "two different pods with equal contents"
    }
    return "two different pods"
}
let twinA = TeleportPod(id: "T", chargeLevel: 60)
let twinB = TeleportPod(id: "T", chargeLevel: 60)
let twinAlias = twinA
print("twinA vs twinAlias: \(comparePods(twinA, twinAlias))")
print("twinA vs twinB:     \(comparePods(twinA, twinB))")
// === cannot be used on CrewSnapshot: it is a struct (value type). Values have no
// identity — every copy is an independent value, there is no shared object to point
// to. === is defined only for class instances (AnyObject).


// MARK: - ================= DEFENSE QUESTIONS =================
/*
 1. Why did CrewSnapshot get an initializer for free and TeleportPod did not?
    Structs automatically get a memberwise initializer (CrewSnapshot(name:deck:oxygen:)).
    Classes never get one; they only get a free init() if EVERY stored property has a
    default value. TeleportPod's id and chargeLevel have none, so we write init(id:chargeLevel:).

 2. What does `mutating` do to self, and why do classes never need it?
    It makes `self` an inout parameter: the method can change stored properties or even
    replace the whole value (`self = CrewSnapshot(...)` in reviveInMedbay). Without it, self
    inside a struct method is a constant. In a class, self is a reference to a heap object;
    methods change the object, not the reference, so no special permission is needed.

 3. In Report 4 both values are `let`. What exactly does `let` freeze for a
    struct, and what does it freeze for a class?
    Struct: the whole value — no property can change, no mutating method can be called.
    Class: only the reference — `pod` must always point to the same object, but the
    object's `var` properties (chargeLevel) can still change.

 4. Why must a lazy property be var? When does lazy change behaviour, not
    just performance?
    Its value is assigned AFTER initialization (on first access), and a `let` must have
    its value when init finishes — so lazy must be var. Behaviour changes when building the
    value has side effects or depends on state: fullDiagnostics prints "Running full scan..."
    only if touched, and it captures the station state at FIRST access (oxygen and hull at
    that moment), not at init and not later.

 5. private vs fileprivate: where in your FlightRecorder would private be
    too strict?
    auditTranscript(of:) is a free function outside the class but in the same file, and it
    needs the raw entries. If rawEntriesForAudit() were private it would be invisible to it;
    fileprivate opens it to this file only, while other files still can't see it.

 Bonus. On which line does deinit fire, and why can't === be used on
 CrewSnapshot?
    On `survivingReference = nil`. Leaving the do-block removes tempPod's reference, but
    survivingReference still holds one, so the count is 1; setting it to nil drops the count
    to 0 and ARC destroys the pod. === compares object identity; CrewSnapshot is a struct,
    values have no identity, so === isn't available for it.
*/