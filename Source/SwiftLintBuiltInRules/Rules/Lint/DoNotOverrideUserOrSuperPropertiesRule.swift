import SwiftSyntax

@SwiftSyntaxRule
struct DoNotOverrideUserOrSuperPropertiesRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    init() {}

    let message: String = "Do not override any of the pre-existing super/user properties or source"

    static let description = RuleDescription(
        identifier: "do_not_override_user_or_super_properties",
        name: "DoNotOverrideUserOrSuperPropertiesRule",
        description: "Do not override any of the pre-existing super/user properties or source",
        kind: .lint,
        nonTriggeringExamples: DoNotOverrideUserOrSuperPropertiesRuleExamples.nonTriggeringExamples,
        triggeringExamples: DoNotOverrideUserOrSuperPropertiesRuleExamples.triggeringExamples
    )
}

private extension DoNotOverrideUserOrSuperPropertiesRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        
        override func visitPost(_ node: DictionaryExprSyntax) {
            guard
                let propertiesContent = node.content.as(DictionaryElementListSyntax.self),
                propertiesContent.contains(where: {
                    let keySegments = $0.key.as(StringLiteralExprSyntax.self)?.segments
                    return keySegments?.contains(where: {
                        $0.as(StringSegmentSyntax.self)?.content.as(TokenSyntax.self)?.text == "source"
                    }) ?? false
                })
            else {
                return
            }
            
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
        
        override func visitPost(_ node: SubscriptCallExprSyntax) {
            guard
                node.arguments.as(LabeledExprListSyntax.self)?.contains(where: {
                    let keySegments = $0.as(LabeledExprSyntax.self)?.expression.as(StringLiteralExprSyntax.self)?.segments
                    return keySegments?.contains(where: {
                        $0.as(StringSegmentSyntax.self)?.content.as(TokenSyntax.self)?.text == "source"
                    }) ?? false
                }) ?? false
            else {
                return
            }
            
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

internal struct DoNotOverrideUserOrSuperPropertiesRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("""
                public static func callIgnored(targetUserId: Int, source: IgnoreEventSourceType) -> AnalyticsEvent {
                    return AnalyticsEvent(
                        name: "ignored_call_viewed",
                        category: .videoChat,
                        properties: ["target_id": targetUserId],
                        logTargets: [.diagnostics]
                    )
                }
        """),
        Example("""
                public static func callEnded(targetUserId: Int, callDuration: TimeInterval? = nil) -> AnalyticsEvent {
                    var properties: [String: any AnalyticsProperty] = ["target_id": targetUserId]
                    if let callDuration = callDuration {
                        properties["call_duration"] = callDuration * 1000
                    }
        
                    return AnalyticsEvent(
                        name: "call_ended",
                        category: .videoChat,
                        properties: properties,
                        logTargets: [.business, .diagnostics]
                    )
                }
        """)
    ]

    static var triggeringExamples: [Example] {
        [
            Example("""
                    public static func callEnded(targetUserId: Int, callDuration: TimeInterval? = nil) -> AnalyticsEvent {
                        var properties: [String: any AnalyticsProperty] = ["target_id": targetUserId]
                        if let callDuration = callDuration {
                            properties["call_duration"] = callDuration * 1000
                        }
                        properties["source"] = "some source"
            
                        return AnalyticsEvent(
                            name: "call_ended",
                            category: .videoChat,
                            properties: properties,
                            logTargets: [.business, .diagnostics]
                        )
                    }
            """),
            Example("""
                    public static func callIgnored(targetUserId: Int, source: IgnoreEventSourceType) -> AnalyticsEvent {
                        return AnalyticsEvent(
                            name: "ignored_call_viewed",
                            category: .videoChat,
                            properties: ["target_id": targetUserId, "source": source.rawValue],
                            logTargets: [.diagnostics]
                        )
                    }
            """)
        ]
    }
}
