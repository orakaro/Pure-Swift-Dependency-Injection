//: Playground - noun: a place where people can play

import Foundation

// Model
struct User {
    let id: Int
    let name: String
    var role: String?
}

// UserRepository
protocol UserRepository {
    func findById(id: Int) -> User?
}
protocol UsesUserRepository {
    var userRepository: UserRepository { get }
}
class MixInUserRepository: UserRepository {
    func findById(id: Int) -> User? {
        return User(id: id, name: "orakaro", role: "member")
    }
}

// UserService
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
protocol UsesUserService {
    var userService: UserService { get }
}
class MixInUserService: UserService {
    let userRepository: UserRepository = MixInUserRepository()
}

// TeamService
protocol TeamService: UsesUserService {
    func buildTeam(leader: User) -> [User?]
}
extension TeamService {
    func buildTeam(leader: User) -> [User?] {
        return [userService.promote(asigneeId: leader.id)]
    }
}
protocol UsesTeamServvice {
    var teamService: TeamService { get }
}
class MixInTeamService: TeamService {
    let userService: UserService = MixInUserService()
}

// Application Live
let applicationLive = MixInTeamService()
let team = applicationLive.buildTeam(leader: User(id: 1, name: "orakaro", role: "member"))
print(team)


// DI for testting
class MockUserRepository: UserRepository {
    func findById(id: Int) -> User? { return nil }
}
class UserServiceForTest: UserService {
    let userRepository: UserRepository = MockUserRepository()
}
let testService = UserServiceForTest()
print(testService.promote(asigneeId: 1))


class TeamServiceForTest: TeamService {
    let userService: UserService = UserServiceForTest()
}
let applicationTest = TeamServiceForTest()
let testTeam = applicationTest.buildTeam(leader: User(id: 1, name: "orakaro", role: "member"))
print(testTeam)
