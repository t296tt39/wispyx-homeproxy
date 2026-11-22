#!/usr/bin/ucode
// wispyx helper: classify | frag | ensure | remember  [confdir]
'use strict';
import { cursor } from 'uci';
import { readfile, writefile, unlink } from 'fs';

const cmd = ARGV[0] || 'classify';
const uci = ARGV[1] ? cursor(ARGV[1], ARGV[1] + '/.save') : cursor();
const C = 'homeproxy';
uci.load(C);
const KNOWN = '/etc/wispyx-hp-known';
const SECOND = ['ru2.srv.wispyx.net', 'br.srv.wispyx.net', 'br2.srv.wispyx.net', 'usbr.srv.wispyx.net'];
const FIRST = /^(pl2|fn|nl[0-9]*|de|sw|nr|us|au)\.(srv|test)\.wispyx\.net$/;
const BAD = /(Россия|Авто|АВТО|авто|Wi.{0,3}Fi|WIFI|wifi|CDN|LTE|Hysteria|XHTTP)/;

function cls(n) {
	if (n.type !== 'vless') return null;
	if (substr(n['.name'], 0, 3) === 'yt_') return null;
	const a = lc(n.address || ''), l = n.label || '';
	if (!match(a, /\.wispyx\.net$/)) return null;
	if (n.transport && n.transport !== 'tcp') return null;
	if (n.tls_reality !== '1') return null;
	const flow = n.vless_flow || '';
	if (flow !== '' && flow !== 'xtls-rprx-vision') return null;
	if (match(l, BAD)) return null;
	if (n.tls_sni && lc(n.tls_sni) !== a) return null;
	const copy = match(l, /COPY/);
	if (index(SECOND, a) >= 0) return copy ? 'X' : 'S';
	if (match(a, FIRST)) return copy ? 'X' : 'F';
	return null;
}

let nodes = [];
uci.foreach(C, 'node', (n) => {
	const c = cls(n);
	if (c) push(nodes, { id: n['.name'], c: c, a: lc(n.address || ''), l: n.label || '' });
});

if (cmd === 'classify') {
	for (let n in nodes) printf('%s\t%s\t%s\t%s\n', n.c, n.id, n.a, n.l);
	exit(0);
}

let changed = false, soft = false;
function setv(id, k, v) {
	if (uci.get(C, id, k) !== v) { uci.set(C, id, k, v); changed = true; }
}

if (cmd === 'frag' || cmd === 'ensure') {
	for (let n in nodes) {
		if (uci.get(C, n.id, 'tls_fragment') !== '1') {
			setv(n.id, 'tls_fragment', '1');
			setv(n.id, 'tls_fragment_size', '10-20');
			setv(n.id, 'tls_fragment_sleep', '10-20');
		}
		setv(n.id, 'tls_utls', (n.c === 'F') ? 'firefox' : 'chrome');
	}
}

const fs_ids = map(filter(nodes, (n) => n.c === 'F' || n.c === 'S'), (n) => n.id);

if (cmd === 'remember') {
	writefile(KNOWN, join('\n', fs_ids) + '\n');
	exit(0);
}

if (cmd === 'ensure') {
	let known = filter(split(trim(readfile(KNOWN) || ''), '\n'), (x) => length(x));
	let cur = uci.get(C, 'config', 'main_urltest_nodes') || [];
	if (type(cur) !== 'array') cur = [cur];
	let curF = [], curS = [];
	for (let id in cur) {
		let n = filter(nodes, (x) => x.id === id)[0];
		if (!n || n.c === 'X') continue;
		push((n.c === 'F') ? curF : curS, id);
	}
	let newF = [], newS = [];
	for (let n in nodes) {
		if (n.c === 'X' || index(known, n.id) >= 0 || index(cur, n.id) >= 0) continue;
		push((n.c === 'F') ? newF : newS, n.id);
	}
	let allS = [...curS, ...newS];
	const sidx = (id) => index(SECOND, filter(nodes, (x) => x.id === id)[0].a);
	allS = sort(allS, (x, y) => sidx(x) - sidx(y));
	let desired = [...curF, ...newF, ...allS];
	if (length(known) && join(',', desired) !== join(',', cur)) {
		uci.set(C, 'config', 'main_urltest_nodes', desired);
		if (uci.get(C, 'config', 'main_node') === 'urltest') changed = true; else soft = true;
	}
	writefile(KNOWN, join('\n', fs_ids) + '\n');
	// YouTube ads path is Xray on the country node. Never clone yt_ bypass copies.
	uci.foreach(C, 'node', (n) => {
		if (substr(n['.name'], 0, 3) === 'yt_') { uci.delete(C, n['.name']); changed = true; }
	});
	if (uci.get(C, 'youtube_node')) { uci.delete(C, 'youtube_node'); changed = true; }
	unlink('/etc/wispyx-hp-yt');
	uci.foreach(C, 'node', (n) => {
		if (('' + n.port) === '8443' && n.vless_flow) {
			uci.delete(C, n['.name'], 'vless_flow');
			changed = true;
		}
	});

}

if (changed || soft) uci.commit(C);
if (changed) print('changed\n');
else if (soft) print('soft\n');
