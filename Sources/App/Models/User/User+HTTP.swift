import Vapor
import Fluent
import Crypto
import JWTVapor
import Authentication
import SkelpoMiddleware

extension Request {
    
    /// Gets the user object that is stored in the request by `JWTAuthenticatableMiddleware`.
    func user()throws -> User {
        
        // Get the authenticated user from the request's auth cache.
        let user = try self.requireAuthenticated(User.self)
        
        // Get the langauge used to translate text to with Lingo.
        if let language = self.http.headers["Language"].first {
            
            // Set the user's `language` property if `language` is not `nil`.
            user.language = language
        }
        
        return user
    }
}

/// Conforms the `User` model to the `BasicJWTAuthenticatable` protocol.
/// This allows verfication of the `User` model with `JWTAuthenticatableMiddleware`.
extension User: BasicJWTAuthenticatable {
    
    /// The key-path for the property to check against `AuthBody.username`
    /// when fetching the user form the database to authenticate.
    static var usernameKey: WritableKeyPath<User, String> {
        return \.email
    }
    
    /// Creaes an access token that is used to verify future requests.
    func accessToken(on request: Request) throws -> Future<Payload> {
        return Future.map(on: request) { try Payload(user: self) }
    }
}
