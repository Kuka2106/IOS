
// 1. Array Creation and Access
let fruits: [String] = ["apple", "banana", "cherry", "mango", "orange"]
print("Third fruit: \(fruits[2])")

// 2. Set Creation and Manipulation
var favoriteNumbers: Set<Int> = [7, 13, 21, 42]
favoriteNumbers.insert(99)
print("Updated favorite numbers set: \(favoriteNumbers)")

// 3. Dictionary Creation and Access
let languageReleaseYears: [String: Int] = [
    "Swift": 2014,
    "Python": 1991,
    "Java": 1995
]
print("Swift was released in \(languageReleaseYears["Swift"] ?? 0)")

// 4. Array Element Update
var colors: [String] = ["red", "green", "blue", "yellow"]
colors[1] = "purple"
print("Updated colors array: \(colors)")


// MARK: - Medium Tasks

// 1. Set Intersection
let setA: Set<Int> = [1, 2, 3, 4]
let setB: Set<Int> = [3, 4, 5, 6]
let intersectionResult = setA.intersection(setB)
print("Intersection of setA and setB: \(intersectionResult)")

// 2. Dictionary Update
var studentScores: [String: Int] = [
    "Aigerim": 85,
    "Timur": 90,
    "Dana": 78
]
studentScores.updateValue(95, forKey: "Aigerim")
print("Updated student scores: \(studentScores)")

// 3. Array Merge
let fruitsPartOne = ["apple", "banana"]
let fruitsPartTwo = ["cherry", "date"]
let mergedFruits = fruitsPartOne + fruitsPartTwo
print("Merged array: \(mergedFruits)")

// 1. Dictionary Key Addition
var countryPopulations: [String: Int] = [
    "Kazakhstan": 19_800_000,
    "USA": 331_000_000,
    "Japan": 125_000_000
]
countryPopulations["Germany"] = 84_000_000
print("Updated country populations: \(countryPopulations)")

// 2. Set Union and Subtract
let animalsOne: Set<String> = ["cat", "dog"]
let animalsTwo: Set<String> = ["dog", "mouse"]
let unionOfAnimals = animalsOne.union(animalsTwo)
let finalAnimalSet = unionOfAnimals.subtracting(animalsTwo)
print("Final set after union and subtract: \(finalAnimalSet)")

// 3. Nested Collection
let studentGrades: [String: [Int]] = [
    "Aigerim": [88, 92, 79],
    "Timur": [75, 81, 90],
    "Dana": [95, 89, 100]
]
let aigerimSecondGrade = studentGrades["Aigerim"]?[1]
print("Aigerim's second grade: \(aigerimSecondGrade ?? 0)")