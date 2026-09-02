# Backlog da revisão geral 2026-09-02 (65 achados, 3 agentes)

Corrigidos: ver commits 22469b9 (análise de sono), 8fb72cf (serviços+telas). Reports completos com file:line no scratchpad da sessão (review_alarm/services/screens/data/presentation.md) — resumo dos IDs em cada commit message.

## Pendentes (por prioridade)
1. **[T7] Acessibilidade**: ~60 controles sem accessibilityIdentifier/Label. Fix estrutural: params em AppButton + ids `dominio.acao` por tela (tabs, settings, tips, stats, onboarding, rating gate). Pré-requisito pra QA por Maestro (RULES #66).
2. **[S18] Crashlytics** ausente (obrigatório, taxonomia §6) + user properties §2.7. Adicionar produto SPM via gem xcodeproj + dSYM Release.
3. **[S13/S16] Analytics restantes**: rating_gate_yes/no/feedback (renomear) + rating_gate_dismissed + trigger param; permission_prompted + alarmkit auth log.
4. **[A5] forceFixed pós-early-ring**: alarme de 1 dia/semana pode silenciar na 3ª semana se o app nunca voltar ao foreground (baseline semanal cobre parcialmente). Repensar: supressão por flag em vez de trocar o schedule.
5. **[A7/A8] AlarmSoundGenerator**: geração inline no main na 1ª passada + write não-atômico; fallback in-app não loopa (alarme silencioso se WAV corrompido).
6. **[A10] Limite de snooze não aplicável no AlarmKit** (countdown do sistema não volta pro app).
7. **[A11] Orçamento de 64 notificações** não conta baselines (4+ alarmes diários estouram).
8. **[A15] SystemVolume**: no-op sem window + nunca restaura o volume do usuário.
9. **[A18] AlarmRingingView** não re-binda quando um 2º alarme assume o overlay.
10. **[S23] Perf**: persist 2x/min no main actor; encoders não-estáticos; saveSleepRecords re-encoda 365d.
11. **[T12] Arquivos >600 linhas**: NotificationService (629), SleepTrackerView (615).
12. **[T13] Documentar exceção Liquid Glass** (UIDesignRequiresCompatibility=false é decisão do soninho).
13. **[T16] 57 keys "stale" no xcstrings** (resolvidas via LocalizationValue — cleanup do catálogo apagaria onboarding/tips).
14. **[S24] recoverGap sem telemetria de falha nem check de autorização Motion.**
15. **[T19-menores] P20 copy dos ciclos, hardcoded "h/m" (30 locales), usage descriptions dizem "Sunrise Alarm", T18 empty state de tips, spinner no toggle de bedtime (T6 parcial: falta loading state), S12 disturbanceSeconds nunca lido.**
16. **BGAppRefreshTask** pro keep-alive sem abrir o app à noite (mitigado pelo horizonte 24h, resolve o caso "não abriu o app no dia").
