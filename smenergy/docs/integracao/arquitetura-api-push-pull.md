# Integracao de Equipamentos (API Push + API Pull)

## Objetivo
Permitir ingestao de dados de equipamentos de outras empresas sem alterar o app Flutter atual, que ja consome o Firestore.

## Estado atual no app
O app usa esta estrutura principal no Firestore:
- `users/{uid}/devices/{deviceId}/sensors/{sensorId}`
- `users/{uid}/devices/{deviceId}/sensors/{sensorId}/readings/{readingId}`

Campos usados pelo app:
- Sensor: `name`, `limit_watts`, `current_watts`, `last_reading_at`, `is_online`
- Reading: `timestamp`, `watts`, `source`

Conclusao: o backend de integracao deve normalizar e gravar nesse formato para manter compatibilidade.

## Arquitetura recomendada
1. API Gateway de integracao
2. Servico de autenticacao de parceiros (API key/OAuth2 + assinatura HMAC)
3. Servico de ingestao (recebe push)
4. Servico de conectores (executa pull por parceiro)
5. Fila de eventos (retry, desacoplamento, backpressure)
6. Processador de normalizacao (modelo canonico)
7. Writer para Firestore (upsert sensor + insert reading)
8. Observabilidade (logs, metricas, DLQ, tracing)

## Fluxo Push (tempo real)
1. Parceiro envia `POST /v1/ingestion/events` com assinatura.
2. API valida autenticacao, schema e `event_id`.
3. Evento entra em fila.
4. Processador converte para modelo canonico.
5. Writer atualiza:
   - `current_watts` e `last_reading_at` no sensor
   - novo documento em `readings`
6. API retorna `202 Accepted` com `trace_id`.

## Fluxo Pull (polling)
1. Scheduler dispara conector do parceiro (ex.: a cada 1-5 min).
2. Conector chama API externa (cursor/desde ultimo timestamp).
3. Dados recebidos entram na mesma fila do push.
4. Processador aplica idempotencia por `event_id` ou hash deterministico.
5. Writer grava no Firestore.

## Modelo canonico de telemetria
Campos minimos:
- `event_id` (string unica global)
- `tenant_id` (cliente SMEnergy)
- `partner_id` (empresa origem)
- `equipment_id`
- `sensor_id` (opcional)
- `metric` (ex.: `power_w`)
- `value` (numero)
- `unit` (ex.: `W`, `kWh`)
- `timestamp_utc` (ISO-8601 UTC)
- `quality` (`good`, `estimated`, `bad`)
- `metadata` (map opcional)

## Mapeamento para Firestore (compatibilidade com app)
Para `metric == power_w`:
- `current_watts = value`
- `last_reading_at = timestamp_utc`
- novo reading:
  - `timestamp = timestamp_utc`
  - `watts = value`
  - `source = partner_id`

Para outras metricas (ex.: tensao, corrente):
- manter em colecao paralela `metrics` ou em `metadata`, sem quebrar UI atual.

## Seguranca minima
- TLS obrigatorio.
- Auth por parceiro: OAuth2 client credentials ou API key.
- Assinatura HMAC em webhook (`X-Signature`, `X-Timestamp`).
- Protecao de replay (janela de 5 min + nonce/event_id unico).
- Rate limit por parceiro e por endpoint.
- Auditoria por `trace_id`.

## Idempotencia e resiliencia
- Tabela/colecao de deduplicacao por `event_id` (TTL 7-30 dias).
- Reprocessamento seguro (at-least-once).
- DLQ para payload invalido ou falha repetida.
- Retry exponencial com jitter.

## SLO inicial sugerido
- Disponibilidade API ingestao: 99.9%
- Latencia P95 ingestao (aceite): < 300 ms
- Lag P95 ate escrita no Firestore: < 30 s
- Taxa de erro 5xx: < 0.5%

## Plano de MVP (4 semanas)
1. Semana 1: modelo canonico + endpoint push + writer Firestore.
2. Semana 2: deduplicacao, retries, observabilidade basica.
3. Semana 3: 1 conector pull real (parceiro piloto).
4. Semana 4: hardening (HMAC, rate limit, DLQ, dashboards).

## Contratos de API
Especificacao inicial em:
- `docs/integracao/openapi-integracao-equipamentos.yaml`
