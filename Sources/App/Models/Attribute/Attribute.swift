import FluentMySQL
import Vapor

/// An attribute for a `User` to store custom data..
final class Attribute: Content, MySQLModel, Migration, Parameter {
    static let entity: String = "attributes"
    
    /// The database ID of a class instance.
    var id: Int?
    
    /// The value of the attribute.
    var text: String
    
    /// A key used to reference the attribute unique to the user.
    let key: String
    
    /// The ID of the user that owns the attribute.
    let userID: Int
    
    /// Creates an attribute for a `User`.
    ///
    /// - parameters:
    ///   - text: The value for the attribute.
    ///   - key: A key to reference the attribute from the database,
    ///          unique in the scope of the user owning it.
    ///   - userID: The ID of the user owning the attribute.
    init(text: String, key: String, userID: Int) {
        self.text = text
        self.userID = userID
        self.key = key
    }
}

extension Attribute {
    static func prepare(on connection: MySQLDatabase.Connection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}
