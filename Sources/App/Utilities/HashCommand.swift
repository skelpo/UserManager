import Command
import Crypto
import Vapor

final class HashCommand: Command {
    var arguments: [CommandArgument] = [CommandArgument.argument(name: "string", help: ["Ths string to hash"])]
    var options: [CommandOption] = []
    var help: [String] = ["Hashes a string with the BCrypt algorithm"]
    
    func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        try context.console.print(BCrypt.hash(context.argument("string")))
        return context.container.future()
    }
}
