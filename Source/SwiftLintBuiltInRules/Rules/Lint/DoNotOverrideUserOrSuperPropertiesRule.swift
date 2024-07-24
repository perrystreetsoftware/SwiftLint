import SwiftSyntax

@SwiftSyntaxRule
struct DoNotOverrideUserOrSuperPropertiesRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    init() {}

    let message = "Do not override any of the pre-existing super/user properties or source"

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
        "tags",
    ]

    static let superProperties = [
        "admin",
        "boost_active",
        "enabled_features",
        "profile_id",
        "profile_type",
        "remote_config_channel",
        "remote_configs",
        "session_id",
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

        private func isInAnalyticsEvent(_ syntax: Syntax?) -> Bool {
            var parent = syntax
            let maxIterations = 10
            var currentIteration = 0
            var isInAnalyticsEvent = false

            while parent != nil, currentIteration < maxIterations {
                if parent?.as(FunctionCallExprSyntax.self)?.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "AnalyticsEvent" {
                    isInAnalyticsEvent = true
                    break
                }
                if parent?.as(FunctionDeclSyntax.self)?.signature.returnClause?.type.as(IdentifierTypeSyntax.self)?.name.text == "AnalyticsEvent" {
                    isInAnalyticsEvent = true
                    break
                }
                if parent?.as(PatternBindingSyntax.self)?.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.name.text == "AnalyticsEvent" {
                    isInAnalyticsEvent = true
                    break
                }

                parent = parent?.parent
                currentIteration += 1
            }

            return isInAnalyticsEvent
        }

        override func visitPost(_ node: DictionaryExprSyntax) {
            let isInAnalyticsEvent = isInAnalyticsEvent(node.parent)

            guard
                let propertiesContent = node.content.as(DictionaryElementListSyntax.self),
                propertiesContent.contains(where: {
                    containsRestrictedProperty(in: $0.key.as(StringLiteralExprSyntax.self))
                }),
                isInAnalyticsEvent
            else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }

        override func visitPost(_ node: SubscriptCallExprSyntax) {
            let isInAnalyticsEvent = isInAnalyticsEvent(node.parent)

            guard
                node.arguments.contains(where: {
                    containsRestrictedProperty(in: $0.expression.as(StringLiteralExprSyntax.self)
                    )
                }),
                isInAnalyticsEvent
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
            public static var viewed: AnalyticsEvent {
                return AnalyticsEvent(
                    name: "viewed",
                    category: .discover,
                    properties: nil,
                    logTargets: [.diagnostics]
                )
            }
        """),
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
        """),
    ]

    static func triggeringExamples() -> [Example] {
        var examples = [Example]()

        DoNotOverrideUserOrSuperPropertiesRule.restrictedProperties.forEach { property in
            examples.append(
                Example("""
                    public static var viewed: AnalyticsEvent {
                        return AnalyticsEvent(
                            name: "viewed",
                            category: .discover,
                            properties: ["\(property)": "some value"],
                            logTargets: [.diagnostics]
                        )
                    }
                """)
            )
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
