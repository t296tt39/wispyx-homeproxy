# wispyx × OpenWrt HomeProxy

Промпт для агента на роутере. Подписка wispyx уже должна быть в HomeProxy.

Порядок работы агента фиксированный:

1. Обновить подписку. Поставить cron: подписка **каждый час**. Рестарт HomeProxy — **раз в сутки** (ночь), не каждый час.
2. Замерить **прямые страны** (не мосты) — взять самый быстрый и стабильный.
2.5. Снимок старых routing_rule → снести все правила и yt_ копии → накатить золото (подписку не ресетить).
3. Вкрутить плюшки (fragment, маршруты, PS5, QUIC).
4. Замерить ещё раз после fragment — main по второму замеру.
5. Мосты и обходы — **вторая линия**, не main, пока прямая страна живая.
6. Автофейловер: urltest из DE/FI/NL/PL/NR + watchdog. Hy2 (Телега/CoD/BF1) следует за той же страной.

Подписка даёт **только ноды**. Фрагментация, маршруты, ИИ, PS5 в UCI сами не приедут.

Секреты, UUID, ключи, тело подписки в отчёт не писать.

`hp.uc` в этом репо — положить в `/usr/share/wispyx/hp.uc` (chmod +x). Старый файл требует Vision для класса F: после перехода на :8443 без Vision **страна (DE/AT/US) пропадает из first-line**, watchdog прыгает на Польшу/обход. Новый: пустой flow на `*.srv.wispyx.net` = F, Обход = S. Ноды не с `*.wispyx.net` classify игнорирует.

`wispyx-hp-hy2-follow` — `/usr/bin/wispyx-hp-hy2-follow`, cron каждую минуту. Hy2 следует за страной urltest (DE/FI/NL/PL/NR). Без default route скрипт сразу выходит.

Не factory-reset HomeProxy (подписка и ноды стран/обходов остаются). Кастомные **routing_rule** перед накатом золота снести и поставить заново — старый зоопарк (yt_ копии, youtube_node, левые outbound) иначе остаётся. Снимок старых правил обязателен.

## Патч leftover Vision (корешу / отдельному агенту)

Страны wispyx: VLESS TCP REALITY **:8443 без Vision**. HomeProxy после Update подписки часто снова пишет `vless_flow=xtls-rprx-vision`. Клиент с Vision на пустой инбаунд не коннектится, Clash 65535, чекер IP показывает **прошлую** живую страну. Один `uci delete` не лечит — импортёр вернёт через час.

Скопируй агенту этот блок:

```
Роутер OpenWrt + HomeProxy. Секреты, UUID, ключи, URL подписки не печатай и в git не клади.

Баг: после Update подписки на карточках *.srv.wispyx.net:8443 снова xtls-rprx-vision. JSON main-out.flow не пустой. Нода не поднимается. Чекер IP = предыдущая страна.

Сделай на роутере (идемпотентно, можно гонять повторно):

1) Скрипт из репо:
   wget -O /tmp/fix-nv8443-flow.sh https://raw.githubusercontent.com/t296tt39/wispyx-homeproxy/master/fix-nv8443-flow.sh
   sh /tmp/fix-nv8443-flow.sh
   /etc/init.d/homeproxy restart

   Если wget нет — правки руками:
   /etc/homeproxy/scripts/generate_client.uc
     было: flow: node.vless_flow,
     стало: flow: ("" + node.port === "8443") ? null : node.vless_flow,
   /etc/homeproxy/scripts/update_subscriptions.uc
     config.vless_flow = (config.port === '8443') ? null : (ob.flow || null);
     в parse URI: если url.port 8443 → vless_flow null, иначе как было (params.flow при tls/reality).
   Для каждой ноды port=8443: uci delete homeproxy.<id>.vless_flow
   uci commit homeproxy
   /etc/init.d/homeproxy restart

2) Проверка (без ключей в отчёт):
   jsonfilter -i /var/run/homeproxy/hiddify-c.json -e '@.outbounds[@.tag="main-out"].flow'
     пусто = ок
   jsonfilter ... '@.outbounds[@.tag="main-out"].server'
     == uci address выбранной страны
   Clash /proxies/main-out/delay gstatic generate_204 не 65535
   ipinfo через mixed-порт 5330: страна совпадает с выбранной нодой (Норвегия может быть Berlin SERV.HOST — так размечена железка)

3) После смены страны в LuCI: один restart HomeProxy и дёрнуть Wi‑Fi клиента. interrupt_exist_connections не включать.

Не требуй Vision «чтобы туннель жил». Не factory-reset. hp.uc из этого репо: пустой flow на *.wispyx.net = first-line F.
```

---

Скопируй агенту блок ниже целиком (полный накат флота).

````
Роутер OpenWrt, HomeProxy, ядро hiddify (или sing-box если hiddify нет). Это wispyx. Секреты/uuid/ключи/тела подписки не печатай. В git не пушь.

Перед плюшками: сними снимок текущих routing_rule / youtube_node / yt_* / valve / PS5, сверь с золотом этого промпта, затем СНЕСИ все routing_rule и yt_/youtube_node и поставь золотой набор заново. Ноды подписки (страны/обходы) не удалять. Factory-reset HomeProxy запрещён.

Цель: интернет, обходы TSPU, игры (PS5/CoD), ИИ, RU-сервисы. Порядок шагов обязательный, не переставляй.

Рабочий транспорт для main: VLESS TCP REALITY **:8443 без Vision** (пустой `vless_flow`). HomeProxy с пустым flow **работает**. Не требуй Vision «чтобы туннель жил».
Протокол-пинг: HTTPS generate_204 (или gstatic) через mixed-порт / Clash API / hiddify-core srun. ICMP ping запрещён — врёт.

Первая линия (кандидаты в main): прямые страны, **порт 8443, flow пустой**
🇵🇱 Польша pl2.srv:8443, 🇫🇮 Финляндия fn.srv:8443, 🇳🇱 Нидерланды nl3.srv:8443 (не origin steal), 🇩🇪 Германия de.srv.wispyx.net:8443, 🇸🇪 Швеция sw.srv:8443, 🇳🇴 Норвегия nr.srv:8443, 🇺🇸 США us.srv:8443 если протокол живой, 🇦🇹 Австрия au.srv:8443.
Не первая линия: «🚀 АВТОРЕЖИМ», auto.wispyx.net, Wi‑Fi WS, Hy2, XHTTP, 🌐 CDN, stolen SNI (yastatic/avito/cdnjs), «Обход …», «Мост …», ru2/br/usbr, прямой Kamatera IP. Ноды не с `*.wispyx.net` в main и в голову urltest не ставить.
Старый inbound :443+Vision на ноде может ещё существовать для кэша Happ — на роутере карточка страны должна быть **:8443 и без flow**.

Вторая линия (fallback, не main пока первая жива):
🇵🇱 Обход Польша ru2:443, 🇫🇮 Обход Финляндия / Мост, 🇺🇸 Обход США usbr:8445.
Их мерять отдельно, писать в отчёт как запас.

════════════════════════════════
ШАГ 1 — ПОДПИСКА (обязательно, не пропускай)
════════════════════════════════
- Найди URL подписки wispyx (uci homeproxy / LuCI Subscription).
- Прямо сейчас скачай и обнови ноды: `ucode /etc/homeproxy/scripts/update_subscriptions.uc` (или кнопка Update в LuCI). Дождись импорта. Без свежих нод ничего не меряй.
- Сразу патч leftover Vision (иначе Update вернёт `xtls-rprx-vision` на `:8443`, нода мертва, чекер IP = старая страна): `wget -O /tmp/fix-nv8443-flow.sh https://raw.githubusercontent.com/t296tt39/wispyx-homeproxy/master/fix-nv8443-flow.sh && sh /tmp/fix-nv8443-flow.sh` затем один `/etc/init.d/homeproxy restart`. JSON `main-out.flow` должен быть пустой.
- Повесь часовой cron, идемпотентно, маркер `#wispyx-hp-sub`, не дублируй:
  `0 * * * * /etc/homeproxy/scripts/update_crond.sh; ucode /usr/share/wispyx/hp.uc ensure >/dev/null 2>&1 #wispyx-hp-sub`
  `sed -i '/#wispyx-hp-sub/d' /etc/crontabs/root` затем допиши строку, `/etc/init.d/cron reload`.
  `ensure` без рестарта ядра: fragment, NV-8443 flow strip, urltest не расширять за пять стран (сначала `hp.uc remember` всех F+S, потом pin DE/FI/NL/PL/NR).
- `uci set homeproxy.subscription.auto_update=1` и `update_via_proxy=1`. Штатный `auto_update_time` — раз в сутки, его не хватает; часовой `#wispyx-hp-sub` init.d не затирает (он трогает только `#homeproxy_autosetup`).
- После каждого обновления подписки:
  1) сотри leftover Vision на first-line: для каждой страны `*.srv.wispyx.net` с `port=8443` сделай `uci delete homeproxy.<id>.vless_flow`. Импортёр после Update часто снова пишет `xtls-rprx-vision` — хендшейк на NV-8443 мёртвый, чекер показывает **прошлый** IP.
     Патч на роутере (обязательно, иначе через час Vision вернётся):
     - `generate_client.uc`: `flow: ("" + node.port === "8443") ? null : node.vless_flow,`
     - `update_subscriptions.uc`: при `port==8443` `vless_flow=null` (и в parse URI, и в parse SINGBOX outbound)
     - `hp.uc ensure` удаляет `vless_flow` с нод `:8443`
     После патча даже грязный UCI не попадёт в JSON.
  2) пересобери члены urltest (UUID нод могли смениться).
  **Ядро не рестартить**, если generate_204 через main-out живой — иначе рвёт PS5/CoD. Исключение: сменил `main_node` или починил flow/catch-all — **один** `homeproxy restart`, иначе UCI «Германия», а `hiddify-c.json` ещё старый выход (`interrupt_exist_connections=0` держит старые TCP).
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
- proxy_calls = 0
- proxy_ru_rule refilter = on, node = main-out
- proxy_ru_rule russia-inside = on, node = main-out

TSPU на домовых провайдерах режет прямой зарубеж (Google, Microsoft, Akamai, Fastly).
`proxy_banned_ru` сам по себе шлёт в VPN только «запрещёнку», остальное идёт direct и умирает.
Не ставь routing_mode=global — тогда пропадут кастомные RU-direct правила.
Не надейся на routing.default_outbound: в режиме proxy_banned_ru final всегда direct-out.

Нужен catch-all ПОСЛЕДНИМ среди routing_rule:
- секция `foreign_via_vpn` (не дублируй)
- enabled=1, action=route, outbound=main-out
- **обязательно** `ip_cidr` `0.0.0.0/0` и `::/0`
Пустой матчер (без доменов/портов/CIDR) **не попадает** в `hiddify-c.json`. Тогда `route.final=direct-out` и зарубеж (YouTube/Google) идёт в ISP/TSPU, хотя Clash `/proxies/main-out/delay` зелёный.
Проверка: `grep 0.0.0.0/0 /var/run/homeproxy/hiddify-c.json` — должна быть строка. Нет строки = правило мёртвое.
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

C) FanDuel → **🇺🇸 США**, не main страны
   `fanduel_proxy` outbound **нельзя** ставить в UUID ноды — `generate_client.uc` умрёт («node is missing»). Нужен `routing_node`:
   - найди карточку `us.srv.wispyx.net:8443` (лейбл 🇺🇸 США), сотри у неё leftover Vision, fragment 10-20, firefox;
   - `uci set homeproxy.fanduel_us=routing_node`, enabled=1, `node=<id этой карточки>`, outbound у routing_node не ставить (это detour);
   - `uci set homeproxy.fanduel_proxy.outbound=fanduel_us`, domain_suffix `fanduel.com`.
   Нет карточки США — временно main-out, в отчёте напиши.

D–F) Телега / CoD / BF1 → **Hy2 той же страны, что urltest**, не VLESS main-out.
   Подписка Happ/SINGBOX Hy2 **не эмитит**. Карточки только руками в UCI, не factory-reset.
   Одна `routing_node` `tspu_hy2` (не две на один Hy2 tag — generate падает). `game_hy2` если был — `enabled=0`.
   Карточки `type=hysteria2` port 443 tls=1 tls_sni=тот же хост tls_alpn=h3 tls_insecure=0 hysteria_up/down_mbps=100.
   Пароль = UUID VLESS **этого** аккаунта (`uci get` с карточки страны), в отчёт не писать.
   `hy2de`→de.srv `hy2fi`→fn.srv `hy2nl`→nl3.srv `hy2pl`→pl2.srv `hy2nr`→nr.srv. Не класть Hy2 в urltest и не в main.
   `tspu_hy2.node` стартует с `hy2de`. Следилка `/usr/bin/wispyx-hp-hy2-follow` (файл в этом репо), cron `* * * * * … #wispyx-hp-hy2`: Clash `main-out.now` → страна → та же Hy2. Два одинаковых выбора подряд, потом reload. Без default route — exit 0.
   Маппинг: DE→hy2de FI→hy2fi NL→hy2nl PL→hy2pl NR→hy2nr. Нет карточки — hy2de.
   Правила (port/port_range, не dest_port; иначе матчер пустой и сожрёт весь UDP):
   - telegram_proxy → tspu_hy2: telegram.org t.me td.es telegram.me tdesktop.com telegram-cdn.org telesco.pe telegra.ph
   - telegram_ip_proxy → tspu_hy2: 149.154.160.0/20 91.108.4.0/22 91.108.8.0/22 91.108.12.0/22 91.108.16.0/22 91.108.36.0/23 91.108.56.0/22
   - cod_ips_proxy → tspu_hy2: 185.34.106.0/23 185.92.222.0/24
   - cod_ports_proxy → tspu_hy2: TCP+UDP 3074 3075, ranges 3478:3480 27014:27050 30000:32000
   - bf1_ports_proxy → tspu_hy2: 3659 5222 9988 17502 22990 42127, ranges 14000:14016 22990:23006 25200:25300 20000:20100
   Не вешать 80/443 в игровые правила. ps5_global_proxy не должен перехватывать приставку раньше портовых правил.

G) YouTube / QUIC
   Реклама YouTube режется **на Xray ноды** (country VLESS → серверный YouTube hop). На роутере отдельных YT-нод нет и не будет.
   quic_drop: udp dest_port 443 → reject (youtube.com, googlevideo.com, ytimg.com, youtu.be, youtubei.googleapis.com, ggpht.com).
   youtube/googlevideo/ytimg → **main-out** той же first-line страны, что и весь зарубеж. catch-all `foreign_via_vpn` это уже делает; если секция `youtube_proxy` есть — outbound=`main-out`.
   ЗАПРЕЩЕНО: клонировать ноды `yt_*`, urltest `youtube_node`, youtube_proxy на Обход/usbr/Wi‑Fi/АВТО, класть YT-копии в main urltest, тащить YouTube на прямой US, менять main из-за YouTube.
   YouTube через двуххоп-обход зависает (QUIC) и **минует** серверный ads-hop. hp.uc ensure не должен создавать yt_ копии; watchdog не переключает YouTube-ноды.

Порядок правил после сноса: private/LAN direct; PS5 если найден; RU-сервисы direct (.ru/.su/.рф); quic_drop; youtube_proxy → main-out; ИИ → main-out; FanDuel → fanduel_us; Telegram+DC / CoD / BF1 → tspu_hy2; valve_direct только если был в снимке; последним foreign_via_vpn → main-out. Catch-all пересоздать последним (порядок секций = порядок JSON).

apply HomeProxy, дождаться ядра.

════════════════════════════════
ШАГ 4 — ВТОРОЙ ЗАМЕР (после плюшек)
════════════════════════════════
Снова протокол-пинг первой линии (fragment уже включён — цифры другие).
Потом отдельно вторая линия (мосты/обходы).
main_node = лучший стабильный из ПЕРВОЙ линии по этому замеру.
Вторую линию в main ставь только если первая снова вся fail/>800ms/флап.
Запиши в отчёт обе таблицы (до и после fragment) и какой main выбран.

Америка с роутера: FanDuel = карточка us.srv:8443 через `fanduel_us`. Остальной US-трафик — urltest VLESS, не прямой Kamatera IP.
Финка если прямой fn.srv мёртв — Обход/Мост как запас, не как первый выбор.
Hy2 не main и не член urltest. Карточки Hy2 на HomeProxy живые (DE/FI/NL/PL/NR).

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
- interval 30s, tolerance 100 ms.
- Члены urltest **ровно пять**, VLESS TCP REALITY :8443 пустой flow, в этом порядке:
  🇩🇪 de.srv  🇫🇮 fn.srv  🇳🇱 nl3.srv  🇵🇱 pl2.srv  🇳🇴 nr.srv
- НЕ класть в urltest: SE/AT/US, АВТОРЕЖИМ, Wi‑Fi, Hy2, XHTTP, CDN, stolen SNI, Обход/Мост, Kamatera/fatal.
- Мосты не в urltest: watchdog берёт S только если все пять F мертвы.
- После pin: `ucode /usr/share/wispyx/hp.uc remember` (все F+S в `/etc/wispyx-hp-known`), иначе hourly ensure допишет SE/AT/US.
- main_node = `urltest` (нативная группа HomeProxy), не одиночная нода и не лейбл АВТОРЕЖИМ.
Ядро само уведёт трафик на самый быстрый живой. Пока страны живы, мост с 350ms не победит. Если все страны timeout — возьмёт обход.

B) Watchdog, даже если urltest есть
Скрипт /usr/bin/wispyx-hp-watch (или /etc/homeproxy.d/), cron каждые 5 минут. Идемпотентно, не плодить crontab.
Нет default route (роутер без WAN) — **не** вешай `*/5` watchdog: generate_204 мёртв → петля рестартов. Закомментируй `#*/5 … #wispyx-hp-watch`. Как появился WAN — раскомментируй.
Логика:
1) HTTPS generate_204 через mixed-порт (часто 127.0.0.1:5330) timeout 8s. 204 = ок, выйти.
2) Два фейла подряд (флаг /tmp/wispyx-hp-fail, не переключать с первого глюка).
3) Протокол-пинг списка: сначала первая линия (F), потом вторая (S). Кандидаты: VLESS TCP REALITY **:8443, flow пустой или vision**, адрес `*.wispyx.net`. После рестарта ядра первый Clash часто 800+ мс — не переключай по одной пробе, вторая обычно 150–250.
4) Взять самый быстрый стабильный (2 ок из 2, или 2 из 3 если флапал).
5) Если текущий main уже этот — не трогать и **не рестартить** ядро. Clash /delay таймаут ≠ смерть ноды. Иначе uci set homeproxy.config.main_node, apply, **reload** (не `/etc/init.d/homeproxy restart` на */5). Готовый скрипт: `wispyx-hp-watch` в этом репо.
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
- Не класть мосты первыми в urltest — только хвост (класс S).
- Не требовать Vision на :8443. Не оставлять `vless_flow=xtls-rprx-vision` на first-line после импорта.
- Не менять `main_node` без последующего `homeproxy restart` (один раз) и проверки `jsonfilter … main-out.server` == UCI address. LuCI-лейбл ≠ живой IP.
- Не ставить catch-all без `0.0.0.0/0`.
- Не убивать watchdog: он нужен. Чини **classify** (`hp.uc` из этого репо), не cron.
- Не включать interrupt_exist_connections — рвёт игры.
- Не ставить main на АВТОРЕЖИМ / Wi‑Fi / Hy2 / XHTTP / CDN / steal.
- Не класть Hy2 в urltest. Не слать Телегу/CoD/BF1 в VLESS, если tspu_hy2 жив.
- Не расширять urltest за DE/FI/NL/PL/NR (SE/AT/US только если явно сказали).
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
- cron `0 * * * * ... update_crond.sh; ucode /usr/share/wispyx/hp.uc ensure … #wispyx-hp-sub` есть ровно одна строка
- cron `17 1 * * * /usr/bin/wispyx-hp-daily #wispyx-hp-daily` есть ровно одна строка
- cron `* * * * * /usr/bin/wispyx-hp-hy2-follow #wispyx-hp-hy2` есть; watchdog `*/5` есть **только если есть default route**
- подписка только что обновлена в этом прогоне (не «уже стояла вчера»)
- PS5 /32 → main-out или «не найден»
- ru_services_direct с ru/su/xn--p1ai, ai_domains_proxy, quic_drop на месте
- telegram/telegram_ip/cod_*/bf1 → tspu_hy2; JSON hysteria2 есть; urltest без Hy2
- show_advanced_rules=1 и catch-all `foreign_via_vpn` → main-out последним, в JSON есть `0.0.0.0/0`
- youtube.com ролик открывается через main-out (нет секций `yt_*` / `youtube_node`)
- АВТОРЕЖИМ не выбран; urltest = DE FI NL PL NR
- leftover Vision на :8443 = 0; interrupt_exist_connections=0; proxy_calls=0
- `ucode /usr/share/wispyx/hp.uc classify`: страны `*.srv.wispyx.net` `:8443` = **F**, Обход = S. Если DE нет в F — leftover Vision на карточке или старый hp.uc (требует `xtls-rprx-vision`). Положи `hp.uc` из этого репо в `/usr/share/wispyx/hp.uc`.
- Живой выход: `jsonfilter -i /var/run/homeproxy/hiddify-c.json -e '@.outbounds[@.tag="main-out"].server'` == UCI address выбранной страны. ipinfo через mixed-порт должен совпасть со страной main (DE → Германия, не Австрия). Не печатай IP в отчёт.
- FanDuel: outbound `fanduel_us`, не main-out.

Отчёт: снимок старых routing_rule / что снесли / что поставили заново / таблица пингов шаг 2 / таблица шаг 4 / main_node / urltest члены / cron watchdog да-нет / запасной мост / PS5 / YouTube outbound=main-out / yt_ нет.
````

## Кенту в Telegram

Репозиторий: https://github.com/t296tt39/wispyx-homeproxy

«открой README, скопируй блок агенту одним куском. Сначала обновить подписку и cron раз в час (+ hp.uc ensure). После импорта сотри Vision с стран :8443. Рестарт ядра — раз в сутки ночью плюс один раз если сменил main. Перед плюшками: снимок старых routing_rule, снести все правила и yt_ копии, накатить золото (подписку не ресетить). Catch-all с 0.0.0.0/0. urltest ровно DE/FI/NL/PL/NR. Телега/CoD/BF1 в Hy2 той же страны (wispyx-hp-hy2-follow). YouTube/ИИ/интернет — VLESS urltest. Мосты запас. Watchdog не вешать без WAN.»
