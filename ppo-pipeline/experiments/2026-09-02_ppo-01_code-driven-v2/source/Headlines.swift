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
            "en-US": Headline(text: "Wake to a sunrise",            highlight: nil),
            "pt-BR": Headline(text: "Acorde com o sol",             highlight: nil),
            "es-ES": Headline(text: "Despierta con el amanecer",    highlight: nil)
        ],
        feature1: [
            "en-US": Headline(text: "Rise in light sleep",          highlight: nil),
            "pt-BR": Headline(text: "Desperte no sono leve",        highlight: nil),
            "es-ES": Headline(text: "Despertar en sueño ligero",    highlight: nil)
        ],
        feature2: [
            "en-US": Headline(text: "Solve math to wake",           highlight: nil),
            "pt-BR": Headline(text: "Resolva contas pra acordar",   highlight: nil),
            "es-ES": Headline(text: "Resuelve mates para apagar",   highlight: nil)
        ],
        settings: [
            "en-US": Headline(text: "Gentle rising volume",         highlight: nil),
            "pt-BR": Headline(text: "Volume que sobe suave",        highlight: nil),
            "es-ES": Headline(text: "Volumen que sube suave",       highlight: nil)
        ],
        onboarding: [
            "en-US": Headline(text: "See your whole night",         highlight: nil),
            "pt-BR": Headline(text: "Veja sua noite inteira",       highlight: nil),
            "es-ES": Headline(text: "Mira toda tu noche",           highlight: nil)
        ]
    )

    // MARK: - Treatment B — Benefit / Outcome

    static let treatmentB = TreatmentCopy(
        id: "B",
        label: "Benefit / Outcome",
        home: [
            "en-US": Headline(text: "Mornings feel easy",          highlight: nil),
            "pt-BR": Headline(text: "Manhãs sem sofrimento",       highlight: nil),
            "es-ES": Headline(text: "Mañanas sin sufrir",          highlight: nil)
        ],
        feature1: [
            "en-US": Headline(text: "Wake at the right moment",    highlight: nil),
            "pt-BR": Headline(text: "Acorde na hora certa",        highlight: nil),
            "es-ES": Headline(text: "Despierta en el momento justo", highlight: nil)
        ],
        feature2: [
            "en-US": Headline(text: "Never oversleep again",       highlight: nil),
            "pt-BR": Headline(text: "Chega de perder a hora",      highlight: nil),
            "es-ES": Headline(text: "Adiós a quedarse dormido",    highlight: nil)
        ],
        settings: [
            "en-US": Headline(text: "Start calm every day",        highlight: nil),
            "pt-BR": Headline(text: "Comece o dia sem susto",      highlight: nil),
            "es-ES": Headline(text: "Empieza el día sin sustos",   highlight: nil)
        ],
        onboarding: [
            "en-US": Headline(text: "Know your sleep at last",     highlight: nil),
            "pt-BR": Headline(text: "Entenda seu sono enfim",      highlight: nil),
            "es-ES": Headline(text: "Entiende tu sueño al fin",    highlight: nil)
        ]
    )

    // MARK: - Treatment C — Specific / Charisma

    static let treatmentC = TreatmentCopy(
        id: "C",
        label: "Specific / Charisma",
        home: [
            "en-US": Headline(text: "Say hi to your alarm",        highlight: nil),
            "pt-BR": Headline(text: "Conheça seu despertador",     highlight: nil),
            "es-ES": Headline(text: "Conoce tu despertador",       highlight: nil)
        ],
        feature1: [
            "en-US": Headline(text: "Smart window, light wake",    highlight: nil),
            "pt-BR": Headline(text: "Janela smart, acordar leve",  highlight: nil),
            "es-ES": Headline(text: "Ventana smart, despertar suave", highlight: nil)
        ],
        feature2: [
            "en-US": Headline(text: "Snooze has no chance",        highlight: nil),
            "pt-BR": Headline(text: "Soneca não tem vez",          highlight: nil),
            "es-ES": Headline(text: "Cero snooze, cero atraso",    highlight: nil)
        ],
        settings: [
            "en-US": Headline(text: "Ten sounds, one sunrise",     highlight: nil),
            "pt-BR": Headline(text: "Dez sons pra acordar",        highlight: nil),
            "es-ES": Headline(text: "Diez sonidos suaves",         highlight: nil)
        ],
        onboarding: [
            "en-US": Headline(text: "Every phase, every night",    highlight: nil),
            "pt-BR": Headline(text: "Toda fase, toda noite",       highlight: nil),
            "es-ES": Headline(text: "Cada fase, cada noche",       highlight: nil)
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
