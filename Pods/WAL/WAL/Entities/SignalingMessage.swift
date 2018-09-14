//
//  SignalingMessage.swift
//  WAL
//
//  Created by Christian Braun on 22.08.18.
//

import Foundation

enum SignalingMessageType: String, Codable {
    case me = "Self"
    case hello = "Hello"
    case welcome = "Welcome"
    case joined = "Joined"
    case left = "Left"
    case offer = "Offer"
    case answer = "Answer"
    case candidate = "Candidate"
}

protocol SignalingMessage: Codable {
    var type: SignalingMessageType { get }
}

struct MeSignalingMessage: SignalingMessage {
    let type = SignalingMessageType.me

    let token: String

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case token = "Token"
    }
}

struct HelloSignalingMessage: SignalingMessage {
    struct Hello: Codable {
        let version: String
        let userAgent: String
        let roomName: String
        let type = ""

        enum CodingKeys: String, CodingKey {
            case version = "Version"
            case userAgent = "Ua"
            case roomName = "Name"
            case type = "Type"
        }
    }

    let type = SignalingMessageType.hello
    let hello: Hello

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case hello = "Hello"
    }
}

struct WelcomeSignalingMessage: SignalingMessage {
    struct Welcome: Codable {
        let room: String
        let users: [String]

        enum CodingKeys: String, CodingKey {
            case room = "Room"
            case users = "Users"
        }
    }

    let type = SignalingMessageType.welcome

    let welcome: Welcome

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case welcome = "Welcome"
    }
}

struct JoinedSignalingMessage: SignalingMessage {
    let type = SignalingMessageType.joined

    let id: String
    let userAgent: String

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case id = "Id"
        case userAgent = "Ua"
    }
}

struct LeftSignalingMessage: SignalingMessage {
    let type = SignalingMessageType.left
    let id: String

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case id = "Id"
    }
}

struct OfferSignalingMessage: SignalingMessage {
    struct OfferContainer: Codable {
        let to: String
        let type: String = "Offer"
        let offer: SessionDescription

        enum CodingKeys: String, CodingKey {
            case to = "To"
            case type = "Type"
            case offer = "Offer"
        }
    }

    let type = SignalingMessageType.offer

    let offer: OfferContainer

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case offer = "Offer"
    }
}

struct AnswerSignalingMessage: SignalingMessage {
    struct AnswerContainer: Codable {
        let to: String
        let type: String = "Answer"
        let answer: SessionDescription

        enum CodingKeys: String, CodingKey {
            case to = "To"
            case type = "Type"
            case answer = "Answer"
        }
    }

    let type = SignalingMessageType.answer
    let answer: AnswerContainer

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case answer = "Answer"
    }
}

struct CandidateSignalingMessage: SignalingMessage {
    struct CandidateContainer: Codable {
        let to: String
        let type: String = "Candidate"
        let candidate: Candidate

        enum CodingKeys: String, CodingKey {
            case to = "To"
            case type = "Type"
            case candidate = "Candidate"
        }
    }

    let type = SignalingMessageType.candidate

    let candidate: CandidateContainer

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case candidate = "Candidate"
    }
}
