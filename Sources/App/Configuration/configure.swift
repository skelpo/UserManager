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
var emailConfirmation: Bool = false

/// Called before your application initializes.
///
/// https://docs.vapor.codes/3.0/getting-started/structure/#configureswift
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
) throws {
    let jwtProvider = JWTProvider { n in
        guard let d = Environment.get("USER_JWT_D") else {
            throw Abort(.internalServerError, reason: "Could not find environment variable 'USER_JWT_D'", identifier: "missingEnvVar")
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
    middlewares.use(APIErrorMiddleware(specializations: [ // Catches all errors and formats them in a JSON response.
        ModelNotFound(),
        DecodingTypeMismatch()
        ]))
    middlewares.use(CORSMiddleware()) // Adds Cross-Origin referance headers to reponses where the request had an 'Origin' header.
    middlewares.use(DateMiddleware.self) // Adds `Date` header to responses
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)
    
    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    
    guard
        let host = Environment.get("DATABASE_HOSTNAME"),
        let user = Environment.get("DATABASE_USER"),
        let name = Environment.get("DATABASE_DB")
    else {
        throw MySQLError(
            identifier: "missingEnvVars",
            reason: "One or more expected environment variables are missing: DATABASE_HOSTNAME, DATABASE_USER, DATABASE_DB",
            source: .capture()
        )
    }
    let config = MySQLDatabaseConfig(
        hostname: host,
        port: 3306,
        username: user,
        password: Environment.get("DATABASE_PASSWORD"),
        database: name
    )
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
    
    let emailFrom = Environment.get("EMAIL_FROM") ?? "info@skelpo.com"
    let emailURL = Environment.get("EMAIL_URL") ?? "http://localhost:8080/v1/users/activate"
    emailConfirmation = (emailFrom == "")
    
    /// Register the `AppConfig` service,
    /// used to store arbitrary data.
    services.register(AppConfig(emailURL: emailURL, emailFrom: emailFrom))
}
