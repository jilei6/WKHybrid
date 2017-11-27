
function buttonClick() {
	MYAPP.commonMethod.validateName("heheda")

}

// Person
function Person(name) {
	this.name = name
}

Person.prototype = {
	constructor: Person,

	sayHello: function() {
		console.log("hello " + this.name)
	}
}

// Student
function Student() {
	Person.call(this, "wind")
}

Student.prototype = Object.create(Person.prototype)

// Child
function Child() {

}

Child.prototype = new Student()

// Object

var MyObject = Object.create(Object.prototype, {
	param: {writable: true, configurable: true, value: "param1"}
})

console.log(MyObject)

var person1 = new Person("wind")
person1.sayHello()

var student = new Student("wind ")
student.sayHello()
console.log(student.age)

console.log(Student)
console.log(Child)

