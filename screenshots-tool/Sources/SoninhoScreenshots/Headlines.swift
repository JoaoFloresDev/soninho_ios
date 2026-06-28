import Foundation

// MARK: - Headline Copy
//
// 3 treatments × 5 slots × 3 locales = 45 headlines.
// Each headline anchors to keywords already in the app's ASO metadata so
// the test learns which *expression* of an indexed keyword converts best.
//
//   en-US keywords: sleep, insomnia, wake tired, bedtime, REM, deep, diary, hygiene
//   pt-BR keywords: insônia, acordar cansado, dormir rápido, rotina noturna, REM, fases, profundo, descanso, leve
//   es-ES keywords: insomnio, despertar cansado, dormir, siesta, rutina nocturna, REM, fases, profundo, descanso
//
// Slots:
//   1. Home — weekly overview + streak
//   2. Sleep Detail — sleep score + REM/deep phase breakdown
//   3. Smart Alarm — wake during light phase window
//   4. Statistics — long-term trends + goal
//   5. Sleep Tips — daily tip + categories

struct Headline {
    let text: String
    let highlight: String?
}

typealias LocalizedHeadlines = [String: Headline]

struct TreatmentCopy {
    let id: String
    let label: String
    let home: LocalizedHeadlines
    let feature1: LocalizedHeadlines
    let feature2: LocalizedHeadlines
    let settings: LocalizedHeadlines
    let onboarding: LocalizedHeadlines
}

enum Headlines {

    // MARK: - Treatment A — Direct / Action (verb + ASO keyword)

    static let treatmentA = TreatmentCopy(
        id: "A",
        label: "Direct / Action",
        home: [
            "en-US": Headline(text: "Wake to a sunrise",       highlight: "sunrise"),
            "pt-BR": Headline(text: "Acorde com o sol",        highlight: "sol"),
            "es-ES": Headline(text: "Despierta con el amanecer", highlight: "amanecer")
        ],
        feature1: [
            "en-US": Headline(text: "Solve math to wake",      highlight: "math"),
            "pt-BR": Headline(text: "Resolva contas pra acordar", highlight: "contas"),
            "es-ES": Headline(text: "Resuelve mates para apagar", highlight: "mates")
        ],
        feature2: [
            "en-US": Headline(text: "Get out of bed",          highlight: "bed"),
            "pt-BR": Headline(text: "Saia logo da cama",       highlight: "cama"),
            "es-ES": Headline(text: "Levántate de la cama",    highlight: "cama")
        ],
        settings: [
            "en-US": Headline(text: "Loud gentle sounds",      highlight: "sounds"),
            "pt-BR": Headline(text: "Sons altos e suaves",     highlight: "Sons"),
            "es-ES": Headline(text: "Sonidos altos y suaves",  highlight: "Sonidos")
        ],
        onboarding: [
            "en-US": Headline(text: "Track your sleep cycle",  highlight: "cycle"),
            "pt-BR": Headline(text: "Veja seu ciclo",          highlight: "ciclo"),
            "es-ES": Headline(text: "Sigue tu ciclo",          highlight: "ciclo")
        ]
    )

    // MARK: - Treatment B — Emotional / Aspirational

    static let treatmentB = TreatmentCopy(
        id: "B",
        label: "Emotional / Aspirational",
        home: [
            "en-US": Headline(text: "Sleep is your superpower",             highlight: "superpower"),
            "pt-BR": Headline(text: "Dormir é seu superpoder",              highlight: "superpoder"),
            "es-ES": Headline(text: "Dormir es tu superpoder",              highlight: "superpoder")
        ],
        feature1: [
            "en-US": Headline(text: "Finally understand your deep sleep",   highlight: "deep"),
            "pt-BR": Headline(text: "Entenda enfim seu sono profundo",      highlight: "profundo"),
            "es-ES": Headline(text: "Comprende por fin tu sueño profundo",  highlight: "profundo")
        ],
        feature2: [
            "en-US": Headline(text: "Gentle mornings start here",           highlight: "Gentle"),
            "pt-BR": Headline(text: "Manhãs mais leves começam aqui",       highlight: "leves")
            ,
            "es-ES": Headline(text: "Mañanas suaves empiezan aquí",         highlight: "suaves")
        ],
        settings: [
            "en-US": Headline(text: "Your sleep, finally understood",       highlight: "understood"),
            "pt-BR": Headline(text: "Seu sono, enfim compreendido",         highlight: "compreendido"),
            "es-ES": Headline(text: "Tu descanso, por fin comprendido",     highlight: "comprendido")
        ],
        onboarding: [
            "en-US": Headline(text: "Tonight, sleep a little better",       highlight: "better"),
            "pt-BR": Headline(text: "Hoje, durma um pouco melhor",          highlight: "melhor"),
            "es-ES": Headline(text: "Esta noche, duerme un poco mejor",     highlight: "mejor")
        ]
    )

    // MARK: - Treatment C — Feature / Technical (differentiator-led)

    static let treatmentC = TreatmentCopy(
        id: "C",
        label: "Feature / Technical",
        home: [
            "en-US": Headline(text: "Apple Health sleep analytics",         highlight: "analytics"),
            "pt-BR": Headline(text: "Análise de sono via Apple Saúde",      highlight: "Análise"),
            "es-ES": Headline(text: "Análisis de sueño con Apple Salud",    highlight: "Análisis")
        ],
        feature1: [
            "en-US": Headline(text: "4 sleep phases scored every night",    highlight: "4"),
            "pt-BR": Headline(text: "4 fases de sono, nota diária",         highlight: "4"),
            "es-ES": Headline(text: "4 fases de sueño con puntuación",      highlight: "4")
        ],
        feature2: [
            "en-US": Headline(text: "Smart alarm in your light phase",      highlight: "Smart"),
            "pt-BR": Headline(text: "Alarme inteligente na fase leve",      highlight: "inteligente"),
            "es-ES": Headline(text: "Alarma inteligente en fase ligera",    highlight: "inteligente")
        ],
        settings: [
            "en-US": Headline(text: "30 days of sleep trends",              highlight: "30"),
            "pt-BR": Headline(text: "30 dias de tendências de sono",        highlight: "30"),
            "es-ES": Headline(text: "30 días de tendencias de sueño",       highlight: "30")
        ],
        onboarding: [
            "en-US": Headline(text: "15 expert sleep tips inside",          highlight: "15"),
            "pt-BR": Headline(text: "15 dicas para o sono profundo",        highlight: "15"),
            "es-ES": Headline(text: "15 consejos para el sueño profundo",   highlight: "15")
        ]
    )

    static let all: [TreatmentCopy] = [treatmentA, treatmentB, treatmentC]
}

// MARK: - Localized App Listing Strings (used by App Store mockup)

enum LocalizedListing {
    static let appName: [String: String] = [
        "en-US": "Slumber: Sleep Cycle Tracker",
        "pt-BR": "Soninho: Monitor de Sono",
        "es-ES": "Sueñito: Monitor de Sueño"
    ]
    static let subtitle: [String: String] = [
        "en-US": "Smart Alarm & Sleep Analysis",
        "pt-BR": "Alarme Inteligente & Análise",
        "es-ES": "Alarma Inteligente y Análisis"
    ]
}
