# Rules: which one fires

The rule engine is core/rules/ (stages.wap, matcher.wap, patterns.wap). This note says how it picks one rule for a
phrase. notes/backbone.md "Stage languages" says when each stage runs.

## Stages
A rule's stage comes from its holes:
- a hole of a shape (`$x`, `$xs...`, `$k: Symbol`) is stage 1, the shape rules;
- a declaration hole (`$f: function`, `$p: predicate`, `$c: class`) is stage 2, run on declared code;
- a typed hole (`$x: int`, `$x: value`) is stage 3, run as typing writes each node.

## Written order
Within one head, rules are tried in written order, and each waits for the stage the earlier ones need. A catch-all
written after a class case runs with it in stage 2, so a class reaches its case and anything else the catch-all:

    rule c_type $type: class => c_record_name $type
    rule c_type $type => refuse "…"

Written order is load order:
1. the sugar rule files (wap/types/rules.wap names them);
2. the C rules (extensions/c/foreign.wap);
3. a program's own rules and those of the files it uses.

A rule that follows a later-stage rule of its head is raised to that stage (stages.wap rule_added). Within one stage,
the most specific rule wins (specificity).

A rule raised to stage 2 writes surface code. The shape rules then shape it, as they shaped the program. A group of
one phrase it rewrote is kept as stage 1 keeps it (group_kept), so `(c_type int)` becomes `int`.

Tests: test/test_rules.wap "a catch-all written after a class case …", test/wap/test_native.sh "a record crosses to C …".
