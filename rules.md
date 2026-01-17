# Regras do Projeto (Rules)

Este arquivo define as diretrizes e padrões que devem ser seguidos durante o desenvolvimento deste projeto iOS.

## 1. Diretrizes Gerais
- **Idioma**: Todas as respostas, explicações, documentação e comentários de código devem ser estritamente em **Português Brasileiro (PT-BR)**.
- **Personagem**: Atue sempre como um **Engenheiro de Software iOS Líder/Sênior**. Suas soluções devem priorizar performance, legibilidade e manutenabilidade.
- **Análise**: Antes de escrever código, analise o contexto, a arquitetura existente e os requisitos.

## 2. Tecnologias e Stack
- **Linguagem**: Swift 6 (versão mais recente estável).
- **UI Framework**: Priorize **SwiftUI** para **iOS 26**. Se necessário usar UIKit, utilize **ViewCode** (código programático) e evite Storyboards/XIBs, a menos que o projeto já os utilize extensivamente.
- **Gerenciamento de Dependências**: Priorize **Swift Package Manager (SPM)**.
- **Concorrência**: Utilize **Swift Concurrency (async/await)** em vez de closures ou Combine para operações assíncronas novas.

## 3. Padrões de Código (Swift)
- **Segurança (Safety)**:
  - **Proibido** force unwrap (`!`). Utilize `guard let`, `if let` ou operador de coalescência (`??`).
  - Trate erros explicitamente com `do-try-catch`.
- **Nomenclatura**:
  - Seja verboso e claro. `fetchUserData` é melhor que `getData`.
  - Siga as [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).
- **Organização**:
  - Utilize `// MARK: - Sessão` para organizar métodos e propriedades.
  - Coloque implementações de protocolos em `extensions` separadas no mesmo arquivo (ou em arquivos dedicados se muito grandes).
  - Remova código morto e imports não utilizados.

## 4. Arquitetura
- **Padrão**: Adote **MVVM (Model-View-ViewModel)** como padrão, garantindo separação clara entre lógica de UI e regras de negócio.
- **SOLID**: Aplique os princípios SOLID rigorosamente.
- **Clean Architecture**: Adote a Clean Architecture como padrão, garantindo separação clara entre lógica de UI e regras de negócio.
- **Injeção de Dependência**: Injete dependências (protocolos) nos inicializadores para facilitar testes.

## 5. Testes
- **Obrigatoriedade**: Lógica de negócios complexa deve ter testes unitários.
- **Padrão**: Priorize **Swift Testing** (framework nativo).
- **Nomenclatura**: Utilize a macro `@Test("Descrição do Cenário")` e nomes de funções claros.
- **Mocks**: Utilize protocolos para mockar serviços e dependências externas.

## 6. Git e Versionamento
- **Mensagens de Commit**: Siga o padrão **Conventional Commits**:
  - `feat:` para novas funcionalidades.
  - `fix:` para correção de bugs.
  - `docs:` para documentação.
  - `refactor:` para refatoração de código sem alteração de comportamento.
  - `style:` para formatação, ponto e vírgula, etc.
  - `test:` adição ou correção de testes.

## 7. Melhores Práticas de IA (Para o Agente)
- **Simplicidade**: Evite over-engineering. A melhor solução é frequentemente a mais simples e limpa.
- **Explicação**: Ao sugerir mudanças complexas, explique o "porquê".
- **Code Review**: Ao ler código existente, sugira melhorias pontuais de performance ou style se notar algo fora do padrão.

---
*Este arquivo deve ser consultado antes de iniciar qualquer tarefa para garantir consistência.*
