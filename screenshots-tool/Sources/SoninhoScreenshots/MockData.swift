import SwiftUI

// MARK: - Sleep Record Mock
//
// Beautiful curated sleep data used across the 5 marketing screens. Tuned
// for visual variety while staying realistic (no 12-hour sleep, no 87%
// REM percentages, etc.).

struct MockSleepRecord: Identifiable, Hashable {
    let id = UUID()
    let dayLabel: String         // "Mon", "Seg", "Lun"
    let durationHours: Double    // e.g. 7.4
    let qualityScore: Int        // 0-100
    let bedtime: String          // "10:45 PM" / "22:45"
    let wake: String             // "6:30 AM" / "06:30"
    let deepMinutes: Int
    let lightMinutes: Int
    let remMinutes: Int
    let awakeMinutes: Int
}

// MARK: - Week Data (Slot 1 — Home weekly chart)

enum MockSleepData {
    static let weekDurations: [Double] = [7.2, 6.8, 7.9, 8.1, 7.3, 8.4, 7.6]

    static func weekLabels(locale: String) -> [String] {
        switch locale {
        case "pt-BR":           return ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]
        case "es-ES", "es-MX":  return ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]
        default:                return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        }
    }

    // 30 days of duration data for the Statistics trend chart
    static let monthDurations: [Double] = [
        6.8, 7.1, 7.5, 6.9, 7.3, 8.0, 7.8,
        7.4, 7.9, 8.2, 7.6, 7.1, 8.0, 7.5,
        7.8, 8.1, 7.4, 7.9, 8.3, 8.0, 7.6,
        7.2, 7.9, 8.2, 8.0, 7.5, 7.8, 8.4,
        7.9, 8.1
    ]

    // Last night detail (Slot 2)
    // 7h36m total — 92 min deep, 218 min light, 116 min REM, 30 min awake
    static let lastNight = MockSleepRecord(
        dayLabel: "",
        durationHours: 7.6,
        qualityScore: 87,
        bedtime: "10:48",
        wake: "06:24",
        deepMinutes: 92,
        lightMinutes: 218,
        remMinutes: 116,
        awakeMinutes: 30
    )
}

// MARK: - Smart Alarm Mock (Slot 3)

struct MockAlarmConfig {
    let scheduledTime: String   // "06:30"
    let scheduledTimeLabel: String  // "AM" or empty for 24h
    let windowMinutes: Int      // 30
    let enabled: Bool
    let weekdaysSelected: [Int] // 1=Mon..7=Sun
}

enum MockAlarm {
    static let demo = MockAlarmConfig(
        scheduledTime: "06:30",
        scheduledTimeLabel: "AM",
        windowMinutes: 30,
        enabled: true,
        weekdaysSelected: [1, 2, 3, 4, 5]
    )
}

// MARK: - Sleep Tip Categories (Slot 5)

struct MockTipCategory: Identifiable, Hashable {
    let id = UUID()
    let nameKey: String
    let icon: String
    let tint: Color
    let count: Int
}

enum MockTipCategories {
    static let all: [MockTipCategory] = [
        MockTipCategory(nameKey: "routine",    icon: "moon.stars.fill",   tint: Color(red: 0.55, green: 0.42, blue: 1.00), count: 4),
        MockTipCategory(nameKey: "environment", icon: "bed.double.fill",  tint: Color(red: 0.38, green: 0.65, blue: 0.98), count: 3),
        MockTipCategory(nameKey: "lifestyle",   icon: "figure.walk",      tint: Color(red: 0.13, green: 0.77, blue: 0.37), count: 3),
        MockTipCategory(nameKey: "nutrition",   icon: "leaf.fill",        tint: Color(red: 0.96, green: 0.62, blue: 0.04), count: 3),
        MockTipCategory(nameKey: "relaxation",  icon: "wind",             tint: Color(red: 0.66, green: 0.33, blue: 0.97), count: 2)
    ]
}

// MARK: - Localized Strings

enum LocalizedLabels {
    static let homeGreeting: [String: String] = [
        "en-US": "Good morning, João",
        "pt-BR": "Bom dia, João",
        "es-ES": "Buenos días, João",
        "es-MX": "Buenos días, João"
    ]
    static let homeWeeklyAvg: [String: String] = [
        "en-US": "Weekly average",
        "pt-BR": "Média da semana",
        "es-ES": "Promedio semanal",
        "es-MX": "Promedio semanal"
    ]
    static let homeStreakCurrent: [String: String] = [
        "en-US": "Current streak",
        "pt-BR": "Sequência atual",
        "es-ES": "Racha actual",
        "es-MX": "Racha actual"
    ]
    static let homeStreakLongest: [String: String] = [
        "en-US": "Best",
        "pt-BR": "Recorde",
        "es-ES": "Mejor",
        "es-MX": "Mejor"
    ]
    static let homeThisWeek: [String: String] = [
        "en-US": "This week",
        "pt-BR": "Esta semana",
        "es-ES": "Esta semana",
        "es-MX": "Esta semana"
    ]
    static let homeAvgBedtime: [String: String] = [
        "en-US": "Avg bedtime",
        "pt-BR": "Hora média",
        "es-ES": "Hora media",
        "es-MX": "Hora media"
    ]
    static let homeAvgSleep: [String: String] = [
        "en-US": "Avg sleep",
        "pt-BR": "Sono médio",
        "es-ES": "Sueño medio",
        "es-MX": "Sueño medio"
    ]
    static let days: [String: String] = [
        "en-US": "days",
        "pt-BR": "dias",
        "es-ES": "días",
        "es-MX": "días"
    ]
    static let hoursShort: [String: String] = [
        "en-US": "h",
        "pt-BR": "h",
        "es-ES": "h",
        "es-MX": "h"
    ]

    // Sleep detail
    static let sleepDetailTitle: [String: String] = [
        "en-US": "Last night",
        "pt-BR": "Última noite",
        "es-ES": "Última noche",
        "es-MX": "Anoche"
    ]
    static let sleepScore: [String: String] = [
        "en-US": "Sleep score",
        "pt-BR": "Pontuação",
        "es-ES": "Puntuación",
        "es-MX": "Puntuación"
    ]
    static let phaseDeep: [String: String] = [
        "en-US": "Deep",
        "pt-BR": "Profundo",
        "es-ES": "Profundo",
        "es-MX": "Profundo"
    ]
    static let phaseLight: [String: String] = [
        "en-US": "Light",
        "pt-BR": "Leve",
        "es-ES": "Ligero",
        "es-MX": "Ligero"
    ]
    static let phaseREM: [String: String] = [
        "en-US": "REM",
        "pt-BR": "REM",
        "es-ES": "REM",
        "es-MX": "REM"
    ]
    static let phaseAwake: [String: String] = [
        "en-US": "Awake",
        "pt-BR": "Acordado",
        "es-ES": "Despierto",
        "es-MX": "Despierto"
    ]
    static let bedtimeShort: [String: String] = [
        "en-US": "Bedtime",
        "pt-BR": "Dormiu",
        "es-ES": "Se acostó",
        "es-MX": "Se acostó"
    ]
    static let wakeShort: [String: String] = [
        "en-US": "Wake",
        "pt-BR": "Acordou",
        "es-ES": "Despertó",
        "es-MX": "Despertó"
    ]

    // Smart alarm
    static let smartAlarmTitle: [String: String] = [
        "en-US": "Smart Alarm",
        "pt-BR": "Alarme Inteligente",
        "es-ES": "Alarma Inteligente",
        "es-MX": "Alarma Inteligente"
    ]
    static let smartAlarmSubtitle: [String: String] = [
        "en-US": "Wakes you during light sleep",
        "pt-BR": "Acorda na fase leve do sono",
        "es-ES": "Te despierta en sueño ligero",
        "es-MX": "Te despierta en sueño ligero"
    ]
    static let smartAlarmWindow: [String: String] = [
        "en-US": "Wake-up window",
        "pt-BR": "Janela de despertar",
        "es-ES": "Ventana de despertar",
        "es-MX": "Ventana de despertar"
    ]
    static let smartAlarmRepeat: [String: String] = [
        "en-US": "Repeat",
        "pt-BR": "Repetir",
        "es-ES": "Repetir",
        "es-MX": "Repetir"
    ]
    static let smartAlarmEnabled: [String: String] = [
        "en-US": "Enabled",
        "pt-BR": "Ativo",
        "es-ES": "Activo",
        "es-MX": "Activo"
    ]
    static let smartAlarmMinutes: [String: String] = [
        "en-US": "min",
        "pt-BR": "min",
        "es-ES": "min",
        "es-MX": "min"
    ]
    static let smartAlarmWeekdaysShort: [String: [String]] = [
        "en-US": ["M", "T", "W", "T", "F", "S", "S"],
        "pt-BR": ["S", "T", "Q", "Q", "S", "S", "D"],
        "es-ES": ["L", "M", "X", "J", "V", "S", "D"],
        "es-MX": ["L", "M", "X", "J", "V", "S", "D"]
    ]
    static let smartAlarmNext: [String: String] = [
        "en-US": "NEXT ALARM",
        "pt-BR": "PRÓXIMO ALARME",
        "es-ES": "PRÓXIMA ALARMA",
        "es-MX": "PRÓXIMA ALARMA"
    ]
    static let smartAlarmInHours: [String: String] = [
        "en-US": "in 7h 42m",
        "pt-BR": "em 7h 42min",
        "es-ES": "en 7 h 42 min",
        "es-MX": "en 7 h 42 min"
    ]
    static let smartAlarmWeekdays: [String: String] = [
        "en-US": "Weekdays",
        "pt-BR": "Dias úteis",
        "es-ES": "Días laborables",
        "es-MX": "Días laborables"
    ]
    static let smartAlarmWeekends: [String: String] = [
        "en-US": "Weekends",
        "pt-BR": "Fim de semana",
        "es-ES": "Fines de semana",
        "es-MX": "Fines de semana"
    ]
    static let smartAlarmLabelWork: [String: String] = [
        "en-US": "Workdays",
        "pt-BR": "Trabalho",
        "es-ES": "Trabajo",
        "es-MX": "Trabajo"
    ]
    static let smartAlarmLabelGym: [String: String] = [
        "en-US": "Morning run",
        "pt-BR": "Corrida matinal",
        "es-ES": "Carrera matutina",
        "es-MX": "Carrera matutina"
    ]
    static let smartAlarmYourAlarms: [String: String] = [
        "en-US": "Your alarms",
        "pt-BR": "Seus alarmes",
        "es-ES": "Tus alarmas",
        "es-MX": "Tus alarmas"
    ]
    static let smartAlarmWakeBetween: [String: String] = [
        "en-US": "Wakes between",
        "pt-BR": "Acorda entre",
        "es-ES": "Te despierta entre",
        "es-MX": "Te despierta entre"
    ]
    static let smartAlarmLightestMoment: [String: String] = [
        "en-US": "at your lightest moment",
        "pt-BR": "no seu sono mais leve",
        "es-ES": "en tu sueño más ligero",
        "es-MX": "en tu sueño más ligero"
    ]

    // Statistics
    static let statsTitle: [String: String] = [
        "en-US": "Statistics",
        "pt-BR": "Estatísticas",
        "es-ES": "Estadísticas",
        "es-MX": "Estadísticas"
    ]
    static let statsMonth: [String: String] = [
        "en-US": "Last 30 days",
        "pt-BR": "Últimos 30 dias",
        "es-ES": "Últimos 30 días",
        "es-MX": "Últimos 30 días"
    ]
    static let statsGoal: [String: String] = [
        "en-US": "Sleep goal",
        "pt-BR": "Meta de sono",
        "es-ES": "Meta de sueño",
        "es-MX": "Meta de sueño"
    ]
    static let statsAvgVsGoal: [String: String] = [
        "en-US": "vs 8h goal",
        "pt-BR": "vs meta 8h",
        "es-ES": "vs meta 8h",
        "es-MX": "vs meta 8h"
    ]
    static let statsConsistency: [String: String] = [
        "en-US": "Consistency",
        "pt-BR": "Consistência",
        "es-ES": "Consistencia",
        "es-MX": "Consistencia"
    ]
    static let statsBestNight: [String: String] = [
        "en-US": "Best night",
        "pt-BR": "Melhor noite",
        "es-ES": "Mejor noche",
        "es-MX": "Mejor noche"
    ]
    static let statsAverageQuality: [String: String] = [
        "en-US": "Average quality",
        "pt-BR": "Qualidade média",
        "es-ES": "Calidad media",
        "es-MX": "Calidad media"
    ]
    static let statsAvgDuration: [String: String] = [
        "en-US": "Avg duration",
        "pt-BR": "Duração média",
        "es-ES": "Duración media",
        "es-MX": "Duración media"
    ]
    static let statsTrendImproving: [String: String] = [
        "en-US": "Improving",
        "pt-BR": "Melhorando",
        "es-ES": "Mejorando",
        "es-MX": "Mejorando"
    ]
    static let statsDuration: [String: String] = [
        "en-US": "Sleep duration",
        "pt-BR": "Duração do sono",
        "es-ES": "Duración del sueño",
        "es-MX": "Duración del sueño"
    ]
    static let statsPhases: [String: String] = [
        "en-US": "Sleep phases",
        "pt-BR": "Fases do sono",
        "es-ES": "Fases del sueño",
        "es-MX": "Fases del sueño"
    ]
    static let statsSchedule: [String: String] = [
        "en-US": "Schedule",
        "pt-BR": "Horário",
        "es-ES": "Horario",
        "es-MX": "Horario"
    ]
    static let statsAvgBedtime: [String: String] = [
        "en-US": "Avg bedtime",
        "pt-BR": "Hora de dormir",
        "es-ES": "Hora de dormir",
        "es-MX": "Hora de dormir"
    ]
    static let statsAvgWake: [String: String] = [
        "en-US": "Avg wake",
        "pt-BR": "Despertar",
        "es-ES": "Despertar",
        "es-MX": "Despertar"
    ]
    static let statsDaysMet: [String: String] = [
        "en-US": "26 of 30 days",
        "pt-BR": "26 de 30 dias",
        "es-ES": "26 de 30 días",
        "es-MX": "26 de 30 días"
    ]
    static let statsPeriodWeek: [String: String] = [
        "en-US": "Week",
        "pt-BR": "Semana",
        "es-ES": "Semana",
        "es-MX": "Semana"
    ]
    static let statsPeriodMonth: [String: String] = [
        "en-US": "Month",
        "pt-BR": "Mês",
        "es-ES": "Mes",
        "es-MX": "Mes"
    ]
    static let statsPeriodYear: [String: String] = [
        "en-US": "Year",
        "pt-BR": "Ano",
        "es-ES": "Año",
        "es-MX": "Año"
    ]
    static let statsDeepDescription: [String: String] = [
        "en-US": "Restorative",
        "pt-BR": "Restaurador",
        "es-ES": "Reparador",
        "es-MX": "Reparador"
    ]
    static let statsLightDescription: [String: String] = [
        "en-US": "Most of the night",
        "pt-BR": "Maior parte da noite",
        "es-ES": "Mayor parte de la noche",
        "es-MX": "Mayor parte de la noche"
    ]
    static let statsRemDescription: [String: String] = [
        "en-US": "Dreams & memory",
        "pt-BR": "Sonhos e memória",
        "es-ES": "Sueños y memoria",
        "es-MX": "Sueños y memoria"
    ]

    // Tips
    static let tipsTitle: [String: String] = [
        "en-US": "Sleep Tips",
        "pt-BR": "Dicas de Sono",
        "es-ES": "Consejos de Sueño",
        "es-MX": "Consejos de Sueño"
    ]
    static let tipsDailyLabel: [String: String] = [
        "en-US": "Tip of the day",
        "pt-BR": "Dica do dia",
        "es-ES": "Consejo del día",
        "es-MX": "Consejo del día"
    ]
    static let tipsDailyTitle: [String: String] = [
        "en-US": "Same bedtime, every night",
        "pt-BR": "Mesmo horário toda noite",
        "es-ES": "La misma hora cada noche",
        "es-MX": "La misma hora cada noche"
    ]
    static let tipsDailyBody: [String: String] = [
        "en-US": "Going to bed at the same hour helps your circadian rhythm settle into a healthy pattern.",
        "pt-BR": "Dormir no mesmo horário ajuda seu ritmo circadiano a se firmar num padrão saudável.",
        "es-ES": "Acostarte a la misma hora ayuda a tu ritmo circadiano a establecer un patrón sano.",
        "es-MX": "Acostarte a la misma hora ayuda a tu ritmo circadiano a establecer un patrón sano."
    ]
    static let tipsCategories: [String: String] = [
        "en-US": "Categories",
        "pt-BR": "Categorias",
        "es-ES": "Categorías",
        "es-MX": "Categorías"
    ]
    static let tipsCategoryNames: [String: [String: String]] = [
        "routine": [
            "en-US": "Routine",
            "pt-BR": "Rotina",
            "es-ES": "Rutina",
            "es-MX": "Rutina"
        ],
        "environment": [
            "en-US": "Environment",
            "pt-BR": "Ambiente",
            "es-ES": "Ambiente",
            "es-MX": "Ambiente"
        ],
        "lifestyle": [
            "en-US": "Lifestyle",
            "pt-BR": "Estilo de Vida",
            "es-ES": "Estilo de Vida",
            "es-MX": "Estilo de Vida"
        ],
        "nutrition": [
            "en-US": "Nutrition",
            "pt-BR": "Nutrição",
            "es-ES": "Nutrición",
            "es-MX": "Nutrición"
        ],
        "relaxation": [
            "en-US": "Relaxation",
            "pt-BR": "Relaxamento",
            "es-ES": "Relajación",
            "es-MX": "Relajación"
        ]
    ]
    static let tipsCountSuffix: [String: String] = [
        "en-US": "tips",
        "pt-BR": "dicas",
        "es-ES": "consejos",
        "es-MX": "consejos"
    ]
    static let tipsAll: [String: String] = [
        "en-US": "All",
        "pt-BR": "Todas",
        "es-ES": "Todos",
        "es-MX": "Todos"
    ]

    // Tip titles for the list (slot 5)
    static let tipMorningLightTitle: [String: String] = [
        "en-US": "Get morning sunlight",
        "pt-BR": "Tome sol pela manhã",
        "es-ES": "Toma sol por la mañana",
        "es-MX": "Toma sol por la mañana"
    ]
    static let tipCoolRoomTitle: [String: String] = [
        "en-US": "Keep the room cool",
        "pt-BR": "Mantenha o quarto fresco",
        "es-ES": "Mantén la habitación fresca",
        "es-MX": "Mantén la habitación fresca"
    ]
    static let tipScreenTimeTitle: [String: String] = [
        "en-US": "No screens 1h before bed",
        "pt-BR": "Sem telas 1h antes de dormir",
        "es-ES": "Sin pantallas 1h antes",
        "es-MX": "Sin pantallas 1h antes"
    ]
    static let tipCaffeineTitle: [String: String] = [
        "en-US": "Avoid caffeine after 2pm",
        "pt-BR": "Evite cafeína após as 14h",
        "es-ES": "Evita la cafeína tras las 14h",
        "es-MX": "Evita la cafeína tras las 14h"
    ]
    static let tipBreathingTitle: [String: String] = [
        "en-US": "Try 4-7-8 breathing",
        "pt-BR": "Tente a respiração 4-7-8",
        "es-ES": "Prueba la respiración 4-7-8",
        "es-MX": "Prueba la respiración 4-7-8"
    ]
    static let tipScheduleTitle: [String: String] = [
        "en-US": "Same bedtime every night",
        "pt-BR": "Mesmo horário toda noite",
        "es-ES": "La misma hora cada noche",
        "es-MX": "La misma hora cada noche"
    ]
    static let tipExerciseTitle: [String: String] = [
        "en-US": "Move during the day",
        "pt-BR": "Movimente-se durante o dia",
        "es-ES": "Muévete durante el día",
        "es-MX": "Muévete durante el día"
    ]

    // Home — Today's analysis + insights + see-all
    static let homeTodaySleep: [String: String] = [
        "en-US": "Today's sleep",
        "pt-BR": "Sono de hoje",
        "es-ES": "Sueño de hoy",
        "es-MX": "Sueño de hoy"
    ]
    static let homeSeeAll: [String: String] = [
        "en-US": "See all",
        "pt-BR": "Ver tudo",
        "es-ES": "Ver todo",
        "es-MX": "Ver todo"
    ]
    static let homeInsightsTitle: [String: String] = [
        "en-US": "Sleep insights",
        "pt-BR": "Insights do sono",
        "es-ES": "Insights del sueño",
        "es-MX": "Insights del sueño"
    ]
    static let homeStartNight: [String: String] = [
        "en-US": "Start tonight's sleep",
        "pt-BR": "Iniciar noite de sono",
        "es-ES": "Iniciar sueño de hoy",
        "es-MX": "Iniciar sueño de hoy"
    ]
    static let homeInsightTitle: [String: String] = [
        "en-US": "Great deep sleep",
        "pt-BR": "Ótimo sono profundo",
        "es-ES": "Sueño profundo excelente",
        "es-MX": "Sueño profundo excelente"
    ]
    static let homeInsightBody: [String: String] = [
        "en-US": "You spent 20% in deep sleep — right in the ideal range.",
        "pt-BR": "Você passou 20% em sono profundo — bem na faixa ideal.",
        "es-ES": "Pasaste el 20% en sueño profundo — en el rango ideal.",
        "es-MX": "Pasaste el 20% en sueño profundo — en el rango ideal."
    ]
    static let homeTrendUp: [String: String] = [
        "en-US": "+8%",
        "pt-BR": "+8%",
        "es-ES": "+8%",
        "es-MX": "+8%"
    ]
    static let homeTodayDate: [String: String] = [
        "en-US": "Today, Nov 11",
        "pt-BR": "Hoje, 11 de nov",
        "es-ES": "Hoy, 11 nov",
        "es-MX": "Hoy, 11 nov"
    ]

    // Sleep analysis detail (Slot 2)
    static let analysisStages: [String: String] = [
        "en-US": "Sleep stages",
        "pt-BR": "Fases do sono",
        "es-ES": "Fases del sueño",
        "es-MX": "Fases del sueño"
    ]
    static let analysisTimeInStages: [String: String] = [
        "en-US": "Time in stages",
        "pt-BR": "Tempo por fase",
        "es-ES": "Tiempo por fase",
        "es-MX": "Tiempo por fase"
    ]
    static let analysisInsights: [String: String] = [
        "en-US": "Insights",
        "pt-BR": "Análise",
        "es-ES": "Análisis",
        "es-MX": "Análisis"
    ]
    static let metricEfficiency: [String: String] = [
        "en-US": "Efficiency",
        "pt-BR": "Eficiência",
        "es-ES": "Eficiencia",
        "es-MX": "Eficiencia"
    ]
    static let metricTimeAsleep: [String: String] = [
        "en-US": "Time asleep",
        "pt-BR": "Tempo dormindo",
        "es-ES": "Tiempo dormido",
        "es-MX": "Tiempo dormido"
    ]
    static let metricDeepSleep: [String: String] = [
        "en-US": "Deep sleep",
        "pt-BR": "Sono profundo",
        "es-ES": "Sueño profundo",
        "es-MX": "Sueño profundo"
    ]
    static let metricRemSleep: [String: String] = [
        "en-US": "REM sleep",
        "pt-BR": "Sono REM",
        "es-ES": "Sueño REM",
        "es-MX": "Sueño REM"
    ]
    static let metricOptimal: [String: String] = [
        "en-US": "Optimal",
        "pt-BR": "Ótimo",
        "es-ES": "Óptimo",
        "es-MX": "Óptimo"
    ]
    static let metricIdealRange: [String: String] = [
        "en-US": "Ideal range",
        "pt-BR": "Faixa ideal",
        "es-ES": "Rango ideal",
        "es-MX": "Rango ideal"
    ]
    static let metricOfTotal: [String: String] = [
        "en-US": "of total",
        "pt-BR": "do total",
        "es-ES": "del total",
        "es-MX": "del total"
    ]
    static let analysisDateLabel: [String: String] = [
        "en-US": "Mon, Nov 11",
        "pt-BR": "Seg, 11 de nov",
        "es-ES": "Lun, 11 nov",
        "es-MX": "Lun, 11 nov"
    ]
    static let qualityExcellent: [String: String] = [
        "en-US": "Excellent",
        "pt-BR": "Excelente",
        "es-ES": "Excelente",
        "es-MX": "Excelente"
    ]
    static let insightExcellentNight: [String: String] = [
        "en-US": "Excellent night — restorative sleep",
        "pt-BR": "Noite excelente — sono restaurador",
        "es-ES": "Noche excelente — sueño reparador",
        "es-MX": "Noche excelente — sueño reparador"
    ]
}

// MARK: - Hypnogram Mock (Slot 2 — Sleep stages chart)
//
// Time series of sleep stages across the night. Stage values follow the
// real app's SleepAnalysisCard scale:
//   1 = Deep, 2 = Light, 3 = REM, 4 = Awake
// Times normalized 0..1 across the night (bedtime → wake).

struct MockHypnogramPoint: Hashable {
    let t: Double   // 0..1 across the night
    let stage: Int  // 1=Deep, 2=Light, 3=REM, 4=Awake
}

enum MockHypnogram {
    /// Realistic ~7h36m hypnogram: 5 sleep cycles, deep sleep early,
    /// more REM in the second half, brief awakenings near morning.
    static let lastNight: [MockHypnogramPoint] = [
        .init(t: 0.00, stage: 4),   // briefly awake at bedtime
        .init(t: 0.03, stage: 2),   // light
        .init(t: 0.08, stage: 1),   // first deep dive
        .init(t: 0.16, stage: 1),
        .init(t: 0.19, stage: 2),
        .init(t: 0.23, stage: 3),   // first REM (short)
        .init(t: 0.26, stage: 2),
        .init(t: 0.31, stage: 1),   // second deep
        .init(t: 0.38, stage: 1),
        .init(t: 0.41, stage: 2),
        .init(t: 0.46, stage: 3),   // REM
        .init(t: 0.50, stage: 2),
        .init(t: 0.54, stage: 1),   // third deep (shorter)
        .init(t: 0.59, stage: 2),
        .init(t: 0.62, stage: 4),   // brief awakening
        .init(t: 0.64, stage: 2),
        .init(t: 0.69, stage: 3),   // long REM
        .init(t: 0.74, stage: 2),
        .init(t: 0.78, stage: 1),   // last deep (very short)
        .init(t: 0.81, stage: 2),
        .init(t: 0.86, stage: 3),   // longest REM near wake
        .init(t: 0.92, stage: 2),
        .init(t: 0.97, stage: 4),
        .init(t: 1.00, stage: 4)
    ]
}

// MARK: - Tip List (Slot 5 — Sleep Tips list rows)

struct MockTipListItem: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let titleKey: String       // looks up in LocalizedLabels via MockTipList.title(for:locale:)
    let categoryKey: String    // matches MockTipCategories.all `nameKey`
    let tint: Color
}

enum MockTipList {
    static let all: [MockTipListItem] = [
        MockTipListItem(
            icon: "sun.horizon.fill",
            titleKey: "tipMorningLightTitle",
            categoryKey: "routine",
            tint: Color(red: 0.55, green: 0.42, blue: 1.00)
        ),
        MockTipListItem(
            icon: "thermometer.snowflake",
            titleKey: "tipCoolRoomTitle",
            categoryKey: "environment",
            tint: Color(red: 0.38, green: 0.65, blue: 0.98)
        ),
        MockTipListItem(
            icon: "iphone.slash",
            titleKey: "tipScreenTimeTitle",
            categoryKey: "lifestyle",
            tint: Color(red: 0.13, green: 0.77, blue: 0.37)
        ),
        MockTipListItem(
            icon: "cup.and.saucer.fill",
            titleKey: "tipCaffeineTitle",
            categoryKey: "nutrition",
            tint: Color(red: 0.96, green: 0.62, blue: 0.04)
        ),
        MockTipListItem(
            icon: "wind",
            titleKey: "tipBreathingTitle",
            categoryKey: "relaxation",
            tint: Color(red: 0.66, green: 0.33, blue: 0.97)
        ),
        MockTipListItem(
            icon: "moon.stars.fill",
            titleKey: "tipScheduleTitle",
            categoryKey: "routine",
            tint: Color(red: 0.55, green: 0.42, blue: 1.00)
        ),
        MockTipListItem(
            icon: "figure.walk",
            titleKey: "tipExerciseTitle",
            categoryKey: "lifestyle",
            tint: Color(red: 0.13, green: 0.77, blue: 0.37)
        )
    ]

    /// Resolve a tip's localized title.
    static func title(for item: MockTipListItem, locale: String) -> String {
        switch item.titleKey {
        case "tipMorningLightTitle": return LocalizedLabels.tipMorningLightTitle[locale] ?? "Get morning sunlight"
        case "tipCoolRoomTitle":     return LocalizedLabels.tipCoolRoomTitle[locale] ?? "Keep the room cool"
        case "tipScreenTimeTitle":   return LocalizedLabels.tipScreenTimeTitle[locale] ?? "No screens 1h before bed"
        case "tipCaffeineTitle":     return LocalizedLabels.tipCaffeineTitle[locale] ?? "Avoid caffeine after 2pm"
        case "tipBreathingTitle":    return LocalizedLabels.tipBreathingTitle[locale] ?? "Try 4-7-8 breathing"
        case "tipScheduleTitle":     return LocalizedLabels.tipScheduleTitle[locale] ?? "Same bedtime every night"
        case "tipExerciseTitle":     return LocalizedLabels.tipExerciseTitle[locale] ?? "Move during the day"
        default: return item.titleKey
        }
    }
}

// MARK: - Format helpers

enum MockFormat {
    /// Returns "7h 24m" / "7h 24min" depending on locale conventions.
    static func duration(_ hours: Double, locale: String) -> String {
        let totalMin = Int((hours * 60).rounded())
        let h = totalMin / 60
        let m = totalMin % 60
        switch locale {
        case "pt-BR": return "\(h)h \(String(format: "%02d", m))min"
        case "es-ES", "es-MX": return "\(h) h \(String(format: "%02d", m)) min"
        default: return "\(h)h \(String(format: "%02d", m))m"
        }
    }
}
