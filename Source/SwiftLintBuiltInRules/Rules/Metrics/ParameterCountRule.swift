import SwiftSyntax

@SwiftSyntaxRule
struct ParameterCountRule: Rule {
    var configuration = ParameterCountRuleConfiguration()

    static let description = RuleDescription(
        identifier: "parameter_count",
        name: "Parameter Count",
        description: "Initializers should not have more than 8 parameters.",
        kind: .metrics,
        nonTriggeringExamples: [
            Example("init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int, g: Int) {}"),
            Example("init(a: Int, b: Int, c: Int, d: Int, e: Int) {}"),
        ],
        triggeringExamples: [
            Example("↓init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int, g: Int, h: Int, i: Int) {}"),
            Example("↓init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int, g: Int, h: Int) {}"),
            Example("↓init?(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int, g: Int, h: Int) {}"),
            Example("↓init?<T>(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int, g: Int, h: Int) {}"),
            Example("↓init?<T: String>(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int, g: Int, h: Int) {}"),
        ]
    )
}

private extension ParameterCountRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: InitializerDeclSyntax) {
            guard !node.modifiers.contains(keyword: .override) else {
                return
            }

            let parameterList = node.signature.parameterClause.parameters
            guard let minThreshold = configuration.severityConfiguration.params.map(\.value).min(by: <) else {
                return
            }

            let allParameterCount = parameterList.count
            if allParameterCount < minThreshold {
                return
            }

            let parameterCount = allParameterCount

            for parameter in configuration.severityConfiguration.params where parameterCount >= parameter.value {
                let reason = "Initializer should have \(configuration.severityConfiguration.error!) parameters " +
                             "or less: it currently has \(parameterCount)"

                violations.append(
                    ReasonedRuleViolation(
                        position: node.initKeyword.positionAfterSkippingLeadingTrivia,
                        reason: reason,
                        severity: parameter.severity
                    )
                )
                return
            }
        }
    }
}
