import Foundation

enum APIError: Error, Equatable, LocalizedError {
    case invalidCredentials
    case sessionExpired
    case server(status: Int)
    case transport

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Incorrect email or password."
        case .sessionExpired: return "Your session expired. Please sign in again."
        case .server(let status): return "Something went wrong (\(status)). Please try again."
        case .transport: return "Can't reach the server. Check your connection and try again."
        }
    }
}
