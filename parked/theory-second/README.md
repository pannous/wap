The second checker: it reads the JSON lines `export.wap` writes of what the kernel accepted (lean4export's shape)
and checks every statement again by its own rules, with nothing of the kernel (notes/theory.md "A second opinion").
Parked, not built: its `use` paths point at wap/kernel from wap/extensions/theory/, and the kernel no longer keeps
the log of accepted statements export.wap reads (Environment.accepted). Wiring it again means moving it back and
bringing that log back.
