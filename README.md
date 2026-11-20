# wispyx × OpenWrt HomeProxy

Промпт для агента на роутере. Подписка wispyx уже должна быть в HomeProxy.

Порядок работы агента фиксированный:

1. Обновить подписку. Поставить cron: подписка **каждый час**. Рестарт HomeProxy — **раз в сутки** (ночь), не каждый час.
2. Замерить **прямые страны** (не мосты) — взять самый быстрый и стабильный.
2.5. Снимок старых routing_rule → снести все правила и yt_ копии → накатить золото (подписку не ресетить).
3. Вкрутить плюшки (fragment, маршруты, PS5, QUIC).
4. Замерить ещё раз после fragment — main по второму замеру.
5. Мосты и обходы — **вторая линия**, не main, пока прямая страна живая.
6. Автофейловер: urltest + watchdog — если текущий сервер подох, сам берёт самый быстрый живой.

Подписка даёт **только ноды**. Фрагментация, маршруты, ИИ, PS5 в UCI сами не приедут.

Секреты, UUID, ключи, тело подписки в отчёт не писать.

Не factory-reset HomeProxy (подписка и ноды стран/обходов остаются). Кастомные **routing_rule** перед накатом золота снести и поставить заново — старый зоопарк (yt_ копии, youtube_node, левые outbound) иначе остаётся. Снимок старых правил обязателен.

---

Скопируй агенту блок ниже целиком.

````
Роутер OpenWrt, HomeProxy, ядро hiddify (или sing-box если hiddify нет). Это wispyx. Секреты/uuid/ключи/тела подписки не печатай. В git не пушь.

Перед плюшками: сними снимок текущих routing_rule / youtube_node / yt_* / valve / PS5, сверь с золотом этого промпта, затем СНЕСИ все routing_rule и yt_/youtube_node и поставь золотой набор заново. Ноды подписки (страны/обходы) не удалять. Factory-reset HomeProxy запрещён.

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
ШАГ 1 — ПОДПИСКА (обязательно, не пропускай)
════════════════════════════════
- Найди URL подписки wispyx (uci homeproxy / LuCI Subscription).
- Прямо сейчас скачай и обнови ноды: `ucode /etc/homeproxy/scripts/update_subscriptions.uc` (или кнопка Update в LuCI). Дождись импорта. Без свежих нод ничего не меряй.
- Повесь часовой cron, идемпотентно, маркер `#wispyx-hp-sub`, не дублируй:
  `0 * * * * /etc/homeproxy/scripts/update_crond.sh #wispyx-hp-sub`
  `sed -i '/#wispyx-hp-sub/d' /etc/crontabs/root` затем допиши строку, `/etc/init.d/cron reload`.
- `uci set homeproxy.subscription.auto_update=1` и `update_via_proxy=1`. Штатный `auto_update_time` — раз в сутки, его не хватает; часовой `#wispyx-hp-sub` init.d не затирает (он трогает только `#homeproxy_autosetup`).
- После каждого обновления подписки пересобери члены urltest (UUID нод могли смениться). **Ядро не рестартить**, если generate_204 через main-out живой — иначе рвёт PS5/CoD.
- Рестарт HomeProxy (ensure fragment/urltest + `homeproxy restart`) — **один раз в сутки**, ночь, маркер `#wispyx-hp-daily`, не дублируй:
  `17 1 * * * /usr/bin/wispyx-hp-daily #wispyx-hp-daily`
  (01:17 UTC ≈ 04:17 МСК). Часовой `#wispyx-hp-sub` только качает ноды.
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
ШАГ 2.5 — СНИМОК И СНОС СТАРЫХ ПРАВИЛ (обязательно, до плюшек)
════════════════════════════════
Не merge поверх зоопарка. Не `uci delete homeproxy` целиком и не Reset в LuCI — снесёшь подписку и ноды.

1) Снимок (в отчёт, без UUID/ключей): список routing_rule (имя, enabled, outbound, кратко домены/порты), youtube_proxy outbound, есть ли youtube_node / yt_*, valve_direct, ps5_global_proxy IP (только факт «есть/нет», LAN-IP в общую подписку не писать), main_node label, члены urltest.
2) Сверка с золотом: лишнее (yt_ копии, youtube_node urltest, youtube_proxy на Обход/usbr, АВТО/Wi‑Fi в urltest, interrupt_exist_connections, дубли routing_rule) — в отчёт как «было лишнее».
3) Снос правил:
   - удалить ВСЕ секции `routing_rule`
   - удалить `youtube_node` и все ноды `yt_*`
   - `uci delete homeproxy.config.main_urltest_nodes` если там Обход/Wi‑Fi/АВТО/YT (члены urltest пересоберёшь на шаге 5)
   - ноды подписки (🇵🇱/🇫🇮/🇩🇪/… и «Обход …») не трогать
   - subscription / server / config.main_node не сносить
4) Сразу после сноса накатить золотой набор шага 3. Из снимка вернуть ТОЛЬКО: valve_direct если был; ps5_global_proxy если IP всё ещё в LAN. Остальное (ИИ, CoD, RU, quic, catch-all, youtube_proxy→main-out) ставится заново по промпту, не «как было».

════════════════════════════════
ШАГ 3 — ЯДРО, ФРАГМЕНТ, МАРШРУТЫ, PS5
════════════════════════════════
uci:
- preferred_core = hiddify (если пакета нет — sing-box)
- packet_encoding = xudp
- routing_mode = proxy_banned_ru
- show_advanced_rules = 1
- proxy_mode = redirect_tproxy
- proxy_ru_rule refilter = on, node = main-out
- proxy_ru_rule russia-inside = on, node = main-out

TSPU на домовых провайдерах режет прямой зарубеж (Google, Microsoft, Akamai, Fastly).
`proxy_banned_ru` сам по себе шлёт в VPN только «запрещёнку», остальное идёт direct и умирает.
Не ставь routing_mode=global — тогда пропадут кастомные RU-direct правила.
Не надейся на routing.default_outbound: в режиме proxy_banned_ru final всегда direct-out.

Нужен catch-all ПОСЛЕДНИМ среди routing_rule:
- секция `foreign_via_vpn` (не дублируй)
- enabled=1, action=route, outbound=main-out
- без доменов/портов — матчит всё, что не съели правила выше
RU (.ru/.su/.рф, госуслуги, банки, Яндекс, VK) остаются в ru_services_direct → direct-out и стоят ВЫШЕ catch-all.

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
   rutube.ru, vk.com, vk.ru, ok.ru, wildberries.ru, gosuslugi.ru, yandex.ru, yandex.net, ya.ru, dzen.ru, mail.ru, sber.ru, tinkoff.ru, tbank.ru, avito.ru, ozon.ru, nalog.ru, mos.ru,
   плюс суффиксы ru, su, xn--p1ai (.рф) — не сужай список, Valve/Steam direct если уже есть (Слава) не трогай.

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
   Реклама YouTube режется **на Xray ноды** (country VLESS → серверный YouTube hop). На роутере отдельных YT-нод нет и не будет.
   quic_drop: udp dest_port 443 → reject (youtube.com, googlevideo.com, ytimg.com, youtu.be, youtubei.googleapis.com, ggpht.com).
   youtube/googlevideo/ytimg → **main-out** той же first-line страны, что и весь зарубеж. catch-all `foreign_via_vpn` это уже делает; если секция `youtube_proxy` есть — outbound=`main-out`.
   ЗАПРЕЩЕНО: клонировать ноды `yt_*`, urltest `youtube_node`, youtube_proxy на Обход/usbr/Wi‑Fi/АВТО, класть YT-копии в main urltest, тащить YouTube на прямой US, менять main из-за YouTube.
   YouTube через двуххоп-обход зависает (QUIC) и **минует** серверный ads-hop. hp.uc ensure не должен создавать yt_ копии; watchdog не переключает YouTube-ноды.

Порядок правил после сноса: private/LAN direct; PS5 если найден; RU-сервисы direct (.ru/.su/.рф); quic_drop; youtube_proxy → main-out; ИИ/FanDuel/Telegram/CoD в VPN; valve_direct только если был в снимке; последним foreign_via_vpn → main-out.

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
Часовой update **не** делает `/etc/init.d/homeproxy restart`, пока generate_204 живой.
Рестарт ядра — cron `#wispyx-hp-daily` раз в сутки (ночь). Скрипт `/usr/bin/wispyx-hp-daily`: ensure fragment/urltest (без yt_ копий), затем restart. Не вешать ensure+restart на `*/5` и не на каждый час.

════════════════════════════════
НЕ ДЕЛАТЬ
════════════════════════════════
- Не начинать с мостов. Сначала прямые страны.
- Не оставлять main на Обходе, если прямая Польша/Финка/NL/DE живая и быстрее.
- Не класть мосты первыми в urltest — только хвост.
- Не включать interrupt_exist_connections — рвёт игры.
- Не ставить main на АВТОРЕЖИМ / Wi‑Fi / Hy2 / XHTTP / CDN / steal.
- Не отключать PS5/CoD «чтобы почистить».
- Не клонировать `yt_*` / `youtube_node` urltest. YouTube = main-out. Не тащить YouTube на Обход/usbr/прямой US.
- Не ждать, что подписка сама включит fragment и route.rules.
- Не пропускать шаг 1. Не оставлять подписку «как было» без свежего update и без часового cron.
- Не рестартить HomeProxy каждый час из-за ensure/подписки — рвёт CoD/PS5. Рестарт ядра раз в сутки (`#wispyx-hp-daily`).
- Не писать IP приставки в общую подписку.
- Не factory-reset HomeProxy (подписка живая). Не merge старых routing_rule поверх золота — снес правила (шаг 2.5), потом наши.
- Не оставлять yt_* / youtube_node «на всякий случай».

════════════════════════════════
ПРОВЕРКА
════════════════════════════════
- Clash API :9090 жив
- HTTPS generate_204 через mixed-порт
- tls_fragment=1 на wispyx VLESS
- main = urltest `wispyx_auto` ИЛИ победитель шага 4; в отчёте как именно устроен фейловер
- watchdog cron есть, пробный generate_204 через mixed-порт проходит
- cron `0 * * * * ... update_crond.sh #wispyx-hp-sub` есть ровно одна строка
- cron `17 1 * * * /usr/bin/wispyx-hp-daily #wispyx-hp-daily` есть ровно одна строка
- подписка только что обновлена в этом прогоне (не «уже стояла вчера»)
- PS5 /32 → main-out или «не найден»
- ru_services_direct с ru/su/xn--p1ai, ai_domains_proxy, cod_*, quic_drop на месте
- show_advanced_rules=1 и catch-all `foreign_via_vpn` → main-out последним среди routing_rule
- youtube.com ролик открывается через main-out (нет секций `yt_*` / `youtube_node`)
- АВТОРЕЖИМ не выбран

Отчёт: снимок старых routing_rule / что снесли / что поставили заново / таблица пингов шаг 2 / таблица шаг 4 / main_node / urltest члены / cron watchdog да-нет / запасной мост / PS5 / YouTube outbound=main-out / yt_ нет.
````

## Кенту в Telegram

Репозиторий: https://github.com/t296tt39/wispyx-homeproxy

«открой README, скопируй блок агенту одним куском. Сначала обновить подписку и cron раз в час. Рестарт ядра — раз в сутки ночью. Перед плюшками: снимок старых routing_rule, снести все правила и yt_ копии, накатить золото (подписку не ресетить). Потом замер стран → плюшки → второй замер → urltest+watchdog. Мосты запас.»
