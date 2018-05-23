import JWTMiddleware
import FluentMySQL
import Vapor

/// A Controller for Admin specific functionality.
final class AdminController: RouteCollection {
    
    /// Registers routes to the incoming router.
    ///
    /// - parameters:
    ///     - router: `Router` to register any new routes to.
    func boot(router: Router) throws {
        
        // Create a route-group that only allows
        // admin users to access the endpoint.
        let admin = router.grouped(
            RouteRestrictionMiddleware<UserStatus, Payload, User>(
                restrictions: [
                    RouteRestriction.init(.GET, at: "users", allowed: [.admin]),
                    RouteRestriction.init(.PATCH, at: "users", User.parameter, allowed: [.admin]),
                    RouteRestriction.init(.PATCH, at: "attributes", Attribute.parameter, allowed: [.admin])
                ],
                parameters: [User.routingSlug: User.resolveParameter, Attribute.routingSlug: Attribute.resolveParameter])
        )
        
        // Register handlers with route paths.
        
        // `self.allUsers` to `GET /users`.
        admin.get("users", use: allUsers)
        
        // These routes decode the request's body to a custom type.
        
        // `self.editUser` to `PATCH /users/:user`.
        admin.patch(UserUpdate.self, at: "users", User.parameter, use: editUser)
        
        // `self.editAttribute` to `PATCH /attributes/:attribute`.
        admin.patch(AttributeUpdate.self, at: "attributes", Attribute.parameter, use: editAttribute)
    }
    
    /// Gets all user models with their attributes.
    func allUsers(_ request: Request)throws -> Future<AllUsersSuccessResponse> {
        
        // Fetch all user models from the database.
        return User.query(on: request).all().flatMap(to: [([Attribute], User)].self) { users in
            
            // Get the attributes for each user, and connect them in a tuple.
            return try users.map { user in
                return try user.attributes(on: request).all().and(result: user)
            }.flatten(on: request)
        }.map(to: [UserResponse].self) { responses in
            
            // Convert each Attibutes/User pair to a `UserRepsonse` instance.
            return responses.map { response in
                return UserResponse(user: response.1, attributes: response.0)
            }
            
        // Create the final response body with the user responses.
        }.map(AllUsersSuccessResponse.init)
    }
    
    /// Updates a user's properties in the database.
    func editUser(_ request: Request, _ body: UserUpdate)throws -> Future<UserSuccessResponse> {
        
        // Get the user with the current path from the database.
        let user = try request.parameters.next(User.self)
        return user.flatMap(to: User.self) { user in
            
            // Update each property that appears in the body.
            user.firstname = body.firstname ?? user.firstname
            user.lastname = body.lastname ?? user.lastname
            user.email = body.email ?? user.email
            user.language = body.language ?? user.language
            user.confirmed = body.confirmed ?? user.confirmed
            user.permissionLevel = body.permissionLevel ?? user.permissionLevel
            
            // Save the updated user to the database and convert it to a `UserResponse`.
            return user.update(on: request)
        }.response(on: request, forProfile: true)
    }
    
    /// Updates an attribute's value in the database with a given ID.
    func editAttribute(_ request: Request, _ body: AttributeUpdate)throws -> Future<Attribute> {
        
        // Get the attribute with the current path from the database.
        let attribute = try request.parameters.next(Attribute.self)
        return attribute.flatMap(to: Attribute.self) { attribute in
            
            // Update the attribute's value and update the instance in the database.
            attribute.text = body.value ?? attribute.text
            return attribute.update(on: request)
        }
    }
}

/// The response structure for `AdminController.allUsers` route.
struct AllUsersSuccessResponse: Content {
    let status: String = "success"
    let users: [UserResponse]
}

/// The request body structure for `AdminController.editUser` handler.
struct UserUpdate: Content {
    let firstname: String?
    let lastname: String?
    let email: String?
    let language: String?
    let confirmed: Bool?
    let permissionLevel: UserStatus?
}

/// The request body structure for `AdminController.editAttribute` handler.
struct AttributeUpdate: Content {
    let value: String?
}
