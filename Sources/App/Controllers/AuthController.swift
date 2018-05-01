import JWTDataProvider
import JWTMiddleware
import CryptoSwift
import LingoVapor
import SendGrid
import Crypto
import Fluent
import Vapor
import JWT

/// A route controller that handles user authentication with JWT.
final class AuthController: RouteCollection {
    func boot(router: Router) throws {
        let auth = router.grouped(any, "users")
        let protected = auth.grouped(JWTAuthenticatableMiddlware<User>())
        
        auth.post(User.self, at: "register", use: register)
        auth.post("newPassword", use: newPassword)
        auth.post("accessToken", use: refreshAccessToken)
        auth.get("activate", use: activate)
        
        protected.post("login", use: login)
        protected.get("status", use: status)
    }
    
    /// Creates a new `User` model in the database.
    func register(_ request: Request, _ user: User)throws -> Future<UserSuccessResponse> {
        
        // Make sure no user exists yet with the email pssed in.
        let count = try User.query(on: request).filter(\.email == user.email).count()
        return count.map(to: User.self) { count in
            guard count < 1 else { throw Abort(.badRequest, reason: "This email is already registered.") }
            return user
        }.flatMap(to: User.self) { (user) in
            
            // Generate a unique code to verify the user with from the current date and time.
            let confirmation = Date().description.md5()
            
            user.emailCode = confirmation
            user.password = try BCrypt.hash(user.password)
            
            return user.save(on: request)
        }.flatMap(to: User.self) { (user) in
            let config = try request.make(AppConfig.self)
            
            // The URL for the user to confirm their account.
            guard let confirmation = user.emailCode else { throw Abort(.internalServerError, reason: "Confirmation code was not set") }
            let url = config.emailURL + confirmation
            
            if !user.confirmed {
                return try request.send(
                    email: "email.activation.text",
                    withSubject: "email.activation.title",
                    from: config.emailFrom,
                    to: user.email,
                    localized: user,
                    interpolations: ["url": url]
                ).transform(to: user)
            } else {
                return request.eventLoop.newSucceededFuture(result: user)
            }
        }
            
        // Convert the user to its reponse representation
        // and return is with a success status.
        .response(on: request, forProfile: true)
    }
    
    /// A route handler that checks that status of the user.
    /// This could be used to verifiy if they are authenticated.
    func status(_ request: Request)throws -> Future<UserSuccessResponse> {
        
        // Return the authenticated user.
        return try request.user().response(on: request, forProfile: false)
    }
    
     /// A route handler that generates a new password for a user.
    func newPassword(_ request: Request)throws -> Future<UserSuccessResponse> {
        
        // Get the email of the user to create a new password for.
        let email = try request.content.syncGet(String.self, at: "email")
        
        // Verify a user exists with the given email.
        let user = try User.query(on: request).filter(\.email == email).first().unwrap(or: Abort(.badRequest, reason: "No user found with email '\(email)'."))
        return user.flatMap(to: (User, String).self) { user in
            
            // Verifiy that the user has confimed their account.
            if (user.confirmed == false) {
                throw Abort(.badRequest, reason: "User is not activated.")
            }
            
            // Create a new random password from the current date/time
            let str = Date().description.md5()
            let index = str.index(str.startIndex, offsetBy: 8)
            let password = String(str[..<index])
            
            user.password = try BCrypt.hash(password)
            return user.save(on: request).and(result: password)
        }.flatMap(to: UserSuccessResponse.self) { saved in
            
            // If there is no API key, just return. This is for testing the service.
            guard Environment.get("SENDGRID_API_KEY") != nil else { return try saved.0.response(on: request, forProfile: false) }
            
            let config = try request.make(AppConfig.self)
            
            // Send a verification email.
            return try request.send(
                email: "email.password.text",
                withSubject: "email.password.title",
                from: config.emailFrom,
                to: email,
                localized:
                saved.0,
                interpolations: ["password": saved.1]
            ).transform(to: saved.0).response(on: request, forProfile: false)
        }
    }
    
    /// A route handler that returns a new access and refresh token for the user.
    func refreshAccessToken(_ request: Request)throws -> Future<[String: String]> {
        let signer = try request.make(JWTService.self)
        
        // Get refresh token from request body and verify it.
        let refreshToken = try request.content.syncGet(String.self, at: "refreshToken")
        let refreshJWT = try JWT<RefreshToken>(from: refreshToken, verifiedUsing: signer.signer)
        try refreshJWT.payload.verify()
        
        // Get the user with the ID that was just fetched.
        let userID = refreshJWT.payload.id
        let user = try User.find(userID, on: request).unwrap(or: Abort(.badRequest, reason: "No user found with ID '\(userID)'."))
        
        return user.flatMap(to: (JSON, Payload).self) { user in
            
            // Construct the new access token payload
            let payload = try App.Payload(user: user)
            return try request.payloadData(signer.sign(payload), with: ["userId": "\(user.requireID())"], as: JSON.self).and(result: payload)
        }.map(to: [String: String].self) { payloadData in
            let payload = try payloadData.0.merge(payloadData.1.json())
            
            // Return the signed token with a success status.
            let token = try signer.sign(payload)
            return ["status": "success", "accessToken": token]
        }
    }
    
    /// Confirms a new user account.
    func activate(_ request: Request)throws -> Future<UserSuccessResponse> {
        
        // Get the user from the database with the email code from the request.
        let code = try request.query.get(String.self, at: "code")
        let user = try User.query(on: request).filter(\.emailCode == code).first().unwrap(or: Abort(.badRequest, reason: "No user found with the given code."))
        
        return user.flatMap(to: User.self) { user in
            guard !user.confirmed else { throw Abort(.badRequest, reason: "User already activated.") }
            
            // Update the confimation properties and save to the database.
            user.confirmed = true
            user.emailCode = nil
            return user.update(on: request)
        }.response(on: request, forProfile: false)
    }
    
    /// Authenticates a user with an email and password.
    /// The actual authentication is handled by the `JWTAuthenticatableMiddleware`.
    /// The request's body should contain an email and a password for authenticating.
    func login(_ request: Request)throws -> Future<LoginResponse> {
        let signer = try request.make(JWTService.self)
        
        let user = try request.requireAuthenticated(User.self)
        let userPayload = try Payload(user: user)
        
        // Create a payload using the standard data
        // and the data from the registered `DataService`s
        let remotePayload = try request.payloadData(
            signer.sign(userPayload),
            with: ["userId": "\(user.requireID())"],
            as: JSON.self
        )
        
        // Create a response form the access token, refresh token. and user response data.
        return remotePayload.map(to: LoginResponse.self) { remotePayload in
            let payload = try remotePayload.merge(userPayload.json())
            
            let accessToken = try signer.sign(payload)
            let refreshToken = try signer.sign(RefreshToken(user: user))
            
            let userResponse = UserResponse(user: user, attributes: nil)
            return LoginResponse(accessToken: accessToken, refreshToken: refreshToken, user: userResponse)
        }
    }
}

struct UserSuccessResponse: Content {
    let status: String = "success"
    let user: UserResponse
}

struct LoginResponse: Content {
    let status = "success"
    let accessToken: String
    let refreshToken: String
    let user: UserResponse
}

extension Request {
    
    /// Sends an email with the SendGrid provider.
    /// The email is translated to the user's `langauge` value.
    ///
    /// - Parameters:
    ///   - body: The body of the email.
    ///   - subject: The subject of the email.
    ///   - address: The email address to send the email to.
    ///   - user: The user to localize the email to.
    ///   - interpolations: The interpolation values to replace placeholders in the email body.
    func send(email body: String, withSubject subject: String, from: String, to address: String, localized user: User, interpolations: [String: String])throws -> Future<Void> {
        
        // Fetch the service from the request so we can translate the email.
        let lingo = try self.lingo()
        
        // Create the SendGrid client servi e so we can send the email.
        let client = try self.make(SendGridClient.self)
        
        // Translate the subject and body.
        let subject: String = lingo.localize(subject, locale: user.language)
        let body: String = lingo.localize(body, locale: user.language, interpolations: interpolations)
        
        // Put all the data for the email togeather
        let name = [user.firstname, user.lastname].compactMap({ $0 }).joined(separator: " ")
        let from = EmailAddress(email: from, name: nil)
        let address = EmailAddress(email: address, name: name)
        let header = Personalization(to: [address], subject: subject)
        let email = SendGridEmail(personalizations: [header], from: from, subject: subject, content: [[
                "type": "text",
                "value": body
            ]])
        
        return try client.send([email], on: self)
    }
}

extension Future {
    
    /// Converts a future's value to a dictionary
    /// using the value in the future as the dictionary's value.
    ///
    /// - Parameter key: The key for the value in the dictionary.
    ///
    /// - Returns: A dictionary instance of type `[String: T]`,
    ///   using the `key` value passed in as the key and the
    ///   value from the future as the value.
    func keyed(_ key: String) -> Future<[String: T]> {
        return self.map(to: [String: T].self) { [key: $0] }
    }
}
