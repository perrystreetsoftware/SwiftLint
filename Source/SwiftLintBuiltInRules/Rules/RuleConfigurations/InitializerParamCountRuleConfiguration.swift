//
//  File.swift
//  
//
//  Created by Bruno Campos on 8/15/24.
//

import Foundation
import SwiftLintCore

@AutoApply
struct InitializerParamCountRuleConfiguration: RuleConfiguration {
    typealias Parent = InitializerParamCountRule

    @ConfigurationElement(inline: true)
    private(set) var severityConfiguration = SeverityLevelsConfiguration<Parent>(warning: 8, error: 8)
}
