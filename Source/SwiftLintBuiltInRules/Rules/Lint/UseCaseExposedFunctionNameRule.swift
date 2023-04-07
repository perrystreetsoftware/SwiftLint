import SwiftSyntax

@SwiftSyntaxRule
struct UseCaseExposedFunctionNameRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    init() {}

    let message: String = "A UseCase's exposed function should be a callAsFunction"

    static let description = RuleDescription(
        identifier: "usecase_exposed_function_name",
        name: "UseCaseExposedFunctionNameRule",
        description: "A UseCase's exposed function should be a callAsFunction",
        kind: .style,
        nonTriggeringExamples: UseCaseExposedFunctionNameRuleExamples.nonTriggeringExamples,
        triggeringExamples: UseCaseExposedFunctionNameRuleExamples.triggeringExamples
    )
}

private extension UseCaseExposedFunctionNameRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            .allExcept(ClassDeclSyntax.self, ProtocolDeclSyntax.self, StructDeclSyntax.self)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.isLogicClass &&
               node.memberBlock.nonPrivateFunctions.count == 1 &&
               !node.memberBlock.nonPrivateFunctions[0].isCallAsFunction {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }

            return .skipChildren
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.isLogicProtocol &&
               node.memberBlock.nonPrivateFunctions.count == 1 &&
               !node.memberBlock.nonPrivateFunctions[0].isCallAsFunction {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }

            return .skipChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.isLogicStruct &&
               node.memberBlock.nonPrivateFunctions.count == 1 &&
               !node.memberBlock.nonPrivateFunctions[0].isCallAsFunction {
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

            return function.modifiers.contains(where: { $0.name.tokenKind != .keyword(.private) })
        }
    }
}

private extension MemberBlockItemListSyntax.Element {
    var isCallAsFunction: Bool {
        (decl.as(FunctionDeclSyntax.self))?.name.text == "callAsFunction"
    }
}

internal struct UseCaseExposedFunctionNameRuleExamples {
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
        }
        """),
        Example("""
        class MyLogic {
            init() {}

            public func callAsFunction() -> String {
                return "call"
            }
        }
        """)
    ]

    static let triggeringExamples: [Example] = [
        Example("""
        public protocol MyLogic {
            func getSomething() -> String
        """),
        Example("""
        public struct MyLogic {
            public init() {}

            public func invoke() -> String {
                return ""
            }
        }
        """),
        Example("""
        public class MyLogic {
            public init() {}

            public func get() -> String {
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
}
