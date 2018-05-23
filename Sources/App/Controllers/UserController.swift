import JWTMiddleware
import Fluent
import Vapor

/// A controller for routes that interact with the `users` database table.
/// Conformance to the `RouteCollection` protocol allows the controller's
/// route to be registered with a route builder like so:
///
///     router.register(collection: UserController())
final class UserController: RouteCollection {
    
    /// Conforms the `UserController` class
    /// to `RouteCollection`.
    ///
    /// This method is used to register
    /// the route handlers to route paths.
    ///
    /// - Parameter router: The router to
    ///   register the routes with.
    func boot(router: Router) {
        let authenticated = router.grouped("users").grouped(
            RouteRestrictionMiddleware<UserStatus, Payload, User>(
                restrictions: [
                    RouteRestriction(.POST, at: any, "users", "profile", allowed: [.admin]),
                    ],
                parameters: [User.routingSlug: User.resolveParameter]
            )
        )
        
        authenticated.get("profile", use: profile)
        authenticated.post(NewUserBody.self, at: "profile", use: save)
        authenticated.get("attributes", use: attributes)
        authenticated.post(AttributeBody.self, at: "attributes", use: createAttribute)
        authenticated.delete("attribute", use: deleteAttributes)
        
        router.delete("users", User.parameter, use: delete)
    }
    
    /// Gets the profile data for the authenticated user.
    /// The requeat passed in should be sent through the
    ///
    /// `JWTAuthenticatableMiddleware<User>()` first to verify
    /// the request and get the user.
    func profile(_ request: Request)throws -> Future<UserSuccessResponse> {
        
        // Get the authenticated user and convert it to a `UserResponse` instance.
        return try request.user().response(on: request, forProfile: true)
    }
    
    /// Updates the authenticates user's `firstname` and
    /// `lastname` properties.
    func save(_ request: Request, _ content: NewUserBody)throws -> Future<UserSuccessResponse> {
        
        // Get the authenticated user, then updates its properties
        // with the request body data.
        let user = try request.user()
        
        user.firstname = content.firstname ?? ""
        user.lastname = content.lastname ?? ""
        
        // Save the updated user, then return a `UserResponse` instance.
        return user.update(on: request).response(on: request, forProfile: true)
    }
    
    /// Gets all the `Attribute` models connected to the
    /// authenticated user.
    func attributes(_ request: Request)throws -> Future<[Attribute]> {
        return try request.user().attributes(on: request).all()
    }
    
    /// Adds or updates an attribute for the authenticated user.
    func createAttribute(_ request: Request, _ content: AttributeBody)throws -> Future<UserSuccessResponse> {
        let user = try request.user()
        
        // Get the attribute with the matching key.
        // If one exists, update its `text` property,
        // otherwise create a new one.
        return try Attribute.query(on: request).filter(\.key == content.attributeKey).first().flatMap(to: Attribute.self) { attribute in
            if let attribute = attribute {
                attribute.text = content.attributeText
                return attribute.save(on: request)
            } else {
                return try user.createAttribute(content.attributeKey, text: content.attributeText, on: request)
            }
            
        // Convert the authenticated user to a `UserResponse`.
        }.transform(to: user).response(on: request, forProfile: true)
    }
    
    /// Deletes a `User` model, along with its connected attributes.
    /// The authed user that is deleting the other user must be an admin.
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        
        // Get the authenticated user and verify they are an admin
        let admin = try request.user()
        guard admin.permissionLevel == .admin else {
            throw Abort(.unauthorized, reason: "Only admins can delete users.")
        }
        
        // Get the user to delete.
        let user = try request.parameters.next(User.self)
        
        // Delete all the `Attribute` models connected to
        // the user, then delete the user.
        return user.flatMap(to: HTTPStatus.self) { user in
            return try user.attributes(on: request).delete().transform(to: .noContent)
        }
    }
    
    /// Deletes an `Attribute` model connected to the authed user,
    /// using either its ID or `key` to find it.
    func deleteAttributes(_ request: Request)throws -> Future<HTTPStatus> {
        let user = try request.user()
        let deleted: Future<Void>

        // If we have a key in the request body, find the connected `Attribute`
        // with that and delete it. If no key is present, try to use the ID.
        // If neither key or ID are present, abort.
        if let key = try request.content.syncGet(String?.self, at: "attributeKey") {
            deleted = try user.attributes(on: request).filter(\.key == key).delete()
        } else if let id = try request.content.syncGet(Attribute.ID?.self, at: "attributeId") {
            deleted = try user.attributes(on: request).filter(\.id == id).delete()
        } else {
            throw Abort(.badRequest, reason: "Missing 'attributeId/attributeKey' data from request")
        }
        
        // Once the deletion is complete, return a 204 (No Content) status code.
        return deleted.transform(to: .noContent)
    }
}

/// A representation of a request body for
/// creating a new user attribute.
struct AttributeBody: Content {
    let attributeKey: String
    let attributeText: String
}

/// A representation of a request body
/// for creating a new user.
struct NewUserBody: Content {
    let firstname: String?
    let lastname: String?
}
