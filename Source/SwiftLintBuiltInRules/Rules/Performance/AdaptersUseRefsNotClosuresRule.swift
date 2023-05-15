import SwiftSyntax

struct AdaptersUseRefsNotClosuresRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.error)

    static let description = RuleDescription(
        identifier: "adapters_use_refs_not_closures",
        name: "Adapters use refs not closures",
        description: "Prefer using function references so that SwiftUI can reduce update passes",
        kind: .performance,
        nonTriggeringExamples: [
            Example("""
            struct SomeAdapter {
              let viewModel: AViewModel

              var body: some View {
                InnerThing(onEvent: { viewModel.onEvent() })
              }
            }
            """),
            Example("""
            struct SomeView {
              let viewModel: AViewModel

              var body: some View {
                InnerView(onEvent: { viewModel.onEvent() })
              }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            struct SomeAdapter {
              let viewModel: AViewModel

              var body: some View {
                InnerView(onEvent: { viewModel.onEvent() })
              }
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension String {
    var isSwiftUIView: Bool {
        self.hasSuffix("View") || self.hasSuffix("Screen") || self.hasSuffix("Page")
    }
}

private extension AdaptersUseRefsNotClosuresRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.identifier.text.hasSuffix("Adapter") {
                return .visitChildren
            } else {
                return .skipChildren
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if node.calledExpression.as(IdentifierExprSyntax.self)?.identifier.text.isSwiftUIView ?? false {
                var closureCount = 0

                node.argumentList.forEach { argument in
                    if argument.expression.as(ClosureExprSyntax.self) != nil {
                        closureCount += 1
                    }
                }

                if closureCount > 0 {
                    violations.append(node.positionAfterSkippingLeadingTrivia)
                }
            }
        }
    }
}
