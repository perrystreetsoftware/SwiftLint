import SwiftSyntax

@SwiftSyntaxRule
struct UseCaseExposedFunctionsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    init() {}

    let message: String = "A UseCase should only expose one public function"

    static let description = RuleDescription(
        identifier: "usecase_exposed_functions",
        name: "UseCaseExposedFunctionsRule",
        description: "A UseCase should only expose one public function",
        kind: .style,
        nonTriggeringExamples: UseCaseExposedFunctionsRuleExamples.nonTriggeringExamples,
        triggeringExamples: UseCaseExposedFunctionsRuleExamples.triggeringExamples
    )

//     func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
//         LegacyFunctionRuleHelper.Visitor(viewMode: .sourceAccurate)
//    }
}

private extension UseCaseExposedFunctionsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            .allExcept(ClassDeclSyntax.self, ProtocolDeclSyntax.self, StructDeclSyntax.self)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.isLogicClass && node.memberBlock.nonPrivateFunctions.count > 1 {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }

            return .skipChildren
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.isLogicProtocol && node.memberBlock.nonPrivateFunctions.count > 1 {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }

            return .skipChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.isLogicStruct && node.memberBlock.nonPrivateFunctions.count > 1 {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }

            return .skipChildren
        }
    }
}

private extension ClassDeclSyntax {
    // Check that it is a logic class
    var isLogicClass: Bool {
        name.text.hasSuffix("Logic") || name.text.hasSuffix("UseCase")
    }
}

private extension StructDeclSyntax {
    // Check that it is a logic struct
    var isLogicStruct: Bool {
        name.text.hasSuffix("Logic") || name.text.hasSuffix("UseCase")
    }
}

private extension ProtocolDeclSyntax {
    // Check that it is a logic struct
    var isLogicProtocol: Bool {
        name.text.hasSuffix("Logic") || name.text.hasSuffix("UseCase")
    }
}

private extension MemberBlockSyntax {
    var nonPrivateFunctions: [MemberBlockItemListSyntax.Element] {
        members.filter { member in
            guard let function: FunctionDeclSyntax = member.decl.as(FunctionDeclSyntax.self) else { return false }

            return function.modifiers.isEmpty ||
                function.modifiers.first?.name.text == "public"
        }
    }
}

internal struct UseCaseExposedFunctionsRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("""
        struct MyView: View {
            var body: some View {
                Image(decorative: "my-image")
            }
        }
        """),
        Example("""
        class MyViewModel: ViewModel {
            var state: State = State.empty()
        }
        """),
        Example("""
        protocol LogicalProtocol {
            func receive() -> Bool
        }
        """),
        Example("""
        public class MyUseCase {
            public init() {}

            public func callAsFunction() -> AnyPublisher<Void, Never> {}

            private func computeInput() {}
        }
        """),
        Example("""
        class MyLogic {
            init() {}

            private func get(fire: String) -> Int {
                return 35
            }
            func callAsFunction() -> String {
                return "call"
            }
        }
        """),
        Example("""
        class MyLogic {
            init() {}

            func get(fire: String) -> Int {
                return 35
            }
        }
        """)
    ]

    static let triggeringExamples: [Example] = [
        Example("""
        public protocol MyLogic {
            func getSomething() -> String
            func callAsFunction() -> AnyPublisher<Void, Never>
        }
        """),
        Example("""
        public struct MyLogic {
            public init() {}

            public func get() -> Int {
                return 45
            }
            public func callAsFunction() -> String {
                return ""
            }
        }
        """),
        Example("""
        public class MyLogic {
            public init() {}

            public func get(fire: String) -> Int {
                return 35
            }
            public func callAsFunction() -> String {
                return "call"
            }
        }
        """),
        Example("""
        class MyLogic {
            init() {}

            func get(fire: String) -> Int {
                return 35
            }
            public func callAsFunction() -> String {
                return "call"
            }
        }
        """),
        Example("""
        class MyLogic {
            init() {}

            func get(fire: String) -> Int {
                return 35
            }
            func callAsFunction() -> String {
                return "call"
            }
        }
        """)
    ]
}
