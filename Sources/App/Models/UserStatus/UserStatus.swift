import FluentMySQL

struct UserStatus: RawRepresentable, Codable, Hashable, MySQLEnumType {
    static let admin = UserStatus(id: 0, name: "admin")
    static let moderator = UserStatus(id: 1, name: "moderator")
    static let standard = UserStatus(id: 2, name: "standard")
    
    static private(set) var statuses: [Int: String] = [
        0: "admin",
        1: "moderator",
        2: "standard"
    ]
    
    let id: Int
    let name: String
    var rawValue: Int { return self.id }
    
    init(id: Int, name: String?) {
        self.id = id
        self.name = name ?? "custom-\(id)"

        if UserStatus.statuses[id] == nil {
           UserStatus.statuses[id] = name
        }
    }
    
    init(from decoder: Decoder)throws {
        let container = try decoder.singleValueContainer()
        let id = try container.decode(Int.self)
        self = .init(rawValue: id)
    }
    
    init(rawValue value: Int) { self = .init(id: value, name: nil) }
    
    func encode(to encoder: Encoder)throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}

extension UserStatus: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        self = .init(rawValue: value)
    }
}
