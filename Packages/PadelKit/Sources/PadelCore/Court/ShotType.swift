import Foundation

/// A padel stroke type, as detected from the Watch's motion on the racket hand.
public enum ShotType: String, Codable, Sendable, CaseIterable, Hashable {
    case forehand, backhand, smash, volley
}
