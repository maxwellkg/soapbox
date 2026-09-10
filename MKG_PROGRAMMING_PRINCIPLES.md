# MKG Programming Principles

This document describes a practical philosophy for building software that is clear, reliable, and maintainable under real constraints.

## Programming philosophy
Code should be beautiful in the practical sense: clear, well-shaped, and easy to trust. It should read as plainly as good English, so that the reader can follow intent without constantly decoding implementation detail. It should also reflect the business and product domain directly, using names and structure that sound like the system being built rather than generic engineering templates.

That posture creates a bias toward strong defaults when the default behavior is a real business rule. If the correct path is usually the same, it is often better to encode that path directly than to rely on every caller to remember it. State and behavior should stay close together when that protects correctness, and mechanisms like callbacks or implicit defaults are appropriate when they make the normal path safer, clearer, and more faithful to the domain.

## Architecture defaults
Framework conventions, especially Rails defaults, are strong baselines and should be favored unless there is a clear, current benefit to deviating.

New layers, dependencies, and abstractions should not be added by habit. They should be introduced only when they remove meaningful complexity now.

Service-object or interactor-heavy architecture is not a default posture. If orchestration complexity is real and present, isolating it in small domain-named internals is appropriate, while keeping application-facing APIs clear and model-centered.

## Domain modeling
Domain language should be used aggressively in naming. Classes, methods, and modules should sound like the product domain rather than generic engineering templates.

Specific names are preferred over sterile abstractions. Complexity should be encapsulated behind intention-revealing APIs, and concerns should represent actual domain traits or roles rather than convenience buckets.

## Single responsibility at every level
Single responsibility applies recursively. Each class or module should own one clear concern, and each method should do one clear thing at one abstraction level.

Mixed-concern methods (for example, combining querying, policy, formatting, and delivery) should be split where change reasons diverge. Extraction should serve clarity and isolation, not aesthetics alone.

## Strong defaults from business logic
When behavior is a true business default, it should be encoded as a code default. Required behavior should not depend on caller discipline.

State and behavior should be coupled when that coupling protects correctness and prevents invalid outcomes. Edge cases should be explicit opt-outs, not implicit missing steps.

This includes lifecycle automation and derived behavior when those flows represent real domain events. Setting default values, enforcing transitions, and triggering follow-on work automatically are all good uses of the framework when they reduce the number of ways the system can drift away from intended business behavior.

## Invariants and enforcement
Important business invariants should be enforced at the most local level that can reliably protect them, and in more than one layer when the risk justifies it. Application code should express the rule clearly and provide good failure behavior, while database constraints or indexes should backstop the invariant when persistence-level correctness matters.

This is especially valuable for singleton rules, state transitions, uniqueness guarantees, and historical records that should not be reopened or silently rewritten. The goal is not duplication for its own sake, but confidence that important truths remain intact even if one path bypasses the usual application flow.

## Code quality bar
Readability and clarity take priority over cleverness. Small details matter: naming precision, local consistency, idiomatic usage, and simple, coherent flow.

Comments are treated as a code smell by default. The preferred path is to make intent legible through structure, naming, and decomposition. A comment is justified when relevant intent cannot be made obvious in code with reasonable refactoring.

Appropriate comment use includes non-obvious technical behavior, domain rules that cannot be expressed clearly enough through naming alone, rationale for intentionally overriding strong defaults, and concrete input/output examples that meaningfully reduce cognitive load.

A useful technical pattern is to isolate unavoidable low-level mechanics inside an intent-revealing method and place explanation only at the unavoidable line or block. A useful business pattern is to describe the rule in product terms and explain the risk it prevents.

Model composition has a comment rule of its own. When a model includes Concerns to assemble its behavior, the include list is the reader's first entry point into the model — it is how they learn what the model is made of without opening every file. A Concern's name can be sufficient on its own when it states its subject plainly: `include Emailing` — a Concern about everything having to do with sending emails — tells a reader what the module owns well enough that a comment would add nothing. Other names are less explicit. `include Lifecycle` does not say what specific behavior the module holds — the transition rules, the timestamp bookkeeping, the confirmation tokens — and leaves a reader no choice but to open the file and reconstruct its role by reading it. In cases like that, the include line can carry a short, domain-spoken summary of what the Concern actually does, keeping the reader's context at the call site instead of forcing the hunt. Naming alone is not always sufficient; the comment is the fallback — concise, product-termed, in the same register as the naming, and updated whenever the Concern's role changes so it stays part of the code contract.

Comment quality should be strict: short, specific, local, and materially useful. Comments that merely restate obvious code, narrate trivial control flow, or repeat method names without adding meaning are generally not useful.

Decorative separators and organizational banners may be used, but they usually indicate structural opportunities for refactoring. They should remain only when refactoring is explicitly not an immediate priority.

Comments are part of the code contract. If code changes make a comment imprecise, the comment should be updated or removed in the same change.

## Testing approach
Tests should optimize for confidence in real behavior. Over-mocking and excessive isolation should be avoided when they reduce signal.

Testing style should be pragmatic, with emphasis on feedback quality over ceremony.

## Use of “controversial” mechanisms
Mechanisms such as callbacks, globals/current context, and similar tools are valid when they simplify orthogonal concerns.

They should be used intentionally and sparingly. The goal is neither dogmatic avoidance nor dogmatic overuse, but clear core flows with contained auxiliary complexity.

## Frontend/CSS direction
Prefer backend-rendered Rails and Ruby solutions wherever they cleanly satisfy the requirement. Plain HTML and CSS are the default for UI work, because they usually produce the clearest, most durable implementation with the least moving parts.

When interactivity is needed, use Hotwire intentionally. Reach for Turbo Frames first when the interaction can be expressed as scoped page replacement. Use Turbo Streams when frames are not sufficient and the product genuinely benefits from server-driven updates across multiple parts of the page. Use Stimulus only when the interaction cannot be expressed cleanly with HTML, CSS, and Turbo.

This should be treated as a business decision, not just a technical one. More interactivity, animation, or frontend complexity is only worthwhile when it materially improves user outcomes. Before reaching for heavier tools, be clear about what real value is being added for the user and whether a simpler approach would accomplish the same goal more reliably. Prefer the simplest technical tool that delivers meaningful product value.

CSS custom properties should be used intentionally for shared values and variants. Magic numbers should be replaced with named values when possible. UI code should remain understandable and composable.

## Documentation
Documentation should explain the domain, the reason a rule exists, and the shape of the system in clear prose. The goal is not just to inventory implementation details, but to make the intended behavior legible so future changes can preserve it.

Bullets are useful for reference material, checklists, and compact examples, but core reasoning should usually be written as paragraphs. Prefer documentation that tells the reader why the code is shaped the way it is, what invariant or product rule it protects, and what would become incorrect if that rule were removed.

## Communication and collaboration
Progress should be communicated proactively through clear status, decision rationale, blockers, and tradeoffs.

Asynchronous, non-blocking collaboration is preferred. Decisions should remain explicit and revisable without losing momentum.

## Decision checklist
1. What is the smallest useful version that can ship now?
2. Can this be solved with existing framework defaults and current code?
3. Is this abstraction earning its keep today (not hypothetically)?
4. Does the language in code match product reality?
5. Was clarity and consistency improved, not just functionality?
6. Are tests focused on confidence, not ceremony?

## Assistant behavior contract
Implementation should start with the simplest plausible approach.

When proposing non-default architecture, tradeoffs should be explicit. Architectural ceremony should not be added without concrete benefit. Incremental, reversible change is preferred over sweeping rewrites. Communication should remain direct, explicit, and grounded in shipped outcomes.
