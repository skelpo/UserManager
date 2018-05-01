import Service

struct AppConfig: ServiceType {
    static func makeService(for worker: Container) throws -> AppConfig {
        return AppConfig()
    }
    
    /// The URL that the user activate
    /// to confirm their account.
    var emailURL: String = ""
    
    /// The email address that the
    /// confirmation and password
    /// reset emails are sent from.
    var emailFrom: String = ""
    
}
