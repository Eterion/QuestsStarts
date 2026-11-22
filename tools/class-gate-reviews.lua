-- Reviewed on 2026-11-20. These apply to Forever, not the original SoD quests.
-- Evidence, confidence and unresolved server facts: docs/class-gate-decisions.md.
return {
    library={
        label='Shared library access',originalMask=128,
        disposition='Keep all-class access',fields={requiredClasses=0},
        ids={78124,78127,78142,78143,78145,78146,78147,78148,78149,78150,
            79091,79093,79094,79095,79096,79097,79535,79536,79947,79948,
            79949,79950,79951,79952,79953,81947,81949,81951,81952,81953,
            81954,81955,81956,82208,84395,84396,84397,84398,84399,84400,
            84401,84402},
    },
    earthmother={
        label='Stalk With The Earthmother',originalMask=64,
        disposition='Correct to Tauren-only; no class mask',
        -- QuestieDB fix 26050f4cc1153961646ac00995362991826a91f2.
        fields={requiredClasses=0,requiredRaces=32},ids={76156,76160,76240},
    },
    cooking={
        label='Anyone Can Cook',originalMask=1,
        disposition='Keep all-class access',fields={requiredClasses=0},ids={79624},
    },
    dragonslayer={
        label='Dragonslayer collection',originalMask=1,
        disposition='Quarantine: Forever giver/access unverified',
        -- Questie/Questie#8264 reports an absent giver, not proof of a class mask.
        fields={requiredClasses=0,sourceUnverified=true},ids={78132,78133,78134},
    },
}
