# Rules: which one fires

The rule engine is core/rules/ (stages.wap, matcher.wap, patterns.wap). This note says how it picks one rule for a
phrase. notes/backbone.md "Stage languages" says when each stage runs.

## Stages
A rule's stage comes from its holes:
- a hole of a shape (`$x`, `$xs...`, `$k: Symbol`) is stage 1, the shape rules;
- a declaration hole (`$f: function`, `$p: predicate`, `$c: class`) is stage 2, run on declared code;
- a typed hole (`$x: int`, `$x: value`) is stage 3, run as typing writes each node.

## The most specific rule wins
A rule waits for the stages of the more specific rules of its head, so the most specific rule wins across stages;
written order plays no part. A rule is more specific than another when it weighs more (specificity, plus a `where`
fact) and the other's pattern fits its pattern. A catch-all beside a class case therefore runs with it in stage 2, so
a class reaches its case and anything else the catch-all:

    rule c_type $type: class => c_record_name $type
    rule c_type $type => refuse "…"

stages.wap rule_added raises a new rule to the latest stage holding a more specific rule of its head, and moves the
less specific rules of earlier stages up to its own stage. Within one stage, the most specific rule wins.

A rule raised to stage 2 writes surface code. The shape rules then shape it, as they shaped the program. A group of
one phrase it rewrote is kept as stage 1 keeps it (group_kept), so `(c_type int)` becomes `int`.

Specification: wiki/rule.md "Which rule applies". Tests: test/test_rules.wap "a catch-all written after a class case …" and "a catch-all written before a class case …", test/wap/test_native.sh "a record crosses to C …".
