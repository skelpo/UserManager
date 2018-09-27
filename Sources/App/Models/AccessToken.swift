import SkelpoMiddleware
import Foundation
import Crypto
import Vapor
import JSON
import JWT

/// A representation of the payload used in the access tokens
/// for this service's authentication.
struct Payload: PermissionedUserPayload {
    let status: UserStatus
    let firstname: String?
    let lastname: String?
    let language: String
    let exp: TimeInterval
    let iat: TimeInterval
    let email: String
    let id: User.ID
    
    init(user: User, expiration: TimeInterval = 3600)throws {
        let now = Date().timeIntervalSince1970
        
        self.status = user.permissionLevel
        self.firstname = user.firstname
        self.lastname = user.lastname
        self.language = user.language
        self.exp = now + expiration
        self.iat = now
        self.email = user.email
        self.id = try user.requireID()
    }
    
    func verify(using signer: JWTSigner) throws {
        let expiration = Date(timeIntervalSince1970: self.exp)
        try ExpirationClaim(value: expiration).verifyNotExpired()
    }
}

/// Payload data for a refresh token
struct RefreshToken: IdentifiableJWTPayload {
    let id: User.ID
    let iat: TimeInterval
    let exp: TimeInterval
    
    init(user: User, expiration: TimeInterval = 24 * 60 * 60 * 30)throws {
        let now = Date().timeIntervalSince1970
        
        self.id = try user.requireID()
        self.iat = now
        self.exp = now + expiration
    }
    
    func verify(using signer: JWTSigner) throws {
        let expiration = Date(timeIntervalSince1970: self.exp)
        try ExpirationClaim(value: expiration).verifyNotExpired()
    }
}

extension JSON: JWTPayload {
    public func verify(using signer: JWTSigner) throws {
        // Don't do anything
        // We only conform to `JWTPayload`
        // so we can sign a JWT with JSON as
        // it's payload.
    }
}
