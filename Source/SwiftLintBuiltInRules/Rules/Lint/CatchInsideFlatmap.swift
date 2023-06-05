import SwiftSyntax

struct CatchInsideFlatmapRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.error)

    init() {}

    let message: String = "A catch statement should be inside of a flatmap"

    static let description = RuleDescription(
        identifier: "catch_inside_flatmap",
        name: "CatchInsideFlatmapRule",
        description: "A catch statement should be inside of a flatmap",
        kind: .style,
        nonTriggeringExamples: CatchInsideFlatmapRuleExamples.nonTriggeringExamples,
        triggeringExamples: CatchInsideFlatmapRuleExamples.triggeringExamples
    )

     func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension CatchInsideFlatmapRule {
    final class Visitor: ViolationsSyntaxVisitor {
        // reverse walk up the tree
        func isDeclaredInFlatmap(_ node: Syntax?) -> Bool {
            guard let node else { return false }
            guard let funcDecl = node.as(FunctionCallExprSyntax.self) else {
                return isDeclaredInFlatmap(node.parent)
            }

            if let member = funcDecl.calledExpression.as(MemberAccessExprSyntax.self) {
                if member.name.text == "flatMap" {
                    return true
                }
            }

            return isDeclaredInFlatmap(node.parent)
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let member = node.calledExpression.as(MemberAccessExprSyntax.self) {
                if member.name.text == "catch" {
                    if !isDeclaredInFlatmap(node._syntaxNode) {
                        violations.append(node.positionAfterSkippingLeadingTrivia)
                    }
                }
            }
        }
    }
}

internal struct CatchInsideFlatmapRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("""
                let publisher = callAsFunction()
                .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in  {
                    guard let self else {
                        return Just(()).eraseToAnyPublisher()
                    }

                    return self
                        .someOtherCall()
                        .catch { _ -> AnyPublisher<Void, Never> in
                            return Just(()).eraseToAnyPublisher()
                        }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        """),
    ]

    static var triggeringExamples: [Example] {
        [
            Example("""
                let publisher = callAsFunction()
                .catch { _ -> AnyPublisher<Void, Never> in
                    return Just(()).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
            """)
        ]
    }
}
