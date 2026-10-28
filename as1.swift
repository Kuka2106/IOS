import Foundation

let firstName: String = "Kuanysh"
let lastName: String = "Manarbekov"

let birthYear: Int = 2004
let currentYear: Int = 2026
let age: Int = currentYear - birthYear

let isStudent: Bool = true
let height: Double = 1.75

let city: String = "Aqtobe"
let university: String = "KBTU"
let favoriteFood: String = "Borsht"

let hobby: String = "Singing"
let numberOfHobbies: Int = 5
let favoriteNumber: Int = 666
let isHobbyCreative: Bool = true

let favoriteMusic: String = "Kairat Nurtas songs"
let favoriteSport: String = "Football"
let hasPet: Bool = true

let futureGoals: String = "In the future, I want to become a professional high heels dancer."
let favoriteEmoji: String = "🤣"

let lifeStory = """
My name is \(firstName) \(lastName).
I am \(age) years old and I was born in \(birthYear).
I am currently a student: \(isStudent).
I live in \(city) and study at \(university).
My height is \(height) meters.
My favorite food is \(favoriteFood).

I enjoy \(hobby) \(favoriteEmoji), which is a creative hobby 
I have \(numberOfHobbies) hobbies in total.
My favorite number is \(favoriteNumber).
My favorite music is \(favoriteMusic).
I enjoy playing \(favoriteSport).
I have a pet: \(hasPet).

\(futureGoals)
"""

print(lifeStory)