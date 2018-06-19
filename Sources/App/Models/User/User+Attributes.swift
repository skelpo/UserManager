import Fluent

extension User {
    /// Create a query that gets all the attributes belonging to a user.
    func attributes(on connection: DatabaseConnectable)throws -> QueryBuilder<Attribute.Database, Attribute> {
        // Return an `Attribute` query that filters on the `userId` field.
        return try Attribute.query(on: connection).filter(\.userID == self.requireID())
    }
    
    /// Creates a dictionary where the key is the attribute's key and the value is the attribute's text.
    func attributesMap(on connection: DatabaseConnectable)throws -> Future<[String:String]> {
        
        // Get all the user's attributes.
        return try self.attributes(on: connection).all().map(to: [String: String].self, { (attributes) in
            
            // Iterate over the attributes, setting the `response` key (`attribute.key`) to `attribute.text`.
            return attributes.reduce(into: [:], { (response, attribute) in
                response[attribute.key] = attribute.text
            })
        })
    }
    
    /// Creates a profile attribute for the user.
    ///
    /// - parameters:
    ///   - key: A public identifier for the attribute.
    ///   - text: The value of the attribute.
    func createAttribute(_ key: String, text: String, on connection: DatabaseConnectable)throws -> Future<Attribute> {
        // Creat and save the attribute to the database.
        // The `Model.requireID` method gets the model's ID if it exists,
        // otherwise it throws an error.
        let attribute = try Attribute(text: text, key: key, userID: self.requireID())
        return attribute.save(on: connection)
    }
    
    /// Removed the attribute from the user bsaed on its key.
    func removeAttribute(key: String, on connection: DatabaseConnectable)throws -> Future<Void> {
        return try self.attributes(on: connection).filter(\.key == key).delete()
    }
    
    /// Remove the attribute from the user based on its database ID.
    func removeAttribute(id: Int, on connection: DatabaseConnectable)throws -> Future<Void> {
        return try self.attributes(on: connection).filter(\.id == id).delete()
    }
}
