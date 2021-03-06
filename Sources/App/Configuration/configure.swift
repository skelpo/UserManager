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
/// - Note: This variable is set through the environment variable "EMAIL_CONFIRMATION" and "on/off" as values.
var emailConfirmation: Bool = true

/// The configuration key for wheather user registration is open to the public
/// or must be executed by an admin user.
/// - Note: This variable can be set through the environment variable "OPEN_REGISTRATION" and "on/off" as values.
var openRegistration: Bool = false

/// Called before your application initializes.
///
/// https://docs.vapor.codes/3.0/getting-started/structure/#configureswift
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
) throws {
    let jwtProvider = JWTProvider { n, d in
        guard let d = d else { throw Abort(.internalServerError, reason: "Could not find environment variable 'JWT_SECRET'", identifier: "missingEnvVar") }
        
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
    services.register(Router.self) { container -> EngineRouter in
        let router = EngineRouter.default()
        try routes(router, container)
        return router
    }
    
    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(CORSMiddleware()) // Adds Cross-Origin referance headers to reponses where the request had an 'Origin' header.
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(APIErrorMiddleware(environment: env, specializations: [ // Catches all errors and formats them in a JSON response.
        ModelNotFound(),
        DecodingTypeMismatch()
    ]))
    services.register(middlewares)
    
    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    let config = MySQLDatabaseConfig(
        hostname: Environment.get("DATABASE_HOSTNAME") ?? "localhost",
        port: Int(Environment.get("DATABASE_PORT") ?? "3306") ?? 3306,
        username: Environment.get("DATABASE_USER") ?? "root",
        password: Environment.get("DATABASE_PASSWORD") ?? "password",
        database: Environment.get("DATABASE_DB") ?? "service_users",
        transport: env.isRelease ? .cleartext : .unverifiedTLS
    )
    let database = MySQLDatabase(config: config)
    databases.add(database: database, as: .mysql)
    services.register(databases)
    
    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .mysql)
    migrations.add(model: Attribute.self, database: .mysql)
    services.register(migrations)
    
    var commands = CommandConfig.default()
    commands.use(HashCommand(), as: "hash")
    services.register(commands)
    
    let jwt = JWTDataConfig()
    services.register(jwt)
    
    let sendgridKey = Environment.get("SENDGRID_API_KEY") ?? "Create Environemnt Variable"
    services.register(SendGridConfig(apiKey: sendgridKey))
    
    let emailFrom = Environment.get("EMAIL_FROM") ?? "info@skelpo.com"
    let emailURL = Environment.get("EMAIL_URL") ?? "http://localhost:8080/v1/users/activate"
    
    emailConfirmation = Environment.get("EMAIL_CONFIRMATION")=="on"
    openRegistration = Environment.get("OPEN_REGISTRATION")=="on"
    
    /// Register the `AppConfig` service,
    /// used to store arbitrary data.
    services.register(AppConfig(emailURL: emailURL, emailFrom: emailFrom))
}
