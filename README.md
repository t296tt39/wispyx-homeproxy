# wispyx × OpenWrt HomeProxy

Промпт для агента на роутере. Подписка wispyx уже должна быть в HomeProxy.

Подписка даёт **только ноды**. Фрагментация, маршруты, ИИ, PS5 в UCI сами не приедут.

Секреты, UUID, ключи, тело подписки в отчёт не писать.

На части роутеров настройки уже стоят частично: **merge**, не factory-reset HomeProxy, не дублировать секции, не сносить рабочие правила.

---

Скопируй агенту блок ниже целиком.

````
Роутер OpenWrt, HomeProxy, ядро hiddify (или sing-box если hiddify нет). Это wispyx. Часть настроек уже может быть — не сноси рабочие правила, не дублируй секции. Сверь UCI, допиши недостающее, оставь то что уже совпадает. Секреты/uuid/ключи/тела подписки не печатай. В git не пушь.

Цель: интернет, обходы TSPU, игры (PS5/CoD), ИИ, RU-сервисы — как на эталоне «облако 1».

════════════════════════════════
0) СНАЧАЛА ПОДПИСКА
════════════════════════════════
- Найди URL подписки wispyx (uci homeproxy / LuCI Subscription).
- Скачай и обнови ноды. Дождись импорта.
- Подписка даёт ТОЛЬКО ноды. Маршруты, tls_fragment, PS5, ИИ сами НЕ приедут. Это надо прописать в UCI.
- После импорта не выбирай main_node = «🚀 АВТОРЕЖИМ» / auto.wispyx.net — на HomeProxy это заглушка, не балансер.
- Не ставь main: Wi‑Fi WS, Hy2, XHTTP, 🌐 CDN, stolen SNI (yastatic/avito/cdnjs). На этом ядре они мёртвые или прямой EU IP.

Рабочий транспорт: только VLESS TCP REALITY + Vision.

════════════════════════════════
1) ЯДРО И РЕЖИМ
════════════════════════════════
uci:
- preferred_core = hiddify (если пакета нет — sing-box)
- packet_encoding = xudp
- routing_mode = proxy_banned_ru
- default_outbound = direct-out
- proxy_mode = redirect_tproxy
- proxy_ru_rule refilter = on, node = main-out
- proxy_ru_rule russia-inside = on, node = main-out

Если uci commit Access denied — uci apply с rollback 90с, не откатывай удачные правки.

════════════════════════════════
2) ФРАГМЕНТАЦИЯ (обязательно, подписка её не пишет)
════════════════════════════════
На КАЖДОЙ wispyx-ноде VLESS TCP REALITY (страны + мосты/обходы REALITY):
- tls_fragment = 1
- tls_fragment_size = 10-20
- tls_fragment_sleep = 10-20
- tls_utls: firefox на странах (🇵🇱 Польша, Финка, NL, DE, SE, NO, US direct, AT)
- tls_utls: chrome на мостах/обходах (Обход Польша ru2, Мост/Мост+ FI, Обход США usbr, stolen SNI если вдруг импортировались)

Wi‑Fi WS / Hy2 / XHTTP не трогать (на ядре всё равно не живут).
Не снимай fragment с нод, где он уже стоит.

════════════════════════════════
3) ОСНОВНОЙ ВЫХОД
════════════════════════════════
- main_node = видимая «🇵🇱 Польша» / «Наша Польша» — pl2.srv.wispyx.net:443, firefox, fragment, Vision.
- Если протокол-пинг HTTPS (не ICMP) на Польшу > 800ms или fail — main_node = «🇵🇱 Обход Польша» (ru2.srv:443, chrome). Это двуххоп через Москву.
- Америка: только «🇺🇸 Обход США» (usbr.srv:8445), не прямой US IP.
- Финка из РФ: «🇫🇮 Обход Финляндия» / Мост, не прямой fn.srv если TSPU режет EU.
- Австрия Hy2 на HomeProxy не поднимается — не делать main.

Протокол-пинг: HTTPS generate_204 через mixed-порт/Clash API, не ping ICMP.

════════════════════════════════
4) НАЙТИ PS5 И КИНУТЬ В ТУННЕЛЬ
════════════════════════════════
Не хардкодь чужой LAN-IP — на каждом роутере свой.

Найди приставку:
- DHCP/ARP/соседи: hostname PlayStation / PS5 / PS4, vendor Sony.
- Если правило ps5_global_proxy уже есть и IP живой — оставь, только проверь enabled и destination main-out.
- Если нашла — routing_rule source_ip_cidr <IP>/32 → main-out, enabled, имя ps5_global_proxy (или не дублируй существующее).
- Если приставок несколько — все в туннель отдельными /32 или одним списком.
- Если PS5 нет в LAN — не выдумывай IP, напиши «PS5 не найден».
- Полный VPN приставки. Не выключай это правило «для чистоты».
- LAN-IP приставки НЕ класть в шаблон подписки панели. Только локальный UCI этого роутера.

════════════════════════════════
5) МАРШРУТЫ (слить без дублей)
════════════════════════════════
Создай/почини, не плоди копии с тем же смыслом:

A) ru_services_direct → direct-out
   суффиксы/домены: rutube.ru, vk.com, vk.ru, ok.ru, wildberries.ru, gosuslugi.ru, yandex.ru, yandex.net, ya.ru, dzen.ru, mail.ru, sber.ru, tinkoff.ru, tbank.ru, avito.ru, ozon.ru, nalog.ru, mos.ru
   (если секция уже шире — не сужай)

B) ai_domains_proxy → main-out
   .ai, openai.com, chatgpt.com, anthropic.com, claude.ai,
   cognition.com, devinapps.com, devinenterprise.com,
   cursor.com, cursor.sh, groq.com, grok.com, x.ai,
   githubcopilot.com, copilot.microsoft.com,
   perplexity.ai, poe.com, huggingface.co, midjourney.com, stability.ai, runwayml.com
   Не выкидывай уже прописанные ИИ-домены.

C) fanduel_proxy → main-out
   fanduel.com (и www)

D) telegram_proxy → main-out
   telegram.org, t.me, td.es, telegram.me, tdesktop.com + DC IP если уже были в UCI — сохрани

E) cod_ips_proxy → main-out
   185.34.106.0/23
   185.92.222.0/24

F) cod_ports_proxy → main-out
   TCP+UDP: 3074, 3075, 3478-3480, 27014-27050, 30000-32000
   (Steam/CS/CoD. Не режь, если диапазон уже шире.)

G) proxy_ru_rule как в п.1 (refilter + russia-inside → main-out)

H) YouTube / QUIC (обязательно, иначе на «Обход Польша» ролик зависает при живом google.com)
   YouTube лезет в UDP 443 (QUIC). Через двуххоп Москва→Польша соединение часто встаёт, TCP при этом живой.
   1) Правило `quic_drop`: network udp, dest_port 443 → reject/block. Весь TUN или хотя бы:
      youtube.com, googlevideo.com, ytimg.com, youtu.be, youtubei.googleapis.com, ggphosted.com
      YouTube остаётся на текущем main (Польша или Обход Польша), но по TCP. Main не менять.
   2) Если после quic_drop крутилка живая: правило `youtube_proxy` этих доменов на обычную «🇵🇱 Польша» (pl2.srv:443), не на Обход. Main не трогать.
   3) Если pl2 с этого WAN не встаёт (поэтому main и есть Обход): youtube_proxy → «🇺🇸 Обход США» (usbr.srv:8445).
   Не пускать YouTube на голый Kamatera / «fatal» / прямой US IP.
   Не решать «мост режет YouTube» сменой main на US.

Порядок: private/LAN direct; PS5 full tunnel; RU-сервисы direct; quic_drop; youtube_proxy если нужен; ИИ/FanDuel/Telegram/CoD в VPN; остальное по proxy_banned_ru.

════════════════════════════════
6) ЧЕГО НЕ ДЕЛАТЬ
════════════════════════════════
- Не отключать PS5/CoD «чтобы почистить».
- Не ставить main на Wi‑Fi, Hy2, XHTTP, CDN, АВТОРЕЖИМ, stolen SNI.
- Не тащить YouTube на прямой US/Kamatera, пока не стоит quic_drop (udp/443 block).
- Не ждать, что обновление подписки само включит fragment и route.rules.
- Не писать IP приставки в общую подписку панели.
- Не сносить чужие локальные правила (гостевые сетки, wan_direct, уже рабочие routing_rule) если они не конфликтуют.
- На части роутеров это уже стоит частично — merge, не factory-reset HomeProxy.

════════════════════════════════
7) ПРИМЕНЕНИЕ И ПРОВЕРКА
════════════════════════════════
1) Обновить подписку.
2) Проставить fragment на VLESS REALITY.
3) main_node Польша (или Обход Польша если прямой fail).
4) Правила + PS5.
5) apply HomeProxy, подождать ядро.
6) Проверить:
   - Clash API :9090 жив
   - HTTPS generate_204 через mixed-порт
   - uci: tls_fragment=1 на wispyx VLESS
   - main_node = Польша или Обход Польша
   - PS5 /32 → main-out если нашли
   - ru_services_direct, ai_domains_proxy, cod_* на месте
   - quic_drop udp/443 → reject
   - youtube.com открывается (ролик, не только google.com)
   - АВТОРЕЖИМ не выбран
Отчёт агента: что уже было / что дописал / IP PS5 или «не найден» / какой main_node / пинг Польши протоколом / YouTube: quic_drop и через какой outbound.
````

## Кенту в Telegram

Репозиторий: https://github.com/t296tt39/wispyx-homeproxy

Или: «открой README, скопируй блок агенту на роутер одним куском».
