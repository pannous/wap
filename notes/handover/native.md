wap-native retired 2026-11-23, no card, nothing open: native-store-freed landed (module_ran frees its store); warp's copying heap now grows at 1/3 (warp 3a069b5b52), compiler.wap peak 2064 → 1041 MB.
Measured, not worth redoing: a bigger initial GC heap leaves the peak unchanged (+47 MB for hello); the null collector traps near 4 GB on compiler.wap and makes small programs slower.
