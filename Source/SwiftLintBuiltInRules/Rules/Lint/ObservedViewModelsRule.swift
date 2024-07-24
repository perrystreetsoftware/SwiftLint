import SwiftSyntax

@SwiftSyntaxRule
struct ObservedViewModelsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    init() {}

    let message = "You must use properties of an @Observed viewModel"

    static let description = RuleDescription(
        identifier: "observed_view_models",
        name: "ObservedViewModels",
        description: "You must use properties of an @Observed viewModel",
        kind: .style,
        nonTriggeringExamples: ObservedViewModelsRuleExamples.nonTriggeringExamples,
        triggeringExamples: ObservedViewModelsRuleExamples.triggeringExamples
    )
}

private extension ObservedViewModelsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        var observedViewModels: [(String, AbsolutePosition)] = []
        var observed = false
        var viewModelCallCount = 0

        // If we see @ObservedObject, we trigger this rule
        static let ObservedObjectKeyword = "ObservedObject"
        // If we see variables that end in this keyword, we trigger this rule
        static let ProbablyAViewModelKeyword = "viewModel"

        override func visit(_ node: MemberBlockItemSyntax) -> SyntaxVisitorContinueKind {
            if let decl = node.decl.as(VariableDeclSyntax.self) {
                if decl.attributes.first?.as(AttributeSyntax.self)?.attributeName.as(
                    IdentifierTypeSyntax.self
                )?.name.text == Self.ObservedObjectKeyword {
                    observed = true
                }

                if let varIdentifier = decl.bindings.first?.pattern.as(
                    IdentifierPatternSyntax.self
                )?.identifier.text {
                    if varIdentifier.uppercased().hasSuffix(Self.ProbablyAViewModelKeyword.uppercased()) {
                        observedViewModels.append((varIdentifier, node.positionAfterSkippingLeadingTrivia))
                    }
                }
            }

            if isMatching {
                return .visitChildren
            }
            return .skipChildren
        }

        private var isMatching: Bool {
            observedViewModels.isNotEmpty && observed
        }

        override func visitPost(_ node: SourceFileSyntax) {
            if viewModelCallCount == 0 && isMatching {
                if let firstObserved = observedViewModels.first {
                    violations.append(firstObserved.1)
                }
            }
        }

        override func visitPost(_ node: MemberAccessExprSyntax) {
            if let identifierText = node.base?.as(DeclReferenceExprSyntax.self)?.baseName.text {
                if observedViewModels.map({ $0.0 }).contains(
                    identifierText.replacingOccurrences(of: "$", with: "")
                ) && node.period.tokenKind == TokenKind.period {
                    viewModelCallCount += 1
                }
            }
        }
    }
}

internal struct ObservedViewModelsRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("""
            struct SomeView: View {
                @ObservedObject var viewModel: ViewModel

                var body: some View {
                    Screen(viewModel.state)
                }

            }
        """),
        Example("""
            struct SomeView: View {
                @ObservedObject var viewModel: ViewModel
                var otherObject: OtherViewModel

                var body: some View {
                    Text(viewModel.title)
                }
            }
        """),
        Example("""
            struct SomeView: View {
                @ObservedObject var viewModel: ViewModel
                var otherObject: OtherViewModel

                var body: some View {
                    Text(viewModel.title)
                }
            }
        """),
        Example("""
            struct SomeView: View {
                @StateObject var viewModel: ViewModel

                var body: some View {
                    EmptyView()
                }

            }
        """),
        Example("""
            struct SomeView: View {
                @ObservedObject var viewModel: ViewModel

                var body: some View {
                    Toggle("Is online", isOn: $viewModel.isOnline)
                }
            }
        """),
    ]

    static var triggeringExamples: [Example] {
        [
            Example("""
                struct SomeView: View {
                    @ObservedObject var viewModel: ViewModel

                    var body: some View {
                        EmptyView()
                    }
                }
            """),
            Example("""
                struct SomeView: View {
                    @ObservedObject var viewModel: ViewModel
                    var otherObject: OtherViewModel

                    var body: some View {
                        Text(otherObject.title)
                    }
                }
            """),
            Example("""
                struct SomeView: View {
                    @ObservedObject var someKindOfViewModel: ViewModel

                    var body: some View {
                        EmptyView()
                    }
                }
            """),
        ]
    }
}
