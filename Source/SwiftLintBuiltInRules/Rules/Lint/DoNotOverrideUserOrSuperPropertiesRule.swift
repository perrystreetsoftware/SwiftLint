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
        triggeringExamples: DoNotOverrideUserOrSuperPropertiesRuleExamples.triggeringExamples()
    )
    
    static let userProperties = [
        "age",
        "device_locale",
        "device_model",
        "email",
        "flavor",
        "hardware_id",
        "ios_app_build_number",
        "ios_app_version",
        "ios_app_version_number",
        "most_recent_app_version_number",
        "name",
        "os_version",
        "profile_age_months",
        "pro_status",
        "tags"
    ]

    static let superProperties = [
        "admin",
        "boost_active",
        "enabled_features",
        "profile_id",
        "profile_type",
        "remote_config_channel",
        "remote_configs",
        "session_id"
    ]
    
    static let restrictedProperties = userProperties + superProperties + ["source"]
}

private extension DoNotOverrideUserOrSuperPropertiesRule {
    
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        
        private func containsRestrictedProperty(in segments: StringLiteralExprSyntax?) -> Bool {
            return segments?.segments.contains(where: { segment in
                DoNotOverrideUserOrSuperPropertiesRule.restrictedProperties.contains(
                    segment.as(StringSegmentSyntax.self)?.content.text ?? ""
                )
            }) ?? false
        }
        
        override func visitPost(_ node: DictionaryExprSyntax) {
            guard
                let propertiesContent = node.content.as(DictionaryElementListSyntax.self),
                propertiesContent.contains(where: {
                    containsRestrictedProperty(in: $0.key.as(StringLiteralExprSyntax.self))
                })
            else {
                return
            }
            
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
        
        override func visitPost(_ node: SubscriptCallExprSyntax) {
            guard
                node.arguments.contains(where: {
                    containsRestrictedProperty(in: $0.expression.as(StringLiteralExprSyntax.self)
                    )
                })
            else {
                return
            }
            
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

private struct DoNotOverrideUserOrSuperPropertiesRuleExamples {
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
    
    static func triggeringExamples() -> [Example] {
        var examples = [Example]()
        
        DoNotOverrideUserOrSuperPropertiesRule.restrictedProperties.forEach { property in
            examples.append(
                Example("""
                    public static func callEnded(targetUserId: Int, callDuration: TimeInterval? = nil) -> AnalyticsEvent {
                        var properties: [String: any AnalyticsProperty] = ["target_id": targetUserId]
                        if let callDuration = callDuration {
                            properties["call_duration"] = callDuration * 1000
                        }
                        properties["\(property)"] = "some value"
            
                        return AnalyticsEvent(
                            name: "call_ended",
                            category: .videoChat,
                            properties: properties,
                            logTargets: [.business, .diagnostics]
                        )
                    }
            """)
            )
            examples.append(
                Example("""
                        public static func callIgnored(targetUserId: Int, source: IgnoreEventSourceType) -> AnalyticsEvent {
                            return AnalyticsEvent(
                                name: "ignored_call_viewed",
                                category: .videoChat,
                                properties: ["target_id": targetUserId, "\(property)": "some value"],
                                logTargets: [.diagnostics]
                            )
                        }
                """)
            )
        }
        
        return examples
    }
}
