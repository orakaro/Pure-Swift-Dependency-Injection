## You don't need (Swift) Dependency Injection Framework
There is [Cake Design Pattern](http://jonasboner.com/real-world-scala-dependency-injection-di/) in Scala to do Dependency Injection (DI), and a minimal version called [Minimal Cake Design Pattern](http://qiita.com/tayama0324/items/7f87ee3672b15dd68016).

We don't really need a framework to do DI in Swift. With pure Swift code only, I will introduce you how to use *Minimal Cake Design Pattern* to do DI at production and test code.

## Every class need Interface and Implementation
With every class, I will create an **Interface** using `protocol`, which name started with`Uses...`, and an **Implementation** using `class` which name started with `MixIn...`.

**Interface** only declares *what* the `protocol` can do, and **Implementation** declares *how*.
```swift
protocol UserRepository {
    func findById(id: Int) -> User?
}

// Interface
protocol UsesUserRepository {
    var userRepository: UserRepository { get }
}
// Implementation
class MixInUserRepository: UserRepository {
    func findById(id: Int) -> User? {
        return User(id: id, name: "orakaro", role: "member")
    }
}
```

When instance of `UserRepository` is used by another class, for example `UserService`, I will use above Interface to declare a new pair `protocol`/`extension`, and of course another **Interface** and **Implementation** for `UserService` itself. 

![](https://i.gyazo.com/9316ee21abe541f5ec172e9e40307297.png)

Sounds more complicated than it is. Let’s look at the code.
```swift
protocol UserService: UsesUserRepository {
    func promote(asigneeId: Int) -> User?
}
extension UserService {
    func promote(asigneeId: Int) -> User? {
        guard var asignee = userRepository.findById(id: asigneeId) else {return nil}
        asignee.role = "leader"
        return asignee
    }
}

// Interface
protocol UsesUserService {
    var userService: UserService { get }
}
// Implementation
class MixInUserService: UserService {
    let userRepository: UserRepository = MixInUserRepository()
}
```

What if `UserService` is used by another `TeamService` again? Well the same logic is applied, `UsesUserService` is used to declare a pair of `protocol`/`extension`, and there will be **Interface**/**Implementation** for the new service also.

```swift
protocol TeamService: UsesUserService {
    func buildTeam(leader: User) -> [User?]
}
extension TeamService {
    func buildTeam(leader: User) -> [User?] {
        return [userService.promote(asigneeId: leader.id)]
    }
}

// Interface
protocol UsesTeamServvice {
    var teamService: TeamService { get }
}
// Implementation
class MixInTeamService: TeamService {
    let userService: UserService = MixInUserService()
}
```
All this kind of wiring is statically typed. If we have a dependency declaration missing, if it is misspelled then we get a compilation error. Furthermore Implementation is immutable (declared as `let`).

## Application use Implementation
For example our application using `TeamService` can be like this
```swift
let applicationLive = MixInTeamService()
let team = applicationLive.buildTeam(leader: User(id: 1, name: "orakaro", role: "member"))
print(team) // [Optional(User(id: 1, name: "orakaro", role: Optional("leader")))]
```

## DI using Interface
At this time we already can *inject* a mock repository into `UserService` to test the `promote` method *even without mocking framework*.
We are not merely creating mocks but the mocks we create are wired in as the declared dependencies wherever defined.
```swift
class MockUserRepository: UserRepository {
    func findById(id: Int) -> User? { return nil }
}
class UserServiceForTest: UserService {
    let userRepository: UserRepository = MockUserRepository()
}
let testService = UserServiceForTest()
print(testService.promote(asigneeId: 1)) // nil
```
The same method can be used to inject `TeamService` to test `buildTeam` method.
```swift
class TeamServiceForTest: TeamService {
    let userService: UserService = UserServiceForTest()
}
let applicationTest = TeamServiceForTest()
let testTeam = applicationTest.buildTeam(leader: User(id: 1, name: "orakaro", role: "member"))
print(testTeam) // [nil]
```
Here is imagination at this time
![](https://i.gyazo.com/b52857f6cf2e0d7054ffeb6efde62b62.png)

For more detail see playground in this repo.

## Summing up
I found this solution to be a simple, clear way to structure Swift code and create the object graph. It uses only pure Swift `protocol`/`extension`, does not depend on any frameworks or libraries, and provides compile-time checking that everything is defined properly.

