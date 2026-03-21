# CLAUDE.md

## What this vault is

This is a **personal Foam Markdown vault** — a personal knowledge base where the user logs facts about themselves, things they've read, metrics they track, and ideas they want to remember.

This is NOT a software project. Do not treat it as one.

---

## Default behavior

When the user says something about themselves or their life, **just log it**. Do not ask what they want you to do with it. Do not ask for clarification unless the meaning is genuinely ambiguous. Act like a quiet, reliable note-taker.

Examples of what to do:

| User says | You do |
| --- | --- |
| "my IQ is 100" | Create or update `facts/iq.md` with the value |
| "I have brown eyes" | Create or update `facts/eye-color.md` |
| "I read Atomic Habits" | Create or update `sources/atomic-habits.md` |
| "I weigh 82kg" | Create or update `metrics/weight.md` |
| "I have ADHD" | Create or update `facts/adhd.md` |

When in doubt: **create a note, confirm what you created, move on.**

---

## Note structure rules

**Every note must be atomic.** One note = one idea, one fact, one metric, one source, one person.

If a note contains multiple claims or topics, split it.

### File locations

| Type | Folder | Template |
| --- | --- | --- |
| Personal facts | `facts/` | `templates/fact.md` |
| Tracked metrics | `metrics/` | `templates/metric.md` |
| Sources / books / articles | `sources/` | `templates/source.md` |
| People / entities | `people/` | `templates/person.md` |
| Concept clusters | `clusters/` | `templates/cluster.md` |
| Daily / session notes | `journal/` | `templates/journal.md` |
| Unprocessed input | `inbox/` | — |

### File naming

Lowercase, hyphen-separated slugs. Examples:

- `facts/eye-color.md`
- `metrics/weight.md`
- `sources/atomic-habits.md`
- `people/andrew-huberman.md`

---

## When the user gives you raw text or a dump

Use `prompts/extract-atomic-notes.md` to split it into atomic notes across the right folders.

---

## What NOT to do

- Do not ask "what would you like me to do with this?"
- Do not summarize what you just did at length
- Do not add sections, analysis, or follow-up questions unless asked
- Do not create files outside the folder structure above
