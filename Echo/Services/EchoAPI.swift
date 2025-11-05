//
//  EchoAPI.swift
//  Echo
//
//  Created by William Entriken on 2025-10-31.
//

import Foundation

protocol EchoAPIProtocol {
    func searchLessonPreviews(language: Language) async throws -> [Lesson]
    func getLessonMetadata(id: Int) async throws -> Lesson
    func getAudio(id: Int) async throws -> Data
    func getUserAvatarFile(id: Int) async throws -> Data
}

// GET https://learnwithecho.com/api/2.0/lessons/fr/
// GET https://learnwithecho.com/api/2.0/lessons/457.json
// GET https://learnwithecho.com/api/2.0/audio/5060
// GET https://learnwithecho.com/avatarFiles/2966.png
final class EchoAPI: EchoAPIProtocol {
    nonisolated static let shared = EchoAPI()
    private let baseURL = URL(string: "https://learnwithecho.com/api/2.0/")!
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    enum APIError: Error {
        case invalidURL
        case invalidResponse
        case httpError(statusCode: Int)
        case decodingError(Error)
        case downloadFailed
    }
    
    private func fetch<T: Decodable>(path: String) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    private func downloadData(path: String) async throws -> Data {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        return data
    }
    
    func searchLessonPreviews(language: Language) async throws -> [Lesson] {
        try await fetch(path: "lessons/\(language.rawValue)/")
    }
    
    func getLessonMetadata(id: Int) async throws -> Lesson {
        try await fetch(path: "lessons/\(id).json")
    }
    
    func getAudio(id: Int) async throws -> Data {
        try await downloadData(path: "audio/\(id).caf")
    }
    
    func getUserAvatarFile(id: Int) async throws -> Data {
        guard let url = URL(string: "https://learnwithecho.com/avatarFiles/\(id).png") else {
            throw APIError.invalidURL
        }
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        return data
    }
}
