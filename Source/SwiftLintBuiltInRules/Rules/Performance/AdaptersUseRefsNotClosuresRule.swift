import SwiftSyntax

@SwiftSyntaxRule
struct AdaptersUseRefsNotClosuresRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

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
            """),
            Example("""
            InboxTabsHostingView(showPaywall: { showPaywall?() })
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
}

private extension String {
    var isSwiftUIView: Bool {
        self.hasSuffix("View") || self.hasSuffix("Screen") || self.hasSuffix("Page")
    }
}

private extension AdaptersUseRefsNotClosuresRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        // reverse walk up the tree
        func isDeclaredInSwiftUiBody(_ node: Syntax?) -> Bool {
            guard let node else { return false }
            guard let patternListBinding = node.as(PatternBindingListSyntax.self) else {
                return isDeclaredInSwiftUiBody(node.parent)
            }

            let isBody = patternListBinding.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body"
            let isReturningView = patternListBinding.first?.typeAnnotation?.type.as(
                SomeOrAnyTypeSyntax.self
            )?.constraint.as(
                IdentifierTypeSyntax.self
            )?.name.text == "View"

            if isBody && isReturningView {
                return isDeclaredInAdapterStruct(node.parent)
            }

            return isDeclaredInSwiftUiBody(node.parent)
        }

        // reverse walk up the tree
        func isDeclaredInAdapterStruct(_ node: Syntax?) -> Bool {
            guard let node else { return false }
            guard let structDecl = node.as(StructDeclSyntax.self) else {
                return isDeclaredInAdapterStruct(node.parent)
            }

            if structDecl.name.text.hasSuffix("Adapter") {
                return true
            }

            return isDeclaredInAdapterStruct(node.parent)
        }

        func isCallingSwiftUiView(_ node: FunctionCallExprSyntax) -> Bool {
            node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text.isSwiftUIView ?? false
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if isCallingSwiftUiView(node) {
                var closureCount = 0

                guard isDeclaredInSwiftUiBody(node._syntaxNode) else { return }

                node.arguments.forEach { argument in
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
