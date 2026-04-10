# AGENTS.md

Soapbox is a small, self-hosted blogging application for a single user. This scope should inform architectural decisions—simplicity and maintainability take priority over generality.

## Programming Philosophy
We want code to be beautiful in the practical sense: clear, well-shaped, and easy to trust. It should read as plainly as good English, so that the reader can follow the intent without constantly translating implementation details into meaning. It should also speak in the language of the business and the product, reflecting the domain it serves rather than hiding behind generic technical abstractions.

This leads to a bias toward strong defaults when those defaults come from real business logic. If the correct behavior is usually the same, it is often better to encode that behavior directly into the system than to rely on every caller to remember to do the right thing. Patterns like callbacks, implicit defaults, and tightly-coupled state and behavior are valid when they make the normal path safer, clearer, and more faithful to the domain.

For the full set of principles and implementation guidance, see [`MKG_PROGRAMMING_PRINCIPLES.md`](./MKG_PROGRAMMING_PRINCIPLES.md).

## Product Context
Soapbox is a small, self-hosted blogging application for a single user. This scope should inform architectural decisions. Simplicity, maintainability, and fidelity to the product matter more than preparing for hypothetical multi-tenant scale, generalized publishing workflows, or speculative future abstractions.

Prefer decisions that keep the application easy to understand and operate for its actual use case. Do not introduce complexity in order to make the system more generic unless the current product clearly requires it.

## Implementation Posture
Prefer working with existing Rails conventions and existing code paths before introducing new layers or abstractions. Extend the current domain model when that keeps the code clearer and more truthful to the product.

Favor domain-shaped names, APIs, and object boundaries over generic helpers, technical buckets, or reusable-looking abstractions that weaken the language of the application. Encode business defaults in the system itself rather than relying on caller discipline, and back important invariants with database constraints when appropriate.

## Frontend Posture
Prefer backend-rendered Rails and Ruby solutions wherever they cleanly satisfy the requirement. Plain HTML and CSS are the default for UI work.

When interactive behavior is needed, reach for Hotwire first. Prefer Turbo Frames when the interaction can be expressed as a scoped replacement. Use Turbo Streams when Frames are not sufficient and the product genuinely benefits from server-driven updates across multiple parts of the page. Use Stimulus only when the interaction cannot be expressed cleanly with HTML, CSS, and Turbo.

Treat frontend complexity as a product decision, not just a technical one. More interactivity or design complexity is only worthwhile when it materially improves the product for the user.

## Documentation Expectations
Documentation should explain domain rules, product intent, and why the code is shaped the way it is. Prefer clear prose over flattened bullet summaries when the goal is to explain reasoning.

When adding comments or documentation, explain intent, constraints, or business rules that are not obvious from the code itself. Do not add explanation that merely narrates what the code is doing line by line.

## Core rule
- At the start of every coding task, load and follow `MKG_PROGRAMMING_PRINCIPLES.md`.
- Treat that file as mandatory operating principles for implementation decisions, code structure, architectural suggestions, documentation, and review quality.
- If any instruction conflicts, follow direct user instructions first, then apply the principles file to all remaining decisions.
