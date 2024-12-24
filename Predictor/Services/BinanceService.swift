import Foundation

actor BinanceService {
    private let baseURL = "https://api.binance.com/api/v3"
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }
    
    func fetchTicker(symbol: String) async throws -> TickerResponse {
        guard let encodedSymbol = symbol.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/ticker/24hr?symbol=\(encodedSymbol)") else {
            throw NetworkError.invalidURL
        }
        
        print("Fetching URL: \(url.absoluteString)")
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            print("Status code for \(symbol): \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Respuesta JSON para \(symbol):", jsonString)
                    }
                    
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .useDefaultKeys
                    
                    do {
                        let response = try decoder.decode(TickerResponse.self, from: data)
                        print("Decodificación exitosa para \(symbol)")
                        return response
                    } catch let DecodingError.dataCorrupted(context) {
                        print("Data corrupted: \(context)")
                        throw NetworkError.decodingError
                    } catch let DecodingError.keyNotFound(key, context) {
                        print("Key '\(key)' not found: \(context.debugDescription)")
                        print("codingPath:", context.codingPath)
                        throw NetworkError.decodingError
                    } catch let DecodingError.valueNotFound(value, context) {
                        print("Value '\(value)' not found: \(context.debugDescription)")
                        print("codingPath:", context.codingPath)
                        throw NetworkError.decodingError
                    } catch let DecodingError.typeMismatch(type, context) {
                        print("Type '\(type)' mismatch: \(context.debugDescription)")
                        print("codingPath:", context.codingPath)
                        throw NetworkError.decodingError
                    } catch {
                        print("Error decodificando respuesta para \(symbol):", error)
                        throw NetworkError.decodingError
                    }
                }
            case 429:
                if let errorResponse = String(data: data, encoding: .utf8) {
                    print("Rate limit exceeded for \(symbol):", errorResponse)
                }
                throw NetworkError.rateLimitExceeded
            case 400...499:
                if let errorResponse = String(data: data, encoding: .utf8) {
                    print("Error de cliente para \(symbol):", errorResponse)
                }
                throw NetworkError.clientError(httpResponse.statusCode)
            case 500...599:
                if let errorResponse = String(data: data, encoding: .utf8) {
                    print("Error del servidor para \(symbol):", errorResponse)
                }
                throw NetworkError.serverError(httpResponse.statusCode)
            default:
                throw NetworkError.unexpectedStatusCode(httpResponse.statusCode)
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            print("Error inesperado para \(symbol):", error)
            throw NetworkError.networkError(error)
        }
    }
    
    func fetchKlines(symbol: String, interval: String = "4h", limit: Int = 100) async throws -> [Kline] {
        guard let encodedSymbol = symbol.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/klines?symbol=\(encodedSymbol)&interval=\(interval)&limit=\(limit)") else {
            throw NetworkError.invalidURL
        }
        
        print("Fetching klines URL: \(url.absoluteString)")
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            print("Klines status code for \(symbol): \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[Any]] {
                        return jsonArray.map { Kline(rawData: $0) }
                    } else {
                        throw NetworkError.decodingError
                    }
                } catch {
                    print("Error decodificando klines para \(symbol):", error)
                    throw NetworkError.decodingError
                }
            case 429:
                throw NetworkError.rateLimitExceeded
            case 400...499:
                throw NetworkError.clientError(httpResponse.statusCode)
            case 500...599:
                throw NetworkError.serverError(httpResponse.statusCode)
            default:
                throw NetworkError.unexpectedStatusCode(httpResponse.statusCode)
            }
        } catch {
            print("Error inesperado al obtener klines para \(symbol):", error)
            throw error
        }
    }

    func fetchAllTickers() async throws -> [TickerResponse] {
        guard let url = URL(string: "\(baseURL)/ticker/24hr") else {
            throw NetworkError.invalidURL
        }
        
        print("Fetching all tickers URL: \(url.absoluteString)")
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            print("All tickers status code: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                return try decoder.decode([TickerResponse].self, from: data)
            case 429:
                throw NetworkError.rateLimitExceeded
            case 400...499:
                throw NetworkError.clientError(httpResponse.statusCode)
            case 500...599:
                throw NetworkError.serverError(httpResponse.statusCode)
            default:
                throw NetworkError.unexpectedStatusCode(httpResponse.statusCode)
            }
        } catch {
            print("Error fetching all tickers:", error)
            throw error
        }
    }

    func getTopVolumeSymbols(count: Int = 5, excludingSymbols: [String] = []) async throws -> [String] {
        let tickers = try await fetchAllTickers()
        
        return tickers
            .filter { $0.symbol.hasSuffix("USDT") && !excludingSymbols.contains($0.symbol) }
            .sorted { Double($0.quoteVolume) ?? 0 > Double($1.quoteVolume) ?? 0 }
            .prefix(count)
            .map { $0.symbol }
    }
} 

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case rateLimitExceeded
    case clientError(Int)
    case serverError(Int)
    case unexpectedStatusCode(Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .decodingError:
            return "Error al procesar la respuesta"
        case .rateLimitExceeded:
            return "Demasiadas peticiones. Por favor, espera un momento"
        case .clientError(let code):
            return "Error del cliente (\(code))"
        case .serverError(let code):
            return "Error del servidor (\(code))"
        case .unexpectedStatusCode(let code):
            return "Código de estado inesperado (\(code))"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        }
    }
} 