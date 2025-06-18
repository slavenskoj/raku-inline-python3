#!/usr/bin/env raku

use Inline::Python3;

my $py = Inline::Python3.new;

say "=== Classes and Objects Examples ===\n";

# Basic class definition
say "1. Basic Python3 class:";
$py.run(q:to/PYTHON/);
class Person:
    def __init__(self, name, age):
        self.name = name
        self.age = age
    
    def greet(self):
        return f"Hello, I'm {self.name} and I'm {self.age} years old"
    
    def have_birthday(self):
        self.age += 1
        return f"{self.name} is now {self.age} years old!"

# Create instances
alice = Person("Alice", 30)
bob = Person("Bob", 25)

print(alice.greet())
print(bob.greet())
PYTHON

# Accessing Python3 objects from Raku
say "\n2. Using Python3 objects in Raku:";
my $alice = $py.run('alice', :eval);
say "Alice's name: " ~ $alice.name;
say "Alice's age: " ~ $alice.age;
say "Birthday: " ~ $alice.have_birthday();
say "New age: " ~ $alice.age;

# Class with properties
say "\n3. Python3 properties and computed attributes:";
$py.run(q:to/PYTHON/);
class Rectangle:
    def __init__(self, width, height):
        self.width = width
        self.height = height
    
    @property
    def area(self):
        return self.width * self.height
    
    @property
    def perimeter(self):
        return 2 * (self.width + self.height)
    
    @property
    def is_square(self):
        return self.width == self.height
    
    def __str__(self):
        return f"Rectangle({self.width}x{self.height})"

rect1 = Rectangle(5, 3)
rect2 = Rectangle(4, 4)

print(f"{rect1} - Area: {rect1.area}, Perimeter: {rect1.perimeter}, Square: {rect1.is_square}")
print(f"{rect2} - Area: {rect2.area}, Perimeter: {rect2.perimeter}, Square: {rect2.is_square}")
PYTHON

# Inheritance
say "\n4. Class inheritance:";
$py.run(q:to/PYTHON/);
class Animal:
    def __init__(self, name, species):
        self.name = name
        self.species = species
    
    def make_sound(self):
        return f"{self.name} makes a sound"
    
    def describe(self):
        return f"{self.name} is a {self.species}"

class Dog(Animal):
    def __init__(self, name, breed):
        super().__init__(name, "dog")
        self.breed = breed
    
    def make_sound(self):
        return f"{self.name} barks: Woof!"
    
    def fetch(self):
        return f"{self.name} is fetching the ball"

class Cat(Animal):
    def __init__(self, name):
        super().__init__(name, "cat")
    
    def make_sound(self):
        return f"{self.name} meows: Meow!"
    
    def purr(self):
        return f"{self.name} is purring"

# Create instances
dog = Dog("Buddy", "Golden Retriever")
cat = Cat("Whiskers")

# Polymorphism in action
animals = [dog, cat]
for animal in animals:
    print(animal.describe())
    print(animal.make_sound())
    print()
PYTHON

# Class methods and static methods
say "\n5. Class methods and static methods:";
$py.run(q:to/PYTHON/);
class MathOperations:
    pi = 3.14159
    
    @staticmethod
    def add(a, b):
        return a + b
    
    @staticmethod
    def multiply(a, b):
        return a * b
    
    @classmethod
    def circle_area(cls, radius):
        return cls.pi * radius ** 2
    
    @classmethod
    def circle_circumference(cls, radius):
        return 2 * cls.pi * radius

# Using static methods
print(f"5 + 3 = {MathOperations.add(5, 3)}")
print(f"4 × 7 = {MathOperations.multiply(4, 7)}")

# Using class methods
print(f"Area of circle (r=5): {MathOperations.circle_area(5):.2f}")
print(f"Circumference of circle (r=5): {MathOperations.circle_circumference(5):.2f}")
PYTHON

# Magic methods
say "\n6. Magic methods (dunder methods):";
$py.run(q:to/PYTHON/);
class Vector:
    def __init__(self, x, y):
        self.x = x
        self.y = y
    
    def __str__(self):
        return f"Vector({self.x}, {self.y})"
    
    def __repr__(self):
        return f"Vector(x={self.x}, y={self.y})"
    
    def __add__(self, other):
        return Vector(self.x + other.x, self.y + other.y)
    
    def __sub__(self, other):
        return Vector(self.x - other.x, self.y - other.y)
    
    def __mul__(self, scalar):
        return Vector(self.x * scalar, self.y * scalar)
    
    def __eq__(self, other):
        return self.x == other.x and self.y == other.y
    
    def __len__(self):
        return int((self.x ** 2 + self.y ** 2) ** 0.5)
    
    def __getitem__(self, index):
        if index == 0:
            return self.x
        elif index == 1:
            return self.y
        else:
            raise IndexError("Vector index out of range")

# Using magic methods
v1 = Vector(3, 4)
v2 = Vector(1, 2)

print(f"v1 = {v1}")
print(f"v2 = {v2}")
print(f"v1 + v2 = {v1 + v2}")
print(f"v1 - v2 = {v1 - v2}")
print(f"v1 * 2 = {v1 * 2}")
print(f"v1 == v2: {v1 == v2}")
print(f"len(v1) = {len(v1)}")
print(f"v1[0] = {v1[0]}, v1[1] = {v1[1]}")
PYTHON

# Data classes (simulated)
say "\n7. Data class pattern:";
$py.run(q:to/PYTHON/);
class Book:
    def __init__(self, title, author, year, isbn=None):
        self.title = title
        self.author = author
        self.year = year
        self.isbn = isbn
    
    def __str__(self):
        return f'"{self.title}" by {self.author} ({self.year})'
    
    def __repr__(self):
        return f"Book(title='{self.title}', author='{self.author}', year={self.year}, isbn='{self.isbn}')"
    
    def __eq__(self, other):
        if not isinstance(other, Book):
            return False
        return (self.title == other.title and 
                self.author == other.author and 
                self.year == other.year)

# Create book instances
book1 = Book("1984", "George Orwell", 1949, "978-0451524935")
book2 = Book("1984", "George Orwell", 1949)
book3 = Book("Animal Farm", "George Orwell", 1945)

print(book1)
print(f"book1 == book2: {book1 == book2}")
print(f"book1 == book3: {book1 == book3}")
PYTHON

# Composition
say "\n8. Composition over inheritance:";
$py.run(q:to/PYTHON/);
class Engine:
    def __init__(self, horsepower):
        self.horsepower = horsepower
        self.running = False
    
    def start(self):
        self.running = True
        return f"Engine started ({self.horsepower} HP)"
    
    def stop(self):
        self.running = False
        return "Engine stopped"

class Radio:
    def __init__(self):
        self.on = False
        self.station = "FM 101.5"
    
    def turn_on(self):
        self.on = True
        return f"Radio on, tuned to {self.station}"
    
    def change_station(self, station):
        self.station = station
        return f"Changed to {station}"

class Car:
    def __init__(self, make, model, horsepower):
        self.make = make
        self.model = model
        self.engine = Engine(horsepower)
        self.radio = Radio()
    
    def start(self):
        return f"{self.make} {self.model}: {self.engine.start()}"
    
    def play_music(self):
        return self.radio.turn_on()
    
    def info(self):
        return f"{self.make} {self.model} with {self.engine.horsepower} HP engine"

# Using composition
car = Car("Toyota", "Camry", 200)
print(car.info())
print(car.start())
print(car.play_music())
print(car.radio.change_station("FM 95.5"))
PYTHON

# Abstract base class pattern
say "\n9. Abstract base class pattern:";
$py.run(q:to/PYTHON/);
from abc import ABC, abstractmethod

class Shape(ABC):
    @abstractmethod
    def area(self):
        pass
    
    @abstractmethod
    def perimeter(self):
        pass
    
    def describe(self):
        return f"This is a {self.__class__.__name__} with area {self.area():.2f}"

class Circle(Shape):
    def __init__(self, radius):
        self.radius = radius
    
    def area(self):
        return 3.14159 * self.radius ** 2
    
    def perimeter(self):
        return 2 * 3.14159 * self.radius

class Square(Shape):
    def __init__(self, side):
        self.side = side
    
    def area(self):
        return self.side ** 2
    
    def perimeter(self):
        return 4 * self.side

# Using abstract base classes
shapes = [Circle(5), Square(4), Circle(3)]
for shape in shapes:
    print(shape.describe())
    print(f"  Perimeter: {shape.perimeter():.2f}")
PYTHON

# Using Python3 classes with Raku
say "\n10. Advanced interaction with Raku:";
$py.run(q:to/PYTHON/);
class Calculator:
    def __init__(self):
        self.memory = 0
        self.history = []
    
    def add(self, x, y):
        result = x + y
        self.history.append(f"add({x}, {y}) = {result}")
        return result
    
    def multiply(self, x, y):
        result = x * y
        self.history.append(f"multiply({x}, {y}) = {result}")
        return result
    
    def store(self, value):
        self.memory = value
        self.history.append(f"stored {value}")
        return f"Stored {value} in memory"
    
    def recall(self):
        self.history.append(f"recalled {self.memory}")
        return self.memory
    
    def get_history(self):
        return self.history

calc = Calculator()
PYTHON

# Use the calculator from Raku
my $calc = $py.run('calc', :eval);
say "Using Python3 Calculator from Raku:";
say "5 + 3 = " ~ $calc.add(5, 3);
say "4 × 7 = " ~ $calc.multiply(4, 7);
say $calc.store(42);
say "Memory: " ~ $calc.recall();

say "\nCalculation history:";
my @history = $calc.get_history();
for @history -> $entry {
    say "  $entry";
}

say "\n=== End of Classes and Objects Examples ===";