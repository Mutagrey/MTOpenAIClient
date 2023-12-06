import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

extension Components.Schemas.CreateChatCompletionRequest.modelPayload.Value2Payload: CaseIterable {
    public static var allCases: [Components.Schemas.CreateChatCompletionRequest.modelPayload.Value2Payload] = [
        .gpt_hyphen_3_period_5_hyphen_turbo,
        .gpt_hyphen_3_period_5_hyphen_turbo_hyphen_0301
    ]
}

public struct OpenAIClient {
    
    public let client: Client
    private let urlSession = URLSession.shared
    private let apiKey: String
    
    public init(apiKey: String) {
        self.client = Client(
            serverURL: try! Servers.server1(),
            transport: URLSessionTransport(),
            middlewares: [AuthMiddleware(apiKey: apiKey)])
        self.apiKey = apiKey
    }
    
    public func createChatCompletionRequest(
        prompt: String,
        model: Components.Schemas.CreateChatCompletionRequest.modelPayload.Value2Payload = .gpt_hyphen_3_period_5_hyphen_turbo,
        systemPrompt: String = "You are a helpful assistant",
        prevMessages: [Components.Schemas.ChatCompletionRequestMessage] = [],
        frequency_penalty: Double?,
        logit_bias: Components.Schemas.CreateChatCompletionRequest.logit_biasPayload?,
        max_tokens: Int?,
        n: Int?,
        presence_penalty: Double?,
        response_format: Components.Schemas.CreateChatCompletionRequest.response_formatPayload?,
        seed: Int?,
        stop: Components.Schemas.CreateChatCompletionRequest.stopPayload?,
        stream: Bool?,
        temperature: Double?,
        top_p: Double?,
        tools: [Components.Schemas.ChatCompletionTool]?,
        tool_choice: Components.Schemas.ChatCompletionToolChoiceOption?,
        user: String?
    ) -> Components.Schemas.CreateChatCompletionRequest {
        .init(
            messages: [.ChatCompletionRequestSystemMessage(.init(content: systemPrompt, role: .system))]
            + prevMessages
            + [.ChatCompletionRequestUserMessage(.init(content: .case1(prompt), role: .user))],
            model: .init(value1: nil, value2: model),
            frequency_penalty: frequency_penalty,
            logit_bias: logit_bias,
            max_tokens: max_tokens,
            n: n,
            presence_penalty: presence_penalty,
            response_format: response_format,
            seed: seed,
            stop: stop,
            stream: stream,
            temperature: temperature,
            top_p: top_p,
            tools: tools,
            tool_choice: tool_choice,
            user: user
        )
    }
    
    public func promptChatGPTStream(
        chatCompletionRequest: Components.Schemas.CreateChatCompletionRequest
    ) -> AsyncThrowingStream<Components.Schemas.CreateChatCompletionStreamResponse, Error> {
        AsyncThrowingStream { continuation in
            Task(priority: .userInitiated) {
                do {
                    var checkedRequest = chatCompletionRequest
                    // make sure stream mode activated
                    checkedRequest.stream = true
                    // create response
                    let response = try await client.createChatCompletion(body: .json(checkedRequest))
                    
                    switch response {
                        case .ok(let okResponse):
                            switch okResponse.body {
                                case .json(let completionResponse):
                                    switch completionResponse {
                                        case .CreateChatCompletionStreamResponse(let streamResponse):
                                            continuation.yield(streamResponse)
                                        default:
                                            continuation.finish(throwing:  "OpenAIClientError - There is No streaming mode!")
                                    }
                            }
                        case .undocumented(let statusCode, let payload):
                            continuation.finish(throwing:  "OpenAIClientError - statuscode: \(statusCode), \(payload)")
                    }
                } catch {
                    continuation.finish(throwing:  error)
                    
                }
            }
        }
    }
    
    public func promptChatGPT(
        chatCompletionRequest: Components.Schemas.CreateChatCompletionRequest
    ) async throws -> Components.Schemas.CreateChatCompletionResponse {
        var checkedRequest = chatCompletionRequest
        // make sure stream mode deactivated
        checkedRequest.stream = false
        // create response
        let response = try await client.createChatCompletion(body: .json(checkedRequest))
        
        switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                    case .json(let completionResponse):
                        switch completionResponse {
                            case .CreateChatCompletionResponse(let response):
                                return response
                            default:
                                throw "OpenAIClientError - Stream Mode is not available!"
                        }
                }
            case .undocumented(let statusCode, let payload):
                throw "OpenAIClientError - statuscode: \(statusCode), \(payload)"
        }
        
    }
    
    public func generateSpeechFrom(input: String,
                                   model: Components.Schemas.CreateSpeechRequest.modelPayload.Value2Payload = .tts_hyphen_1,
                                   voice: Components.Schemas.CreateSpeechRequest.voicePayload = .alloy,
                                   format: Components.Schemas.CreateSpeechRequest.response_formatPayload = .aac
    ) async throws -> Data {
        let response = try await client.createSpeech(body: .json(
            .init(
                model: .init(value1: nil, value2: model),
                input: input,
                voice: voice,
                response_format: format
            )))
        
        switch response {
        case .ok(let response):
            switch response.body {
            case .any(let body):
                var data = Data()
                for try await byte in body {
                    data.append(contentsOf: byte)
                }
                return data
            }
            
        case .undocumented(let statusCode, let payload):
            throw "OpenAIClientError - statuscode: \(statusCode), \(payload)"
        }
    }

    /// Use URLSession manually until swift-openapi-runtime support MultipartForm
    public func generateAudioTransciptions(audioData: Data, fileName: String = "recording.m4a") async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        let boundary: String = UUID().uuidString
        request.timeoutInterval = 30
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let bodyBuilder = MultipartFormDataBodyBuilder(boundary: boundary, entries: [
            .file(paramName: "file", fileName: fileName, fileData: audioData, contentType: "audio/mpeg"),
            .string(paramName: "model", value: "whisper-1"),
            .string(paramName: "response_format", value: "text")
        ])
        request.httpBody = bodyBuilder.build()
        let (data, resp) = try await urlSession.data(for: request)
        guard let httpResp = resp as? HTTPURLResponse, httpResp.statusCode == 200 else {
            throw "Invalid Status Code \((resp as? HTTPURLResponse)?.statusCode ?? -1)"
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw "Invalid format"
        }
        
        return text
    }
    
    public func generateDallE3Image(prompt: String,
                                    quality: Components.Schemas.CreateImageRequest.qualityPayload = .standard,
                                    responseFormat: Components.Schemas.CreateImageRequest.response_formatPayload = .url,
                                    style: Components.Schemas.CreateImageRequest.stylePayload = .vivid
                                    
    ) async throws -> Components.Schemas.Image {
        
        let response = try await client.createImage(.init(body: .json(
            .init(
                prompt: prompt,
                model: .init(value1: nil, value2: .dall_hyphen_e_hyphen_3),
                n: 1,
                quality: quality,
                response_format: responseFormat,
                size: ._1024x1024,
                style: style
            ))))
        
        switch response {
        case .ok(let response):
            switch response.body {
            case .json(let imageResponse) where imageResponse.data.first != nil:
                return imageResponse.data.first!
                
            default:
                throw "Unknown response"
            }
            
        case .undocumented(let statusCode, let payload):
            throw "OpenAIClientError - statuscode: \(statusCode), \(payload)"
        }
    }
    
}
