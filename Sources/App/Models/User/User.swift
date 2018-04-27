//
//  User.swift
//  groups
//
//  Created by Ralph Küpper on 7/23/17.
//
//

import FluentMySQL
import Crypto
import Vapor

/// A generic user that can be conected to any service that uses JWT for authentication.
final class User: Content, MySQLModel, Migration, Parameter {
    
    /// The database ID of the class instance.
    var id: Int?
    
    ///
    var firstname: String?
    
    ///
    var lastname: String?
    
    ///
    var email: String
    
    ///
    var password: String
    
    ///
    var language: String
    
    ///
    var emailCode: String?
    
    ///
    var confirmed: Bool
    
    ///
    var permissionLevel: UserStatus
    
    ///
    var deletedAt: Date?
    
    /// Create a user with an email address and a language.
    /// When using this initializer, the user is created with a permission level of 0 and an empty password.
    ///
    /// - parameters:
    ///   - email: The user's email address.
    ///   - language: The user's prefered language for translating the confimation email or any other text with Lingo.
    init(_ email: String, _ language: String) throws {
        self.email = email
        self.language = language
        self.password = ""
        self.confirmed = !emailConfirmation
        self.permissionLevel = .standard
    }
    
    /// Create a user with an email, language, first name, last name, password, and email code.
    ///
    /// - Parameters:
    ///   - email: The user's email address
    ///   - language: The user's prefered language.
    ///   - firstName: The user's first name. This defaults to `nil`.
    ///   - lastName: The user's last name. This defaults to `nil`.
    ///   - password: The user's raw password. The initializer hashes it.
    ///   - emailCode: The email code for confirming the user account.
    /// - Throws: Errors when hashing the password
    convenience init(_ email: String, _ language: String, _ firstName: String? = nil, _ lastName: String? = nil, _ password: String, _ emailCode: String)throws {
        try self.init(email, language)
        
        self.firstname = firstName
        self.lastname = lastName
        self.emailCode = emailCode
        self.password = try BCryptDigest().hash(password)
    }
    
    // We implement a custom decoder so we can have default
    // values for some of the properties.
    init(from decoder: Decoder)throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decodeIfPresent(User.ID.self, forKey: .id)
        self.firstname = try container.decodeIfPresent(String.self, forKey: .firstname)
        self.lastname = try container.decodeIfPresent(String.self, forKey: .lastname)
        self.email = try container.decode(String.self, forKey: .email)
        self.password = try container.decode(String.self, forKey: .password)
        self.language = try container.decodeIfPresent(String.self, forKey: .language) ?? "en"
        self.emailCode = try container.decodeIfPresent(String.self, forKey: .emailCode)
        self.confirmed = try container.decodeIfPresent(Bool.self, forKey: .confirmed) ?? !emailConfirmation
        self.permissionLevel = try container.decodeIfPresent(UserStatus.self, forKey: .permissionLevel) ?? .standard
        self.deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
    }
}

/// Conforms the `User` model to the `SoftDeletable` protocol.
/// Allows a `users` row to be temporarily deleted from the database
/// with the possibility to restore.
extension User: SoftDeletable {
    
    /// Allows Fluent to set the `deletedAt` property to the value stored in the database.
    static var deletedAtKey: WritableKeyPath<User, Date?> {
        return \.deletedAt
    }
}
