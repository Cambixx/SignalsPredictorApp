import Foundation

actor SignalAnalyzer {
    let binanceService: BinanceService
    
    init(binanceService: BinanceService = BinanceService()) {
        self.binanceService = binanceService
    }
    
    func analyzeSymbol(_ symbol: String) async throws -> TradingSignal? {
        do {
            let klines = try await binanceService.fetchKlines(symbol: symbol, interval: "4h", limit: 100)
            let ticker = try await binanceService.fetchTicker(symbol: symbol)
            
            // Calculamos medias móviles
            let prices = klines.map { $0.close }
            let ema20 = calculateEMA(prices: prices, period: 20)
            let ema50 = calculateEMA(prices: prices, period: 50)
            
            // Calculamos RSI
            let rsi = calculateRSI(prices: prices, period: 14)
            
            // Verificamos que tengamos suficientes datos
            guard let lastEma20 = ema20.last,
                  let lastEma50 = ema50.last,
                  let lastRsi = rsi.last,
                  let currentPrice = Double(ticker.lastPrice) else {
                return nil
            }
            
            // Generamos señal basada en el cruce de medias móviles y RSI
            let emaDiff = ((lastEma20 - lastEma50) / lastEma50) * 100
            
            // Señal de compra: EMA20 cruza por encima de EMA50 y RSI < 70
            if lastEma20 > lastEma50 && lastRsi < 70 {
                let targetPrice = currentPrice * 1.02 // Target 2% arriba
                let confidence = calculateConfidence(rsi: lastRsi, emaDiff: emaDiff)
                
                return TradingSignal(
                    pair: formatSymbol(symbol),
                    type: .buy,
                    entryPrice: formatPrice(currentPrice),
                    targetPrice: formatPrice(targetPrice),
                    timestamp: Date(),
                    confidence: confidence
                )
            }
            
            // Señal de venta: EMA20 cruza por debajo de EMA50 y RSI > 30
            if lastEma20 < lastEma50 && lastRsi > 30 {
                let targetPrice = currentPrice * 0.98 // Target 2% abajo
                let confidence = calculateConfidence(rsi: lastRsi, emaDiff: abs(emaDiff))
                
                return TradingSignal(
                    pair: formatSymbol(symbol),
                    type: .sell,
                    entryPrice: formatPrice(currentPrice),
                    targetPrice: formatPrice(targetPrice),
                    timestamp: Date(),
                    confidence: confidence
                )
            }
            
            return nil
            
        } catch {
            print("Error analizando \(symbol): \(error)")
            throw error
        }
    }
    
    func analyzePrediction(_ symbol: String) async throws -> PredictionSignal? {
        do {
            let klines = try await binanceService.fetchKlines(symbol: symbol, interval: "4h", limit: 100)
            let ticker = try await binanceService.fetchTicker(symbol: symbol)
            
            // Calculamos indicadores técnicos
            let prices = klines.map { $0.close }
            let volumes = klines.map { $0.volume }
            
            // Medias móviles
            let ema20 = calculateEMA(prices: prices, period: 20)
            let ema50 = calculateEMA(prices: prices, period: 50)
            let ema200 = calculateEMA(prices: prices, period: 200)
            
            // RSI y Volumen
            let rsi = calculateRSI(prices: prices, period: 14)
            let volumeMA = calculateSMA(prices: volumes, period: 20)
            
            guard let lastPrice = Double(ticker.lastPrice),
                  let lastEma20 = ema20.last,
                  let lastEma50 = ema50.last,
                  let lastEma200 = ema200.last,
                  let lastRsi = rsi.last,
                  let lastVolume = volumes.last,
                  let avgVolume = volumeMA.last else {
                return nil
            }
            
            print("📊 Análisis para \(symbol):")
            print("RSI: \(lastRsi)")
            print("EMA20: \(lastEma20)")
            print("EMA50: \(lastEma50)")
            print("Volumen actual: \(lastVolume)")
            print("Volumen promedio: \(avgVolume)")
            
            // Múltiples niveles de análisis (incluyendo especulativo)
            let priceAboveEma20 = lastPrice > lastEma20
            let ema20AboveEma50 = lastEma20 > lastEma50
            let priceNearEma20 = abs((lastPrice - lastEma20) / lastEma20) < 0.02 // Precio cerca del EMA20
            
            // Condiciones muy permisivas para nivel especulativo
            let isSpeculativeUptrend = priceAboveEma20 || ema20AboveEma50 || priceNearEma20 || lastPrice > lastEma50 * 0.93
            let hasMinimalVolume = lastVolume > (avgVolume * 0.8)
            let isRsiRecovering = lastRsi > 30 && lastRsi < 65
            
            print("Tendencia especulativa: \(isSpeculativeUptrend)")
            print("Volumen mínimo: \(hasMinimalVolume)")
            print("RSI en rango: \(isRsiRecovering)")
            
            // Diferentes niveles de score
            var totalScore = 0
            var analysisPoints = [String]()
            
            if isSpeculativeUptrend {
                if priceAboveEma20 && ema20AboveEma50 {
                    totalScore += 40
                    analysisPoints.append("Tendencia alcista confirmada")
                } else if priceAboveEma20 || ema20AboveEma50 {
                    totalScore += 25
                    analysisPoints.append("Señales de tendencia alcista")
                } else {
                    totalScore += 15
                    analysisPoints.append("Posible cambio de tendencia")
                }
            }
            
            if hasMinimalVolume {
                totalScore += 15
                if lastVolume > (avgVolume * 1.2) {
                    totalScore += 10
                    analysisPoints.append("Volumen por encima de la media")
                } else {
                    analysisPoints.append("Volumen estable")
                }
            }
            
            if isRsiRecovering {
                totalScore += 15
                if lastRsi < 45 {
                    totalScore += 10
                    analysisPoints.append("RSI en zona favorable")
                } else {
                    analysisPoints.append("RSI en rango neutral")
                }
            }
            
            // Añadimos score base mínimo
            totalScore += 10
            
            print("Score total: \(totalScore)")
            
            // Clasificación por niveles de confianza
            let confidenceLevel: String
            if totalScore >= 70 {
                confidenceLevel = "Alta confiabilidad"
            } else if totalScore >= 50 {
                confidenceLevel = "Confiabilidad media"
            } else if totalScore >= 35 {
                confidenceLevel = "Baja confiabilidad"
            } else {
                confidenceLevel = "Nivel especulativo"
            }
            
            // Generamos predicción incluso con score bajo
            if totalScore > 25 { // Extremadamente permisivo
                let potentialGain = calculatePotentialGain(
                    currentPrice: lastPrice,
                    rsi: lastRsi,
                    confidence: Double(totalScore)
                )
                
                analysisPoints.append(confidenceLevel)
                
                let signal = PredictionSignal(
                    pair: formatSymbol(symbol),
                    currentPrice: formatPrice(lastPrice),
                    predictedPrice: formatPrice(lastPrice * (1 + potentialGain)),
                    confidence: totalScore,
                    timeframe: "4h",
                    analysis: analysisPoints.joined(separator: ". ")
                )
                
                print("✅ Predicción generada con confianza: \(totalScore)% (\(confidenceLevel))")
                return signal
            }
            
            print("❌ No cumple ni los criterios mínimos especulativos")
            return nil
        } catch {
            print("Error analizando predicción para \(symbol): \(error)")
            throw error
        }
    }
    
    func analyzeSpeculativePrediction(_ symbol: String) async throws -> PredictionSignal? {
        do {
            let klines = try await binanceService.fetchKlines(symbol: symbol, interval: "4h", limit: 100)
            let ticker = try await binanceService.fetchTicker(symbol: symbol)
            
            let prices = klines.map { $0.close }
            let volumes = klines.map { $0.volume }
            let highs = klines.map { $0.high }
            let lows = klines.map { $0.low }
            
            let ema20 = calculateEMA(prices: prices, period: 20)
            let ema50 = calculateEMA(prices: prices, period: 50)
            let rsi = calculateRSI(prices: prices, period: 14)
            let volumeMA = calculateSMA(prices: volumes, period: 20)
            
            guard let lastPrice = Double(ticker.lastPrice),
                  let lastEma20 = ema20.last,
                  let lastEma50 = ema50.last,
                  let lastRsi = rsi.last,
                  let lastVolume = volumes.last,
                  let avgVolume = volumeMA.last else {
                return nil
            }
            
            var score = 0
            var analysisPoints = ["Predicción especulativa"]
            
            // 1. Análisis de Tendencia
            if lastPrice > lastEma20 { 
                score += 10 
                analysisPoints.append("Precio sobre EMA20")
            }
            if lastPrice > lastEma50 { 
                score += 10
                analysisPoints.append("Precio sobre EMA50")
            }
            if lastEma20 > lastEma50 { 
                score += 10
                analysisPoints.append("EMA20 sobre EMA50")
            }
            
            // 2. Análisis de RSI
            if lastRsi < 70 && lastRsi > 30 {
                score += 10
                if lastRsi < 45 {
                    score += 5
                    analysisPoints.append("RSI en zona de compra")
                } else {
                    analysisPoints.append("RSI en rango saludable")
                }
            }
            
            // 3. Análisis de Volumen
            let volumeRatio = lastVolume / avgVolume
            if volumeRatio > 1.5 {
                score += 15
                analysisPoints.append("Alto volumen de operaciones")
            } else if volumeRatio > 1.0 {
                score += 10
                analysisPoints.append("Volumen por encima de la media")
            }
            
            // 4. Análisis de Volatilidad
            let recentCandles = Array(klines.suffix(14))
            let volatility = calculateVolatility(candles: recentCandles)
            if volatility < 0.02 { // Baja volatilidad
                score += 10
                analysisPoints.append("Baja volatilidad")
            }
            
            // 5. Momentum y Fuerza de Tendencia
            let momentum = calculateMomentum(prices: prices)
            if momentum > 0 {
                score += 10
                analysisPoints.append("Momentum positivo")
            }
            
            // 6. Análisis de Soportes y Resistencias
            let supportLevel = findNearestSupport(prices: prices, currentPrice: lastPrice)
            if supportLevel > 0 {
                let distanceToSupport = abs((lastPrice - supportLevel) / lastPrice)
                if distanceToSupport < 0.02 {
                    score += 10
                    analysisPoints.append("Cerca de soporte fuerte")
                }
            }
            
            // 7. Análisis de Acumulación/Distribución
            let adl = calculateADL(highs: highs, lows: lows, closes: prices, volumes: volumes)
            if adl > 0 {
                score += 5
                analysisPoints.append("Fase de acumulación")
            }
            
            // 8. Sentimiento del Mercado
            let marketSentiment = analyzeMarketSentiment(
                rsi: lastRsi,
                volumeRatio: volumeRatio,
                momentum: momentum,
                volatility: volatility
            )
            analysisPoints.append("Sentimiento: \(marketSentiment)")
            
            // Calculamos ganancia potencial basada en todos los factores
            let potentialGain = calculateDynamicGain(
                score: score,
                rsi: lastRsi,
                volatility: volatility,
                volumeRatio: volumeRatio
            )
            
            return PredictionSignal(
                pair: formatSymbol(symbol),
                currentPrice: formatPrice(lastPrice),
                predictedPrice: formatPrice(lastPrice * (1 + potentialGain)),
                confidence: max(20, score),
                timeframe: "4h",
                analysis: analysisPoints.joined(separator: ". ")
            )
        } catch {
            print("Error en análisis especulativo de \(symbol): \(error)")
            return nil
        }
    }
    
    func getTopVolumeSymbols(count: Int = 5, excludingSymbols: [String] = []) async throws -> [String] {
        return try await binanceService.getTopVolumeSymbols(count: count, excludingSymbols: excludingSymbols)
    }
    
    private func calculateEMA(prices: [Double], period: Int) -> [Double] {
        guard prices.count >= period else { return [] }
        
        let multiplier = 2.0 / Double(period + 1)
        var ema = [prices[0]]
        
        for i in 1..<prices.count {
            let value = (prices[i] - ema[i-1]) * multiplier + ema[i-1]
            ema.append(value)
        }
        
        return ema
    }
    
    private func calculateRSI(prices: [Double], period: Int) -> [Double] {
        guard prices.count >= period + 1 else { return [] }
        
        var gains = [Double]()
        var losses = [Double]()
        
        for i in 1..<prices.count {
            let difference = prices[i] - prices[i-1]
            gains.append(max(difference, 0))
            losses.append(max(-difference, 0))
        }
        
        var rsi = [Double]()
        var avgGain = gains[..<period].reduce(0, +) / Double(period)
        var avgLoss = losses[..<period].reduce(0, +) / Double(period)
        
        for i in period..<gains.count {
            avgGain = (avgGain * Double(period - 1) + gains[i]) / Double(period)
            avgLoss = (avgLoss * Double(period - 1) + losses[i]) / Double(period)
            
            let rs = avgGain / avgLoss
            rsi.append(100 - (100 / (1 + rs)))
        }
        
        return rsi
    }
    
    private func calculateConfidence(rsi: Double, emaDiff: Double) -> Int {
        // Calcula la confianza de la señal basada en la fuerza de los indicadores
        let rsiConfidence: Double
        if rsi < 30 {
            rsiConfidence = (30 - rsi) / 30 * 100
        } else if rsi > 70 {
            rsiConfidence = (rsi - 70) / 30 * 100
        } else {
            rsiConfidence = 50
        }
        
        let emaConfidence = min(abs(emaDiff) * 10, 100)
        
        return Int((rsiConfidence + emaConfidence) / 2)
    }
    
    private func formatSymbol(_ symbol: String) -> String {
        let base = symbol.dropLast(4)
        let quote = symbol.suffix(4)
        return "\(base)/\(quote)"
    }
    
    private func formatPrice(_ price: Double) -> String {
        // Si el precio es menor a 0.01, usamos notación científica
        if price < 0.01 {
            return String(format: "%.8f", price)
        } else if price < 1 {
            return String(format: "%.6f", price)
        } else if price < 100 {
            return String(format: "%.4f", price)
        } else {
            return String(format: "%.2f", price)
        }
    }
    
    private func calculatePotentialGain(currentPrice: Double, rsi: Double, confidence: Double) -> Double {
        // Ajustamos la ganancia potencial según el nivel de confianza
        let baseGain = 0.015 + (confidence / 100.0 * 0.035) // Entre 1.5% y 5%
        let rsiMultiplier = (55.0 - min(rsi, 55.0)) / 55.0
        return baseGain * (1 + rsiMultiplier)
    }
    
    private func calculateSupportScore(_ prices: [Double], currentPrice: Double) -> Double {
        // Identificamos niveles de soporte basados en mínimos previos
        let recentPrices = Array(prices.suffix(50))
        var supportLevels = [Double]()
        
        // Encontramos mínimos locales
        for i in 1..<recentPrices.count-1 {
            if recentPrices[i] < recentPrices[i-1] && recentPrices[i] < recentPrices[i+1] {
                supportLevels.append(recentPrices[i])
            }
        }
        
        // Calculamos la distancia al soporte más cercano
        let closestSupport = supportLevels.min { abs($0 - currentPrice) < abs($1 - currentPrice) }
        
        if let support = closestSupport {
            let distance = abs((currentPrice - support) / support)
            if distance < 0.03 { // Aumentamos el rango de 2% a 3%
                return 20.0
            } else if distance < 0.07 { // Aumentamos el rango de 5% a 7%
                return 10.0
            }
        }
        
        return 0.0
    }
    
    private func calculateSMA(prices: [Double], period: Int) -> [Double] {
        guard prices.count >= period else { return [] }
        
        var sma = [Double]()
        for i in period...prices.count {
            let slice = prices[i-period..<i]
            let average = slice.reduce(0, +) / Double(period)
            sma.append(average)
        }
        
        return sma
    }
    
    // Funciones auxiliares para los nuevos análisis
    private func calculateVolatility(candles: [Kline]) -> Double {
        let returns = zip(candles.dropFirst(), candles).map { (current, previous) in
            abs((current.close - previous.close) / previous.close)
        }
        return returns.reduce(0, +) / Double(returns.count)
    }
    
    private func calculateMomentum(prices: [Double]) -> Double {
        guard prices.count >= 10 else { return 0 }
        let recentPrices = Array(prices.suffix(10))
        let oldPrice = recentPrices.first!
        let currentPrice = recentPrices.last!
        return ((currentPrice - oldPrice) / oldPrice) * 100
    }
    
    private func findNearestSupport(prices: [Double], currentPrice: Double) -> Double {
        let recentPrices = Array(prices.suffix(50))
        var potentialSupports: [Double] = []
        
        // Encontrar mínimos locales
        for i in 1..<recentPrices.count-1 {
            if recentPrices[i] < recentPrices[i-1] && recentPrices[i] < recentPrices[i+1] {
                potentialSupports.append(recentPrices[i])
            }
        }
        
        // Encontrar el soporte más cercano por debajo del precio actual
        return potentialSupports.filter { $0 < currentPrice }
            .max() ?? 0
    }
    
    private func calculateADL(highs: [Double], lows: [Double], closes: [Double], volumes: [Double]) -> Double {
        var adl = 0.0
        for i in 0..<closes.count {
            let mfm = ((closes[i] - lows[i]) - (highs[i] - closes[i])) / (highs[i] - lows[i])
            let mfv = mfm * volumes[i]
            adl += mfv
        }
        return adl
    }
    
    private func analyzeMarketSentiment(rsi: Double, volumeRatio: Double, momentum: Double, volatility: Double) -> String {
        var sentiment = 0.0
        
        // RSI contribution
        if rsi < 30 { sentiment += 2 }
        else if rsi < 45 { sentiment += 1 }
        else if rsi > 70 { sentiment -= 1 }
        
        // Volume contribution
        if volumeRatio > 1.5 { sentiment += 1 }
        
        // Momentum contribution
        if momentum > 2 { sentiment += 1 }
        else if momentum < -2 { sentiment -= 1 }
        
        // Volatility contribution
        if volatility < 0.02 { sentiment += 1 }
        
        // Clasificar el sentimiento
        if sentiment >= 3 { return "Muy Alcista" }
        else if sentiment >= 1 { return "Alcista" }
        else if sentiment > -1 { return "Neutral" }
        else if sentiment > -3 { return "Bajista" }
        else { return "Muy Bajista" }
    }
    
    private func calculateDynamicGain(score: Int, rsi: Double, volatility: Double, volumeRatio: Double) -> Double {
        var baseGain = 0.02 // 2% base
        
        // Ajustar por score
        baseGain *= (1.0 + Double(score) / 100.0)
        
        // Ajustar por RSI
        if rsi < 40 { baseGain *= 1.2 }
        
        // Ajustar por volatilidad
        baseGain *= (1.0 + volatility)
        
        // Ajustar por volumen
        if volumeRatio > 1.5 { baseGain *= 1.1 }
        
        return min(baseGain, 0.05) // Máximo 5% de ganancia potencial
    }
} 