//
//  ClientModels.swift
//
//
//  Created by Sergey Petrov on 04.12.2023.
//

import Foundation

/// OpenAI models
/// - chat completion
/// - image generation
/// - custom model
public enum OpenAIModel {
    
    case chat(Chat)
    case image(ImageGeneration)
    case custom(String)
    
    public enum Chat: String, CaseIterable, Identifiable {
        case gpt_4_1106_preview = "gpt-4-1106-preview"
        case gpt_4_vision_preview = "gpt-4-vision-preview"
        case gpt_4 = "gpt-4"
        case gpt_4_0314 = "gpt-4-0314"
        case gpt_4_0613 = "gpt-4-0613"
        case gpt_4_32k = "gpt-4-32k"
        case gpt_4_32k_0314 = "gpt-4-32k-0314"
        case gpt_4_32k_0613 = "gpt-4-32k-0613"
        case gpt_3_5_turbo_1106 = "gpt-3.5-turbo-1106"
        case gpt_3_5_turbo = "gpt-3.5-turbo"
        case gpt_3_5_turbo_16k = "gpt-3.5-turbo-16k"
        case gpt_3_5_turbo_0301 = "gpt-3.5-turbo-0301"
        case gpt_3_5_turbo_0613 = "gpt-3.5-turbo-0613"
        case gpt_3_5_turbo_16k_0613 = "gpt-3.5-turbo-16k-0613"
        public var id: Self { self }
    }
    
    public enum ImageGeneration: String {
        case dall_e_3 = ""
    }
}
