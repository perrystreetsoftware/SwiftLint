import SwiftSyntax

struct AdaptersReceiveRefsNotClosuresRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    static let description = RuleDescription(
        identifier: "adapters_receive_refs_not_closures",
        name: "Adapters receive refs not closures",
        description: "Prefer using function references so that SwiftUI can reduce update passes",
        kind: .performance,
        nonTriggeringExamples: [
            Example("""
            let viewModel = ViewModel()
            lazy var view = Adapter(callback: viewModel.callback)
            """),
            Example("""
            let viewModel = ViewModel(callback: { viewModel.callback })
            """),
            Example("""
            AccountScreen(onButtonTapped: viewModel.onButtonTapped)
            """)
        ],
        triggeringExamples: [
            Example("""
            let viewModel = ViewModel()
            lazy var view = Adapter(callback: { viewModel.callback })
            """),
            Example("""
            let view = Adapter(state: true, callback: { viewModel.callback })
            """),
            Example("""
            let view = Adapter(state: true,
                               onButtonTapped: { viewModel.callback })
            """),
            Example("""
            Adapter(state: .initial,
                    isEnabled: false,
                    onButtonTapped: { viewModel.callback })
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension String {
    var isSwiftUIView: Bool {
        self.hasSuffix("Adapter")
    }
}

private extension AdaptersReceiveRefsNotClosuresRule {
    final class Visitor: ViolationsSyntaxVisitor {
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
