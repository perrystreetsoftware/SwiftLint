import SwiftSyntax

struct RefsNotClosuresRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    static let description = RuleDescription(
        identifier: "refs_not_closures",
        name: "Refs not closures",
        description: "Prefer using function references so that SwiftUI can reduce update passes",
        kind: .performance,
        nonTriggeringExamples: [
            Example("""
            let viewModel = ViewModel()
            lazy var view = View(callback: viewModel.callback)
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
            lazy var view = View(callback: { viewModel.callback })
            """),
            Example("""
            let view = View(state: true, callback: { viewModel.callback })
            """),
            Example("""
            let view = MyScreen(state: true,
                                onButtonTapped: { viewModel.callback })
            """),
            Example("""
            AccountPage(state: .initial,
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
        self.hasSuffix("View") || self.hasSuffix("Page") || self.hasSuffix("Screen")
    }
}

private extension RefsNotClosuresRule {
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
