import SkelpoMiddleware
import JWTDataProvider
import Authentication
import FluentMySQL
import LingoVapor
import JWTVapor
import SendGrid
import Vapor

/// Used to check wheather we should send a confirmation email when a user creates an account,
/// or if they should be auto-confirmed.
let emailConfirmation: Bool = false

/// Called before your application initializes.
///
/// https://docs.vapor.codes/3.0/getting-started/structure/#configureswift
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
) throws {
    let jwtProvider = JWTProvider { n in
        guard let d = Environment.get("REVIEWSENDER_JWT_D") else {
            throw Abort(.internalServerError, reason: "Could not find environment variable 'REVIEWSENDER_JWT_D'", identifier: "missingEnvVar")
        }
        
        let headers = JWTHeader(alg: "RS256", crit: ["exp", "aud"], kid: "user_manager_kid")
        return try RSAService(n: n, e: "AQAB", d: d, header: headers)
    }
    
    /// Register providers first
    try services.register(LingoProvider(defaultLocale: ""))
    try services.register(AuthenticationProvider())
    try services.register(FluentMySQLProvider())
    try services.register(SendGridProvider())
    try services.register(StorageProvider())
    try services.register(jwtProvider)
    
    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(CORSMiddleware()) // Adds Cross-Origin referance headers to reponses where the request had an 'Origin' header.
    middlewares.use(DateMiddleware.self) // Adds `Date` header to responses
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(APIErrorMiddleware()) // Catches all errors and formats them in a JSON response.
    services.register(middlewares)
    
    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    let config = MySQLDatabaseConfig(hostname: "localhost", port: 3306, username: "root", password: "password", database: "service_users")
    let database = MySQLDatabase(config: config)
    databases.add(database: database, as: .mysql)
    services.register(databases)
    
    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Attribute.self, database: .mysql)
    migrations.add(model: User.self, database: .mysql)
    services.register(migrations)
    
    let jwt = JWTDataConfig()
    services.register(jwt)
    
    let sendgridKey = Environment.get("SENDGRID_API_KEY") ?? "Create Environemnt Variable"
    services.register(SendGridConfig(apiKey: sendgridKey))
    
    /// Register the `AppConfig` service,
    /// used to store arbitrary data.
    services.register(AppConfig.self)
}
