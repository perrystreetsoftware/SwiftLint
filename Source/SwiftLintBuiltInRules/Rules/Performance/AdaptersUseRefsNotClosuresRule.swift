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
        // reverse walk up the tree
        func isDeclaredInSwiftUiBody(_ node: Syntax?) -> Bool {
            guard let node else { return false }
            guard let patternListBinding = node.as(PatternBindingListSyntax.self) else {
                return isDeclaredInSwiftUiBody(node.parent)
            }

            let isBody = patternListBinding.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body"
            let isReturningView = patternListBinding.first?.typeAnnotation?.as(TypeAnnotationSyntax.self)?.type.as(ConstrainedSugarTypeSyntax.self)?.baseType.as(SimpleTypeIdentifierSyntax.self)?.name.text == "View"

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

            if structDecl.identifier.text.hasSuffix("Adapter") {
                return true
            }

            return isDeclaredInAdapterStruct(node.parent)
        }

        func isCallingSwiftUiView(_ node: FunctionCallExprSyntax) -> Bool {
            node.calledExpression.as(IdentifierExprSyntax.self)?.identifier.text.isSwiftUIView ?? false
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if isCallingSwiftUiView(node) {
                var closureCount = 0

                guard isDeclaredInSwiftUiBody(node._syntaxNode) else { return }

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
