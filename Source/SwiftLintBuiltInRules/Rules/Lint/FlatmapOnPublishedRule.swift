import SwiftSyntax

struct FlatmapOnPublishedRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.error)

    init() {}

    let message: String = "Do not apply a `.flatMap` on a `$published` value"

    static let description = RuleDescription(
        identifier: "flatmap_on_published",
        name: "FlatmapOnPublishedRule",
        description: "Do not apply a `.flatMap` on a `$published` value",
        kind: .style,
        nonTriggeringExamples: FlatmapOnPublishedRuleExamples.nonTriggeringExamples,
        triggeringExamples: FlatmapOnPublishedRuleExamples.triggeringExamples
    )

     func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension FlatmapOnPublishedRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard
                let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
                let outerBase = calledExpression.base?.as(FunctionCallExprSyntax.self),
                let outerCalledExpression = outerBase.calledExpression.as(MemberAccessExprSyntax.self),
                outerCalledExpression.name.text == "flatMap",
                let innerBase = outerCalledExpression.base?.as(MemberAccessExprSyntax.self),
                innerBase.name.text.starts(with: "$")
            else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

internal struct FlatmapOnPublishedRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("""
                let publisher =
                    repo.$published
                        .map { value -> AnyPublisher<Void, Never> in
                            return Just(()).eraseToAnyPublisher()
                        }
                        .switchToLatest()
                        .eraseToAnyPublisher()
        """),
        Example("""
                let publisher =
                    repo.$published
                        .map { value -> AnyPublisher<Void, Never> in
                            return Just(()).flatMap { _ in -> AnyPublisher<Void, Never> in
                                return Just(()).eraseToAnyPublisher()
                            }.eraseToAnyPublisher()
                        }
                        .switchToLatest()
                        .eraseToAnyPublisher()
        """)
    ]

    static var triggeringExamples: [Example] {
        [
            Example("""
                let publisher =
                    repo.$published
                        .flatMap { value -> AnyPublisher<Void, Never> in
                            return Just(()).eraseToAnyPublisher()
                        }
                        .eraseToAnyPublisher()
            """)
        ]
    }
}
