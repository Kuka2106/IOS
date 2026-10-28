// =============================================================
//  Station ALMA-7: Rescue Protocol
//  iOS Mobile Development · Module 3 · Lab Assignment
//
//  How to use:
//   • Xcode: File → New → Playground → Blank, replace everything
//     with this file's contents.
//   • Terminal: swift ALMA7_Starter.swift
//
//  Rules:
//   • Do NOT modify the STARTER CODE section.
//   • `!` (force unwrap) is forbidden: −0.5 points each.
//   • No map / filter / reduce / compactMap.
//   • Use the exact function names from the assignment PDF.
// =============================================================


// MARK: - =================== STARTER CODE ===================
// MARK: - Do not modify anything in this section

typealias Reading = (sensor: String, value: Int)

/// Splits a string at the first occurrence of the separator.
/// splitOnce("O2:87", by: ":") -> ("O2", "87")
/// splitOnce("hello", by: ":") -> nil
func splitOnce(_ line: String, by separator: Character) -> (String, String)? {
    guard let index = line.firstIndex(of: separator) else { return nil }
    let left = String(line[..<index])
    let right = String(line[line.index(after: index)...])
    return (left, right)
}

let rawLog = [
    "O2:87", "TEMP:-12", "O2:9x", "PRESS:101", "TEMP:abc", "O2:",
    "RAD:3", "O2:64", ":55", "TEMP:31", "PRESS:98", "O2:71",
    "RAD:-1", "TEMP:4", "PRESS:1o2", "O2:90"
]

class Tank {
    var level: Int
    init(level: Int) { self.level = level }
}

class Module {
    let name: String
    var oxygenTank: Tank?
    init(name: String, oxygenTank: Tank?) {
        self.name = name
        self.oxygenTank = oxygenTank
    }
}

class CrewMember {
    let name: String
    let role: String
    let priority: Int      // 1 = evacuated first
    var module: Module?    // nil = in open space
    init(name: String, role: String, priority: Int, module: Module?) {
        self.name = name
        self.role = role
        self.priority = priority
        self.module = module
    }
}

let lab  = Module(name: "Lab",  oxygenTank: Tank(level: 40))
let hab  = Module(name: "Hab",  oxygenTank: Tank(level: 12))
let dock = Module(name: "Dock", oxygenTank: nil)

let crew = [
    CrewMember(name: "Timur",   role: "Engineer",  priority: 3, module: lab),
    CrewMember(name: "Dana",    role: "Scientist", priority: 4, module: dock),
    CrewMember(name: "Aigerim", role: "Commander", priority: 1, module: hab),
    CrewMember(name: "Nurlan",  role: "Pilot",     priority: 2, module: nil)
]

var roster: [String: CrewMember] = [:]
for member in crew { roster[member.name] = member }

print("ALMA-7 systems online: \(rawLog.count) log lines, \(crew.count) crew members.")

// MARK: - ================= END OF STARTER CODE =================


// MARK: - =================== YOUR SOLUTION ===================


// MARK: Level 1 · Decoding Telemetry

// 1.1
/// A line is valid only if: it contains ":", the sensor name is non-empty,
/// the value parses as Int, and the value is >= 0 (except TEMP, which may be negative).
/// Everything is checked in a single guard let with comma-separated conditions.
func parseReading(_ raw: String) -> Reading? {
    guard let (sensor, valueString) = splitOnce(raw, by: ":"),
          !sensor.isEmpty,
          let value = Int(valueString),
          value >= 0 || sensor == "TEMP" else {
        return nil
    }
    return (sensor: sensor, value: value)
}

// Test parseReading with at least two calls (plus the examples from the PDF).
print("--- 1.1 parseReading ---")
print(parseReading("O2:87") ?? (sensor: "nil", value: 0))
print(parseReading("TEMP:-12") ?? (sensor: "nil", value: 0))
print(parseReading("RAD:-1") ?? (sensor: "nil", value: 0))
print(parseReading(":55") ?? (sensor: "nil", value: 0))

// 1.2
func parseLog(_ lines: [String]) -> (valid: [Reading], invalidCount: Int) {
    var validReadings: [Reading] = []
    var invalidCount = 0
    for line in lines {
        if let reading = parseReading(line) {
            validReadings.append(reading)
        } else {
            invalidCount += 1
        }
    }
    return (valid: validReadings, invalidCount: invalidCount)
}

let parsedLog = parseLog(rawLog)
print("--- 1.2 parseLog ---")
print("Valid readings: \(parsedLog.valid.count), invalid lines: \(parsedLog.invalidCount)")
print(parseLog(["O2:5", "bad"]))              // second test call

let A = parsedLog.invalidCount
print("Code fragment A = \(A)")


// MARK: Level 2 · Analysis

// 2.1
func select(_ readings: [Reading], where isIncluded: (Reading) -> Bool) -> [Reading] {
    var result: [Reading] = []
    for reading in readings {
        if isIncluded(reading) {
            result.append(reading)
        }
    }
    return result
}

func values(of readings: [Reading]) -> [Int] {
    var result: [Int] = []
    for reading in readings {
        result.append(reading.value)
    }
    return result
}

// select must use a trailing closure and $0.
let o2Readings = select(parsedLog.valid) { $0.sensor == "O2" }
let tempReadings = select(parsedLog.valid) { $0.sensor == "TEMP" }

print("--- 2.1 select / values ---")
print("O2 readings: \(o2Readings)")
print("O2 values: \(values(of: o2Readings))")
print("TEMP values: \(values(of: tempReadings))")     // second test call

// 2.2
func stats(of values: [Int]) -> (min: Int, max: Int, average: Double)? {
    guard let firstValue = values.first else { return nil }
    var minValue = firstValue
    var maxValue = firstValue
    var sum = 0
    for value in values {
        if value < minValue { minValue = value }
        if value > maxValue { maxValue = value }
        sum += value
    }
    return (min: minValue, max: maxValue, average: Double(sum) / Double(values.count))
}

// Variadic version must not duplicate logic — single line, no return.
func stats(_ values: Int...) -> (min: Int, max: Int, average: Double)? {
    stats(of: values)
}

print("--- 2.2 stats ---")
print(stats(3, 8, 1) ?? (min: 0, max: 0, average: 0.0))   // (min: 1, max: 8, average: 4.0)
print(stats() ?? (min: 0, max: 0, average: 0.0))          // nil case

let o2Stats = stats(of: values(of: o2Readings))
let tempStats = stats(of: values(of: tempReadings))

// Code fragment B = average O2 value, converted to Int.
let B = Int(o2Stats?.average ?? 0)
print("Code fragment B = \(B)")

// 2.3 · The Closure Ladder
print("--- 2.3 Closure Ladder ---")

// 1. Full closure syntax with types and return
let sorted1 = parsedLog.valid.sorted(by: { (a: Reading, b: Reading) -> Bool in
    return a.value > b.value
})

// 2. Types inferred from context
let sorted2 = parsedLog.valid.sorted(by: { (a, b) in
    return a.value > b.value
})

// 3. Implicit return
let sorted3 = parsedLog.valid.sorted(by: { (a, b) in a.value > b.value })

// 4. Shorthand argument names
let sorted4 = parsedLog.valid.sorted(by: { $0.value > $1.value })

// 5. Trailing closure
let sorted5 = parsedLog.valid.sorted { $0.value > $1.value }

let allSortsMatch = values(of: sorted1) == values(of: sorted2)
    && values(of: sorted2) == values(of: sorted3)
    && values(of: sorted3) == values(of: sorted4)
    && values(of: sorted4) == values(of: sorted5)
print("All five sorts match: \(allSortsMatch)")


// MARK: Level 3 · Temperature Stabilization

// 3.1
func heatUp(_ t: Int) -> Int { t + 5 }
func coolDown(_ t: Int) -> Int { t - 3 }
func hold(_ t: Int) -> Int { t }

func chooseProtocol(for temp: Int) -> (Int) -> Int {
    if temp < 18 { return heatUp }
    if temp > 24 { return coolDown }
    return hold
}

print("--- 3.1 chooseProtocol ---")
print(heatUp(10), coolDown(30), hold(20))          // first test call (three functions at once)
print(chooseProtocol(for: 10)(10), chooseProtocol(for: 30)(30), chooseProtocol(for: 20)(20))

// 3.2
func runUntilStable(from start: Int, maxSteps: Int = 10) -> (finalTemp: Int, steps: Int, isStable: Bool) {
    var temp = start
    var steps = 0
    while (temp < 18 || temp > 24) && steps < maxSteps {
        let activeProtocol = chooseProtocol(for: temp)
        temp = activeProtocol(temp)
        steps += 1
    }
    let isStable = temp >= 18 && temp <= 24
    return (finalTemp: temp, steps: steps, isStable: isStable)
}

print("--- 3.2 runUntilStable ---")
print(runUntilStable(from: 31))                      // (finalTemp: 22, steps: 3, isStable: true)
print(runUntilStable(from: -100, maxSteps: 5))        // (finalTemp: -75, steps: 5, isStable: false)

// Code fragment C = steps for the lowest valid temperature in the log,
// found via select + stats (not typed in by hand).
let lowestTemp = tempStats?.min ?? 0
let C = runUntilStable(from: lowestTemp).steps
print("Lowest valid TEMP in log: \(lowestTemp)")
print("Code fragment C = \(C)")


// MARK: Level 4 · The Crew

// 4.1
func oxygenLevel(of member: CrewMember) -> Int? {
    member.module?.oxygenTank?.level
}

print("--- 4.1 oxygenLevel ---")
print(oxygenLevel(of: roster["Timur"] ?? crew[0]) ?? -1)   // 40
print(oxygenLevel(of: roster["Nurlan"] ?? crew[0]) ?? -1)  // -1 (no data)

// 4.2
func status(of member: CrewMember) -> String {
    guard let level = oxygenLevel(of: member) else {
        let location = member.module?.name ?? "open space"
        return "\(member.name): no data (\(location))"
    }
    let state = level < 20 ? "CRITICAL" : "OK"
    return "\(member.name): \(level)% \(state)"
}

print("--- 4.2 status (whole crew) ---")
for member in crew {
    print(status(of: member))
}

// 4.3
@discardableResult
func transferOxygen(from source: inout Int, to target: inout Int, amount: Int) -> Int {
    guard amount > 0 else { return 0 }
    let capacity = 100
    let takeable = min(amount, source)
    let room = capacity - target
    let actualTransfer = min(takeable, room)
    guard actualTransfer > 0 else { return 0 }
    source -= actualTransfer
    target += actualTransfer
    return actualTransfer
}

print("--- 4.3 transferOxygen ---")
if let labTank = lab.oxygenTank, let habTank = hab.oxygenTank {
    let transferred = transferOxygen(from: &labTank.level, to: &habTank.level, amount: 30)
    print("Transferred \(transferred) units from Lab to Hab. Lab now: \(labTank.level), Hab now: \(habTank.level)")

    // Second test call: negative amount must do nothing.
    let rejectedTransfer = transferOxygen(from: &labTank.level, to: &habTank.level, amount: -5)
    print("Negative-amount transfer moved: \(rejectedTransfer) (should be 0)")
}

// Code fragment D = oxygen level in Hab after the transfer.
let D = hab.oxygenTank?.level ?? 0
print("Code fragment D = \(D)")

// 4.4
func evacuationOrder(_ names: String..., roster: [String: CrewMember]) -> [String] {
    var found: [CrewMember] = []
    for name in names {
        guard let member = roster[name] else {
            print("Unknown crew member: \(name)")
            continue
        }
        found.append(member)
    }
    let sortedMembers = found.sorted { $0.priority < $1.priority }
    var result: [String] = []
    for member in sortedMembers {
        result.append(member.name)
    }
    return result
}

print("--- 4.4 evacuationOrder ---")
print(evacuationOrder("Dana", "Ghost", "Aigerim", "Timur", roster: roster))
// Unknown crew member: Ghost
// ["Aigerim", "Timur", "Dana"]
print(evacuationOrder("Nurlan", "Aigerim", roster: roster))   // second test call


// MARK: Level 5 · The Saboteur's Logbook
//
// Problems found in the original code (not every bug is a `!`):
//
// 1. `member.module!` — crashes for any crew member with no module
//    (Nurlan: module == nil). Force-unwrapping nil traps the program.
// 2. `.oxygenTank!` — crashes for any module with no tank
//    (Dock: oxygenTank == nil, e.g. Dana). Same trap risk.
// 3. `oxygenLevel(of: member)!` in firstCritical — crashes for any crew
//    member with no oxygen data (no module, or module without a tank).
// 4. `return result!` in firstCritical — if NO crew member is critical,
//    `result` stays nil and the force unwrap crashes. This wouldn't even
//    need bad data, just a healthy crew.
// 5. LOGIC BUG (not a `!` at all): the loop never stops once it finds a
//    critical member — it keeps scanning and overwrites `result` with
//    every later critical member it finds. So the function actually
//    returns the LAST critical member, not the first, despite its name.
//    With the starter crew only Aigerim is critical, so this bug is
//    invisible until there are two or more critical members.

func reportOxygen(for member: CrewMember) -> String {
    guard let tank = member.module?.oxygenTank else {
        return "\(member.name): no tank data"
    }
    return "\(member.name): \(tank.level)%"
}

func firstCritical(in crew: [CrewMember]) -> String? {
    for member in crew {
        guard let level = oxygenLevel(of: member) else { continue }
        if level < 20 {
            return member.name   // stop at the FIRST critical member
        }
    }
    return nil
}

print("--- Level 5 Saboteur fixes ---")
// Test 1: reportOxygen no longer crashes on crew members without tanks/modules.
print(reportOxygen(for: roster["Dana"] ?? crew[0]))    // "Dana: no tank data"
print(reportOxygen(for: roster["Nurlan"] ?? crew[0]))  // "Nurlan: no tank data"

// Test 2: firstCritical with the real crew (only Aigerim is critical).
print(firstCritical(in: crew) ?? "none")               // "Aigerim"

// Test 3 (proves the LOGIC bug is fixed, not just the `!`s):
// build a crew where TWO members are critical, in a known order, and
// confirm the function returns the FIRST one, not the last.
let criticalTank1 = Tank(level: 5)
let criticalModule1 = Module(name: "TestModuleA", oxygenTank: criticalTank1)
let criticalMember1 = CrewMember(name: "TestCritical1", role: "Test", priority: 1, module: criticalModule1)

let criticalTank2 = Tank(level: 8)
let criticalModule2 = Module(name: "TestModuleB", oxygenTank: criticalTank2)
let criticalMember2 = CrewMember(name: "TestCritical2", role: "Test", priority: 2, module: criticalModule2)

let testCrew = [criticalMember1, criticalMember2]
let firstCriticalTestResult = firstCritical(in: testCrew)
print("First critical in test crew: \(firstCriticalTestResult ?? "none")")
// Must print "TestCritical1": the buggy original would have kept
// overwriting `result` and returned "TestCritical2" instead.


// MARK: Finale · Launch Code

let launchCode = "\(A)-\(B)-\(C)-\(D)"
print("LAUNCH CODE: \(launchCode)")


// MARK: Bonus

func makeAlarm(threshold: Int) -> (Int) -> Bool {
    var alarmCount = 0
    return { level in
        let isBelow = level < threshold
        if isBelow {
            alarmCount += 1
            print("Alarm #\(alarmCount)")
        }
        return isBelow
    }
}

print("--- Bonus makeAlarm ---")
let alarm = makeAlarm(threshold: 20)
print(alarm(12))   // Alarm #1 -> true
print(alarm(40))   // false
print(alarm(5))    // Alarm #2 -> true

let alarm2 = makeAlarm(threshold: 50)   // second, independent alarm/counter
print(alarm2(10))  // Alarm #1 -> true (its own counter, starts fresh)


// MARK: - ================= DEFENSE QUESTIONS =================
/*
 1. guard let vs if let beyond syntax:
    guard let unwraps the optional and, on failure, forces an early exit
    (return / continue / break / throw) from the current scope. The
    unwrapped value then stays available for the REST of the function,
    not just inside a nested block. if let only makes the unwrapped
    value available inside its own braces; once that block ends, the
    binding is gone.
    Example where if let makes things worse — parseReading has four
    conditions to check before it can build a Reading. With if let you'd
    have to nest every remaining line one level deeper for each check
    (a "pyramid of doom"):
        if let (sensor, valueString) = splitOnce(raw, by: ":") {
            if !sensor.isEmpty {
                if let value = Int(valueString) {
                    if value >= 0 || sensor == "TEMP" {
                        return (sensor, value)
                    }
                }
            }
        }
        return nil
    guard let keeps the same logic flat, with the failure/return written
    once, at the top, right next to the conditions it belongs to.

 2. Why can't you call stats(someArray) where someArray: [Int]?
    Because `stats(_ values: Int...)` is variadic: it expects each Int to
    be listed separately at the call site (stats(1, 2, 3)), and Swift
    turns those separate arguments into an [Int] array INSIDE the
    function body. It does not accept an already-built [Int] array as a
    stand-in for "a list of Int arguments" — there's no array-splat in
    Swift. So `stats(someArray)` doesn't type-check against the variadic
    overload; you'd need `stats(of: someArray)` (the array-taking
    overload) instead.

 3. Why doesn't transferOxygen(from: &x, to: &x, amount: 5) compile?
    Because both `from` and `to` are inout parameters, and passing the
    SAME variable to two inout parameters of the same call would give
    the function two mutable, aliased references to one memory location
    at once. Swift's exclusivity-of-access rules forbid this at compile
    time. It prevents a real bug: inside the function you'd be reading
    and writing `source` and `target` as if they were independent, but
    they'd secretly be the same storage — so `source -= actualTransfer`
    and `target += actualTransfer` could interleave unpredictably and
    corrupt the single shared value instead of moving oxygen between two
    different tanks.

 4. Why doesn't oxygenLevel(of: dana) ?? "no data" compile?
    oxygenLevel(of:) returns Int?, and "no data" is a String. The ??
    operator requires the default (right-hand side) to have the SAME
    type as the value wrapped by the optional (Int here), not just "be
    convertible to a String when printed." To fix it you either give an
    Int default (oxygenLevel(of: dana) ?? -1) or convert to a
    description first, e.g. "\(oxygenLevel(of: dana) ?? -1)" or an
    explicit ternary that produces a String on both branches.

 5. Full type of chooseProtocol and how to read it:
    chooseProtocol has type: (Int) -> ((Int) -> Int)
    Read it from the outermost arrow inward: chooseProtocol is a
    function that takes one Int (the temperature) and returns a
    function; that returned function itself has type (Int) -> Int,
    i.e. it takes an Int and returns an Int. So calling
    chooseProtocol(for: 10) doesn't give you a temperature — it gives
    you back one of heatUp / coolDown / hold, which you then call again
    with a temperature to actually get an Int.

 Bonus. Where does the alarm counter live after makeAlarm returns?
    `alarmCount` is captured BY REFERENCE by the closure that
    makeAlarm returns. Swift moves captured mutable variables out of
    the stack frame into a heap-allocated box that the closure holds a
    reference to. Once makeAlarm returns, its own stack frame is gone,
    but the closure (a reference type) keeps that heap box alive for as
    long as the closure itself exists. Every call to `alarm(...)` reads
    and writes that same persistent heap storage, which is why the
    counter keeps incrementing across calls instead of resetting.
*/
