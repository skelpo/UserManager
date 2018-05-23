import FluentMySQL
import Vapor

final class AdminController: RouteCollection {
    func boot(router: Router) throws {
        let users = router.grouped("users")
        
        users.get(use: allUsers)
    }
    
    func allUsers(_ request: Request)throws -> Future<AllUsersSuccessResponse> {
        return User.query(on: request).all().flatMap(to: [([Attribute], User)].self) { users in
            return try users.map { user in
                return try user.attributes(on: request).all().and(result: user)
            }.flatten(on: request)
        }.map(to: [UserResponse].self) { responses in
            return responses.map { response in
                return UserResponse(user: response.1, attributes: response.0)
            }
        }.map(AllUsersSuccessResponse.init)
    }
    
}

struct AllUsersSuccessResponse: Content {
    let status: String = "success"
    let users: [UserResponse]
}
