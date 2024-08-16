//
//  File.swift
//  
//
//  Created by Bruno Campos on 8/15/24.
//

import Foundation
import SwiftLintCore

@AutoApply
struct ParameterCountRuleConfiguration: RuleConfiguration {
    typealias Parent = ParameterCountRule

    @ConfigurationElement(inline: true)
    private(set) var severityConfiguration = SeverityLevelsConfiguration<Parent>(warning: 8, error: 8)
}
