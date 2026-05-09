# Contributing to Horizon-Suite

Thank you for your interest in contributing to Horizon-Suite! This guide covers
how issues are classified, how to label them, and the branch naming conventions
we use for all work.

---

## Issue Types

When opening an issue, select the type that best describes your report:

| Type | Use for |
|---|---|
| **Bug** | Something isn't working correctly |
| **Feature** | New, big-ticket functionality you'd like to see |
| **Improvement** | Quality of life or betterment to existing functionality |
| **Refactor** | Code restructuring with no behaviour change |
| **Localisation** | Translations and locale additions or corrections |
| **Chore** | Maintenance, upkeep, tooling |
| **Docs** | Documentation additions or corrections |

---

## Labels

Apply labels to add detail beyond the issue type. You do not need a label that
duplicates the type — the type already captures that.

### Priority

| Label | Description |
|---|---|
| `[Priority] Critical` | Blocked from use — handle immediately |
| `[Priority] High` | Disruptive — handle at next earliest convenience |
| `[Priority] Medium` | Noticeable — handle when available |
| `[Priority] Low` | Present — handle if time permits |

### Module

Tag which part of the addon is affected:

| Label | Module |
|---|---|
| `[Module] Axis` | Core — dependencies and data |
| `[Module] Cache` | Loot Toasts and Bags |
| `[Module] Essence` | Character Sheet |
| `[Module] Flow` | Chat and Social |
| `[Module] Focus` | Objectives |
| `[Module] Insight` | Tooltips |
| `[Module] Meridian` | TBD |
| `[Module] Presence` | Toasts |
| `[Module] Vista` | Minimap |

### Upkeep (used with Chore type)

| Label | Description |
|---|---|
| `[Upkeep] Administration` | Repository tidiness and optimisation |
| `[Upkeep] Maintenance` | Data management and processing |

---

## Branch Naming

All branches must follow `<type>/<kebab-case-name>`:

| Prefix | Issue type | Example |
|---|---|---|
| `fix/` | Bug | `fix/focus-tracker-nil-error` |
| `feature/` | Feature | `feature/insight-spell-rank-display` |
| `improve/` | Improvement | `improve/presence-toast-animation` |
| `refactor/` | Refactor | `refactor/flow-chat-handler` |
| `locale/` | Localisation | `locale/deDE-focus-strings` |
| `chore/` | Chore | `chore/cleanup-stale-savedvariables` |
| `docs/` | Docs | `docs/vista-api-reference` |
| `hotfix/` | Critical Bug | `hotfix/axis-crash-on-login` |

Branch from `dev`. PRs target `dev`. `main` is production.

---

## Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): short description
```

Valid types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

The scope is optional but encouraged — use the module name in lowercase:
`feat(focus): add group objective tracking`

Notes for branch-name types that differ from commit types:
- `improve/` branches → use `feat:` or `refactor:` in commits
- `locale/` branches → use `feat:` in commits
- `hotfix/` branches → use `fix:` in commits

---

## Submitting a Pull Request

1. Branch from `dev`: `git switch dev && git pull --rebase origin dev && git switch -c fix/my-fix`
2. Keep commits small and focused
3. Open a PR targeting `dev`
4. Describe *why* the change is being made, not just what
5. Tag the relevant `[Module]` and `[Priority]` labels
6. A director will review and merge

For urgent production fixes, see the hotfix flow — branch from `main` and target `main` directly.
