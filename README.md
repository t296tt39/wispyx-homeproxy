# wispyx × OpenWrt HomeProxy

Промпт для агента на роутере. Подписка wispyx уже должна быть в HomeProxy.

Порядок работы агента фиксированный:

1. Обновить подписку.
2. Замерить **прямые страны** (не мосты) — взять самый быстрый и стабильный.
3. Вкрутить плюшки (fragment, маршруты, PS5, QUIC).
4. Замерить ещё раз после fragment — main по второму замеру.
5. Мосты и обходы — **вторая линия**, не main, пока прямая страна живая.
6. Автофейловер: urltest + watchdog — если текущий сервер подох, сам берёт самый быстрый живой.

Подписка даёт **только ноды**. Фрагментация, маршруты, ИИ, PS5 в UCI сами не приедут.

Секреты, UUID, ключи, тело подписки в отчёт не писать.

На части роутеров настройки уже стоят частично: **merge**, не factory-reset HomeProxy, не дублировать секции, не сносить рабочие правила.

---

Скопируй агенту блок ниже целиком.

````
Роутер OpenWrt, HomeProxy, ядро hiddify (или sing-box если hiddify нет). Это wispyx. Часть настроек уже может быть — не сноси рабочие правила, не дублируй секции. Сверь UCI, допиши недостающее, оставь то что уже совпадает. Секреты/uuid/ключи/тела подписки не печатай. В git не пушь.

Цель: интернет, обходы TSPU, игры (PS5/CoD), ИИ, RU-сервисы. Порядок шагов обязательный, не переставляй.

Рабочий транспорт для main: только VLESS TCP REALITY + Vision.
Протокол-пинг: HTTPS generate_204 (или gstatic) через mixed-порт / Clash API / hiddify-core srun. ICMP ping запрещён — врёт.

Первая линия (кандидаты в main): прямые страны
🇵🇱 Польша pl2.srv:443, 🇫🇮 Финляндия fn.srv:443, 🇳🇱 Нидерланды (не origin steal), 🇩🇪 Германия, 🇸🇪 Швеция, 🇳🇴 Норвегия, 🇺🇸 США direct только если протокол живой (часто TSPU режет), 🇦🇹 Австрия REALITY :443 если живая.
Не первая линия: «🚀 АВТОРЕЖИМ», auto.wispyx.net, Wi‑Fi WS, Hy2, XHTTP, 🌐 CDN, stolen SNI (yastatic/avito/cdnjs), «Обход …», «Мост …», ru2/br/usbr, прямой Kamatera IP как «fatal».

Вторая линия (fallback, не main пока первая жива):
🇵🇱 Обход Польша ru2:443, 🇫🇮 Обход Финляндия / Мост, 🇺🇸 Обход США usbr:8445.
Их мерять отдельно, писать в отчёт как запас.

════════════════════════════════
ШАГ 1 — ПОДПИСКА
════════════════════════════════
- Найди URL подписки wispyx (uci homeproxy / LuCI Subscription).
- Скачай и обнови ноды. Дождись импорта. Без свежих нод ничего не меряй.
- Подписка даёт ТОЛЬКО ноды. Маршруты, tls_fragment, PS5, ИИ сами НЕ приедут.

════════════════════════════════
ШАГ 2 — ПЕРВЫЙ ЗАМЕР (до плюшек)
════════════════════════════════
Поставь временно ядро если его ещё нет: preferred_core=hiddify (иначе sing-box), packet_encoding=xudp.
Протокол-пинг по всем нодам первой линии. Таблица: нода, ms, fail/ok, 2–3 попытки если флапает.
main_node = лучший из первой линии: живой, стабильный (без флапа), минимальная задержка.
Если вся первая линия fail/timeout/>800ms — тогда main из второй линии (обычно Обход Польша).
Не ставь main на АВТОРЕЖИМ / Wi‑Fi / Hy2 / XHTTP / CDN / steal.

════════════════════════════════
ШАГ 3 — ЯДРО, ФРАГМЕНТ, МАРШРУТЫ, PS5
════════════════════════════════
uci:
- preferred_core = hiddify (если пакета нет — sing-box)
- packet_encoding = xudp
- routing_mode = proxy_banned_ru
- default_outbound = direct-out
- proxy_mode = redirect_tproxy
- proxy_ru_rule refilter = on, node = main-out
- proxy_ru_rule russia-inside = on, node = main-out

Если uci commit Access denied — uci apply с rollback 90с.

Фрагментация на КАЖДОЙ wispyx-ноде VLESS TCP REALITY (страны + мосты):
- tls_fragment = 1
- tls_fragment_size = 10-20
- tls_fragment_sleep = 10-20
- tls_utls firefox на странах, chrome на мостах/обходах
Wi‑Fi WS / Hy2 / XHTTP не трогать. Не снимай fragment где уже стоит.

PS5: не хардкодь чужой LAN-IP.
DHCP/ARP: hostname PlayStation / PS5 / PS4, vendor Sony.
Если ps5_global_proxy уже есть и IP живой — оставь, проверь enabled → main-out.
Нашла — source_ip_cidr <IP>/32 → main-out. Несколько приставок — все.
Нет в LAN — «PS5 не найден», не выдумывай IP.
Полный VPN приставки. LAN-IP не писать в подписку панели.

Маршруты, без дублей (секцию шире не сужай):

A) ru_services_direct → direct-out
   rutube.ru, vk.com, vk.ru, ok.ru, wildberries.ru, gosuslugi.ru, yandex.ru, yandex.net, ya.ru, dzen.ru, mail.ru, sber.ru, tinkoff.ru, tbank.ru, avito.ru, ozon.ru, nalog.ru, mos.ru

B) ai_domains_proxy → main-out
   .ai, openai.com, chatgpt.com, anthropic.com, claude.ai,
   cognition.com, devinapps.com, devinenterprise.com,
   cursor.com, cursor.sh, groq.com, grok.com, x.ai,
   githubcopilot.com, copilot.microsoft.com,
   perplexity.ai, poe.com, huggingface.co, midjourney.com, stability.ai, runwayml.com
   Уже прописанные ИИ не выкидывать.

C) fanduel_proxy → main-out
   fanduel.com

D) telegram_proxy → main-out
   telegram.org, t.me, td.es, telegram.me, tdesktop.com + DC IP если уже были

E) cod_ips_proxy → main-out
   185.34.106.0/23, 185.92.222.0/24

F) cod_ports_proxy → main-out
   TCP+UDP 3074, 3075, 3478-3480, 27014-27050, 30000-32000

G) YouTube / QUIC
   quic_drop: udp dest_port 443 → reject/block (весь TUN или youtube.com, googlevideo.com, ytimg.com, youtu.be, youtubei.googleapis.com, ggphosted.com).
   YouTube через двуххоп-обход часто зависает при живом google.com — это QUIC, не «мост режет YouTube».
   Если после quic_drop ролик мёртв: youtube_proxy этих доменов на лучшую ПРЯМУЮ страну с шага 2/4 (не на Обход).
   Если прямых стран нет — youtube_proxy на 🇺🇸 Обход США (usbr), не на голый Kamatera/fatal.
   Main из-за YouTube на US не менять.

Порядок правил: private/LAN direct; PS5; RU-сервисы direct; quic_drop; youtube_proxy если нужен; ИИ/FanDuel/Telegram/CoD в VPN; остальное proxy_banned_ru.

apply HomeProxy, дождаться ядра.

════════════════════════════════
ШАГ 4 — ВТОРОЙ ЗАМЕР (после плюшек)
════════════════════════════════
Снова протокол-пинг первой линии (fragment уже включён — цифры другие).
Потом отдельно вторая линия (мосты/обходы).
main_node = лучший стабильный из ПЕРВОЙ линии по этому замеру.
Вторую линию в main ставь только если первая снова вся fail/>800ms/флап.
Запиши в отчёт обе таблицы (до и после fragment) и какой main выбран.

Америка с роутера: «🇺🇸 Обход США» usbr, не прямой US IP.
Финка если прямой fn.srv мёртв — Обход/Мост как запас, не как первый выбор.
Австрия Hy2 на HomeProxy не поднимается.

════════════════════════════════
ШАГ 5 — АВТОПЕРЕКЛЮЧЕНИЕ (если сервер подох)
════════════════════════════════
Нужно чтобы при смерти текущего выхода роутер САМ брал самый быстрый живой. Не ждать человека.

A) Нативный urltest HomeProxy (предпочтительно)
Если в UCI/LuCI у node есть type=urltest (или urltest-группа):
- Создай ОДНУ группу `wispyx_auto` (не дублируй, если уже есть).
- test_url = https://www.gstatic.com/generate_204 (HTTPS, не ICMP).
- interval 5m–10m. idle_timeout ~30m.
- interrupt_exist_connections = 0 / false — иначе рвёт PS5/CoD на каждом замере.
- tolerance ~100–150 ms, чтобы не прыгать между соседними странами каждую минуту.
- Члены СТРОГО в таком порядке:
  1) все живые VLESS TCP REALITY первой линии (страны);
  2) в хвост вторая линия: Обход Польша, Обход Финляндия/Мост, Обход США.
- В группу НЕ класть: АВТОРЕЖИМ, Wi‑Fi, Hy2, XHTTP, CDN, stolen SNI, прямой Kamatera/fatal.
- main_node = эта urltest-группа, не одиночная нода.
Ядро само уведёт трафик на самый быстрый живой. Пока страны живы, мост с 350ms не победит. Если все страны timeout — возьмёт обход.

B) Watchdog, даже если urltest есть
Скрипт /usr/bin/wispyx-hp-watch (или /etc/homeproxy.d/), cron каждые 5 минут. Идемпотентно, не плодить crontab.
Логика:
1) HTTPS generate_204 через mixed-порт (часто 127.0.0.1:5330) timeout 8s. 204 = ок, выйти.
2) Два фейла подряд (флаг /tmp/wispyx-hp-fail, не переключать с первого глюка).
3) Протокол-пинг списка: сначала первая линия, потом вторая. Кандидаты только VLESS TCP REALITY+Vision.
4) Взять самый быстрый стабильный (2 ок из 2, или 2 из 3 если флапал).
5) Если текущий main уже этот — не трогать. Иначе uci set homeproxy.config.main_node, apply, reload HomeProxy.
6) Лог в logger -t wispyx-hp-watch. Секреты не писать.
Если main это urltest-группа и generate_204 через неё мёртв — reload HomeProxy; если после reload всё ещё мёртв — временно поставь лучшую одиночную ноду с замера, в отчёте напиши.

C) После обновления подписки
Пересобери список членов urltest (новые ноды, старые UUID могли смениться). Watchdog не удалять.

════════════════════════════════
НЕ ДЕЛАТЬ
════════════════════════════════
- Не начинать с мостов. Сначала прямые страны.
- Не оставлять main на Обходе, если прямая Польша/Финка/NL/DE живая и быстрее.
- Не класть мосты первыми в urltest — только хвост.
- Не включать interrupt_exist_connections — рвёт игры.
- Не ставить main на АВТОРЕЖИМ / Wi‑Fi / Hy2 / XHTTP / CDN / steal.
- Не отключать PS5/CoD «чтобы почистить».
- Не тащить YouTube на прямой US, пока нет quic_drop.
- Не ждать, что подписка сама включит fragment и route.rules.
- Не писать IP приставки в общую подписку.
- Merge, не factory-reset HomeProxy.

════════════════════════════════
ПРОВЕРКА
════════════════════════════════
- Clash API :9090 жив
- HTTPS generate_204 через mixed-порт
- tls_fragment=1 на wispyx VLESS
- main = urltest `wispyx_auto` ИЛИ победитель шага 4; в отчёте как именно устроен фейловер
- watchdog cron есть, пробный generate_204 через mixed-порт проходит
- PS5 /32 → main-out или «не найден»
- ru_services_direct, ai_domains_proxy, cod_*, quic_drop на месте
- youtube.com ролик открывается
- АВТОРЕЖИМ не выбран

Отчёт: что было / что дописал / таблица пингов шаг 2 / таблица шаг 4 / main_node / urltest члены / cron watchdog да-нет / запасной мост / IP PS5 / YouTube outbound.
````

## Кенту в Telegram

Репозиторий: https://github.com/t296tt39/wispyx-homeproxy

«открой README, скопируй блок агенту одним куском. Подписка → замер стран → плюшки → второй замер → urltest+watchdog. Мосты запас. Если сервер подох — сам пересядет на самый быстрый живой.»
