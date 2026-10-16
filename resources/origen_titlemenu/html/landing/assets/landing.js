(function(){"use strict";/**
* @vue/shared v3.5.43
* (c) 2018-present Yuxi (Evan) You and Vue contributors
* @license MIT
**/function on(e){const a=Object.create(null);for(const o of e.split(","))a[o]=1;return o=>o in a}const Z={},ca=[],qe=()=>{},Wn=()=>!1,lo=e=>e.charCodeAt(0)===111&&e.charCodeAt(1)===110&&(e.charCodeAt(2)>122||e.charCodeAt(2)<97),co=e=>e.startsWith("onUpdate:"),fe=Object.assign,nn=(e,a)=>{const o=e.indexOf(a);o>-1&&e.splice(o,1)},st=Object.prototype.hasOwnProperty,W=(e,a)=>st.call(e,a),D=Array.isArray,oa=e=>Pa(e)==="[object Map]",uo=e=>Pa(e)==="[object Set]",Jn=e=>Pa(e)==="[object Date]",F=e=>typeof e=="function",ne=e=>typeof e=="string",Pe=e=>typeof e=="symbol",J=e=>e!==null&&typeof e=="object",Qn=e=>(J(e)||F(e))&&F(e.then)&&F(e.catch),Zn=Object.prototype.toString,Pa=e=>Zn.call(e),lt=e=>Pa(e).slice(8,-1),Yn=e=>Pa(e)==="[object Object]",rn=e=>ne(e)&&e!=="NaN"&&e[0]!=="-"&&""+parseInt(e,10)===e,Na=on(",key,ref,ref_for,ref_key,onVnodeBeforeMount,onVnodeMounted,onVnodeBeforeUpdate,onVnodeUpdated,onVnodeBeforeUnmount,onVnodeUnmounted"),po=e=>{const a=Object.create(null);return o=>a[o]||(a[o]=e(o))},ct=/-\w/g,ye=po(e=>e.replace(ct,a=>a.slice(1).toUpperCase())),dt=/\B([A-Z])/g,da=po(e=>e.replace(dt,"-$1").toLowerCase()),mo=po(e=>e.charAt(0).toUpperCase()+e.slice(1)),tn=po(e=>e?`on${mo(e)}`:""),Ne=(e,a)=>!Object.is(e,a),sn=(e,...a)=>{for(let o=0;o<e.length;o++)e[o](...a)},er=(e,a,o,n=!1)=>{Object.defineProperty(e,a,{configurable:!0,enumerable:!1,writable:n,value:o})},ut=e=>{const a=parseFloat(e);return isNaN(a)?e:a};let ar;const fo=()=>ar||(ar=typeof globalThis<"u"?globalThis:typeof self<"u"?self:typeof window<"u"?window:typeof global<"u"?global:{});function X(e){if(D(e)){const a={};for(let o=0;o<e.length;o++){const n=e[o],r=ne(n)?ht(n):X(n);if(r)for(const i in r)a[i]=r[i]}return a}else if(ne(e)||J(e))return e}const pt=/;(?![^(]*\))/g,mt=/:([^]+)/,ft=/"(?:[^"\\]|\\[^])*"|'(?:[^'\\]|\\[^])*'|\\[^]|\/\*[^]*?\*\//g;function ht(e){const a={};return e.replace(ft,o=>o.startsWith("/*")?"":o).split(pt).forEach(o=>{if(o){const n=o.split(mt);n.length>1&&(a[n[0].trim()]=n[1].trim())}}),a}function ho(e){let a="";if(ne(e))a=e;else if(D(e))for(let o=0;o<e.length;o++){const n=ho(e[o]);n&&(a+=n+" ")}else if(J(e))for(const o in e)e[o]&&(a+=o+" ");return a.trim()}const gt=on("itemscope,allowfullscreen,formnovalidate,ismap,nomodule,novalidate,readonly");function or(e){return!!e||e===""}function bt(e,a,o){if(e.length!==a.length)return!1;let n=!0;for(let r=0;n&&r<e.length;r++)n=go(e[r],a[r],o);return n}function nr(e,a,o){if(e.size!==a.size)return!1;const n=Array.from(a),r=new Uint8Array(n.length);for(const i of e){let l=-1;for(let t=0;t<n.length;t++)if(!r[t]&&go(i,n[t],o)){l=t;break}if(l<0)return!1;r[l]=1}return!0}function vt(e,a,o){let n=oa(e),r=oa(a);if(n||r||(n=uo(e),r=uo(a),n||r))return n&&r?nr(e,a,o):!1;const i=Object.keys(e).length,l=Object.keys(a).length;if(i!==l)return!1;for(const t in e){const s=e.hasOwnProperty(t),u=a.hasOwnProperty(t);if(s&&!u||!s&&u||!go(e[t],a[t],o))return!1}return String(e)===String(a)}function rr(e,a,o,n){o||(o=[new Map,new Map]);const[r,i]=o;if(r.has(e)||i.has(a))return r.get(e)===a&&i.get(a)===e;r.set(e,a),i.set(a,e);const l=n(e,a,o);return r.delete(e),i.delete(a),l}function go(e,a,o){if(e===a)return!0;let n=Jn(e),r=Jn(a);return n||r?n&&r?e.getTime()===a.getTime():!1:(n=Pe(e),r=Pe(a),n||r?e===a:(n=D(e),r=D(a),n||r?n&&r?rr(e,a,o,bt):!1:(n=J(e),r=J(a),n||r?!n||!r?!1:rr(e,a,o,vt):String(e)===String(a))))}const ir=e=>!!(e&&e.__v_isRef===!0),V=e=>ne(e)?e:e==null?"":D(e)||J(e)&&(e.toString===Zn||!F(e.toString))?ir(e)?V(e.value):JSON.stringify(e,tr,2):String(e),tr=(e,a)=>ir(a)?tr(e,a.value):oa(a)?{[`Map(${a.size})`]:[...a.entries()].reduce((o,[n,r],i)=>(o[ln(n,i)+" =>"]=r,o),{})}:uo(a)?{[`Set(${a.size})`]:[...a.values()].map(o=>ln(o))}:Pe(a)?ln(a):J(a)&&!D(a)&&!Yn(a)?String(a):a,ln=(e,a="")=>{var o;return Pe(e)?`Symbol(${(o=e.description)!=null?o:a})`:e};/**
* @vue/reactivity v3.5.43
* (c) 2018-present Yuxi (Evan) You and Vue contributors
* @license MIT
**/let de;class yt{constructor(a=!1){this.detached=a,this._active=!0,this._on=0,this.effects=[],this.cleanups=[],this._isPaused=!1,this._warnOnRun=!0,this.__v_skip=!0,!a&&de&&(de.active?(this.parent=de,this.index=(de.scopes||(de.scopes=[])).push(this)-1):(this._active=!1,this._warnOnRun=!1))}get active(){return this._active}pause(){if(this._active){this._isPaused=!0;let a,o;if(this.scopes){const n=this.scopes.slice();for(a=0,o=n.length;a<o;a++)n[a].pause()}for(a=0,o=this.effects.length;a<o;a++)this.effects[a].pause()}}resume(){if(this._active&&this._isPaused){this._isPaused=!1;let a,o;if(this.scopes){const r=this.scopes.slice();for(a=0,o=r.length;a<o;a++)r[a].resume()}const n=this.effects.slice();for(a=0,o=n.length;a<o;a++)n[a].resume()}}run(a){if(this._active){const o=de;try{return de=this,a()}finally{de=o}}}on(){++this._on===1&&(this.prevScope=de,de=this)}off(){if(this._on>0&&--this._on===0){if(de===this)de=this.prevScope;else{let a=de;for(;a;){if(a.prevScope===this){a.prevScope=this.prevScope;break}a=a.prevScope}}this.prevScope=void 0}}stop(a){if(this._active){this._active=!1;let o,n;for(o=0,n=this.effects.length;o<n;o++)this.effects[o].stop();for(this.effects.length=0,o=0,n=this.cleanups.length;o<n;o++)this.cleanups[o]();if(this.cleanups.length=0,this.scopes){const r=this.scopes.slice();for(o=0,n=r.length;o<n;o++)r[o].stop(!0);this.scopes.length=0}if(!this.detached&&this.parent&&!a){const r=this.parent.scopes.pop();r&&r!==this&&(this.parent.scopes[this.index]=r,r.index=this.index)}this.parent=void 0}}}function xt(){return de}let ee;const cn=new WeakSet;class sr{constructor(a){this.fn=a,this.deps=void 0,this.depsTail=void 0,this.flags=5,this.next=void 0,this.cleanup=void 0,this.scheduler=void 0,de&&(de.active?de.effects.push(this):this.flags&=-2)}pause(){this.flags|=64}resume(){this.flags&64&&(this.flags&=-65,cn.has(this)&&(cn.delete(this),this.trigger()))}notify(){this.flags&2&&!(this.flags&32)||this.flags&8||cr(this)}run(){if(!(this.flags&1))return this.fn();this.flags|=2,fr(this),dr(this);const a=ee,o=ze;ee=this,ze=!0;try{return this.fn()}finally{ur(this),ee=a,ze=o,this.flags&=-3}}stop(){if(this.flags&1){for(let a=this.deps;a;a=a.nextDep)mn(a);this.deps=this.depsTail=void 0,fr(this),this.onStop&&this.onStop(),this.flags&=-2}}trigger(){this.flags&64?cn.add(this):this.scheduler?this.scheduler():this.runIfDirty()}runIfDirty(){pn(this)&&this.run()}get dirty(){return pn(this)}}let lr=0,Ia,Oa;function cr(e,a=!1){if(e.flags|=8,a){e.next=Oa,Oa=e;return}e.next=Ia,Ia=e}function dn(){lr++}function un(){if(--lr>0)return;if(Oa){let a=Oa;for(Oa=void 0;a;){const o=a.next;a.next=void 0,a.flags&=-9,a=o}}let e;for(;Ia;){let a=Ia;for(Ia=void 0;a;){const o=a.next;if(a.next=void 0,a.flags&=-9,a.flags&1)try{a.trigger()}catch(n){e||(e=n)}a=o}}if(e)throw e}function dr(e){for(let a=e.deps;a;a=a.nextDep)a.version=-1,a.prevActiveLink=a.dep.activeLink,a.dep.activeLink=a}function ur(e){let a,o=e.depsTail,n=o;for(;n;){const r=n.prevDep;n.version===-1?(n===o&&(o=r),mn(n),wt(n)):a=n,n.dep.activeLink=n.prevActiveLink,n.prevActiveLink=void 0,n=r}e.deps=a,e.depsTail=o}function pn(e){for(let a=e.deps;a;a=a.nextDep)if(a.dep.version!==a.version||a.dep.computed&&(pr(a.dep.computed)||a.dep.version!==a.version))return!0;return!!e._dirty}function pr(e){if(e.flags&4&&!(e.flags&16)||(e.flags&=-17,e.globalVersion===Ta)||(e.globalVersion=Ta,!e.isSSR&&e.flags&128&&(!e.deps&&!e._dirty||!pn(e))))return;e.flags|=2;const a=e.dep,o=ee,n=ze;ee=e,ze=!0;try{dr(e);const r=e.fn(e._value);(a.version===0||Ne(r,e._value))&&(e.flags|=128,e._value=r,a.version++)}catch(r){throw a.version++,r}finally{ee=o,ze=n,ur(e),e.flags&=-3}}function mn(e,a=!1){const{dep:o,prevSub:n,nextSub:r}=e;if(n&&(n.nextSub=r,e.prevSub=void 0),r&&(r.prevSub=n,e.nextSub=void 0),o.subs===e&&(o.subs=n,!n&&o.computed)){o.computed.flags&=-5;for(let i=o.computed.deps;i;i=i.nextDep)mn(i,!0)}!a&&!--o.sc&&o.map&&o.map.delete(o.key)}function wt(e){const{prevDep:a,nextDep:o}=e;a&&(a.nextDep=o,e.prevDep=void 0),o&&(o.prevDep=a,e.nextDep=void 0)}let ze=!0;const mr=[];function Ie(){mr.push(ze),ze=!1}function Oe(){const e=mr.pop();ze=e===void 0?!0:e}function fr(e){const{cleanup:a}=e;if(e.cleanup=void 0,a){const o=ee;ee=void 0;try{a()}finally{ee=o}}}let Ta=0;class Ct{constructor(a,o){this.sub=a,this.dep=o,this.version=o.version,this.nextDep=this.prevDep=this.nextSub=this.prevSub=this.prevActiveLink=void 0}}class fn{constructor(a){this.computed=a,this.version=0,this.activeLink=void 0,this.subs=void 0,this.map=void 0,this.key=void 0,this.sc=0,this.__v_skip=!0}track(a){if(!ee||!ze||ee===this.computed)return;let o=this.activeLink;if(o===void 0||o.sub!==ee)o=this.activeLink=new Ct(ee,this),ee.deps?(o.prevDep=ee.depsTail,ee.depsTail.nextDep=o,ee.depsTail=o):ee.deps=ee.depsTail=o,hr(o);else if(o.version===-1&&(o.version=this.version,o.nextDep)){const n=o.nextDep;n.prevDep=o.prevDep,o.prevDep&&(o.prevDep.nextDep=n),o.prevDep=ee.depsTail,o.nextDep=void 0,ee.depsTail.nextDep=o,ee.depsTail=o,ee.deps===o&&(ee.deps=n)}return o}trigger(a){this.version++,Ta++,this.notify(a)}notify(a){dn();try{for(let o=this.subs;o;o=o.prevSub)o.sub.notify()&&o.sub.dep.notify()}finally{un()}}}function hr(e){if(e.dep.sc++,e.sub.flags&4){const a=e.dep.computed;if(a&&!e.dep.subs){a.flags|=20;for(let n=a.deps;n;n=n.nextDep)hr(n)}const o=e.dep.subs;o!==e&&(e.prevSub=o,o&&(o.nextSub=e)),e.dep.subs=e}}const hn=new WeakMap,ua=Symbol(""),gn=Symbol(""),$a=Symbol("");function he(e,a,o){if(ze&&ee){let n=hn.get(e);n||hn.set(e,n=new Map);let r=n.get(o);r||(n.set(o,r=new fn),r.map=n,r.key=o),r.track()}}function Ke(e,a,o,n,r,i){const l=hn.get(e);if(!l){Ta++;return}const t=s=>{s&&s.trigger()};if(dn(),a==="clear")l.forEach(t);else{const s=D(e),u=s&&rn(o);if(s&&o==="length"){const d=Number(n);l.forEach((m,A)=>{(A==="length"||A===$a||!Pe(A)&&A>=d)&&t(m)})}else switch((o!==void 0||l.has(void 0))&&t(l.get(o)),u&&t(l.get($a)),a){case"add":s?u&&t(l.get("length")):(t(l.get(ua)),oa(e)&&t(l.get(gn)));break;case"delete":s||(t(l.get(ua)),oa(e)&&t(l.get(gn)));break;case"set":oa(e)&&t(l.get(ua));break}}un()}function wa(e){const a=G(e);return a===e||(he(a,"iterate",$a),Le(e))?a:$e(e)?na(e)?a.map(o=>ra(ke(o))):a.map(ra):a.map(ke)}function bo(e){return he(e=G(e),"iterate",$a),e}function Te(e,a){return $e(e)?ra(na(e)?ke(a):a):ke(a)}const St={__proto__:null,[Symbol.iterator](){return bn(this,Symbol.iterator,e=>Te(this,e))},concat(...e){return wa(this).concat(...e.map(a=>D(a)?wa(a):a))},entries(){return bn(this,"entries",e=>(e[1]=Te(this,e[1]),e))},every(e,a){return Ge(this,"every",e,a,void 0,arguments)},filter(e,a){return Ge(this,"filter",e,a,o=>o.map(n=>Te(this,n)),arguments)},find(e,a){return Ge(this,"find",e,a,o=>Te(this,o),arguments)},findIndex(e,a){return Ge(this,"findIndex",e,a,void 0,arguments)},findLast(e,a){return Ge(this,"findLast",e,a,o=>Te(this,o),arguments)},findLastIndex(e,a){return Ge(this,"findLastIndex",e,a,void 0,arguments)},forEach(e,a){return Ge(this,"forEach",e,a,void 0,arguments)},includes(...e){return vn(this,"includes",e)},indexOf(...e){return vn(this,"indexOf",e)},join(e){return wa(this).join(e)},lastIndexOf(...e){return vn(this,"lastIndexOf",e)},map(e,a){return Ge(this,"map",e,a,void 0,arguments)},pop(){return Ra(this,"pop")},push(...e){return Ra(this,"push",e)},reduce(e,...a){return gr(this,"reduce",e,a)},reduceRight(e,...a){return gr(this,"reduceRight",e,a)},shift(){return Ra(this,"shift")},some(e,a){return Ge(this,"some",e,a,void 0,arguments)},splice(...e){return Ra(this,"splice",e)},toReversed(){return wa(this).toReversed()},toSorted(e){return wa(this).toSorted(e)},toSpliced(...e){return wa(this).toSpliced(...e)},unshift(...e){return Ra(this,"unshift",e)},values(){return bn(this,"values",e=>Te(this,e))}};function bn(e,a,o){const n=bo(e),r=n[a]();return n!==e&&!Le(e)&&(r._next=r.next,r.next=()=>{const i=r._next();return i.done||(i.value=o(i.value)),i}),r}const At=Array.prototype;function Ge(e,a,o,n,r,i){const l=bo(e),t=l!==e&&!Le(e),s=l[a];if(s!==At[a]){const m=s.apply(e,i);return t?ke(m):m}let u=o;l!==e&&(t?u=function(m,A){return o.call(this,Te(e,m),A,e)}:o.length>2&&(u=function(m,A){return o.call(this,m,A,e)}));const d=s.call(l,u,n);return t&&r?r(d):d}function gr(e,a,o,n){const r=bo(e),i=r!==e&&!Le(e);let l=o,t=!1;r!==e&&(i?(t=n.length===0,l=function(u,d,m){return t&&(t=!1,u=Te(e,u)),o.call(this,u,Te(e,d),m,e)}):o.length>3&&(l=function(u,d,m){return o.call(this,u,d,m,e)}));const s=r[a](l,...n);return t?Te(e,s):s}function vn(e,a,o){const n=G(e);he(n,"iterate",$a);const r=n[a](...o);return(r===-1||r===!1)&&wn(o[0])?(o[0]=G(o[0]),n[a](...o)):r}function Ra(e,a,o=[]){Ie(),dn();const n=G(e)[a].apply(e,o);return un(),Oe(),n}const Mt=on("__proto__,__v_isRef,__isVue"),br=new Set(Object.getOwnPropertyNames(Symbol).filter(e=>e!=="arguments"&&e!=="caller").map(e=>Symbol[e]).filter(Pe));function _t(e){Pe(e)||(e=String(e));const a=G(this);return he(a,"has",e),a.hasOwnProperty(e)}class vr{constructor(a=!1,o=!1){this._isReadonly=a,this._isShallow=o}get(a,o,n){if(o==="__v_skip")return a.__v_skip;const r=this._isReadonly,i=this._isShallow;if(o==="__v_isReactive")return!r;if(o==="__v_isReadonly")return r;if(o==="__v_isShallow")return i;if(o==="__v_raw")return n===(r?i?Ar:Sr:i?Cr:wr).get(a)||Object.getPrototypeOf(a)===Object.getPrototypeOf(n)?a:void 0;const l=D(a);if(!r){let s;if(l&&(s=St[o]))return s;if(o==="hasOwnProperty")return _t}const t=Reflect.get(a,o,ue(a)?a:n);if((Pe(o)?br.has(o):Mt(o))||(r||he(a,"get",o),i))return t;if(ue(t)){const s=l&&rn(o)?t:t.value;return r&&J(s)?xn(s):s}return J(t)?r?xn(t):wo(t):t}}class yr extends vr{constructor(a=!1){super(!1,a)}set(a,o,n,r){let i=a[o];const l=D(a)&&rn(o);if(!this._isShallow){const u=$e(i);if(!Le(n)&&!$e(n)&&(i=G(i),n=G(n)),!l&&ue(i)&&!ue(n))return u||(i.value=n),!0}const t=l?Number(o)<a.length:W(a,o),s=Reflect.set(a,o,n,ue(a)?a:r);return a===G(r)&&s&&(t?Ne(n,i)&&Ke(a,"set",o,n):Ke(a,"add",o,n)),s}deleteProperty(a,o){const n=W(a,o);a[o];const r=Reflect.deleteProperty(a,o);return r&&n&&Ke(a,"delete",o,void 0),r}has(a,o){const n=Reflect.has(a,o);return(!Pe(o)||!br.has(o))&&he(a,"has",o),n}ownKeys(a){return he(a,"iterate",D(a)?"length":ua),Reflect.ownKeys(a)}}class xr extends vr{constructor(a=!1){super(!0,a)}set(a,o){return!0}deleteProperty(a,o){return!0}}const Lt=new yr,kt=new xr,zt=new yr(!0),Et=new xr(!0),yn=e=>e,vo=e=>Reflect.getPrototypeOf(e);function jt(e,a,o){return function(...n){const r=this.__v_raw,i=G(r),l=oa(i),t=e==="entries"||e===Symbol.iterator&&l,s=e==="keys"&&l,u=r[e](...n),d=o?yn:a?ra:ke;return!a&&he(i,"iterate",s?gn:ua),fe(Object.create(u),{next(){const{value:m,done:A}=u.next();return A?{value:m,done:A}:{value:t?[d(m[0]),d(m[1])]:d(m),done:A}}})}}function yo(e){return function(...a){return e==="delete"?!1:e==="clear"?void 0:this}}function qt(e,a){const o={get(r){const i=this.__v_raw,l=G(i),t=G(r);e||(Ne(r,t)&&he(l,"get",r),he(l,"get",t));const{has:s}=vo(l),u=a?yn:e?ra:ke;if(s.call(l,r))return u(i.get(r));if(s.call(l,t))return u(i.get(t));i!==l&&i.get(r)},get size(){const r=this.__v_raw;return!e&&he(G(r),"iterate",ua),r.size},has(r){const i=this.__v_raw,l=G(i),t=G(r);return e||(Ne(r,t)&&he(l,"has",r),he(l,"has",t)),r===t?i.has(r):i.has(r)||i.has(t)},forEach(r,i){const l=this,t=l.__v_raw,s=G(t),u=a?yn:e?ra:ke;return!e&&he(s,"iterate",ua),t.forEach((d,m)=>r.call(i,u(d),u(m),l))}};return fe(o,e?{add:yo("add"),set:yo("set"),delete:yo("delete"),clear:yo("clear")}:{add(r){const i=G(this),l=vo(i),t=G(r),s=!a&&!Le(r)&&!$e(r)?t:r;return l.has.call(i,s)||Ne(r,s)&&l.has.call(i,r)||Ne(t,s)&&l.has.call(i,t)||(i.add(s),Ke(i,"add",s,s)),this},set(r,i){!a&&!Le(i)&&!$e(i)&&(i=G(i));const l=G(this),{has:t,get:s}=vo(l);let u=t.call(l,r);u||(r=G(r),u=t.call(l,r));const d=s.call(l,r);return l.set(r,i),u?Ne(i,d)&&Ke(l,"set",r,i):Ke(l,"add",r,i),this},delete(r){const i=G(this),{has:l,get:t}=vo(i);let s=l.call(i,r);s||(r=G(r),s=l.call(i,r)),t&&t.call(i,r);const u=i.delete(r);return s&&Ke(i,"delete",r,void 0),u},clear(){const r=G(this),i=r.size!==0,l=r.clear();return i&&Ke(r,"clear",void 0,void 0),l}}),["keys","values","entries",Symbol.iterator].forEach(r=>{o[r]=jt(r,e,a)}),o}function xo(e,a){const o=qt(e,a);return(n,r,i)=>r==="__v_isReactive"?!e:r==="__v_isReadonly"?e:r==="__v_raw"?n:Reflect.get(W(o,r)&&r in n?o:n,r,i)}const Pt={get:xo(!1,!1)},Nt={get:xo(!1,!0)},It={get:xo(!0,!1)},Ot={get:xo(!0,!0)},wr=new WeakMap,Cr=new WeakMap,Sr=new WeakMap,Ar=new WeakMap;function Tt(e){switch(e){case"Object":case"Array":return 1;case"Map":case"Set":case"WeakMap":case"WeakSet":return 2;default:return 0}}function wo(e){return $e(e)?e:Co(e,!1,Lt,Pt,wr)}function $t(e){return Co(e,!1,zt,Nt,Cr)}function xn(e){return Co(e,!0,kt,It,Sr)}function ip(e){return Co(e,!0,Et,Ot,Ar)}function Co(e,a,o,n,r){if(!J(e)||e.__v_raw&&!(a&&e.__v_isReactive)||e.__v_skip||!Object.isExtensible(e))return e;const i=r.get(e);if(i)return i;const l=Tt(lt(e));if(l===0)return e;const t=new Proxy(e,l===2?n:o);return r.set(e,t),t}function na(e){return $e(e)?na(e.__v_raw):!!(e&&e.__v_isReactive)}function $e(e){return!!(e&&e.__v_isReadonly)}function Le(e){return!!(e&&e.__v_isShallow)}function wn(e){return e?!!e.__v_raw:!1}function G(e){const a=e&&e.__v_raw;return a?G(a):e}function Rt(e){return!W(e,"__v_skip")&&Object.isExtensible(e)&&er(e,"__v_skip",!0),e}const ke=e=>J(e)?wo(e):e,ra=e=>J(e)?xn(e):e;function ue(e){return e?e.__v_isRef===!0:!1}function se(e){return Dt(e,!1)}function Dt(e,a){return ue(e)?e:new Ft(e,a)}class Ft{constructor(a,o){this.dep=new fn,this.__v_isRef=!0,this.__v_isShallow=!1,this._rawValue=o?a:G(a),this._value=o?a:ke(a),this.__v_isShallow=o}get value(){return this.dep.track(),this._value}set value(a){const o=this._rawValue,n=this.__v_isShallow||Le(a)||$e(a);a=n?a:G(a),Ne(a,o)&&(this._rawValue=a,this._value=n?a:ke(a),this.dep.trigger())}}function ge(e){return ue(e)?e.value:e}const Bt={get:(e,a,o)=>a==="__v_raw"?e:ge(Reflect.get(e,a,o)),set:(e,a,o,n)=>{const r=e[a];return ue(r)&&!ue(o)?(r.value=o,!0):Reflect.set(e,a,o,n)}};function Mr(e){return na(e)?e:new Proxy(e,Bt)}class Ht{constructor(a,o,n){this.fn=a,this.setter=o,this._value=void 0,this.dep=new fn(this),this.__v_isRef=!0,this.deps=void 0,this.depsTail=void 0,this.flags=16,this.globalVersion=Ta-1,this.next=void 0,this.effect=this,this.__v_isReadonly=!o,this.isSSR=n}notify(){if(this.flags|=16,!(this.flags&8)&&ee!==this)return cr(this,!0),!0}get value(){const a=this.dep.track();return pr(this),a&&(a.version=this.dep.version),this._value}set value(a){this.setter&&this.setter(a)}}function Vt(e,a,o=!1){let n,r;return F(e)?n=e:(n=e.get,r=e.set),new Ht(n,r,o)}const So={},Ao=new WeakMap;let pa;function Ut(e,a=!1,o=pa){if(o){let n=Ao.get(o);n||Ao.set(o,n=[]),n.push(e)}}function Kt(e,a,o=Z){const{immediate:n,deep:r,once:i,scheduler:l,augmentJob:t,call:s}=o,u=N=>r?N:Le(N)||r===!1||r===0?Xe(N,1):Xe(N);let d,m,A,E,g=!1,b=!1;if(ue(e)?(m=()=>e.value,g=Le(e)):na(e)?(m=()=>u(e),g=!0):D(e)?(b=!0,g=e.some(N=>na(N)||Le(N)),m=()=>e.map(N=>{if(ue(N))return N.value;if(na(N))return u(N);if(F(N))return s?s(N,2):N()})):F(e)?a?m=s?()=>s(e,2):e:m=()=>{if(A){Ie();try{A()}finally{Oe()}}const N=pa;pa=d;try{return s?s(e,3,[E]):e(E)}finally{pa=N}}:m=qe,a&&r){const N=m,re=r===!0?1/0:r;m=()=>Xe(N(),re)}const j=xt(),q=()=>{d.stop(),j&&j.active&&nn(j.effects,d)};if(i&&a){const N=a;a=(...re)=>{const S=N(...re);return q(),S}}let w=b?new Array(e.length).fill(So):So;const $=N=>{if(!(!(d.flags&1)||!d.dirty&&!N))if(a){const re=d.run();if(N||r||g||(b?re.some((S,B)=>Ne(S,w[B])):Ne(re,w))){A&&A();const S=pa;pa=d;try{const B=[re,w===So?void 0:b&&w[0]===So?[]:w,E];w=re,s?s(a,3,B):a(...B)}finally{pa=S}}}else d.run()};return t&&t($),d=new sr(m),d.scheduler=l?()=>l($,!1):$,E=N=>Ut(N,!1,d),A=d.onStop=()=>{const N=Ao.get(d);if(N){if(s)s(N,4);else for(const re of N)re();Ao.delete(d)}},a?n?$(!0):w=d.run():l?l($.bind(null,!0),!0):d.run(),q.pause=d.pause.bind(d),q.resume=d.resume.bind(d),q.stop=q,q}function Xe(e,a=1/0,o){if(a<=0||!J(e)||e.__v_skip||(o=o||new Map,(o.get(e)||0)>=a))return e;if(o.set(e,a),a--,ue(e))Xe(e.value,a,o);else if(D(e))for(let n=0;n<e.length;n++)Xe(e[n],a,o);else if(uo(e)||oa(e))e.forEach(n=>{Xe(n,a,o)});else if(Yn(e)){for(const n in e)Xe(e[n],a,o);for(const n of Object.getOwnPropertySymbols(e))Object.prototype.propertyIsEnumerable.call(e,n)&&Xe(e[n],a,o)}return e}/**
* @vue/runtime-core v3.5.43
* (c) 2018-present Yuxi (Evan) You and Vue contributors
* @license MIT
**/const Da=[];let Cn=!1;function tp(e,...a){if(Cn)return;Cn=!0,Ie();const o=Da.length?Da[Da.length-1].component:null,n=o&&o.appContext.config.warnHandler,r=Gt();if(n)Ca(n,o,11,[e+a.map(i=>{var l,t;return(t=(l=i.toString)==null?void 0:l.call(i))!=null?t:JSON.stringify(i)}).join(""),o&&o.proxy,r.map(({vnode:i})=>`at <${Mi(o,i.type)}>`).join(`
`),r]);else{const i=[`[Vue warn]: ${e}`,...a];r.length&&i.push(`
`,...Xt(r)),console.warn(...i)}Oe(),Cn=!1}function Gt(){let e=Da[Da.length-1];if(!e)return[];const a=[];for(;e;){const o=a[0];o&&o.vnode===e?o.recurseCount++:a.push({vnode:e,recurseCount:0});const n=e.component&&e.component.parent;e=n&&n.vnode}return a}function Xt(e){const a=[];return e.forEach((o,n)=>{a.push(...n===0?[]:[`
`],...Wt(o))}),a}function Wt({vnode:e,recurseCount:a}){const o=a>0?`... (${a} recursive calls)`:"",n=e.component?e.component.parent==null:!1,r=` at <${Mi(e.component,e.type,n)}`,i=">"+o;return e.props?[r,...Jt(e.props),i]:[r+i]}function Jt(e){const a=[],o=Object.keys(e);return o.slice(0,3).forEach(n=>{a.push(..._r(n,e[n]))}),o.length>3&&a.push(" ..."),a}function _r(e,a,o){return ne(a)?(a=JSON.stringify(a),o?a:[`${e}=${a}`]):typeof a=="number"||typeof a=="boolean"||a==null?o?a:[`${e}=${a}`]:ue(a)?(a=_r(e,G(a.value),!0),o?a:[`${e}=Ref<`,a,">"]):F(a)?[`${e}=fn${a.name?`<${a.name}>`:""}`]:(a=G(a),o?a:[`${e}=`,a])}function Ca(e,a,o,n){try{return n?e(...n):e()}catch(r){Mo(r,a,o)}}function Ee(e,a,o,n){if(F(e)){const r=Ca(e,a,o,n);return r&&Qn(r)&&r.catch(i=>{Mo(i,a,o)}),r}if(D(e)){const r=[];for(let i=0;i<e.length;i++)r.push(Ee(e[i],a,o,n));return r}}function Mo(e,a,o,n=!0){const r=a?a.vnode:null,{errorHandler:i,throwUnhandledErrorInProduction:l}=a&&a.appContext.config||Z;if(a){let t=a.parent;const s=a.proxy,u=`https://vuejs.org/error-reference/#runtime-${o}`;for(;t;){const d=t.ec;if(d){for(let m=0;m<d.length;m++)if(d[m](e,s,u)===!1)return}t=t.parent}if(i){Ie(),Ca(i,null,10,[e,s,u]),Oe();return}}Qt(e,o,r,n,l)}function Qt(e,a,o,n=!0,r=!1){if(r)throw e;console.error(e)}const xe=[];let Re=-1;const Sa=[];let ia=null,Aa=0;const Lr=Promise.resolve();let _o=null;function Sn(e){const a=_o||Lr;return e?a.then(this?e.bind(this):e):a}function Zt(e){let a=Re+1,o=xe.length;for(;a<o;){const n=a+o>>>1,r=xe[n],i=Fa(r);i<e||i===e&&r.flags&2?a=n+1:o=n}return a}function An(e){if(!(e.flags&1)){const a=Fa(e),o=xe[xe.length-1];!o||!(e.flags&2)&&a>=Fa(o)?xe.push(e):xe.splice(Zt(a),0,e),e.flags|=1,kr()}}function kr(){_o||(_o=Lr.then(jr))}function Yt(e){if(!D(e))ia&&e.id===-1?ia.splice(Aa+1,0,e):e.flags&1||(Sa.push(e),e.flags|=1);else for(let a=0;a<e.length;a++)Sa.push(e[a]);kr()}function zr(e,a,o=Re+1){for(;o<xe.length;o++){const n=xe[o];if(n&&n.flags&2){if(e&&n.id!==e.uid)continue;xe.splice(o,1),o--,n.flags&4&&(n.flags&=-2),n(),n.flags&4||(n.flags&=-2)}}}function Er(e){if(Sa.length){const a=[...new Set(Sa)].sort((o,n)=>Fa(o)-Fa(n));if(Sa.length=0,ia){for(let o=0;o<a.length;o++)ia.push(a[o]);return}for(ia=a,Aa=0;Aa<ia.length;Aa++){const o=ia[Aa];o.flags&4&&(o.flags&=-2),o.flags&8||o(),o.flags&=-2}ia=null,Aa=0}}const Fa=e=>e.id==null?e.flags&2?-1:1/0:e.id;function jr(e){try{for(Re=0;Re<xe.length;Re++){const a=xe[Re];a&&!(a.flags&8)&&(a.flags&4&&(a.flags&=-2),Ca(a,a.i,a.i?15:14),a.flags&4||(a.flags&=-2))}}finally{for(;Re<xe.length;Re++){const a=xe[Re];a&&(a.flags&=-2)}Re=-1,xe.length=0,Er(),_o=null,(xe.length||Sa.length)&&jr()}}let Ae=null,qr=null;function Lo(e){const a=Ae;return Ae=e,qr=e&&e.type.__scopeId||null,a}function es(e,a=Ae,o){if(!a||e._n)return e;const n=(...r)=>{n._d&&fi(-1);const i=Lo(a),l=ha.length;let t;try{t=e(...r)}finally{for(let s=ha.length;s>l;s--)mi();Lo(i),n._d&&fi(1)}return t};return n._n=!0,n._c=!0,n._d=!0,n}function as(e,a){if(Ae===null)return e;const o=Do(Ae),n=e.dirs||(e.dirs=[]);for(let r=0;r<a.length;r++){let[i,l,t,s=Z]=a[r];i&&(F(i)&&(i={mounted:i,updated:i}),i.deep&&Xe(l),n.push({dir:i,instance:o,value:l,oldValue:void 0,arg:t,modifiers:s}))}return e}function ma(e,a,o,n){const r=e.dirs,i=a&&a.dirs;for(let l=0;l<r.length;l++){const t=r[l];i&&(t.oldValue=i[l].value);let s=t.dir[n];s&&(Ie(),Ee(s,o,8,[e.el,t,e,a]),Oe())}}function os(e,a){if(ve){let o=ve.provides;const n=ve.parent&&ve.parent.provides;n===o&&(o=ve.provides=Object.create(n)),o[e]=a}}function ko(e,a,o=!1){const n=Ys();if(n||Ma){let r=Ma?Ma._context.provides:n?n.parent==null||n.ce?n.vnode.appContext&&n.vnode.appContext.provides:n.parent.provides:void 0;if(r&&e in r)return r[e];if(arguments.length>1)return o&&F(a)?a.call(n&&n.proxy):a}}const ns=Symbol.for("v-scx"),rs=()=>ko(ns);function ta(e,a,o){return Pr(e,a,o)}function Pr(e,a,o=Z){const{immediate:n,deep:r,flush:i,once:l}=o,t=fe({},o),s=a&&n||!a&&i!=="post";let u;if(Qa){if(i==="sync"){const E=rs();u=E.__watcherHandles||(E.__watcherHandles=[])}else if(!s){const E=()=>{};return E.stop=qe,E.resume=qe,E.pause=qe,E}}const d=ve;t.call=(E,g,b)=>Ee(E,d,g,b);let m=!1;i==="post"?t.scheduler=E=>{Se(E,d&&d.suspense)}:i!=="sync"&&(m=!0,t.scheduler=(E,g)=>{g?E():An(E)}),t.augmentJob=E=>{a&&(E.flags|=4),m&&(E.flags|=2,d&&(E.id=d.uid,E.i=d))};const A=Kt(e,a,t);return Qa&&(u?u.push(A):s&&A()),A}function is(e,a,o){const n=this.proxy,r=ne(e)?e.includes(".")?Nr(n,e):()=>n[e]:e.bind(n,n);let i;F(a)?i=a:(i=a.handler,o=a);const l=Ja(this),t=Pr(r,i.bind(n),o);return l(),t}function Nr(e,a){const o=a.split(".");return()=>{let n=e;for(let r=0;r<o.length&&n;r++)n=n[o[r]];return n}}const ts=Symbol("_vte"),zo=e=>e.__isTeleport,Mn=Symbol("_leaveCb");function ss(e){let a=e[0];if(e.length>1){for(const o of e)if(o.type!==Je){a=o;break}}return a}function Ir(e){if(!Ln(e))return zo(e.type)&&e.children?ss(e.children):e;if(e.component)return e.component.subTree;const{shapeFlag:a,children:o}=e;if(o){if(a&16)return o[0];if(a&32&&F(o.default))return o.default()}}function _n(e,a){if(e.shapeFlag&6&&e.component){e.transition=a;const o=e.component.subTree;_n(zo(o.type)&&Ir(o)||o,a)}else e.shapeFlag&128?(e.ssContent.transition=a.clone(e.ssContent),e.ssFallback.transition=a.clone(e.ssFallback)):e.transition=a}function Or(e){e.ids=[e.ids[0]+e.ids[2]+++"-",0,0]}function Tr(e,a){let o;return!!((o=Object.getOwnPropertyDescriptor(e,a))&&!o.configurable)}const Eo=new WeakMap;function Ba(e,a,o,n,r=!1){if(D(e)){e.forEach((b,j)=>Ba(b,a&&(D(a)?a[j]:a),o,n,r));return}if(Ha(n)&&!r){n.shapeFlag&512&&n.type.__asyncResolved&&n.component.subTree.component&&Ba(e,a,o,n.component.subTree);return}const i=n.shapeFlag&4?Do(n.component):n.el,l=r?null:i,{i:t,r:s}=e,u=a&&a.r,d=t.refs===Z?t.refs={}:t.refs,m=t.setupState,A=G(m),E=m===Z?Wn:b=>Tr(d,b)?!1:W(A,b),g=(b,j)=>!(j&&Tr(d,j));if(u!=null&&u!==s){if($r(a),ne(u))d[u]=null,E(u)&&(m[u]=null);else if(ue(u)){const b=a;g(u,b.k)&&(u.value=null),b.k&&(d[b.k]=null)}}if(F(s))Ca(s,t,12,[l,d]);else{const b=ne(s),j=ue(s);if(b||j){const q=()=>{if(e.f){const w=b?E(s)?m[s]:d[s]:g()||!e.k?s.value:d[e.k];if(r)D(w)&&nn(w,i);else if(D(w))w.includes(i)||w.push(i);else if(b)d[s]=[i],E(s)&&(m[s]=d[s]);else{const $=[i];g(s,e.k)&&(s.value=$),e.k&&(d[e.k]=$)}}else b?(d[s]=l,E(s)&&(m[s]=l)):j&&(g(s,e.k)&&(s.value=l),e.k&&(d[e.k]=l))};if(l){const w=()=>{q(),Eo.delete(e)};w.id=-1,Eo.set(e,w),Se(w,o)}else $r(e),q()}}}function $r(e){const a=Eo.get(e);a&&(a.flags|=8,Eo.delete(e))}fo().requestIdleCallback,fo().cancelIdleCallback;const Ha=e=>!!e.type.__asyncLoader,Ln=e=>e.type.__isKeepAlive;function ls(e,a){Rr(e,"a",a)}function cs(e,a){Rr(e,"da",a)}function Rr(e,a,o=ve){const n=e.__wdc||(e.__wdc=()=>{let r=o;for(;r;){if(r.isDeactivated)return;r=r.parent}return e()});if(jo(a,n,o),o){let r=o.parent;for(;r&&r.parent;)Ln(r.parent.vnode)&&ds(n,a,o,r),r=r.parent}}function ds(e,a,o,n){const r=jo(a,e,n,!0);qo(()=>{nn(n[a],r)},o)}function jo(e,a,o=ve,n=!1){if(o){const r=o[e]||(o[e]=[]),i=a.__weh||(a.__weh=(...l)=>{Ie();const t=Ja(o),s=Ee(a,o,e,l);return t(),Oe(),s});return n?r.unshift(i):r.push(i),i}}const We=e=>(a,o=ve)=>{(!Qa||e==="sp")&&jo(e,(...n)=>a(...n),o)},us=We("bm"),Va=We("m"),ps=We("bu"),ms=We("u"),kn=We("bum"),qo=We("um"),fs=We("sp"),hs=We("rtg"),gs=We("rtc");function bs(e,a=ve){jo("ec",e,a)}const vs="components";function Dr(e,a){return xs(vs,e,!0,a)||e}const ys=Symbol.for("v-ndc");function xs(e,a,o=!0,n=!1){const r=Ae||ve;if(r){const i=r.type;{const t=Ai(i,!1);if(t&&(t===a||t===ye(a)||t===mo(ye(a))))return i}const l=Fr(r[e]||i[e],a)||Fr(r.appContext[e],a);return!l&&n?i:l}}function Fr(e,a){return e&&(e[a]||e[ye(a)]||e[mo(ye(a))])}function be(e,a,o,n){let r;const i=o,l=D(e);if(l||ne(e)){const t=l&&na(e);let s=!1,u=!1;t&&(s=!Le(e),u=$e(e),e=bo(e)),r=new Array(e.length);for(let d=0,m=e.length;d<m;d++)r[d]=a(s?u?ra(ke(e[d])):ke(e[d]):e[d],d,void 0,i)}else if(typeof e=="number"){r=new Array(e);for(let t=0;t<e;t++)r[t]=a(t+1,t,void 0,i)}else if(J(e))if(e[Symbol.iterator])r=Array.from(e,(t,s)=>a(t,s,void 0,i));else{const t=Object.keys(e);r=new Array(t.length);for(let s=0,u=t.length;s<u;s++){const d=t[s];r[s]=a(e[d],d,s,i)}}else r=[];return r}const zn=e=>e?wi(e)?Do(e):zn(e.parent):null,Ua=fe(Object.create(null),{$:e=>e,$el:e=>e.vnode.el,$data:e=>e.data,$props:e=>e.props,$attrs:e=>e.attrs,$slots:e=>e.slots,$refs:e=>e.refs,$parent:e=>zn(e.parent),$root:e=>zn(e.root),$host:e=>e.ce,$emit:e=>e.emit,$options:e=>Ur(e),$forceUpdate:e=>e.f||(e.f=()=>{An(e.update)}),$nextTick:e=>e.n||(e.n=Sn.bind(e.proxy)),$watch:e=>is.bind(e)}),En=(e,a)=>e!==Z&&!e.__isScriptSetup&&W(e,a),ws={get({_:e},a){if(a==="__v_skip")return!0;const{ctx:o,setupState:n,data:r,props:i,accessCache:l,type:t,appContext:s}=e;if(a[0]!=="$"){const A=l[a];if(A!==void 0)switch(A){case 1:return n[a];case 2:return r[a];case 4:return o[a];case 3:return i[a]}else{if(En(n,a))return l[a]=1,n[a];if(r!==Z&&W(r,a))return l[a]=2,r[a];if(W(i,a))return l[a]=3,i[a];if(o!==Z&&W(o,a))return l[a]=4,o[a];jn&&(l[a]=0)}}const u=Ua[a];let d,m;if(u)return a==="$attrs"&&he(e.attrs,"get",""),u(e);if((d=t.__cssModules)&&(d=d[a]))return d;if(o!==Z&&W(o,a))return l[a]=4,o[a];if(m=s.config.globalProperties,W(m,a))return m[a]},set({_:e},a,o){const{data:n,setupState:r,ctx:i}=e;return En(r,a)?(r[a]=o,!0):n!==Z&&W(n,a)?(n[a]=o,!0):W(e.props,a)||a[0]==="$"&&a.slice(1)in e?!1:(i[a]=o,!0)},has({_:{data:e,setupState:a,accessCache:o,ctx:n,appContext:r,props:i,type:l}},t){let s;return!!(o[t]||e!==Z&&t[0]!=="$"&&W(e,t)||En(a,t)||W(i,t)||W(n,t)||W(Ua,t)||W(r.config.globalProperties,t)||(s=l.__cssModules)&&s[t])},defineProperty(e,a,o){return o.get!=null?e._.accessCache[a]=0:W(o,"value")&&this.set(e,a,o.value,null),Reflect.defineProperty(e,a,o)}};function Br(e){return D(e)?e.reduce((a,o)=>(a[o]=null,a),{}):e}let jn=!0;function Cs(e){const a=Ur(e),o=e.proxy,n=e.ctx;jn=!1,a.beforeCreate&&Hr(a.beforeCreate,e,"bc");const{data:r,computed:i,methods:l,watch:t,provide:s,inject:u,created:d,beforeMount:m,mounted:A,beforeUpdate:E,updated:g,activated:b,deactivated:j,beforeDestroy:q,beforeUnmount:w,destroyed:$,unmounted:N,render:re,renderTracked:S,renderTriggered:B,errorCaptured:ie,serverPrefetch:Be,expose:aa,inheritAttrs:va,components:Zo,directives:Yo,filters:Gn}=a;if(u&&Ss(u,n,null),l)for(const te in l){const ae=l[te];F(ae)&&(n[te]=ae.bind(o))}if(r){const te=r.call(o,o);J(te)&&(e.data=wo(te))}if(jn=!0,i)for(const te in i){const ae=i[te],ya=F(ae)?ae.bind(o,o):F(ae.get)?ae.get.bind(o,o):qe,en=!F(ae)&&F(ae.set)?ae.set.bind(o):qe,xa=sa({get:ya,set:en});Object.defineProperty(n,te,{enumerable:!0,configurable:!0,get:()=>xa.value,set:je=>xa.value=je})}if(t)for(const te in t)Vr(t[te],n,o,te);if(s){const te=F(s)?s.call(o):s;Reflect.ownKeys(te).forEach(ae=>{os(ae,te[ae])})}d&&Hr(d,e,"c");function Ce(te,ae){D(ae)?ae.forEach(ya=>te(ya.bind(o))):ae&&te(ae.bind(o))}if(Ce(us,m),Ce(Va,A),Ce(ps,E),Ce(ms,g),Ce(ls,b),Ce(cs,j),Ce(bs,ie),Ce(gs,S),Ce(hs,B),Ce(kn,w),Ce(qo,N),Ce(fs,Be),D(aa))if(aa.length){const te=e.exposed||(e.exposed={});aa.forEach(ae=>{Object.defineProperty(te,ae,{get:()=>o[ae],set:ya=>o[ae]=ya,enumerable:!0})})}else e.exposed||(e.exposed={});re&&e.render===qe&&(e.render=re),va!=null&&(e.inheritAttrs=va),Zo&&(e.components=Zo),Yo&&(e.directives=Yo),Be&&Or(e)}function Ss(e,a,o=qe){D(e)&&(e=qn(e));for(const n in e){const r=e[n];let i;J(r)?"default"in r?i=ko(r.from||n,r.default,!0):i=ko(r.from||n):i=ko(r),ue(i)?Object.defineProperty(a,n,{enumerable:!0,configurable:!0,get:()=>i.value,set:l=>i.value=l}):a[n]=i}}function Hr(e,a,o){Ee(D(e)?e.map(n=>n.bind(a.proxy)):e.bind(a.proxy),a,o)}function Vr(e,a,o,n){let r=n.includes(".")?Nr(o,n):()=>o[n];if(ne(e)){const i=a[e];F(i)&&ta(r,i)}else if(F(e))ta(r,e.bind(o));else if(J(e))if(D(e))e.forEach(i=>Vr(i,a,o,n));else{const i=F(e.handler)?e.handler.bind(o):a[e.handler];F(i)&&ta(r,i,e)}}function Ur(e){const a=e.type,{mixins:o,extends:n}=a,{mixins:r,optionsCache:i,config:{optionMergeStrategies:l}}=e.appContext,t=i.get(a);let s;return t?s=t:!r.length&&!o&&!n?s=a:(s={},r.length&&r.forEach(u=>Po(s,u,l,!0)),Po(s,a,l)),J(a)&&i.set(a,s),s}function Po(e,a,o,n=!1){const{mixins:r,extends:i}=a;i&&Po(e,i,o,!0),r&&r.forEach(l=>Po(e,l,o,!0));for(const l in a)if(!(n&&l==="expose")){const t=As[l]||o&&o[l];e[l]=t?t(e[l],a[l]):a[l]}return e}const As={data:Kr,props:Gr,emits:Gr,methods:Ka,computed:Ka,beforeCreate:we,created:we,beforeMount:we,mounted:we,beforeUpdate:we,updated:we,beforeDestroy:we,beforeUnmount:we,destroyed:we,unmounted:we,activated:we,deactivated:we,errorCaptured:we,serverPrefetch:we,components:Ka,directives:Ka,watch:_s,provide:Kr,inject:Ms};function Kr(e,a){return a?e?function(){return fe(F(e)?e.call(this,this):e,F(a)?a.call(this,this):a)}:a:e}function Ms(e,a){return Ka(qn(e),qn(a))}function qn(e){if(D(e)){const a={};for(let o=0;o<e.length;o++)a[e[o]]=e[o];return a}return e}function we(e,a){return e?[...new Set([].concat(e,a))]:a}function Ka(e,a){return e?fe(Object.create(null),e,a):a}function Gr(e,a){return e?D(e)&&D(a)?[...new Set([...e,...a])]:fe(Object.create(null),Br(e),Br(a??{})):a}function _s(e,a){if(!e)return a;if(!a)return e;const o=fe(Object.create(null),e);for(const n in a)o[n]=we(e[n],a[n]);return o}function Xr(){return{app:null,config:{isNativeTag:Wn,performance:!1,globalProperties:{},optionMergeStrategies:{},errorHandler:void 0,warnHandler:void 0,compilerOptions:{}},mixins:[],components:{},directives:{},provides:Object.create(null),optionsCache:new WeakMap,propsCache:new WeakMap,emitsCache:new WeakMap}}let Ls=0;function ks(e,a){return function(n,r=null){F(n)||(n=fe({},n)),r!=null&&!J(r)&&(r=null);const i=Xr(),l=new WeakSet,t=[];let s=!1;const u=i.app={_uid:Ls++,_component:n,_props:r,_container:null,_context:i,_instance:null,version:sl,get config(){return i.config},set config(d){},use(d,...m){return l.has(d)||(d&&F(d.install)?(l.add(d),d.install(u,...m)):F(d)&&(l.add(d),d(u,...m))),u},mixin(d){return i.mixins.includes(d)||i.mixins.push(d),u},component(d,m){return m?(i.components[d]=m,u):i.components[d]},directive(d,m){return m?(i.directives[d]=m,u):i.directives[d]},mount(d,m,A){if(!s){const E=u._ceVNode||pe(n,r);return E.appContext=i,A===!0?A="svg":A===!1&&(A=void 0),e(E,d,A),s=!0,u._container=d,d.__vue_app__=u,Do(E.component)}},onUnmount(d){t.push(d)},unmount(){s&&(Ee(t,u._instance,16),e(null,u._container),delete u._container.__vue_app__)},provide(d,m){return i.provides[d]=m,u},runWithContext(d){const m=Ma;Ma=u;try{return d()}finally{Ma=m}}};return u}}let Ma=null;const zs=(e,a)=>a==="modelValue"||a==="model-value"?e.modelModifiers:e[`${a}Modifiers`]||e[`${ye(a)}Modifiers`]||e[`${da(a)}Modifiers`];function Es(e,a,...o){if(e.isUnmounted)return;const n=e.vnode.props||Z;let r=o;const i=a.startsWith("update:"),l=i&&zs(n,a.slice(7));l&&(l.trim&&(r=o.map(d=>ne(d)?d.trim():d)),l.number&&(r=r.map(ut)));let t,s=n[t=tn(a)]||n[t=tn(ye(a))];!s&&i&&(s=n[t=tn(da(a))]),s&&Ee(s,e,6,r);const u=n[t+"Once"];if(u){if(!e.emitted)e.emitted={};else if(e.emitted[t])return;e.emitted[t]=!0,Ee(u,e,6,r)}}const js=new WeakMap;function Wr(e,a,o=!1){const n=o?js:a.emitsCache,r=n.get(e);if(r!==void 0)return r;const i=e.emits;let l={},t=!1;if(!F(e)){const s=u=>{const d=Wr(u,a,!0);d&&(t=!0,fe(l,d))};!o&&a.mixins.length&&a.mixins.forEach(s),e.extends&&s(e.extends),e.mixins&&e.mixins.forEach(s)}return!i&&!t?(J(e)&&n.set(e,null),null):(D(i)?i.forEach(s=>l[s]=null):fe(l,i),J(e)&&n.set(e,l),l)}function No(e,a){return!e||!lo(a)?!1:(a=a.slice(2),a=a==="Once"?a:a.replace(/Once$/,""),W(e,a[0].toLowerCase()+a.slice(1))||W(e,da(a))||W(e,a))}function sp(){}function Jr(e){const{type:a,vnode:o,proxy:n,withProxy:r,propsOptions:[i],slots:l,attrs:t,emit:s,render:u,renderCache:d,props:m,data:A,setupState:E,ctx:g,inheritAttrs:b}=e,j=Lo(e);let q,w;try{if(o.shapeFlag&4){const N=r||n,re=N;q=De(u.call(re,N,d,m,E,A,g)),w=t}else{const N=a;q=De(N.length>1?N(m,{attrs:t,slots:l,emit:s}):N(m,null)),w=a.props?t:qs(t)}}catch(N){ha.length=0,Mo(N,e,1),q=pe(Je)}let $=q;if(w&&b!==!1){const N=Object.keys(w),{shapeFlag:re}=$;N.length&&re&7&&(i&&N.some(co)&&(w=Ps(w,i)),$=_a($,w,!1,!0))}if(o.dirs&&($=_a($,null,!1,!0),$.dirs=$.dirs?$.dirs.concat(o.dirs):o.dirs),o.transition){const N=zo($.type)&&Ir($)||$;_n(N,o.transition)}return q=$,Lo(j),q}const qs=e=>{let a;for(const o in e)(o==="class"||o==="style"||lo(o))&&((a||(a={}))[o]=e[o]);return a},Ps=(e,a)=>{const o={};for(const n in e)(!co(n)||!(n.slice(9)in a))&&(o[n]=e[n]);return o};function Ns(e,a,o){const{props:n,children:r,component:i}=e,{props:l,children:t,patchFlag:s}=a,u=i.emitsOptions;if(a.dirs||a.transition)return!0;if(o&&s>=0){if(s&1024)return!0;if(s&16)return n?Qr(n,l,u):!!l;if(s&8){const d=a.dynamicProps;for(let m=0;m<d.length;m++){const A=d[m];if(Zr(l,n,A)&&!No(u,A))return!0}}}else return(r||t)&&(!t||!t.$stable)?!0:n===l?!1:n?l?Qr(n,l,u):!0:!!l;return!1}function Qr(e,a,o){const n=Object.keys(a);if(n.length!==Object.keys(e).length)return!0;for(let r=0;r<n.length;r++){const i=n[r];if(Zr(a,e,i)&&!No(o,i))return!0}return!1}function Zr(e,a,o){const n=e[o],r=a[o];return o==="style"&&J(n)&&J(r)?!go(n,r):n!==r}function Is({vnode:e,parent:a,suspense:o},n){for(;a;){const r=a.subTree;if(r.suspense&&r.suspense.activeBranch===e&&(r.suspense.vnode.el=r.el=n,e=r),r===e)(e=a.vnode).el=n,a=a.parent;else break}o&&o.activeBranch===e&&(o.vnode.el=n)}const Yr={},ei=()=>Object.create(Yr),ai=e=>Object.getPrototypeOf(e)===Yr;function Os(e,a,o,n=!1){const r={},i=ei();e.propsDefaults=Object.create(null),oi(e,a,r,i);for(const l in e.propsOptions[0])l in r||(r[l]=void 0);o?e.props=n?r:$t(r):e.type.props?e.props=r:e.props=i,e.attrs=i}function Ts(e,a,o,n){const{props:r,attrs:i,vnode:{patchFlag:l}}=e,t=G(r),[s]=e.propsOptions;let u=!1;if((n||l>0)&&!(l&16)){if(l&8){const d=e.vnode.dynamicProps;for(let m=0;m<d.length;m++){let A=d[m];if(No(e.emitsOptions,A))continue;const E=a[A];if(s)if(W(i,A))E!==i[A]&&(i[A]=E,u=!0);else{const g=ye(A);r[g]=Pn(s,t,g,E,e,!1)}else E!==i[A]&&(i[A]=E,u=!0)}}}else{oi(e,a,r,i)&&(u=!0);let d;for(const m in t)(!a||!W(a,m)&&((d=da(m))===m||!W(a,d)))&&(s?o&&(o[m]!==void 0||o[d]!==void 0)&&(r[m]=Pn(s,t,m,void 0,e,!0)):delete r[m]);if(i!==t)for(const m in i)(!a||!W(a,m))&&(delete i[m],u=!0)}u&&Ke(e.attrs,"set","")}function oi(e,a,o,n){const[r,i]=e.propsOptions;let l=!1,t;if(a)for(let s in a){if(Na(s))continue;const u=a[s];let d;r&&W(r,d=ye(s))?!i||!i.includes(d)?o[d]=u:(t||(t={}))[d]=u:No(e.emitsOptions,s)||(!(s in n)||u!==n[s])&&(n[s]=u,l=!0)}if(i){const s=G(o),u=t||Z;for(let d=0;d<i.length;d++){const m=i[d];o[m]=Pn(r,s,m,u[m],e,!W(u,m))}}return l}function Pn(e,a,o,n,r,i){const l=e[o];if(l!=null){const t=W(l,"default");if(t&&n===void 0){const s=l.default;if(l.type!==Function&&!l.skipFactory&&F(s)){const{propsDefaults:u}=r;if(o in u)n=u[o];else{const d=Ja(r);n=u[o]=s.call(null,a),d()}}else n=s;r.ce&&r.ce._setProp(o,n)}l[0]&&(i&&!t?n=!1:l[1]&&(n===""||n===da(o))&&(n=!0))}return n}const $s=new WeakMap;function ni(e,a,o=!1){const n=o?$s:a.propsCache,r=n.get(e);if(r)return r;const i=e.props,l={},t=[];let s=!1;if(!F(e)){const d=m=>{s=!0;const[A,E]=ni(m,a,!0);fe(l,A),E&&t.push(...E)};!o&&a.mixins.length&&a.mixins.forEach(d),e.extends&&d(e.extends),e.mixins&&e.mixins.forEach(d)}if(!i&&!s)return J(e)&&n.set(e,ca),ca;if(D(i))for(let d=0;d<i.length;d++){const m=ye(i[d]);ri(m)&&(l[m]=Z)}else if(i)for(const d in i){const m=ye(d);if(ri(m)){const A=i[d],E=l[m]=D(A)||F(A)?{type:A}:fe({},A),g=E.type;let b=!1,j=!0;if(D(g))for(let q=0;q<g.length;++q){const w=g[q],$=F(w)&&w.name;if($==="Boolean"){b=!0;break}else $==="String"&&(j=!1)}else b=F(g)&&g.name==="Boolean";E[0]=b,E[1]=j,(b||W(E,"default"))&&t.push(m)}}const u=[l,t];return J(e)&&n.set(e,u),u}function ri(e){return e[0]!=="$"&&!Na(e)}const Nn=e=>e==="_"||e==="_ctx"||e==="$stable",In=e=>D(e)?e.map(De):[De(e)],Rs=(e,a,o)=>{if(a._n)return a;const n=es((...r)=>In(a(...r)),o);return n._c=!1,n},ii=(e,a,o)=>{const n=e._ctx;for(const r in e){if(Nn(r))continue;const i=e[r];if(F(i))a[r]=Rs(r,i,n);else if(i!=null){const l=In(i);a[r]=()=>l}}},ti=(e,a)=>{const o=In(a);e.slots.default=()=>o},si=(e,a,o)=>{for(const n in a)(o||!Nn(n))&&(e[n]=a[n])},Ds=(e,a,o)=>{const n=e.slots=ei();if(e.vnode.shapeFlag&32){const r=a._;r?(si(n,a,o),o&&er(n,"_",r,!0)):ii(a,n)}else a&&ti(e,a)},Fs=(e,a,o)=>{const{vnode:n,slots:r}=e;let i=!0,l=Z;if(n.shapeFlag&32){const t=a._;t?o&&t===1?i=!1:si(r,a,o):(i=!a.$stable,ii(a,r)),l=a}else a&&(ti(e,a),l={default:1});if(i)for(const t in r)!Nn(t)&&l[t]==null&&delete r[t]},Se=Ks;function Bs(e){return Hs(e)}function Hs(e,a){const o=fo();o.__VUE__=!0;const{insert:n,remove:r,patchProp:i,createElement:l,createText:t,createComment:s,setText:u,setElementText:d,parentNode:m,nextSibling:A,setScopeId:E=qe,insertStaticContent:g}=e,b=(c,p,f,C=null,v=null,x=null,z=void 0,k=null,L=!!p.dynamicChildren)=>{if(c===p)return;c&&!Xa(c,p)&&(C=an(c),je(c,v,x,!0),c=null),p.patchFlag===-2&&(L=!1,p.dynamicChildren=null),p.dynamicChildren&&c&&c.dynamicChildren&&c.dynamicChildren.hasOnce&&(p.dynamicChildren===ca&&(p.dynamicChildren=[]),p.dynamicChildren.hasOnce=!0);const{type:y,ref:O,shapeFlag:P}=p;switch(y){case Io:j(c,p,f,C);break;case Je:q(c,p,f,C);break;case Oo:c==null&&w(p,f,C,z);break;case H:Zo(c,p,f,C,v,x,z,k,L);break;default:P&1?re(c,p,f,C,v,x,z,k,L):P&6?Yo(c,p,f,C,v,x,z,k,L):(P&64||P&128)&&y.process(c,p,f,C,v,x,z,k,L,to)}O!=null&&v?Ba(O,c&&c.ref,x,p||c,!p):O==null&&c&&c.ref!=null&&Ba(c.ref,null,x,c,!0)},j=(c,p,f,C)=>{if(c==null)n(p.el=t(p.children),f,C);else{const v=p.el=c.el;p.children!==c.children&&u(v,p.children)}},q=(c,p,f,C)=>{c==null?n(p.el=s(p.children||""),f,C):p.el=c.el},w=(c,p,f,C)=>{[c.el,c.anchor]=g(c.children,p,f,C,c.el,c.anchor)},$=({el:c,anchor:p},f,C)=>{let v;for(;c&&c!==p;)v=A(c),n(c,f,C),c=v;n(p,f,C)},N=({el:c,anchor:p})=>{let f;for(;c&&c!==p;)f=A(c),r(c),c=f;r(p)},re=(c,p,f,C,v,x,z,k,L)=>{if(p.type==="svg"?z="svg":p.type==="math"&&(z="mathml"),c==null)S(p,f,C,v,x,z,k,L);else{const y=c.el&&c.el._isVueCE?c.el:null;try{y&&y._beginPatch(),Be(c,p,v,x,z,k,L)}finally{y&&y._endPatch()}}},S=(c,p,f,C,v,x,z,k)=>{let L,y;const{props:O,shapeFlag:P,transition:I,dirs:R}=c;if(L=c.el=l(c.type,x,O&&O.is,O),P&8?d(L,c.children):P&16&&ie(c.children,L,null,C,v,On(c,x),z,k),R&&ma(c,null,C,"created"),B(L,c,c.scopeId,z,C),O){for(const Y in O)Y!=="value"&&!Na(Y)&&i(L,Y,null,O[Y],x,C);"value"in O&&i(L,"value",null,O.value,x),(y=O.onVnodeBeforeMount)&&Fe(y,C,c)}R&&ma(c,null,C,"beforeMount");const K=Vs(v,I);K&&I.beforeEnter(L),n(L,p,f),((y=O&&O.onVnodeMounted)||K||R)&&Se(()=>{try{y&&Fe(y,C,c),K&&I.enter(L),R&&ma(c,null,C,"mounted")}finally{}},v)},B=(c,p,f,C,v)=>{if(f&&E(c,f),C)for(let x=0;x<C.length;x++)E(c,C[x]);if(v){let x=v.subTree;if(p===x||pi(x.type)&&(x.ssContent===p||x.ssFallback===p)){const z=v.vnode;B(c,z,z.scopeId,z.slotScopeIds,v.parent)}}},ie=(c,p,f,C,v,x,z,k,L=0)=>{for(let y=L;y<c.length;y++){const O=c[y]=k?Qe(c[y]):De(c[y]);b(null,O,p,f,C,v,x,z,k)}},Be=(c,p,f,C,v,x,z)=>{const k=p.el=c.el;let{patchFlag:L,dynamicChildren:y,dirs:O}=p;L|=c.patchFlag&16;const P=c.props||Z,I=p.props||Z;let R;if(f&&fa(f,!1),(R=I.onVnodeBeforeUpdate)&&Fe(R,f,p,c),O&&ma(p,c,f,"beforeUpdate"),f&&fa(f,!0),y&&(!c.dynamicChildren||c.dynamicChildren.length!==y.length)&&(L=0,z=!1,y=null),(P.innerHTML&&I.innerHTML==null||P.textContent&&I.textContent==null)&&d(k,""),y?aa(c.dynamicChildren,y,k,f,C,On(p,v),x):z||ae(c,p,k,null,f,C,On(p,v),x,!1),L>0){if(L&16)va(k,P,I,f,v);else if(L&2&&P.class!==I.class&&i(k,"class",null,I.class,v),L&4&&i(k,"style",P.style,I.style,v),L&8){const K=p.dynamicProps;for(let Y=0;Y<K.length;Y++){const Q=K[Y],ce=P[Q],me=I[Q];(me!==ce||Q==="value")&&i(k,Q,ce,me,v,f)}}L&1&&c.children!==p.children&&d(k,p.children)}else!z&&y==null&&va(k,P,I,f,v);((R=I.onVnodeUpdated)||O)&&Se(()=>{R&&Fe(R,f,p,c),O&&ma(p,c,f,"updated")},C)},aa=(c,p,f,C,v,x,z)=>{for(let k=0;k<p.length;k++){const L=c[k],y=p[k],O=L.el&&(L.type===H||!Xa(L,y)||L.shapeFlag&198)?m(L.el):f;b(L,y,O,null,C,v,x,z,!0)}},va=(c,p,f,C,v)=>{if(p!==f){if(p!==Z)for(const x in p)!Na(x)&&!(x in f)&&i(c,x,p[x],null,v,C);for(const x in f){if(Na(x))continue;const z=f[x],k=p[x];z!==k&&x!=="value"&&i(c,x,k,z,v,C)}"value"in f&&i(c,"value",p.value,f.value,v)}},Zo=(c,p,f,C,v,x,z,k,L)=>{const y=p.el=c?c.el:t(""),O=p.anchor=c?c.anchor:t("");let{patchFlag:P,dynamicChildren:I,slotScopeIds:R}=p;R&&(k=k?k.concat(R):R),c==null?(n(y,f,C),n(O,f,C),ie(p.children||[],f,O,v,x,z,k,L)):P>0&&P&64&&I&&c.dynamicChildren&&c.dynamicChildren.length===I.length?(aa(c.dynamicChildren,I,f,v,x,z,k),(p.key!=null||v&&p===v.subTree)&&li(c,p,!0)):ae(c,p,f,O,v,x,z,k,L)},Yo=(c,p,f,C,v,x,z,k,L)=>{p.slotScopeIds=k,c==null?p.shapeFlag&512?v.ctx.activate(p,f,C,z,L):Gn(p,f,C,v,x,z,L):at(c,p,L)},Gn=(c,p,f,C,v,x,z)=>{const k=c.component=Zs(c,C,v);if(Ln(c)&&(k.ctx.renderer=to),el(k,!1,z),k.asyncDep){if(v&&v.registerDep(k,Ce,z),!c.el){const L=k.subTree=pe(Je);q(null,L,p,f),c.placeholder=L.el}}else Ce(k,c,p,f,v,x,z)},at=(c,p,f)=>{const C=p.component=c.component;if(Ns(c,p,f))if(C.asyncDep&&!C.asyncResolved){p.el=c.el,te(C,p,f);return}else C.next=p,C.update();else p.el=c.el,C.vnode=p},Ce=(c,p,f,C,v,x,z)=>{const k=()=>{if(c.isMounted){let{next:P,bu:I,u:R,parent:K,vnode:Y}=c;{const Ve=ci(c);if(Ve){P&&(P.el=Y.el,te(c,P,z)),Ve.asyncDep.then(()=>{Se(()=>{c.isUnmounted||y()},v)});return}}let Q=P,ce;fa(c,!1),P?(P.el=Y.el,te(c,P,z)):P=Y,I&&sn(I),(ce=P.props&&P.props.onVnodeBeforeUpdate)&&Fe(ce,K,P,Y),fa(c,!0);const me=Jr(c),He=c.subTree;c.subTree=me,b(He,me,m(He.el),an(He),c,v,x),P.el=me.el,Q===null&&Is(c,me.el),R&&Se(R,v),(ce=P.props&&P.props.onVnodeUpdated)&&Se(()=>Fe(ce,K,P,Y),v)}else{let P;const{el:I,props:R}=p,{bm:K,m:Y,parent:Q,root:ce,type:me}=c,He=Ha(p);fa(c,!1),K&&sn(K),!He&&(P=R&&R.onVnodeBeforeMount)&&Fe(P,Q,p),fa(c,!0);{ce.ce&&ce.ce._hasShadowRoot()&&ce.ce._injectChildStyle(me,c.parent?c.parent.type:void 0);const Ve=c.subTree=Jr(c);b(null,Ve,f,C,c,v,x),p.el=Ve.el}if(Y&&Se(Y,v),!He&&(P=R&&R.onVnodeMounted)){const Ve=p;Se(()=>Fe(P,Q,Ve),v)}(p.shapeFlag&256||Q&&Ha(Q.vnode)&&Q.vnode.shapeFlag&256)&&c.a&&Se(c.a,v),c.isMounted=!0,p=f=C=null}};c.scope.on();const L=c.effect=new sr(k);c.scope.off();const y=c.update=L.run.bind(L),O=c.job=L.runIfDirty.bind(L);O.i=c,O.id=c.uid,L.scheduler=()=>An(O),fa(c,!0),y()},te=(c,p,f)=>{p.component=c;const C=c.vnode.props;c.vnode=p,c.next=null,Ts(c,p.props,C,f),Fs(c,p.children,f),Ie(),zr(c),Oe()},ae=(c,p,f,C,v,x,z,k,L=!1)=>{const y=c&&c.children,O=c?c.shapeFlag:0,P=p.children,{patchFlag:I,shapeFlag:R}=p;if(I>0){if(I&128){en(y,P,f,C,v,x,z,k,L);return}else if(I&256){ya(y,P,f,C,v,x,z,k,L);return}}R&8?(O&16&&io(y,v,x),P!==y&&d(f,P)):O&16?R&16?en(y,P,f,C,v,x,z,k,L):io(y,v,x,!0):(O&8&&d(f,""),R&16&&ie(P,f,C,v,x,z,k,L))},ya=(c,p,f,C,v,x,z,k,L)=>{c=c||ca,p=p||ca;const y=c.length,O=p.length,P=Math.min(y,O);let I;for(I=0;I<P;I++){const R=p[I]=L?Qe(p[I]):De(p[I]);b(c[I],R,f,null,v,x,z,k,L)}y>O?io(c,v,x,!0,!1,P):ie(p,f,C,v,x,z,k,L,P)},en=(c,p,f,C,v,x,z,k,L)=>{let y=0;const O=p.length;let P=c.length-1,I=O-1;for(;y<=P&&y<=I;){const R=c[y],K=p[y]=L?Qe(p[y]):De(p[y]);if(Xa(R,K))b(R,K,f,null,v,x,z,k,L);else break;y++}for(;y<=P&&y<=I;){const R=c[P],K=p[I]=L?Qe(p[I]):De(p[I]);if(Xa(R,K))b(R,K,f,null,v,x,z,k,L);else break;P--,I--}if(y>P){if(y<=I){const R=I+1,K=R<O?p[R].el:C;for(;y<=I;)b(null,p[y]=L?Qe(p[y]):De(p[y]),f,K,v,x,z,k,L),y++}}else if(y>I)for(;y<=P;)je(c[y],v,x,!0),y++;else{const R=y,K=y,Y=new Map;for(y=K;y<=I;y++){const _e=p[y]=L?Qe(p[y]):De(p[y]);_e.key!=null&&Y.set(_e.key,y)}let Q,ce=0;const me=I-K+1;let He=!1,Ve=0;const so=new Array(me);for(y=0;y<me;y++)so[y]=0;for(y=R;y<=P;y++){const _e=c[y];if(ce>=me){je(_e,v,x,!0);continue}let Ue;if(_e.key!=null)Ue=Y.get(_e.key);else for(Q=K;Q<=I;Q++)if(so[Q-K]===0&&Xa(_e,p[Q])){Ue=Q;break}Ue===void 0?je(_e,v,x,!0):(so[Ue-K]=y+1,Ue>=Ve?Ve=Ue:He=!0,b(_e,p[Ue],f,null,v,x,z,k,L),ce++)}const rt=He?Us(so):ca;for(Q=rt.length-1,y=me-1;y>=0;y--){const _e=K+y,Ue=p[_e],it=p[_e+1],tt=_e+1<O?it.el||ui(it):C;so[y]===0?b(null,Ue,f,tt,v,x,z,k,L):He&&(Q<0||y!==rt[Q]?xa(Ue,f,tt,2):Q--)}}},xa=(c,p,f,C,v=null)=>{const{el:x,type:z,transition:k,children:L,shapeFlag:y}=c;if(y&6){xa(c.component.subTree,p,f,C);return}if(y&128){c.suspense.move(p,f,C);return}if(y&64){z.move(c,p,f,to);return}if(z===H){n(x,p,f);for(let P=0;P<L.length;P++)xa(L[P],p,f,C);n(c.anchor,p,f);return}if(z===Oo){$(c,p,f);return}if(C!==2&&y&1&&k)if(C===0)k.persisted&&!x[Mn]?n(x,p,f):(k.beforeEnter(x),n(x,p,f),Se(()=>k.enter(x),v));else{const{leave:P,delayLeave:I,afterLeave:R}=k,K=()=>{c.ctx.isUnmounted?r(x):n(x,p,f)},Y=()=>{const Q=x._isLeaving||!!x[Mn];x._isLeaving&&x[Mn](!0),k.persisted&&!Q?K():P(x,()=>{K(),R&&R()})};I?I(x,K,Y):Y()}else n(x,p,f)},je=(c,p,f,C=!1,v=!1)=>{const{type:x,props:z,ref:k,children:L,dynamicChildren:y,shapeFlag:O,patchFlag:P,dirs:I,cacheIndex:R,memo:K}=c;if((P===-2||y&&y.hasOnce)&&(v=!1),k!=null&&(Ie(),Ba(k,null,f,c,!0),Oe()),R!=null&&(!c.ctx||c.ctx===p)&&(p.renderCache[R]=void 0),O&256){p.ctx.deactivate(c);return}const Y=O&1&&I,Q=!Ha(c);let ce;if(Q&&(ce=z&&z.onVnodeBeforeUnmount)&&Fe(ce,p,c),O&6)np(c.component,f,C);else{if(O&128){c.suspense.unmount(f,C);return}Y&&ma(c,null,p,"beforeUnmount"),O&64?c.type.remove(c,p,f,to,C):y&&!y.hasOnce&&(x!==H||P>0&&P&64)?io(y,p,f,!1,!0):(x===H&&P&384||!v&&O&16)&&io(L,p,f),C&&ot(c)}const me=K!=null&&R==null;(Q&&(ce=z&&z.onVnodeUnmounted)||Y||me)&&Se(()=>{ce&&Fe(ce,p,c),Y&&ma(c,null,p,"unmounted"),me&&(c.el=null)},f)},ot=c=>{const{type:p,el:f,anchor:C,transition:v}=c;if(p===H){op(f,C);return}if(p===Oo){N(c),v&&!v.persisted&&v.afterLeave&&v.afterLeave();return}const x=()=>{r(f),v&&!v.persisted&&v.afterLeave&&v.afterLeave()};if(c.shapeFlag&1&&v&&!v.persisted){const{leave:z,delayLeave:k}=v,L=()=>z(f,x);k?k(c.el,x,L):L()}else x()},op=(c,p)=>{let f;for(;c!==p;)f=A(c),r(c),c=f;r(p)},np=(c,p,f)=>{const{bum:C,scope:v,job:x,subTree:z,um:k,m:L,a:y}=c;di(L),di(y),C&&sn(C),v.stop(),x?(x.flags|=8,je(z,c,p,f)):c.vnode.el&&z&&(z.transition=c.vnode.transition,je(z,c,p,f)),k&&Se(k,p),Se(()=>{c.isUnmounted=!0},p)},io=(c,p,f,C=!1,v=!1,x=0)=>{for(let z=x;z<c.length;z++)je(c[z],p,f,C,v)},an=c=>{if(c.shapeFlag&6)return an(c.component.subTree);if(c.shapeFlag&128)return c.suspense.next();const p=A(c.anchor||c.el),f=p&&p[ts];return f?A(f):p};let Xn=!1;const nt=(c,p,f)=>{let C;c==null?p._vnode&&(je(p._vnode,null,null,!0),C=p._vnode.component):b(p._vnode||null,c,p,null,null,null,f),p._vnode=c,Xn||(Xn=!0,zr(C),Er(),Xn=!1)},to={p:b,um:je,m:xa,r:ot,mt:Gn,mc:ie,pc:ae,pbc:aa,n:an,o:e};return{render:nt,hydrate:void 0,createApp:ks(nt)}}function On({type:e,props:a},o){return o==="svg"&&e==="foreignObject"||o==="mathml"&&e==="annotation-xml"&&a&&a.encoding&&a.encoding.includes("html")?void 0:o}function fa({effect:e,job:a},o){o?(e.flags|=32,a.flags|=4):(e.flags&=-33,a.flags&=-5)}function Vs(e,a){return(!e||e&&!e.pendingBranch)&&a&&!a.persisted}function li(e,a,o=!1){const n=e.children,r=a.children;if(D(n)&&D(r))for(let i=0;i<n.length;i++){const l=n[i];let t=r[i];t.shapeFlag&1&&!t.dynamicChildren&&((t.patchFlag<=0||t.patchFlag===32)&&(t=r[i]=Qe(r[i]),t.el=l.el),!o&&t.patchFlag!==-2&&li(l,t)),t.type===Io&&(t.patchFlag===-1&&(t=r[i]=Qe(t)),t.el=l.el),t.type===Je&&!t.el&&(t.el=l.el)}}function Us(e){const a=e.slice(),o=[0];let n,r,i,l,t;const s=e.length;for(n=0;n<s;n++){const u=e[n];if(u!==0){if(r=o[o.length-1],e[r]<u){a[n]=r,o.push(n);continue}for(i=0,l=o.length-1;i<l;)t=i+l>>1,e[o[t]]<u?i=t+1:l=t;u<e[o[i]]&&(i>0&&(a[n]=o[i-1]),o[i]=n)}}for(i=o.length,l=o[i-1];i-- >0;)o[i]=l,l=a[l];return o}function ci(e){const a=e.subTree.component;if(a)return a.asyncDep&&!a.asyncResolved?a:ci(a)}function di(e){if(e)for(let a=0;a<e.length;a++)e[a].flags|=8}function ui(e){if(e.placeholder)return e.placeholder;const a=e.component;return a?ui(a.subTree):null}const pi=e=>e.__isSuspense;function Ks(e,a){a&&a.pendingBranch?D(e)?a.effects.push(...e):a.effects.push(e):Yt(e)}const H=Symbol.for("v-fgt"),Io=Symbol.for("v-txt"),Je=Symbol.for("v-cmt"),Oo=Symbol.for("v-stc"),ha=[];let Me=null;function M(e=!1){ha.push(Me=e?null:[])}function mi(){ha.pop(),Me=ha[ha.length-1]||null}let Ga=1;function fi(e,a=!1){Ga+=e,e<0&&Me&&a&&(Me.hasOnce=!0)}function hi(e){return e.dynamicChildren=Ga>0?Me||ca:null,mi(),Ga>0&&Me&&Me.push(e),e}function _(e,a,o,n,r,i){return hi(h(e,a,o,n,r,i,!0))}function gi(e,a,o,n,r){return hi(pe(e,a,o,n,r,!0))}function bi(e){return e?e.__v_isVNode===!0:!1}function Xa(e,a){return e.type===a.type&&e.key===a.key}const vi=({key:e})=>e??null,To=({ref:e,ref_key:a,ref_for:o})=>(typeof e=="number"&&(e=""+e),e!=null?ne(e)||ue(e)||F(e)?{i:Ae,r:e,k:a,f:!!o}:e:null);function h(e,a=null,o=null,n=0,r=null,i=e===H?0:1,l=!1,t=!1){const s={__v_isVNode:!0,__v_skip:!0,type:e,props:a,key:a&&vi(a),ref:a&&To(a),scopeId:qr,slotScopeIds:null,children:o,component:null,suspense:null,ssContent:null,ssFallback:null,dirs:null,transition:null,el:null,anchor:null,target:null,targetStart:null,targetAnchor:null,staticCount:0,shapeFlag:i,patchFlag:n,dynamicProps:r,dynamicChildren:null,appContext:null,ctx:Ae};return t?($o(s,o),i&128&&e.normalize(s)):o&&(s.shapeFlag|=ne(o)?8:16),Ga>0&&!l&&Me&&(s.patchFlag>0||i&6)&&s.patchFlag!==32&&Me.push(s),s}const pe=Gs;function Gs(e,a=null,o=null,n=0,r=null,i=!1){if((!e||e===ys)&&(e=Je),bi(e)){const t=_a(e,a,!0);return o&&$o(t,o),Ga>0&&!i&&Me&&(t.shapeFlag&6?Me[Me.indexOf(e)]=t:Me.push(t)),t.patchFlag=-2,t}if(tl(e)&&(e=e.__vccOpts),a){a=Xs(a);let{class:t,style:s}=a;t&&!ne(t)&&(a.class=ho(t)),J(s)&&(wn(s)&&!D(s)&&(s=fe({},s)),a.style=X(s))}const l=ne(e)?1:pi(e)?128:zo(e)?64:J(e)?4:F(e)?2:0;return h(e,a,o,n,r,l,i,!0)}function Xs(e){return e?wn(e)||ai(e)?fe({},e):e:null}function _a(e,a,o=!1,n=!1){const{props:r,ref:i,patchFlag:l,children:t,transition:s}=e,u=a?Ws(r||{},a):r,d={__v_isVNode:!0,__v_skip:!0,type:e.type,props:u,key:u&&vi(u),ref:a&&a.ref?o&&i?D(i)?i.concat(To(a)):[i,To(a)]:To(a):i,scopeId:e.scopeId,slotScopeIds:e.slotScopeIds,children:t,target:e.target,targetStart:e.targetStart,targetAnchor:e.targetAnchor,staticCount:e.staticCount,shapeFlag:e.shapeFlag,patchFlag:a&&e.type!==H?l===-1?16:l|16:l,dynamicProps:e.dynamicProps,dynamicChildren:e.dynamicChildren,appContext:e.appContext,dirs:e.dirs,transition:s,component:e.component,suspense:e.suspense,ssContent:e.ssContent&&_a(e.ssContent),ssFallback:e.ssFallback&&_a(e.ssFallback),placeholder:e.placeholder,el:e.el,anchor:e.anchor,ctx:e.ctx,ce:e.ce,cacheIndex:e.cacheIndex};return s&&n&&_n(d,s.clone(d)),d}function La(e=" ",a=0){return pe(Io,null,e,a)}function yi(e,a){const o=pe(Oo,null,e);return o.staticCount=a,o}function oe(e="",a=!1){return a?(M(),gi(Je,null,e)):pe(Je,null,e)}function De(e){return e==null||typeof e=="boolean"?pe(Je):D(e)?pe(H,null,e.slice()):bi(e)?Qe(e):pe(Io,null,String(e))}function Qe(e){return e.el===null&&e.patchFlag!==-1||e.memo?e:_a(e)}function $o(e,a){let o=0;const{shapeFlag:n}=e;if(a==null)a=null;else if(D(a))o=16;else if(typeof a=="object")if(n&65){const r=a.default;r&&(r._c&&(r._d=!1),$o(e,r()),r._c&&(r._d=!0));return}else{o=32;const r=a._;!r&&!ai(a)?a._ctx=Ae:r===3&&Ae&&(Ae.slots._===1?a._=1:(a._=2,e.patchFlag|=1024))}else if(F(a)){if(n&65){$o(e,{default:a});return}a={default:a,_ctx:Ae},o=32}else a=String(a),n&64?(o=16,a=[La(a)]):o=8;e.children=a,e.shapeFlag|=o}function Ws(...e){const a={};for(let o=0;o<e.length;o++){const n=e[o];for(const r in n)if(r==="class")a.class!==n.class&&(a.class=ho([a.class,n.class]));else if(r==="style")a.style=X([a.style,n.style]);else if(lo(r)){const i=a[r],l=n[r];l&&i!==l&&!(D(i)&&i.includes(l))?a[r]=i?[].concat(i,l):l:l==null&&i==null&&!co(r)&&(a[r]=l)}else r!==""&&(a[r]=n[r])}return a}function Fe(e,a,o,n=null){Ee(e,a,7,[o,n])}const Js=Xr();let Qs=0;function Zs(e,a,o){const n=e.type,r=(a?a.appContext:e.appContext)||Js,i={uid:Qs++,vnode:e,type:n,parent:a,appContext:r,root:null,next:null,subTree:null,effect:null,update:null,job:null,scope:new yt(!0),render:null,proxy:null,exposed:null,exposeProxy:null,withProxy:null,provides:a?a.provides:Object.create(r.provides),ids:a?a.ids:["",0,0],accessCache:null,renderCache:[],components:null,directives:null,propsOptions:ni(n,r),emitsOptions:Wr(n,r),emit:null,emitted:null,propsDefaults:Z,inheritAttrs:n.inheritAttrs,ctx:Z,data:Z,props:Z,attrs:Z,slots:Z,refs:Z,setupState:Z,setupContext:null,suspense:o,suspenseId:o?o.pendingId:0,asyncDep:null,asyncResolved:!1,isMounted:!1,isUnmounted:!1,isDeactivated:!1,bc:null,c:null,bm:null,m:null,bu:null,u:null,um:null,bum:null,da:null,a:null,rtg:null,rtc:null,ec:null,sp:null};return i.ctx={_:i},i.root=a?a.root:i,i.emit=Es.bind(null,i),e.ce&&e.ce(i),i}let ve=null;const Ys=()=>ve||Ae;let Ro,Wa;{const e=fo(),a=(o,n)=>{let r;return(r=e[o])||(r=e[o]=[]),r.push(n),i=>{r.length>1?r.forEach(l=>l(i)):r[0](i)}};Ro=a("__VUE_INSTANCE_SETTERS__",o=>ve=o),Wa=a("__VUE_SSR_SETTERS__",o=>Qa=o)}const Ja=e=>{const a=ve;return Ro(e),e.scope.on(),()=>{e.scope.off(),Ro(a)}},xi=()=>{ve&&ve.scope.off(),Ro(null)};function wi(e){return e.vnode.shapeFlag&4}let Qa=!1;function el(e,a=!1,o=!1){a&&Wa(a);const{props:n,children:r}=e.vnode,i=wi(e);Os(e,n,i,a),Ds(e,r,o||a);const l=i?al(e,a):void 0;return a&&Wa(!1),l}function al(e,a){const o=e.type;e.accessCache=Object.create(null),e.proxy=new Proxy(e.ctx,ws);const{setup:n}=o;if(n){Ie();const r=e.setupContext=n.length>1?nl(e):null,i=Ja(e),l=Ca(n,e,0,[e.props,r]),t=Qn(l);if(Oe(),i(),(t||e.sp)&&!Ha(e)&&Or(e),t){if(l.then(xi,xi),a)return l.then(s=>{Wa(!0);try{Ci(e,s,a)}finally{Wa(!1)}}).catch(s=>{Mo(s,e,0)});e.asyncDep=l}else Ci(e,l)}else Si(e)}function Ci(e,a,o){F(a)?e.type.__ssrInlineRender?e.ssrRender=a:e.render=a:J(a)&&(e.setupState=Mr(a)),Si(e)}function Si(e,a,o){const n=e.type;e.render||(e.render=n.render||qe);{const r=Ja(e);Ie();try{Cs(e)}finally{Oe(),r()}}}const ol={get(e,a){return he(e,"get",""),e[a]}};function nl(e){const a=o=>{e.exposed=o||{}};return{attrs:new Proxy(e.attrs,ol),slots:e.slots,emit:e.emit,expose:a}}function Do(e){return e.exposed?e.exposeProxy||(e.exposeProxy=new Proxy(Mr(Rt(e.exposed)),{get(a,o){if(o in a)return a[o];if(o in Ua)return Ua[o](e)},has(a,o){return o in a||o in Ua}})):e.proxy}const rl=/(?:^|[-_])\w/g,il=e=>e.replace(rl,a=>a.toUpperCase()).replace(/[-_]/g,"");function Ai(e,a=!0){return F(e)?e.displayName||e.name:e.name||a&&e.__name}function Mi(e,a,o=!1){let n=Ai(a);if(!n&&a.__file){const r=a.__file.match(/([^/\\]+)\.\w+$/);r&&(n=r[1])}if(!n&&e){const r=i=>{for(const l in i)if(i[l]===a)return l};n=r(e.components)||e.parent&&r(e.parent.type.components)||r(e.appContext.components)}return n?il(n):o?"App":"Anonymous"}function tl(e){return F(e)&&"__vccOpts"in e}const sa=(e,a)=>Vt(e,a,Qa),sl="3.5.43";/**
* @vue/runtime-dom v3.5.43
* (c) 2018-present Yuxi (Evan) You and Vue contributors
* @license MIT
**/let Tn;const _i=typeof window<"u"&&window.trustedTypes;if(_i)try{Tn=_i.createPolicy("vue",{createHTML:e=>e})}catch{}const Li=Tn?e=>Tn.createHTML(e):e=>e,ll="http://www.w3.org/2000/svg",cl="http://www.w3.org/1998/Math/MathML",Ze=typeof document<"u"?document:null,ki=Ze&&Ze.createElement("template"),dl={insert:(e,a,o)=>{a.insertBefore(e,o||null)},remove:e=>{const a=e.parentNode;a&&a.removeChild(e)},createElement:(e,a,o,n)=>{const r=a==="svg"?Ze.createElementNS(ll,e):a==="mathml"?Ze.createElementNS(cl,e):o?Ze.createElement(e,{is:o}):Ze.createElement(e);return e==="select"&&n&&n.multiple!=null&&r.setAttribute("multiple",n.multiple),r},createText:e=>Ze.createTextNode(e),createComment:e=>Ze.createComment(e),setText:(e,a)=>{e.nodeValue=a},setElementText:(e,a)=>{e.textContent=a},parentNode:e=>e.parentNode,nextSibling:e=>e.nextSibling,querySelector:e=>Ze.querySelector(e),setScopeId(e,a){e.setAttribute(a,"")},insertStaticContent(e,a,o,n,r,i){const l=o?o.previousSibling:a.lastChild;if(r&&(r===i||r.nextSibling))for(;a.insertBefore(r.cloneNode(!0),o),!(r===i||!(r=r.nextSibling)););else{ki.innerHTML=Li(n==="svg"?`<svg>${e}</svg>`:n==="mathml"?`<math>${e}</math>`:e);const t=ki.content;if(n==="svg"||n==="mathml"){const s=t.firstChild;for(;s.firstChild;)t.appendChild(s.firstChild);t.removeChild(s)}a.insertBefore(t,o)}return[l?l.nextSibling:a.firstChild,o?o.previousSibling:a.lastChild]}},ul=Symbol("_vtc");function pl(e,a,o){const n=e[ul];n&&(a=(a?[a,...n]:[...n]).join(" ")),a==null?e.removeAttribute("class"):o?e.setAttribute("class",a):e.className=a}const Fo=Symbol("_vod"),zi=Symbol("_vsh"),ml={name:"show",beforeMount(e,{value:a},{transition:o}){e[Fo]=e.style.display==="none"?"":e.style.display,o&&a?o.beforeEnter(e):Za(e,a)},mounted(e,{value:a},{transition:o}){o&&a&&o.enter(e)},updated(e,{value:a,oldValue:o},{transition:n}){!a!=!o&&(n?a?(n.beforeEnter(e),Za(e,!0),n.enter(e)):n.leave(e,()=>{Za(e,!1)}):Za(e,a))},beforeUnmount(e,{value:a}){Za(e,a)}};function Za(e,a){e.style.display=a?e[Fo]:"none",e[zi]=!a}const fl=Symbol(""),hl=/(?:^|;)\s*display\s*:/;function gl(e,a,o){const n=e.style,r=ne(o);let i=!1;if(o&&!r){if(a)if(ne(a))for(const l of a.split(";")){const t=l.slice(0,l.indexOf(":")).trim();o[t]==null&&Ya(n,t,"")}else for(const l in a)o[l]==null&&Ya(n,l,"");for(const l in o){l==="display"&&(i=!0);const t=o[l];t!=null?vl(e,l,!ne(a)&&a?a[l]:void 0,t)||Ya(n,l,t):Ya(n,l,"")}}else if(r){if(a!==o){const l=n[fl];l&&(o+=";"+l),n.cssText=o,i=hl.test(o)}}else a&&e.removeAttribute("style");Fo in e&&(e[Fo]=i?n.display:"",e[zi]&&(n.display="none"))}const Bo=/\s*!important$/;function Ya(e,a,o){if(D(o))o.forEach(n=>Ya(e,a,n));else if(o==null&&(o=""),a.startsWith("--"))Bo.test(o)?e.setProperty(a,o.replace(Bo,""),"important"):e.setProperty(a,o);else{const n=bl(e,a);Bo.test(o)?e.setProperty(da(n),o.replace(Bo,""),"important"):e[n]=o}}const Ei=["Webkit","Moz","ms"],$n={};function bl(e,a){const o=$n[a];if(o)return o;let n=ye(a);if(n!=="filter"&&n in e)return $n[a]=n;n=mo(n);for(let r=0;r<Ei.length;r++){const i=Ei[r]+n;if(i in e)return $n[a]=i}return a}function vl(e,a,o,n){return e.tagName==="TEXTAREA"&&(a==="width"||a==="height")&&ne(n)&&o===n}const ji="http://www.w3.org/1999/xlink";function qi(e,a,o,n,r,i=gt(a)){n&&a.startsWith("xlink:")?o==null?e.removeAttributeNS(ji,a.slice(6,a.length)):e.setAttributeNS(ji,a,o):o==null||i&&!or(o)?e.removeAttribute(a):e.setAttribute(a,i?"":Pe(o)?String(o):o)}function Pi(e,a,o,n,r){if(a==="innerHTML"||a==="textContent"){o!=null&&(e[a]=a==="innerHTML"?Li(o):o);return}const i=e.tagName;if(a==="value"&&i!=="PROGRESS"&&!i.includes("-")){const t=i==="OPTION"?e.getAttribute("value")||"":e.value,s=o==null?e.type==="checkbox"?"on":"":String(o);(t!==s||!("_value"in e))&&(e.value=s),o==null&&e.removeAttribute(a),e._value=o;return}let l=!1;if(o===""||o==null){const t=typeof e[a];t==="boolean"?o=or(o):o==null&&t==="string"?(o="",l=!0):t==="number"&&(o=0,l=!0)}try{e[a]=o}catch{}l&&e.removeAttribute(r||a)}function yl(e,a,o,n){e.addEventListener(a,o,n)}function xl(e,a,o,n){e.removeEventListener(a,o,n)}const Ni=Symbol("_vei");function wl(e,a,o,n,r=null){const i=e[Ni]||(e[Ni]={}),l=i[a];if(n&&l)l.value=n;else{const[t,s]=Al(a);if(n){const u=i[a]=Ll(n,r);yl(e,t,u,s)}else l&&(xl(e,t,l,s),i[a]=void 0)}}const Cl=/(Once|Passive|Capture)$/,Sl=/^on:?(?:Once|Passive|Capture)$/;function Al(e){let a,o;for(;(o=e.match(Cl))&&!Sl.test(e);)a||(a={}),e=e.slice(0,e.length-o[1].length),a[o[1].toLowerCase()]=!0;return[e[2]===":"?e.slice(3):da(e.slice(2)),a]}let Rn=0;const Ml=Promise.resolve(),_l=()=>Rn||(Ml.then(()=>Rn=0),Rn=Date.now());function Ll(e,a){const o=n=>{if(!n._vts)n._vts=Date.now();else if(n._vts<=o.attached)return;const r=o.value;if(D(r)){const i=n.stopImmediatePropagation;n.stopImmediatePropagation=()=>{i.call(n),n._stopped=!0};const l=r.slice(),t=[n];for(let s=0;s<l.length&&!n._stopped;s++){const u=l[s];u&&Ee(u,a,5,t)}}else Ee(r,a,5,[n])};return o.value=e,o.attached=_l(),o}const Ii=e=>e.charCodeAt(0)===111&&e.charCodeAt(1)===110&&e.charCodeAt(2)>96&&e.charCodeAt(2)<123,kl=(e,a,o,n,r,i)=>{const l=r==="svg";a==="class"?pl(e,n,l):a==="style"?gl(e,o,n):lo(a)?co(a)||wl(e,a,o,n,i):(a[0]==="."?(a=a.slice(1),!0):a[0]==="^"?(a=a.slice(1),!1):zl(e,a,n,l))?(Pi(e,a,n),!e.tagName.includes("-")&&(a==="value"||a==="checked"||a==="selected")&&qi(e,a,n,l,i,a!=="value")):e._isVueCE&&(El(e,a)||e._def.__asyncLoader&&(/[A-Z]/.test(a)||!ne(n)))?Pi(e,ye(a),n,i,a):(a==="true-value"?e._trueValue=n:a==="false-value"&&(e._falseValue=n),qi(e,a,n,l))};function zl(e,a,o,n){if(n)return!!(a==="innerHTML"||a==="textContent"||a in e&&Ii(a)&&F(o));if(a==="spellcheck"||a==="draggable"||a==="translate"||a==="autocorrect"||a==="sandbox"&&e.tagName==="IFRAME"||a==="form"||a==="list"&&e.tagName==="INPUT"||a==="type"&&e.tagName==="TEXTAREA")return!1;if(a==="width"||a==="height"){const r=e.tagName;if(r==="IMG"||r==="VIDEO"||r==="CANVAS"||r==="SOURCE")return!1}return Ii(a)&&ne(o)?!1:a in e}function El(e,a){const o=e._def.props;if(!o)return!1;const n=ye(a);return Array.isArray(o)?o.some(r=>ye(r)===n):Object.keys(o).some(r=>ye(r)===n)}const jl=["ctrl","shift","alt","meta"],ql={stop:e=>e.stopPropagation(),prevent:e=>e.preventDefault(),self:e=>e.target!==e.currentTarget,ctrl:e=>!e.ctrlKey,shift:e=>!e.shiftKey,alt:e=>!e.altKey,meta:e=>!e.metaKey,left:e=>"button"in e&&e.button!==0,middle:e=>"button"in e&&e.button!==1,right:e=>"button"in e&&e.button!==2,exact:(e,a)=>jl.some(o=>e[`${o}Key`]&&!a.includes(o))},Dn=(e,a)=>{if(!e)return e;const o=e._withMods||(e._withMods={}),n=a.join(".");return o[n]||(o[n]=(r,...i)=>{for(let l=0;l<a.length;l++){const t=ql[a[l]];if(t&&t(r,a))return}return e(r,...i)})},Pl=fe({patchProp:kl},dl);let Oi;function Nl(){return Oi||(Oi=Bs(Pl))}const Il=(...e)=>{const a=Nl().createApp(...e),{mount:o}=a;return a.mount=n=>{const r=Tl(n);if(!r)return;const i=a._component;!F(i)&&!i.render&&!i.template&&(i.template=r.innerHTML),r.nodeType===1&&(r.textContent="");const l=o(r,!1,Ol(r));return r instanceof Element&&(r.removeAttribute("v-cloak"),r.setAttribute("data-v-app","")),l},a};function Ol(e){if(e instanceof SVGElement)return"svg";if(typeof MathMLElement=="function"&&e instanceof MathMLElement)return"mathml"}function Tl(e){return ne(e)?document.querySelector(e):e}const $l=""+new URL("ogn-arte-final.png",document.currentScript&&document.currentScript.tagName.toUpperCase()==="SCRIPT"&&document.currentScript.src||document.baseURI).href,Rl=""+new URL("ogn-bienvenida.png",document.currentScript&&document.currentScript.tagName.toUpperCase()==="SCRIPT"&&document.currentScript.src||document.baseURI).href,Dl=""+new URL("papel-mapa-limpio.png",document.currentScript&&document.currentScript.tagName.toUpperCase()==="SCRIPT"&&document.currentScript.src||document.baseURI).href,Fl=""+new URL("rotulo-mapa.png",document.currentScript&&document.currentScript.tagName.toUpperCase()==="SCRIPT"&&document.currentScript.src||document.baseURI).href,Bl=""+new URL("ogn-slot-bloqueado.png",document.currentScript&&document.currentScript.tagName.toUpperCase()==="SCRIPT"&&document.currentScript.src||document.baseURI).href,Hl=""+new URL("ogn-crear-pj-2.png",document.currentScript&&document.currentScript.tagName.toUpperCase()==="SCRIPT"&&document.currentScript.src||document.baseURI).href,Vl=""+new URL("ogn-arte-final.webp",document.currentScript&&document.currentScript.tagName.toUpperCase()==="SCRIPT"&&document.currentScript.src||document.baseURI).href,Ul=""+new URL("ogn-bienvenida.webp",document.currentScript&&document.currentScript.tagName.toUpperCase()==="SCRIPT"&&document.currentScript.src||document.baseURI).href,Kl=""+new URL("papel-mapa-limpio.webp",document.currentScript&&document.currentScript.tagName.toUpperCase()==="SCRIPT"&&document.currentScript.src||document.baseURI).href,Gl=""+new URL("rotulo-mapa.webp",document.currentScript&&document.currentScript.tagName.toUpperCase()==="SCRIPT"&&document.currentScript.src||document.baseURI).href,Xl=""+new URL("ogn-slot-bloqueado.webp",document.currentScript&&document.currentScript.tagName.toUpperCase()==="SCRIPT"&&document.currentScript.src||document.baseURI).href,Wl=""+new URL("ogn-crear-pj-2.webp",document.currentScript&&document.currentScript.tagName.toUpperCase()==="SCRIPT"&&document.currentScript.src||document.baseURI).href,Ho={origen:{art:$l,poster:Rl,paper:Dl,rotuloMapa:Fl,lockBg:Bl,createBg:Hl},nacion:{art:Vl,poster:Ul,paper:Kl,rotuloMapa:Gl,lockBg:Xl,createBg:Wl}},Fn=se(document.documentElement.dataset.marca||"origen");window.addEventListener("message",e=>{const a=e.data;a&&a.accion==="origen:marca:puesta"&&typeof a.marca=="string"&&(Fn.value=a.marca)});const Jl=sa(()=>Ho[Fn.value]||Ho.origen);function Ti(){return Jl}const Ql={class:"ogn-img"},Zl=["src"],Yl={key:1,class:"ogn-img-ph"},ec={key:0},ac={__name:"OgnImage",props:{src:{type:String,default:""},srcKey:{type:String,default:""},images:{type:Object,default:()=>({})},label:{type:String,default:""}},setup(e){const a=e,o=sa(()=>a.src||a.srcKey&&(a.images||{})[a.srcKey]||"");return(n,r)=>(M(),_("div",Ql,[o.value?(M(),_("img",{key:0,src:o.value,alt:""},null,8,Zl)):(M(),_("div",Yl,[e.label?(M(),_("span",ec,V(e.label),1)):oe("",!0)]))]))}},$i={coche:'<path d="M3 13.4l1.5-4.6A2.3 2.3 0 0 1 6.7 7.2h6.6a2.3 2.3 0 0 1 2.2 1.6l1.5 4.6v2.5a.9.9 0 0 1-.9.9h-1.2a.9.9 0 0 1-.9-.9v-.6H5.9v.6a.9.9 0 0 1-.9.9H3.8a.9.9 0 0 1-.9-.9z"/>',dinero:'<path fill-rule="evenodd" d="M2.4 5.2h15.2a1 1 0 0 1 1 1v7.6a1 1 0 0 1-1 1H2.4a1 1 0 0 1-1-1V6.2a1 1 0 0 1 1-1zm7.6 2.4a2.4 2.4 0 1 0 0 4.8 2.4 2.4 0 0 0 0-4.8z"/>',cesta:'<path fill-rule="evenodd" d="M5.4 6.4v-.7a4.6 4.6 0 0 1 9.2 0v.7h2.2l-1 9.5a1.4 1.4 0 0 1-1.4 1.3H5.6a1.4 1.4 0 0 1-1.4-1.3l-1-9.5zm2.2 0h4.8v-.7a2.4 2.4 0 0 0-4.8 0z"/>',edificio:'<path fill-rule="evenodd" d="M3.6 2.8h12.8v14.4H3.6zM6 5.4h2.4v2.4H6zm5.6 0H14v2.4h-2.4zM6 9.8h2.4v2.4H6zm5.6 0H14v2.4h-2.4zM8.6 14.2h2.8v3H8.6z"/>',casa:'<path fill-rule="evenodd" d="M10 2.2 18.8 9.1h-2.6v8.2H3.8V9.1H1.2zM8.7 12h2.6v5.3H8.7z"/>',casa_venta:'<path fill-rule="evenodd" d="M8 2.6 15 8.1h-2.1v2.5H9.6a1.4 1.4 0 0 0-1.4 1.4v5H3V8.1H1zM6.9 12.3h2.2v4.7H6.9z"/><path fill-rule="evenodd" d="M11 11.6h7a1 1 0 0 1 1 1v3.8a1 1 0 0 1-1 1h-7a1 1 0 0 1-1-1v-3.8a1 1 0 0 1 1-1zm1.6 1.9v1.6h3.8v-1.6z"/><path d="M13.9 9.2h1.2v2.4h-1.2z"/>',hotel:'<path d="M2.2 4.4a1 1 0 0 1 2 0v6h13.6a1 1 0 0 1 1 1v5.2a1 1 0 0 1-2 0v-1.8H4.2v1.8a1 1 0 0 1-2 0z"/><circle cx="7.1" cy="7.7" r="1.95"/><path d="M10 5.9h5.6a2.2 2.2 0 0 1 2.2 2.2v1.5H10z"/>',calavera:'<path fill-rule="evenodd" d="M10 2.2a6.6 6.6 0 0 0-4.2 11.7v2.2a1.4 1.4 0 0 0 1.4 1.4h5.6a1.4 1.4 0 0 0 1.4-1.4v-2.2A6.6 6.6 0 0 0 10 2.2zM7.5 8a1.7 1.7 0 1 1 0 3.4A1.7 1.7 0 0 1 7.5 8zm5 0a1.7 1.7 0 1 1 0 3.4A1.7 1.7 0 0 1 12.5 8z"/>',bandera:'<path d="M4.3 2.3a1 1 0 0 1 1 1v14.4a1 1 0 1 1-2 0V3.3a1 1 0 0 1 1-1z"/><path d="M6.6 3.5h9.2a.7.7 0 0 1 .58 1.1L14.5 7.3l1.88 2.7a.7.7 0 0 1-.58 1.1H6.6z"/>',ocio:'<path d="M3.2 3.2h13.6a.7.7 0 0 1 .53 1.16L10.9 11.5v4.1h2.7a.9.9 0 1 1 0 1.8H6.4a.9.9 0 1 1 0-1.8h2.7v-4.1L2.67 4.36A.7.7 0 0 1 3.2 3.2z"/>',huella:'<path d="M10 11.4c2.5 0 4.6 1.7 4.6 3.9 0 1.6-1.3 2.5-2.9 2.5-.7 0-1.2-.15-1.7-.15s-1 .15-1.7.15c-1.6 0-2.9-.9-2.9-2.5 0-2.2 2.1-3.9 4.6-3.9z"/><ellipse cx="5.6" cy="8.4" rx="1.7" ry="2.2"/><ellipse cx="14.4" cy="8.4" rx="1.7" ry="2.2"/><ellipse cx="8.4" cy="4.4" rx="1.6" ry="2.1"/><ellipse cx="11.6" cy="4.4" rx="1.6" ry="2.1"/>',movil:'<path fill-rule="evenodd" d="M6.4 1.8h7.2a1.9 1.9 0 0 1 1.9 1.9v12.6a1.9 1.9 0 0 1-1.9 1.9H6.4a1.9 1.9 0 0 1-1.9-1.9V3.7a1.9 1.9 0 0 1 1.9-1.9zm1.5 1.9a.55.55 0 0 0 0 1.1h4.2a.55.55 0 0 0 0-1.1zM10 14.3a1.15 1.15 0 1 0 0 2.3 1.15 1.15 0 0 0 0-2.3z"/>',chincheta:'<path fill-rule="evenodd" d="M10 1.6A6.4 6.4 0 0 0 3.6 8c0 4.6 5.5 9.9 5.73 10.12a.96.96 0 0 0 1.34 0C10.9 17.9 16.4 12.6 16.4 8A6.4 6.4 0 0 0 10 1.6zm0 4.1a2.3 2.3 0 1 1 0 4.6 2.3 2.3 0 0 1 0-4.6z"/>',local:'<path d="M3.4 3h13.2l1.55 4.15a.7.7 0 0 1-.65.95H2.5a.7.7 0 0 1-.65-.95z"/><path fill-rule="evenodd" d="M3.7 9.6h12.6v7.6H3.7zm2.5 1.9v3.4h3.4v-3.4z"/>',estrella:'<path d="M10 1.8l2.45 5.1 5.45.73-3.98 3.83 1.02 5.44L10 14.27l-4.94 2.63 1.02-5.44L2.1 7.63l5.45-.73z"/>',sirena:'<path d="M10 2.2a4.4 4.4 0 0 0-4.4 4.4v4.2h8.8V6.6A4.4 4.4 0 0 0 10 2.2z"/><path d="M3.6 12.4h12.8a1 1 0 0 1 1 1v2.2a1 1 0 0 1-1 1H3.6a1 1 0 0 1-1-1v-2.2a1 1 0 0 1 1-1z"/>',escudo:'<path fill-rule="evenodd" d="M10 1.8l6.6 2.6v5.2c0 4-2.8 7.3-6.6 8.6-3.8-1.3-6.6-4.6-6.6-8.6V4.4zm0 3.6a2 2 0 1 0 0 4 2 2 0 0 0 0-4z"/>',compartido:'<path d="M7.5 9.7a3.15 3.15 0 1 0 0-6.3 3.15 3.15 0 0 0 0 6.3z"/><path d="M7.5 11a5.9 5.9 0 0 0-5.65 4.2.92.92 0 0 0 .88 1.2h9.54a.92.92 0 0 0 .88-1.2A5.9 5.9 0 0 0 7.5 11z"/><path d="M14.4 9.3a2.6 2.6 0 1 0 0-5.2 2.6 2.6 0 0 0 0 5.2z"/><path d="M14.4 10.5c-.52 0-1.02.07-1.5.2a7.6 7.6 0 0 1 1.94 3.4c.1.4.11.8.05 1.17h3.1a.9.9 0 0 0 .87-1.16 4.65 4.65 0 0 0-4.46-3.61z"/>',persona:'<path d="M10 3.2a3.4 3.4 0 1 0 0 6.8 3.4 3.4 0 0 0 0-6.8z"/><path d="M10 11.2a6.4 6.4 0 0 0-6.2 4.75.95.95 0 0 0 .92 1.25h10.56a.95.95 0 0 0 .92-1.25A6.4 6.4 0 0 0 10 11.2z"/>',maletin:'<path fill-rule="evenodd" d="M8 2.6h4a1.8 1.8 0 0 1 1.8 1.8v.9h2.7a1.5 1.5 0 0 1 1.5 1.5v8.1a1.5 1.5 0 0 1-1.5 1.5H3.5A1.5 1.5 0 0 1 2 14.9V6.8a1.5 1.5 0 0 1 1.5-1.5h2.7v-.9A1.8 1.8 0 0 1 8 2.6zm0 2.7h4v-.9H8z"/>',gasolina:'<path fill-rule="evenodd" d="M3 3.6A1.6 1.6 0 0 1 4.6 2h5A1.6 1.6 0 0 1 11.2 3.6V17.4H3zm1.9 1.1v3.1h4.4V4.7z"/><path d="M12.4 5.9l1.5 1.5a1.6 1.6 0 0 1 .47 1.13v4.36a.92.92 0 0 0 1.84 0V8.06a3 3 0 0 0-.88-2.12l-2.2-2.2-1.06 1.07 1.07 1.06a.55.55 0 1 1-.74.03z"/>',cruz:'<path d="M8.1 2.4h3.8v5.7h5.7v3.8h-5.7v5.7H8.1v-5.7H2.4V8.1h5.7z"/>',tenis:'<path fill-rule="evenodd" d="M16.02 3.98A5.4 4.5 -45 1 0 8.38 11.62A5.4 4.5 -45 1 0 16.02 3.98zM14.67 5.33A3.5 2.6 -45 1 0 9.73 10.27A3.5 2.6 -45 1 0 14.67 5.33z"/><path d="M10.08 10.62L15.02 5.68A.5 .5 0 0 0 14.32 4.98L9.38 9.92A.5 .5 0 0 0 10.08 10.62z"/><path d="M10.01 6.31L13.69 9.99A.5 .5 0 0 0 14.39 9.29L10.71 5.61A.5 .5 0 0 0 10.01 6.31z"/><path d="M7.59 10.79L2.49 15.89A1.15 1.15 0 0 0 4.11 17.51L9.21 12.41A1.15 1.15 0 0 0 7.59 10.79z"/><path d="M2.1 4.4A2.3 2.3 0 0 1 6.7 4.4A2.3 2.3 0 0 1 2.1 4.4z"/>',baloncesto:'<path d="M4.1 4.74A7.9 7.9 0 0 0 2.12 9.4L5.78 9.4A9 9 0 0 0 4.1 4.74zM15.9 4.74A7.9 7.9 0 0 1 17.88 9.4L14.22 9.4A9 9 0 0 1 15.9 4.74zM4.1 15.26A7.9 7.9 0 0 1 2.12 10.6L5.78 10.6A9 9 0 0 1 4.1 15.26zM15.9 15.26A7.9 7.9 0 0 0 17.88 10.6L14.22 10.6A9 9 0 0 0 15.9 15.26zM4.98 3.9A7.9 7.9 0 0 1 9.4 2.12L9.4 9.4L6.98 9.4A10.2 10.2 0 0 0 4.98 3.9zM15.02 3.9A7.9 7.9 0 0 0 10.6 2.12L10.6 9.4L13.02 9.4A10.2 10.2 0 0 1 15.02 3.9zM4.98 16.1A7.9 7.9 0 0 0 9.4 17.88L9.4 10.6L6.98 10.6A10.2 10.2 0 0 1 4.98 16.1zM15.02 16.1A7.9 7.9 0 0 1 10.6 17.88L10.6 10.6L13.02 10.6A10.2 10.2 0 0 0 15.02 16.1z"/>',golf:'<path d="M6.25 3L6.25 15.2A.95 .95 0 0 0 8.15 15.2L8.15 3A.95 .95 0 0 0 6.25 3z"/><path d="M8.1 2.2L15.8 5.3L8.1 8.4z"/><path d="M2.2 16.3C2.2 15.2 4.6 14.5 7.2 14.5C9.8 14.5 12.2 15.2 12.2 16.3C12.2 17.4 9.8 18.1 7.2 18.1C4.6 18.1 2.2 17.4 2.2 16.3z"/><path d="M13 13.4A2.4 2.4 0 0 1 17.8 13.4A2.4 2.4 0 0 1 13 13.4z"/>',bolos:'<path d="M6 1.8C7.2 1.8 8.1 2.8 8.1 4C8.1 5.2 7.1 6 7 7.1C8.2 8.5 9 10.4 9 12.4C9 14.3 8.4 16.2 7.8 17.8L4.2 17.8C3.6 16.2 3 14.3 3 12.4C3 10.4 3.8 8.5 5 7.1C4.9 6 3.9 5.2 3.9 4C3.9 2.8 4.8 1.8 6 1.8z"/><path fill-rule="evenodd" d="M10 13.4A4.2 4.2 0 0 1 18.4 13.4A4.2 4.2 0 0 1 10 13.4zM12.25 11.6A.85 .85 0 0 1 13.95 11.6A.85 .85 0 0 1 12.25 11.6zM14.55 11.3A.85 .85 0 0 1 16.25 11.3A.85 .85 0 0 1 14.55 11.3z"/>',caza:'<path d="M7.1 9.4L12.9 9.4C13.1 12 12.1 14.6 11.3 16.7A1.35 1.35 0 0 1 8.7 16.7C7.9 14.6 6.9 12 7.1 9.4z"/><path d="M7.4 10.2C6.2 9.2 4.2 9.1 2.8 10C3.8 11.6 5.8 12.2 7.3 11.6z"/><path d="M12.6 10.2C13.8 9.2 15.8 9.1 17.2 10C16.2 11.6 14.2 12.2 12.7 11.6z"/><path d="M9.38 9.27L6.38 2.27A.85 .85 0 0 0 4.82 2.93L7.82 9.93A.85 .85 0 0 0 9.38 9.27z"/><path d="M7.04 4.64L3.24 3.44A.8 .8 0 0 0 2.76 4.96L6.56 6.16A.8 .8 0 0 0 7.04 4.64z"/><path d="M6.88 4.78L8.88 2.38A.75 .75 0 0 0 7.72 1.42L5.72 3.82A.75 .75 0 0 0 6.88 4.78z"/><path d="M10.62 9.27L13.62 2.27A.85 .85 0 0 1 15.18 2.93L12.18 9.93A.85 .85 0 0 1 10.62 9.27z"/><path d="M12.96 4.64L16.76 3.44A.8 .8 0 0 1 17.24 4.96L13.44 6.16A.8 .8 0 0 1 12.96 4.64z"/><path d="M13.12 4.78L11.12 2.38A.75 .75 0 0 1 12.28 1.42L14.28 3.82A.75 .75 0 0 1 13.12 4.78z"/>',pesca:'<path fill-rule="evenodd" d="M18.2 10C16.4 6.5 13.7 5 10.9 5C8.4 5 6.4 6.5 5.2 8.1L2 5.4L2.9 10L2 14.6L5.2 11.9C6.4 13.5 8.4 15 10.9 15C13.7 15 16.4 13.5 18.2 10zM13.25 9A1.05 1.05 0 0 1 15.35 9A1.05 1.05 0 0 1 13.25 9z"/>',cono:'<path d="M8.5 2.2h3l1.05 3.9h-5.1zM7.05 7.6h5.9l1.1 4.1H5.95zM5.5 13.2h9l.95 3.3H4.55z"/><path d="M2.4 17.1h15.2a.8.8 0 0 1 0 1.6H2.4a.8.8 0 0 1 0-1.6z"/>',patata:'<path fill-rule="evenodd" d="M6.6 3.5c3-2.3 8.1-1.9 10.1 1.5 2.1 3.5 1.2 8.7-1.8 11-3 2.4-8.3 2.1-10.1-1.1C3.1 11.8 3.7 5.7 6.6 3.5zM6.8 8.2a1.1 1.1 0 1 0 2.2 0a1.1 1.1 0 1 0-2.2 0zM11.2 6.6a1.1 1.1 0 1 0 2.2 0a1.1 1.1 0 1 0-2.2 0zM10.6 12a1.1 1.1 0 1 0 2.2 0a1.1 1.1 0 1 0-2.2 0z"/>',corona:'<path d="M2.2 5.6l4.3 3.9L10 2.9l3.5 6.6 4.3-3.9-1.7 9.5H3.9z"/><path d="M3.9 16.5h12.2v1.9H3.9z"/>',mascara:'<path fill-rule="evenodd" d="M1.8 6.2C4.4 5 7.2 4.8 10 6c2.8-1.2 5.6-1 8.2.2.3 4.4-1.4 7.8-4.6 8.2-1.6.2-2.6-.9-3.6-2.2-1 1.3-2 2.4-3.6 2.2-3.2-.4-4.9-3.8-4.6-8.2zM4.5 9.1a2.1 1.35 0 1 0 4.2 0a2.1 1.35 0 1 0-4.2 0zM11.3 9.1a2.1 1.35 0 1 0 4.2 0a2.1 1.35 0 1 0-4.2 0z"/>',paintball:'<path fill-rule="evenodd" d="M2 10A8 8 0 0 1 18 10A8 8 0 0 1 2 10zM4.4 10A5.6 5.6 0 0 1 15.6 10A5.6 5.6 0 0 1 4.4 10zM6.8 10A3.2 3.2 0 0 1 13.2 10A3.2 3.2 0 0 1 6.8 10z"/>',casino:'<path fill-rule="evenodd" d="M5.4 2.4L14.6 2.4A3 3 0 0 1 17.6 5.4L17.6 14.6A3 3 0 0 1 14.6 17.6L5.4 17.6A3 3 0 0 1 2.4 14.6L2.4 5.4A3 3 0 0 1 5.4 2.4zM4.95 6.5A1.55 1.55 0 0 1 8.05 6.5A1.55 1.55 0 0 1 4.95 6.5zM11.95 6.5A1.55 1.55 0 0 1 15.05 6.5A1.55 1.55 0 0 1 11.95 6.5zM8.45 10A1.55 1.55 0 0 1 11.55 10A1.55 1.55 0 0 1 8.45 10zM4.95 13.5A1.55 1.55 0 0 1 8.05 13.5A1.55 1.55 0 0 1 4.95 13.5zM11.95 13.5A1.55 1.55 0 0 1 15.05 13.5A1.55 1.55 0 0 1 11.95 13.5z"/>',gimnasio:'<path d="M5.1 4.6L6.1 4.6A1 1 0 0 1 7.1 5.6L7.1 14.4A1 1 0 0 1 6.1 15.4L5.1 15.4A1 1 0 0 1 4.1 14.4L4.1 5.6A1 1 0 0 1 5.1 4.6z"/><path d="M14.9 4.6L13.9 4.6A1 1 0 0 0 12.9 5.6L12.9 14.4A1 1 0 0 0 13.9 15.4L14.9 15.4A1 1 0 0 0 15.9 14.4L15.9 5.6A1 1 0 0 0 14.9 4.6z"/><path d="M2.5 7L4 7A.9 .9 0 0 1 4.9 7.9L4.9 12.1A.9 .9 0 0 1 4 13L2.5 13A.9 .9 0 0 1 1.6 12.1L1.6 7.9A.9 .9 0 0 1 2.5 7z"/><path d="M17.5 7L16 7A.9 .9 0 0 0 15.1 7.9L15.1 12.1A.9 .9 0 0 0 16 13L17.5 13A.9 .9 0 0 0 18.4 12.1L18.4 7.9A.9 .9 0 0 0 17.5 7z"/><path d="M6.5 8.8L13.5 8.8L13.5 11.2L6.5 11.2z"/>',tatuaje:'<path d="M17.07 2.65L17.35 2.93A2.2 2.2 0 0 1 17.35 6.04L14.24 9.15A2.2 2.2 0 0 1 11.13 9.15L10.85 8.87A2.2 2.2 0 0 1 10.85 5.76L13.96 2.65A2.2 2.2 0 0 1 17.07 2.65z"/><path d="M10.35 7.81L12.19 9.65L8.94 12.05L7.95 11.06z"/><path d="M8.27 11.1L8.9 11.73L6.61 13.39z"/><path d="M4.4 12.6C4.4 12.6 6.6 15.1 6.6 16.2A2.2 2.2 0 0 1 2.2 16.2C2.2 15.1 4.4 12.6 4.4 12.6z"/>',juego:'<path fill-rule="evenodd" d="M6.2 5.2L13.8 5.2C16.2 5.2 17.4 7 17.9 9.6L18.3 12.6C18.6 14.8 17 16 15.4 15.2C14.4 14.7 13.7 13.4 12.7 13.1L7.3 13.1C6.3 13.4 5.6 14.7 4.6 15.2C3 16 1.4 14.8 1.7 12.6L2.1 9.6C2.6 7 3.8 5.2 6.2 5.2zM5.6 7.2L6.8 7.2L6.8 8.6L8.2 8.6L8.2 9.8L6.8 9.8L6.8 11.2L5.6 11.2L5.6 9.8L4.2 9.8L4.2 8.6L5.6 8.6zM11.9 10.1A1 1 0 0 1 13.9 10.1A1 1 0 0 1 11.9 10.1zM13.9 8.1A1 1 0 0 1 15.9 8.1A1 1 0 0 1 13.9 8.1z"/>',copa:'<path d="M3.2 3.2h13.6a.7.7 0 0 1 .53 1.16L10.9 11.5v4.1h2.7a.9.9 0 1 1 0 1.8H6.4a.9.9 0 1 1 0-1.8h2.7v-4.1L2.67 4.36A.7.7 0 0 1 3.2 3.2z"/>',autobus:'<path fill-rule="evenodd" d="M5.6 2L14.4 2A2.2 2.2 0 0 1 16.6 4.2L16.6 13.2A2.2 2.2 0 0 1 14.4 15.4L5.6 15.4A2.2 2.2 0 0 1 3.4 13.2L3.4 4.2A2.2 2.2 0 0 1 5.6 2zM6 4L14 4A.8 .8 0 0 1 14.8 4.8L14.8 8.6A.8 .8 0 0 1 14 9.4L6 9.4A.8 .8 0 0 1 5.2 8.6L5.2 4.8A.8 .8 0 0 1 6 4zM5.55 12.5A1.05 1.05 0 0 1 7.65 12.5A1.05 1.05 0 0 1 5.55 12.5zM12.35 12.5A1.05 1.05 0 0 1 14.45 12.5A1.05 1.05 0 0 1 12.35 12.5z"/><path d="M5.2 14.4L6.6 14.4A.8 .8 0 0 1 7.4 15.2L7.4 17.2A.8 .8 0 0 1 6.6 18L5.2 18A.8 .8 0 0 1 4.4 17.2L4.4 15.2A.8 .8 0 0 1 5.2 14.4z"/><path d="M13.4 14.4L14.8 14.4A.8 .8 0 0 1 15.6 15.2L15.6 17.2A.8 .8 0 0 1 14.8 18L13.4 18A.8 .8 0 0 1 12.6 17.2L12.6 15.2A.8 .8 0 0 1 13.4 14.4z"/>',avion:'<path d="M10 1.4c.62 0 1.12.5 1.12 1.12V7.1l6.28 3.6v1.6l-6.28-1.86v3.9l1.9 1.35v1.42L10 15.98l-3.02 1.03v-1.42l1.9-1.35v-3.9L2.6 12.3v-1.6l6.28-3.6V2.52c0-.62.5-1.12 1.12-1.12z"/>',taxi:'<path d="M3 14.4l1.5-4.6A2.3 2.3 0 0 1 6.7 8.2h6.6a2.3 2.3 0 0 1 2.2 1.6l1.5 4.6v2.5a.9.9 0 0 1-.9.9h-1.2a.9.9 0 0 1-.9-.9v-.6H5.9v.6a.9.9 0 0 1-.9.9H3.8a.9.9 0 0 1-.9-.9z"/><path d="M7.8 2.4L12.2 2.4A.8 .8 0 0 1 13 3.2L13 5.4A.8 .8 0 0 1 12.2 6.2L7.8 6.2A.8 .8 0 0 1 7 5.4L7 3.2A.8 .8 0 0 1 7.8 2.4z"/>',camion:'<path d="M2.4 3.4L10.8 3.4A.8 .8 0 0 1 11.6 4.2L11.6 12.4A.8 .8 0 0 1 10.8 13.2L2.4 13.2A.8 .8 0 0 1 1.6 12.4L1.6 4.2A.8 .8 0 0 1 2.4 3.4z"/><path fill-rule="evenodd" d="M12.6 6.2L15.4 6.2C15.9 6.2 16.3 6.4 16.6 6.8L18.1 9.2C18.3 9.5 18.4 9.8 18.4 10.2L18.4 13.2L12.6 13.2zM13.8 7.4L15.2 7.4L16.6 9.8L13.8 9.8z"/><path d="M2.9 15.4A2.3 2.3 0 0 1 7.5 15.4A2.3 2.3 0 0 1 2.9 15.4z"/><path d="M12.5 15.4A2.3 2.3 0 0 1 17.1 15.4A2.3 2.3 0 0 1 12.5 15.4z"/>',arbol:'<path d="M10 1.6L14.6 7.4L12.6 7.4L16.6 11.8L14.4 11.8L17.8 15.4L11.3 15.4L11.3 18.4L8.7 18.4L8.7 15.4L2.2 15.4L5.6 11.8L3.4 11.8L7.4 7.4L5.4 7.4z"/>',tractor:'<path fill-rule="evenodd" d="M3.4 2.6h5.4a.8.8 0 0 1 .8.8v5.8H3.4zM4.8 4h3.4v3.4H4.8z"/><path d="M9.6 7.6h6.8a1 1 0 0 1 1 1v3.4H9.6zM12.6 4.2h1.2v3.4h-1.2z"/><path fill-rule="evenodd" d="M1.8 13.8a4.2 4.2 0 1 0 8.4 0a4.2 4.2 0 1 0-8.4 0zM4.5 13.8a1.5 1.5 0 1 0 3 0a1.5 1.5 0 1 0-3 0z"/><path fill-rule="evenodd" d="M12.8 15.4a2.6 2.6 0 1 0 5.2 0a2.6 2.6 0 1 0-5.2 0zM14.5 15.4a.9.9 0 1 0 1.8 0a.9.9 0 1 0-1.8 0z"/>',brote:'<path d="M9.2 8.5h1.6v6.3H9.2z"/><path d="M9.6 9.4C6.9 9.8 3.4 8.6 2.6 4.4c3.9-.6 6.9 1.2 7 5z"/><path d="M10.4 7.6c.2-3.4 2.8-5.6 7-5.2-.4 4.1-3.4 5.8-7 5.2z"/><path d="M2.4 16.2c1.6-1.6 4.6-2.2 7.6-2.2s6 .6 7.6 2.2a.9.9 0 0 1-.64 1.54H3.04a.9.9 0 0 1-.64-1.54z"/>',pico:'<path d="M12.97 5.33L3.35 14.95A1.2 1.2 0 0 0 5.05 16.65L14.67 7.03A1.2 1.2 0 0 0 12.97 5.33z"/><path d="M4.77 3.35C12.69 -.89 20.89 7.31 16.65 15.23C16.51 10 10 3.49 4.77 3.35z"/>',pollo:'<path d="M2.6 4.2C2 7.5 2.2 10.6 3.4 12.6C4.8 15 7.4 15.8 10 15.8C13.4 15.8 16 13.8 16 10.6C16 9 15.2 7.6 14.4 6.8L11.8 6.4C11.2 8.6 9.4 9.2 7.6 8.6C6 8.1 4.6 5.8 2.6 4.2z"/><path fill-rule="evenodd" d="M11.2 5.4A2.4 2.4 0 0 1 16 5.4A2.4 2.4 0 0 1 11.2 5.4zM13.5 5A.7 .7 0 0 1 14.9 5A.7 .7 0 0 1 13.5 5z"/><path d="M10.95 3.5A.95 .95 0 0 1 12.85 3.5A.95 .95 0 0 1 10.95 3.5z"/><path d="M12.4 2.6A1 1 0 0 1 14.4 2.6A1 1 0 0 1 12.4 2.6z"/><path d="M14 3.2A.9 .9 0 0 1 15.8 3.2A.9 .9 0 0 1 14 3.2z"/><path d="M15.6 4.5L18.2 5.6L15.6 6.6z"/><path d="M14.65 7.8A.85 .85 0 0 1 16.35 7.8A.85 .85 0 0 1 14.65 7.8z"/><path d="M7.65 15L7.65 17.9A.65 .65 0 0 0 8.95 17.9L8.95 15A.65 .65 0 0 0 7.65 15z"/><path d="M10.85 15L10.85 17.9A.65 .65 0 0 0 12.15 17.9L12.15 15A.65 .65 0 0 0 10.85 15z"/>',basura:'<path d="M8.2 1.8L11.8 1.8A.6 .6 0 0 1 12.4 2.4L12.4 3.8A.6 .6 0 0 1 11.8 4.4L8.2 4.4A.6 .6 0 0 1 7.6 3.8L7.6 2.4A.6 .6 0 0 1 8.2 1.8z"/><path d="M3.6 3.6L16.4 3.6A.8 .8 0 0 1 17.2 4.4L17.2 5.4A.8 .8 0 0 1 16.4 6.2L3.6 6.2A.8 .8 0 0 1 2.8 5.4L2.8 4.4A.8 .8 0 0 1 3.6 3.6z"/><path fill-rule="evenodd" d="M4.2 7.4L15.8 7.4L14.8 17.2C14.75 17.8 14.3 18.2 13.7 18.2L6.3 18.2C5.7 18.2 5.25 17.8 5.2 17.2zM8 9.4L8 9.4A.7 .7 0 0 1 8.7 10.1L8.7 15.3A.7 .7 0 0 1 8 16L8 16A.7 .7 0 0 1 7.3 15.3L7.3 10.1A.7 .7 0 0 1 8 9.4zM12 9.4L12 9.4A.7 .7 0 0 1 12.7 10.1L12.7 15.3A.7 .7 0 0 1 12 16L12 16A.7 .7 0 0 1 11.3 15.3L11.3 10.1A.7 .7 0 0 1 12 9.4z"/>',paquete:'<path d="M10 1.6L17.6 5.5L10 9.4L2.4 5.5z"/><path d="M2.4 6.9L9.35 10.45L9.35 18.2L2.4 14.6z"/><path d="M17.6 6.9L10.65 10.45L10.65 18.2L17.6 14.6z"/>',parking:'<path fill-rule="evenodd" d="M5.2 2.2L14.8 2.2A3 3 0 0 1 17.8 5.2L17.8 14.8A3 3 0 0 1 14.8 17.8L5.2 17.8A3 3 0 0 1 2.2 14.8L2.2 5.2A3 3 0 0 1 5.2 2.2zM6.7 5L10.6 5A3.3 3.3 0 0 1 10.6 11.6L9.1 11.6L9.1 15L6.7 15zM9.1 7.2L10.5 7.2A1.1 1.1 0 0 1 10.5 9.4L9.1 9.4z"/>',llave:'<path fill-rule="evenodd" d="M3.85 16.15A4.3 4.3 0 0 1 9.93 10.07A4.3 4.3 0 0 1 3.85 16.15zM5.05 14.95A1.6 1.6 0 0 1 7.31 12.69A1.6 1.6 0 0 1 5.05 14.95z"/><path d="M8.44 9.86L15.09 3.21L16.79 4.91L16.22 5.47L17.92 7.17L16.65 8.44L14.95 6.75L14.24 7.45L15.37 8.59L14.1 9.86L12.97 8.73L10.14 11.56z"/>',taller:'<path d="M11.66 6.29L14.66 3.29A4.2 4.2 0 1 0 16.71 5.34L13.71 8.34z"/><path d="M10.35 7.53L3.71 14.17A1.5 1.5 0 0 0 5.83 16.29L12.47 9.65A1.5 1.5 0 0 0 10.35 7.53z"/>',rayo:'<path d="M12 1.6L4.2 11.4L9.2 11.4L8 18.4L15.8 8.4L10.8 8.4z"/>',ayuntamiento:'<path d="M10 1.8L18.2 5.9L18.2 7.3L1.8 7.3L1.8 5.9z"/><path d="M3.5 8.5L4.8 8.5A.3 .3 0 0 1 5.1 8.8L5.1 14.2A.3 .3 0 0 1 4.8 14.5L3.5 14.5A.3 .3 0 0 1 3.2 14.2L3.2 8.8A.3 .3 0 0 1 3.5 8.5z"/><path d="M7.4 8.5L8.7 8.5A.3 .3 0 0 1 9 8.8L9 14.2A.3 .3 0 0 1 8.7 14.5L7.4 14.5A.3 .3 0 0 1 7.1 14.2L7.1 8.8A.3 .3 0 0 1 7.4 8.5z"/><path d="M11.3 8.5L12.6 8.5A.3 .3 0 0 1 12.9 8.8L12.9 14.2A.3 .3 0 0 1 12.6 14.5L11.3 14.5A.3 .3 0 0 1 11 14.2L11 8.8A.3 .3 0 0 1 11.3 8.5z"/><path d="M15.2 8.5L16.5 8.5A.3 .3 0 0 1 16.8 8.8L16.8 14.2A.3 .3 0 0 1 16.5 14.5L15.2 14.5A.3 .3 0 0 1 14.9 14.2L14.9 8.8A.3 .3 0 0 1 15.2 8.5z"/><path d="M2.2 15.6L17.8 15.6A.4 .4 0 0 1 18.2 16L18.2 17.6A.4 .4 0 0 1 17.8 18L2.2 18A.4 .4 0 0 1 1.8 17.6L1.8 16A.4 .4 0 0 1 2.2 15.6z"/>',camiseta:'<path d="M7.1 2.6C7.5 4 8.6 4.9 10 4.9C11.4 4.9 12.5 4 12.9 2.6L18.4 5.3L16.5 9.6L14.7 8.8L14.7 17.4L5.3 17.4L5.3 8.8L3.5 9.6L1.6 5.3z"/>',gema:'<path fill-rule="evenodd" d="M1.8 7.2 5.5 2.6h9l3.7 4.6L10 17.8zM3.9 7.1h12.2l-.8 1.2H4.7zM8.2 3.7h3.6l1.1 2.4H7.1z"/>',tijeras:'<path fill-rule="evenodd" d="M2.3 14.3A3.3 3.3 0 0 1 8.9 14.3A3.3 3.3 0 0 1 2.3 14.3zM4 14.3A1.6 1.6 0 0 1 7.2 14.3A1.6 1.6 0 0 1 4 14.3z"/><path fill-rule="evenodd" d="M17.7 14.3A3.3 3.3 0 0 0 11.1 14.3A3.3 3.3 0 0 0 17.7 14.3zM16 14.3A1.6 1.6 0 0 0 12.8 14.3A1.6 1.6 0 0 0 16 14.3z"/><path d="M7.2 11.4L15.6 1.8L9.6 12.8z"/><path d="M12.8 11.4L4.4 1.8L10.4 12.8z"/>',pistola:'<path fill-rule="evenodd" d="M2.4 4.4L17.4 4.4C17.85 4.4 18.2 4.75 18.2 5.2L18.2 9C18.2 9.4 18 9.7 17.6 9.9L16.9 10.2L17.9 16.6C18 17.2 17.6 17.6 17 17.6L13.9 17.6C13.4 17.6 13 17.3 12.9 16.8L12.3 13.8L9.6 13.8C8.6 13.8 7.8 13 7.8 12L7.8 10L2.4 10C2 10 1.6 9.6 1.6 9.2L1.6 5.2C1.6 4.75 1.95 4.4 2.4 4.4zM9.4 10.6L11.9 10.6L12.2 12.4L10 12.4C9.6 12.4 9.4 12.1 9.4 11.8z"/>',spray:'<path d="M4.4 9.4C4.4 7.4 5.8 6.2 7.8 6.2C9.8 6.2 11.2 7.4 11.2 9.4L11.2 17C11.2 17.7 10.7 18.2 10 18.2L5.6 18.2C4.9 18.2 4.4 17.7 4.4 17z"/><path d="M6.8 2.4L8.8 2.4A.6 .6 0 0 1 9.4 3L9.4 4.6A.6 .6 0 0 1 8.8 5.2L6.8 5.2A.6 .6 0 0 1 6.2 4.6L6.2 3A.6 .6 0 0 1 6.8 2.4z"/><path d="M12.7 3.8A1.1 1.1 0 0 1 14.9 3.8A1.1 1.1 0 0 1 12.7 3.8z"/><path d="M15.8 2.8A1.1 1.1 0 0 1 18 2.8A1.1 1.1 0 0 1 15.8 2.8z"/><path d="M15.8 6A1.1 1.1 0 0 1 18 6A1.1 1.1 0 0 1 15.8 6z"/><path d="M13.1 7.6A1.1 1.1 0 0 1 15.3 7.6A1.1 1.1 0 0 1 13.1 7.6z"/>',mira:'<path fill-rule="evenodd" d="M3.5 10A6.5 6.5 0 0 1 16.5 10A6.5 6.5 0 0 1 3.5 10zM5.3 10A4.7 4.7 0 0 1 14.7 10A4.7 4.7 0 0 1 5.3 10z"/><path d="M9.1 2L9.1 6.4A.9 .9 0 0 0 10.9 6.4L10.9 2A.9 .9 0 0 0 9.1 2z"/><path d="M9.1 13.6L9.1 18A.9 .9 0 0 0 10.9 18L10.9 13.6A.9 .9 0 0 0 9.1 13.6z"/><path d="M2 10.9L6.4 10.9A.9 .9 0 0 0 6.4 9.1L2 9.1A.9 .9 0 0 0 2 10.9z"/><path d="M13.6 10.9L18 10.9A.9 .9 0 0 0 18 9.1L13.6 9.1A.9 .9 0 0 0 13.6 10.9z"/><path d="M8.6 10A1.4 1.4 0 0 1 11.4 10A1.4 1.4 0 0 1 8.6 10z"/>',exclamacion:'<path fill-rule="evenodd" d="M2 10A8 8 0 0 1 18 10A8 8 0 0 1 2 10zM8.85 5.2L8.85 11A1.15 1.15 0 0 0 11.15 11L11.15 5.2A1.15 1.15 0 0 0 8.85 5.2zM8.65 14.4A1.35 1.35 0 0 1 11.35 14.4A1.35 1.35 0 0 1 8.65 14.4z"/>'},oc={garages:"#3b9dff",banking:"#f0c33c",shops:"#d1218e",public:"#8fa3b8",housing:"#a97bff",illegal:"#ff8a2b",racing:"#2ee6a8",activities:"#5ad2e8",mascotas:"#ffb3c7",telefonos:"#b9f36b",trabajos:"#ffd166",gasolineras:"#7ee081",emergencias:"#ff6b6b",locales:"#c8a0ff",misiones:"#ffffff",eventos:"#ffe066",aviso:"#ff3355",avisos:"#ff3355",referencia:"#2f6bff",referencias:"#2f6bff"};function nc(e){const a=parseInt(String(e).slice(1),16);return((a>>16)*299+(a>>8&255)*587+(a&255)*114)/1e3>150?"rgba(8,8,12,0.92)":"#fff"}const Ri="https://cfx-nui-origen_map/html/leaflet/1.8.0/leaflet",rc=6,ic=2e3;let eo=null;function tc(){return new Promise(e=>{const a=Date.now(),o=document.createElement("link");o.rel="stylesheet",o.href=`${Ri}.css?r=${a}`,document.head.appendChild(o);const n=document.createElement("script");n.src=`${Ri}.js?r=${a}`,n.onload=()=>e(!!window.L),n.onerror=()=>{n.remove(),o.remove(),e(!1)},document.head.appendChild(n)})}function Di(){return window.L?Promise.resolve(!0):eo||(eo=(async()=>{for(let e=0;e<rc;e++)if(e&&await new Promise(a=>setTimeout(a,ic)),window.L||await tc())return!0;return!1})().finally(()=>{eo=null}),eo)}const Vo=(e,a)=>{const o=e.__vccOpts||e;for(const[n,r]of a)o[n]=r;return o},sc={class:"ogn-mapa-ficha"},lc="https://cfx-nui-origen_map/html/teselas/styleAtlas/{z}/{x}/{y}.jpg",cc=.02072,dc=117.3,uc=172.8,pc=.75,mc=Vo({__name:"MapaFicha",props:{coords:{type:Object,default:null},puntos:{type:Array,default:()=>[]}},setup(e){const a=e,o=se(null);let n=null,r=null,i=null,l=null,t=!0;const s=[[-3400,-3500],[7600,4100]];function u(g){return g.extend({},g.CRS.Simple,{projection:g.Projection.LonLat,scale:b=>Math.pow(2,b),zoom:b=>Math.log(b)/Math.LN2,distance:(b,j)=>Math.hypot(j.lng-b.lng,j.lat-b.lat),transformation:new g.Transformation(cc,dc,-.0205,uc),infinite:!0})}function d(g){const b=g.color||oc[g.cat]||"#d8d5da",j=$i[g.icono]||$i.edificio;return`<span class="ogn-sitio" style="--fondo:${b};color:${nc(b)}"><svg viewBox="0 0 20 20" fill="currentColor">${j}</svg></span>`}function m(){const g=window.L;if(!n||!g)return;r&&n.removeLayer(r);const b=[];a.coords&&a.coords.x!=null&&b.push({x:a.coords.x,y:a.coords.y,tipo:"ubicacion"}),a.puntos.forEach(j=>b.push(j)),r=g.layerGroup(b.map(j=>g.marker([j.y,j.x],{interactive:!1,icon:g.divIcon({className:"",iconSize:[0,0],iconAnchor:[0,0],html:j.tipo==="ubicacion"?'<span class="ogn-pin"></span>':d(j)})}))).addTo(n),A()}function A(){if(!n)return;n.fitBounds(s,{animate:!1,padding:[2,2]});const g=n.getZoom()+pc,b=a.coords;b&&b.x!=null?n.setView([b.y,b.x],g,{animate:!1}):n.setZoom(g,{animate:!1})}function E(){const g=window.L;if(!(t===!1||n||!o.value)){if(!g){Di().then(b=>{b?E():console.warn("[origen_titlemenu] Leaflet no está cargado: el mapa de la ficha se queda vacío")});return}n=g.map(o.value,{crs:u(g),layers:[g.tileLayer(lc,{minZoom:0,maxZoom:5,noWrap:!0})],center:[2e3,250],zoom:1,minZoom:0,maxZoom:5,zoomSnap:0,zoomDelta:.25,zoomControl:!1,attributionControl:!1,dragging:!1,scrollWheelZoom:!1,doubleClickZoom:!1,boxZoom:!1,keyboard:!1,touchZoom:!1,tap:!1}),m(),l=setTimeout(()=>{n&&(n.invalidateSize({animate:!1}),A())},400),window.ResizeObserver&&(i=new ResizeObserver(()=>{n&&(n.invalidateSize({animate:!1}),A())}),i.observe(o.value))}}return ta(()=>a.coords,m,{deep:!0}),ta(()=>a.puntos,m,{deep:!0}),Va(E),kn(()=>{t=!1,clearTimeout(l),i&&i.disconnect(),n&&(n.remove(),n=null)}),(g,b)=>(M(),_("div",sc,[h("div",{ref_key:"lienzo",ref:o,class:"ogn-mapa-ficha__lienzo"},null,512),b[0]||(b[0]=h("div",{class:"ogn-mapa-ficha__grano"},null,-1))]))}},[["__scopeId","data-v-0adf894f"]]),Fi=["Afganistán","Albania","Alemania","Andorra","Angola","Antigua y Barbuda","Arabia Saudí","Argelia","Argentina","Armenia","Australia","Austria","Azerbaiyán","Bahamas","Bangladés","Barbados","Baréin","Bélgica","Belice","Benín","Bielorrusia","Birmania","Bolivia","Bosnia y Herzegovina","Botsuana","Brasil","Brunéi","Bulgaria","Burkina Faso","Burundi","Bután","Cabo Verde","Camboya","Camerún","Canadá","Catar","Chad","Chequia","Chile","China","Chipre","Ciudad del Vaticano","Colombia","Comoras","Corea del Norte","Corea del Sur","Costa de Marfil","Costa Rica","Croacia","Cuba","Dinamarca","Dominica","Ecuador","Egipto","El Salvador","Emiratos Árabes Unidos","Eritrea","Eslovaquia","Eslovenia","España","Estados Unidos","Estonia","Esuatini","Etiopía","Filipinas","Finlandia","Fiyi","Francia","Gabón","Gambia","Georgia","Ghana","Granada","Grecia","Guatemala","Guinea","Guinea-Bisáu","Guinea Ecuatorial","Guyana","Haití","Honduras","Hungría","India","Indonesia","Irak","Irán","Irlanda","Islandia","Islas Marshall","Islas Salomón","Israel","Italia","Jamaica","Japón","Jordania","Kazajistán","Kenia","Kirguistán","Kiribati","Kosovo","Kuwait","Laos","Lesoto","Letonia","Líbano","Liberia","Libia","Liechtenstein","Lituania","Luxemburgo","Madagascar","Malasia","Malaui","Maldivas","Malí","Malta","Marruecos","Mauricio","Mauritania","México","Micronesia","Moldavia","Mónaco","Mongolia","Montenegro","Mozambique","Namibia","Nauru","Nepal","Nicaragua","Níger","Nigeria","Noruega","Nueva Zelanda","Omán","Países Bajos","Pakistán","Palaos","Palestina","Panamá","Papúa Nueva Guinea","Paraguay","Perú","Polonia","Portugal","Reino Unido","República Centroafricana","República del Congo","República Democrática del Congo","República Dominicana","Ruanda","Rumanía","Rusia","Samoa","San Cristóbal y Nieves","San Marino","San Vicente y las Granadinas","Santa Lucía","Santo Tomé y Príncipe","Senegal","Serbia","Seychelles","Sierra Leona","Singapur","Siria","Somalia","Sri Lanka","Sudáfrica","Sudán","Sudán del Sur","Suecia","Suiza","Surinam","Tailandia","Tanzania","Tayikistán","Timor Oriental","Togo","Tonga","Trinidad y Tobago","Túnez","Turkmenistán","Turquía","Tuvalu","Ucrania","Uganda","Uruguay","Uzbekistán","Vanuatu","Venezuela","Vietnam","Yemen","Yibuti","Zambia","Zimbabue"];function Bi(e){return String(e).normalize("NFD").replace(/[̀-ͯ]/g,"").toLowerCase()}const fc=[{id:"general",titulo:"Normativa general",resumen:"Conceptos básicos, normas generales, reportes y sanciones.",fuente:"https://origenls.gitbook.io/normativa-origenls/normativa-general-origen-ls",md:`
## 1. Conceptos básicos

**1.1. In Character (IC).** Todo lo que le sucede a nuestro personaje o a nuestro entorno de la ciudad cuando estamos dentro del juego.

**1.2. Out of Character (OOC).** Todo lo que sucede o se habla fuera de nuestro personaje, tanto dentro como fuera del juego. Por ejemplo, todo lo que se hable en una llamada de Discord y no se escuche dentro del juego se considera OOC. También sería un reporte con un administrador.

**1.3. PowerGaming (PG).** El PowerGaming no está permitido. Se considera PG hacer cosas que en la vida real no podrías hacer, al no tener ni sentido ni lógica por ser imposibles de realizar. También se considera PG forzar rol a un jugador sin darle la posibilidad de reaccionar tras una acción.

Ejemplos: hablar por radio mientras estás esposado, herido o muerto; meterse en arbustos sin ser visto para tener ventaja en tercera persona; no rolear golpes o caídas de vehículos.

Excepciones: en persecuciones policiales se permite mayor libertad (montaña con deportivos), pero no saltos descontrolados ni derivados. No es necesario rolear choques en persecuciones.

**1.4. MetaGaming (MG).** El MetaGaming es utilizar información que no obtenemos en rol para beneficio de nuestro personaje o de otras personas, y no está permitido.

Se considera MG: utilizar información obtenida fuera del servidor dentro del juego, intencionadamente o por error; reconocer jugadores por la voz si van enmascarados.

**1.5. BunnyJump (BJ).** El BJ no está permitido y se produce cuando el jugador comienza a dar saltos para desplazarse más rápidamente.

**1.6. PlayerKill (PK).** El PK se aplica en situaciones donde tu personaje está totalmente inconsciente, es decir, a la espera de pulsar E para reaparecer en el hospital. Todo lo que transcurra desde ese momento hasta que te trate un EMS o reaparezcas en el hospital no podrá ser recordado.

**1.7. CharacterKill (CK).** Es cuando nuestro personaje muere de forma definitiva, incluyendo la pérdida del dinero, armas e identidad. Para poder seguir jugando se deberá crear un personaje nuevo con una historia y nombre distintos.

Tipos de CK:

- **CK propio:** decisión propia preaprobada por administración; requiere entre 15 y 22 días mínimo antes de otro CK secundario.
- **CK banda:** una banda oficial elimina a un integrante de otra banda, policía o civil; requiere aprobación previa.
- **CK policial:** una facción policial realiza el CK bajo fundamento sólido; requiere aprobación previa.

**1.8. DeathMatch (DM).** Se entiende por DM la acción de agredir o matar a otros usuarios sin motivo aparente, previo o por puro aburrimiento.

**1.9. RevengeKill (RK).** Se considera RK que, tras un rol agresivo, se tomen represalias inmediatamente contra el usuario o grupo involucrado.

**1.10. VehicleDeathMatch (VDM).** Se considera VDM provocar la inconsciencia a otro jugador usando un vehículo de forma intencionada.

**1.11. BadDriving (BD).** Hace referencia a la conducción inadecuada de un vehículo sin respetar la lógica en lo que respecta a la vida misma.

**1.12. Rol de entorno (RDE).** La ciudad tiene vida continua: transeúntes, cámaras sin audio, vecinos en ventanas y zonas restringidas como la base militar o el aeropuerto.

Las cámaras pueden rolearse solo donde estén físicamente instaladas, excepto en comisaría, sucursales, banco central, garaje y aeropuerto. Debe actuarse conforme al rol de entorno; por ejemplo, no entrar libremente en la base militar.

**1.13. Interpretación del personaje y de la situación.** Crea una historia para tu personaje y actúa como si existiera en la vida real en cada una de las situaciones. Siempre deberemos actuar acorde a nuestro personaje y a la personalidad que tenga: acento, forma de ser, etc.

Debe respetarse la situación del personaje, con una evolución coherente y progresiva. Los civiles no pueden actuar como banda o mafia, ni acordar vestir colores específicos (salvo en eventos).

**1.14. Fairplay.** Se deberá jugar con FairPlay: poner en primer lugar el gusto de jugar limpiamente y disfrutar del rol por encima de la ambición de victoria. Se debe dar oportunidad al resto de jugadores y no ir de forma ambiciosa y egoísta a la victoria.

Ejemplos de incumplimiento: una motocicleta entrando a un callejón en una persecución sin dar oportunidad policial; una banda secuestrando a un jefe y llevándolo a su barrio sin permitir el rescate.

**1.15. Comandos /me y /do.**

**/me:** se utiliza para acciones sin animación visual; se escribe en tercera persona. Ejemplo: «saca la libreta de su bolsillo».

**/do:** para acciones hacia otras personas. No se puede forzar su cumplimiento: hay que preguntar con /do si la aceptan. Describe expresiones, entorno o situaciones vinculadas al rol (golpes, heridas). No puede expresar pensamientos ni sentimientos, mentir con él es sancionable y no puede usarse en beneficio propio.

**1.16. AFK.** Está prohibido quedarse AFK más de 15 minutos.

**1.17. Dupeo.** Cualquier tipo de dupeo deberá ser reportado al momento al staff; de lo contrario podrás ser expulsado del servidor. De igual forma, si eres conocedor de que alguien realiza una acción igual o similar, también podrás ser expulsado de la comunidad.

**1.18. Uso de la tercera persona.** El uso de la tercera persona ÚNICAMENTE está permitido en tiroteos.

## 2. Normas generales

**2.1. Valora tu vida.** Tienes que valorar tu vida y la de tus compañeros o seres queridos como si de la vida real se tratase, y buscar siempre la supervivencia de tu personaje por encima de todo.

Debes actuar con sentido común y acorde a ello. Ignorar este hecho y no valorar tu vida conlleva una sanción por parte de administración.

**2.2. Evadir rol.** Se considera evasión de rol:

- Evitar rolear de forma intencionada con alguien.
- Quedarse AFK.
- Desconectarse para evitar un rol.
- Ir al NPC médico habiendo EMS de servicio.
- Pulsar E mientras se es tratado por la EMS.

**2.3. Cortar el rol.** Se considera cortar el rol:

- No parar el rol para reportar.
- Tratar por el chat de voz IC temas que son OOC durante el rol sin que este haya acabado.
- No esperar a que un rol termine para poder hablar sobre lo sucedido con el propio jugador.
- Utilizar de forma abusiva el chat /ooc durante el rol. SIEMPRE debes esperar a que el rol termine para aclararlo en caso de no estar de acuerdo en cómo ha transcurrido.

**2.4. Rol ajeno.** Se considera rol ajeno:

- Sin estar previamente conectado en la ciudad, conectarte y unirte a un rol ya iniciado.
- Intervenir en un rol cerrado con la policía, por ejemplo un atraco.

**2.5. Daños sensibles.**

**2.5.1. Violaciones:** las violaciones o cualquier rol de esta índole no están permitidos bajo ningún concepto.

**2.5.2. Torturas, amputaciones y mutilaciones:** no están permitidas por norma general. Solo se podrán realizar si dicho rol es pactado y aceptado por ambas partes.

**2.6. Insultos y faltas de respeto.** Los insultos y las faltas de respeto OOC no están permitidos y serán motivo de sanción administrativa. Los insultos y faltas de respeto IC están permitidos en los siguientes supuestos:

- Sentido común y uso moderado del lenguaje ofensivo.
- Si la situación y el rol lo permiten, sin insultar en exceso o de forma continuada.

Los insultos y faltas de respeto IC reiterados o que no respeten el entorno supondrán baneo permanente del servidor. Quedan prohibidos los insultos homófobos, tránsfobos y racistas, así como las palabras que son baneables en plataformas de streaming.

**2.7. Zonas seguras y calientes.**

**2.7.1. Zonas seguras:** el gimnasio del sur, ubicado en Vespucci, y las que poseen rol de entorno, como las comisarías, los hospitales, el aeropuerto o la base militar.

**2.7.2. Zonas calientes:** no hay zonas calientes, a excepción de las que poseen rol de entorno, como los barrios de banda, las sedes de mafia o el médico ilegal. Se puede iniciar un rol agresivo dentro de ellas sin necesidad de rol previo o policía de servicio. En las zonas calientes no se puede usar el /auxilio para llamar a la EMS.

**2.8. Uso de binds y emote binds.** Está totalmente prohibido el uso de binds en roles agresivos. Todo lo que conlleva rolear con otra persona en un acto delictivo o agresivo se debe rolear de manera adecuada sin emplear binds.

**2.9. Bugs y fallos.** El conocimiento y uso de cualquier tipo de bug o fallo detectado en el servidor está prohibido y será sancionado por administración en los siguientes supuestos:

- Evadir el rol o escaparse de cualquier forma.
- Beneficio propio.
- Cualquier otra situación que genere una ventaja.

**2.10. Uso de programas externos.**

- Está prohibido el uso de todos los programas externos a FiveM que den ventaja sobre otros jugadores, ya sean mods visuales o programas que mejoren la puntería.
- Los mods permitidos son NVE, FiveMods y QuantV, para una mejora visual.
- Están permitidos los programas para grabar y retransmitir (OBS, Streamlabs, etc.).
- No se permite el uso de multicuenta.
- Están prohibidas las modificaciones de la carpeta Citizen que proporcionen ventajas frente a los demás jugadores.
- Están prohibidas las miras externas.

**2.11. Publicidad de otros servidores o servicios.** Queda prohibida y será sancionada por la administración con la expulsión del servidor cualquier publicidad de otros servidores o servicios dentro del servidor, en Discord o por cualquier otro método que lo permita.

**2.13. Uso del chat y comandos de texto.**

**2.13.1. /msg:** chat OOC para hablar con otro jugador de forma privada y consultar dudas o situaciones del rol. No está permitido usarlo para quejas, protestas o incordiar a otro jugador.

**2.13.2. /auxilio y /entorno:** son comandos para mandar alertas a los EMS o policías y NUNCA pueden ser falsos. Se deben rolear en tercera persona, como si fuéramos un NPC que está observando la situación.

**2.13.3. /dado y /dados:** los dados son un sistema de azar que ayuda a resolver situaciones donde dos partes no se ponen de acuerdo, o cualquier acción que se quiera dejar en manos de la suerte.

/dado ofrece dos únicas posibilidades y está enfocado a un rol individual. Ejemplo: «/me rebusca en el bolsillo en busca de una moneda», «/do ¿encontraría alguna moneda?», y el dado determina el resultado.

/dados ofrece lo mismo pero con más posibilidades, enfocado a un rol con más gente. Ambas partes tiran, y quien saque el número más alto lleva la razón. En caso de empate se repite la tirada.

**2.13.4. Chat de voz:** JAMÁS se podrá hablar OOC por el chat de voz, salvo que la administración lo permita. Está prohibido usar un simulador de voz, ya que ensucia la experiencia de los demás jugadores, salvo que esté previamente aceptado por la administración.

**2.14. Vestimenta.** Se puede identificar a la gente por su apariencia siempre y cuando sean casos muy evidentes.

**2.15. Slots de personajes.** No está permitido tener un personaje en banda, mafia o crew y otro en la policía.

**2.16. Robo de vehículos.** Los vehículos únicamente podrán robarse con fines ilícitos o para realizar un desplazamiento puntual del punto A al punto B, debiendo posteriormente deshacerse del vehículo.

Si dejas un vehículo robado fuera y entras a un housing, hotel u otro interior, el vehículo desaparecerá. En estos casos no se realizarán devoluciones ni recuperaciones.

**2.17. Civiles ilegales.**

- No está permitido realizar roles de extorsión o protección en locales bajo ningún concepto sin aprobación administrativa.
- NO está permitido robar o secuestrar a un trabajador en su zona de trabajo siempre que realice su labor de forma no conflictiva y con rol previo. Solo se podrá realizar un rol agresivo a un local si está aprobado por administración.
- NUNCA se podrá robar comida o bebida a una persona. Si se encuentra en maleteros u otros depósitos, sí podrá ser robada.
- Robar a personas sin un rol previo con el único fin de quitarles pertenencias se considera loot farming y está totalmente prohibido.
- No se podrá rolear como banda o PDB sin serlo oficialmente dentro del servidor.
- Si quienes van a realizar un acto delictivo son civiles, no podrán exceder de 3 integrantes en un mismo rol.
- Hay que ser consciente de que, si se va a realizar un rol contra una banda o PDB oficial, hay que atenerse a las consecuencias.
- No se podrán robar móviles ni cambiarles la contraseña. Se podrá rolear la sustracción del móvil durante un rol para obtener la información necesaria, pero deberá ser devuelto posteriormente.
- Está prohibido obligar a una persona a sacar dinero del banco.
- Está prohibido robar tablets de negocios, boosting, bandas o racing.
- Para cachear o robar a una persona muerta es necesario haber tenido un rol previo con ese jugador.
- Los civiles ilegales solo podrán hacer un máximo de 5 robos a la semana.

**2.18. Grafitis.** Queda prohibido:

- Dibujar contenido obsceno, ofensivo, marcas reales o cualquier elemento relacionado con el OOC, aplicando siempre el sentido común.
- Realizar grafitis en recintos de negocios. Solo se permitirán si los propietarios del negocio lo solicitan, ya que se consideran espacios privados y no murales públicos.
- Concentrar un número excesivo de grafitis en una misma zona, para evitar sobrecargar visualmente el área.

El incumplimiento de esta normativa conllevará una sanción.

**2.19. Imágenes OOC en el móvil.** El uso de mods, programas o cualquier tipo de ayuda externa para subir este tipo de imágenes está totalmente prohibido.

**2.20. Matrículas.**

- No se puede rolear que un vehículo no tiene matrícula visible, ya sea porque no se vea por tuneo o mediante /do.
- La única forma de encubrir tu matrícula es con el ítem de Matrícula Falsa.

**2.21. Nitro en persecuciones.** El nitro únicamente podrá utilizarse en carreras o eventos autorizados y en persecuciones de carreras.

Su uso en cualquier otro contexto, especialmente durante persecuciones de robos o actos delictivos, no está permitido. El incumplimiento conllevará la correspondiente sanción por parte del staff.

## 3. Reportes

**3.1. Procedimiento para reportar un rol.** Ambas partes deberán llegar a un entendimiento utilizando los canales adecuados (/msg o Discord), NUNCA por el chat de voz IC. En caso de no llegar a un entendimiento, se utilizarán los canales de Discord habilitados para este fin (tickets de reportes).

Queda prohibida y será motivo de sanción administrativa cualquier falta de respeto hacia la administración, así como el incumplimiento de las indicaciones que esta pueda dar en un reporte o intervención.

**3.2. Presentación de pruebas.** Las pruebas que se aporten para el reporte de un rol han de ser las obtenidas desde el punto de vista del propio jugador que reporta.

No serán válidos extractos de directos de la parte contraria, clips sin voz o en los que no se entienda, ni clips en los que no se aprecie bien la situación reportada.

## 4. Sanciones

**4.1. Infracciones de normativa.** Las infracciones de normativa conllevan una penalización dependiendo de la gravedad de la misma.

## 5. Comunicación con el staff

**5.1. Canales permitidos.** Para mantener comunicación con cualquier miembro del staff se deberá escribir a través de los Discord oficiales, abriendo los respectivos tickets, o mediante canales administrativos. Dentro del juego será mediante el sistema de reportes in game y NUNCA pidiendo la ID.

Hablar a un staff por privado está prohibido y es motivo de sanción.
`},{id:"segundo-slot",titulo:"Segundo slot",resumen:"Qué puedes y qué no puedes hacer con tu segundo personaje.",fuente:"https://origenls.gitbook.io/normativa-origenls/normativa-segundo-slot",md:`
## 1. Normas básicas

- No se puede tener un personaje de banda y otro de policía.
- Este personaje no puede tener relación familiar con el personaje principal.
- Prohibido pasarse objetos, dinero o cualquier tipo de beneficio de un personaje a otro mediante terceros usuarios.
- El personaje no puede pertenecer a la misma facción que tu personaje principal ni trabajar en el mismo comercio.
- No se puede utilizar información obtenida con un personaje en el otro (metagaming).
- No se permite crear un segundo personaje únicamente para evadir sanciones o consecuencias del primero.
- No se puede utilizar el segundo personaje para beneficiar directa o indirectamente al personaje principal.
- Cambiar constantemente entre personajes para obtener ventajas temporales podrá considerarse abuso de slot.
- La administración se reserva el derecho de retirar o suspender el acceso al segundo slot en caso de incumplimiento.
- Cualquier vacío legal o situación no contemplada en esta normativa quedará a criterio de la administración.
- El uso del segundo slot implica la aceptación total de estas normas y de futuras modificaciones que puedan añadirse.
`},{id:"casas",titulo:"Casas",resumen:"Límites de propiedad, llaves, inactividad y wipes.",fuente:"https://origenls.gitbook.io/normativa-origenls/normativa-casas",md:`
1. Un usuario podrá tener un máximo de 5 casas, siempre que sea acorde a su IDP.

2. Cada usuario será responsable de quién tiene las llaves. Si pierden el inventario porque alguien con llaves retiró cosas, no se devuelven.

3. Ante cualquier pérdida de ítems o bug debe abrirse un ticket aportando prueba en vídeo.

4. Solo se permite un cambio de casa, siempre solicitándolo por ticket y asumiendo el posible sobrecoste.

5. Si un usuario está inactivo más de 15 días naturales, la casa podrá ser retirada sin previo aviso, perdiendo lo que haya dentro, excepto que la inactividad esté justificada. Su retirada queda a criterio de la administración.

6. Las casas solo se mantienen dentro de un mismo wipe. Al haber un nuevo wipe hay que solicitarla por ticket nuevamente.

7. Si el usuario se hace CK puede reclamarla de nuevo para el nuevo personaje, siempre que esté acorde a la IDP. Si no, se le permitirá el cambio sin coste alguno.

8. Para obtener una casa siempre será por medio de ticket.

9. Las únicas casas que se pueden amueblar por fuera son aquellas obtenidas mediante experiencia y de tamaño grande.

10. No se puede obtener ningún beneficio económico de la propiedad: alquilar la propiedad, alquilar habitaciones, cobrar facturas de suministros, etc.
`},{id:"comercio",titulo:"Comercio",resumen:"Plantilla, horarios, economía, eventos, sectores y postulaciones.",fuente:"https://origenls.gitbook.io/normativa-origenls/normativa-comercio",md:`
## 1. Gestión de personal y estructura

**1.1. Capacidad de plantilla.** Máximo 30 empleados por comercio, repartidos entre horario latam y España.

**1.2. Jerarquía obligatoria.** La estructura debe incluir jefes, subjefes, encargados y empleados según niveles: niveles 0-1, 30 empleados; niveles 2-3, 35 empleados; nivel 4, 35 empleados.

**1.3. Contrataciones y despidos.** Todo movimiento debe realizarse mediante rol IC previo en las contrataciones. Prohibido contratar exclusivamente por Discord o ticket. Es necesario rol en el Discord de comercio. El jefe puede despedir cuando sea necesario.

**1.4. Uso indebido del local.** Se permite el uso del almacén con fines lícitos.

**1.5. Derecho de admisión.** Los propietarios pueden establecer listas negras, excepto si el local es el único de su tipo en el servidor.

## 2. Horarios y actividad

**2.1. Compromiso de actividad.** Tener una inactividad prolongada injustificada podrá conllevar la retirada del local por parte de la administración.

**2.2. Tiempo de servicio mínimo.** Al abrir el local al público, el trabajador debe mantenerse en servicio activo un mínimo de 30 minutos consecutivos.

**2.3. Actividad del dueño.** Debe administrar activamente: gestión de empleados, inventario y fichajes. La inactividad reiterada conlleva expropiación.

**2.4. Anuncios.** Respetar 3 minutos entre anuncios; se puede anunciar cada 30 minutos.

## 3. Economía y convenios

**3.1. Cobros.** El pago de los salarios se realiza cada 30 minutos.

**3.2. NPC y venta automática.** Cuando no hay empleados, el precio en el NPC será el doble del precio de mostrador, para fomentar el rol presencial.

**3.3. Sistema de convenios.** Sin límites. Prohibido regalar comida. Prohibidas las grúas gratis. Los descuentos son iguales dentro y fuera de servicio. Prohibido vender grandes cantidades a otros locales, solo mediante contrataciones privadas. Los locales que no sean de hostelería pueden pagar 50/50 recogiendo la comida. Se permite la entrega a otros locales.

**3.4. Porcentajes de descuento.** Trabajadores, máximo 15 %. Entre locales, máximo 10 %. Facciones del Estado, máximo 15 %.

**3.5. Control de caja.** Todo movimiento debe justificarse. Retirar sin justificar genera sanción. El dinero es solo para gastos empresariales; el uso personal implica la pérdida del negocio. La facturación es obligatoria. Prohibida la competencia desleal.

## 4. Eventos

**4.1. Número de eventos.** Uno mensual obligatorio, incluyendo colaboraciones.

**4.2. Solicitud.** Los eventos se deben notificar con un mínimo de 5 días de antelación.

**4.3. Aprobación.** Todo evento requiere aprobación previa del staff, vía ticket.

**4.4. Tope de premios.** Debe ser aprobado por administración.

**4.5. Cancelación.** Hay que avisar con antelación.

**4.6.** Diferencia mínima de 3 horas entre eventos.

**4.7. Organización.** El comercio organizador será el único responsable de la planificación, organización y correcto desarrollo del evento.

**4.8. Colaboración entre comercios.** El organizador gestiona las necesidades (catering, vehículos, decoración) con otros negocios.

**4.9. Responsabilidad del personal.** Los empleados organizadores no podrán participar como concursantes; solo funciones organizativas.

## 5. Salarios

Los salarios se generan automáticamente cada 30 minutos de servicio activo.

## 6. Primas

Basadas en horas trabajadas. Solo desde encargado hacia abajo, entregadas administrativamente. El local con más horas recibe una sorpresa. Se solicitan de domingo a lunes con capturas de Excel, tablet y reinicio de horas.

Retiro de directiva: hasta 20 000 $ por semana para uso propio, siempre que no se descapitalice el negocio.

## 7. Régimen sancionador

Tres avisos equivalen a un strike. Las siguientes sanciones serán strikes directos. Tres strikes suponen la pérdida del negocio. La contratación ilegal —pagos en negro o exceder el límite de empleados— está sancionada. El staff puede alterar condiciones o retirar sanciones.

### Reglas de conducta laboral

**Honestidad y materiales.** Prohibido robar recursos, materiales, herramientas, dinero o servicios.

**Uso de sistemas de trabajo.** Prohibido usar el menú de empleado fuera de servicio o en beneficio propio. Excepción: garaje y almacén personal antes o después de la jornada.

**Vehículos de empresa.** Exclusivamente para trabajar. Prohibido usarlos para delitos o paseos personales.

**Funciones de la directiva.** Un empleado solo sale acompañado de directiva para cerrar convenios, vender papeletas o promocionar eventos.

## 8. Normativa específica por sector

### A. Talleres mecánicos

**Legalidad.** Solo se reparan vehículos legales. El cliente debe dar las llaves voluntariamente.

**Registro.** Obligatorio registrar la matrícula, o la placa si es estatal, de cada reparación o tuneo.

**Autoservicio.** Prohibido arreglar tu propio vehículo sin facturar y registrar el servicio como si fueras un cliente.

**Uso personal.** Está prohibido que cualquier mecánico limpie, repare o modifique su propio vehículo. El incumplimiento elimina las mejoras y aplica sanción grave, con posible expulsión. Si es directiva, el taller recibe un strike; si es el dueño, pierde el local.

**Ruedas 4x4 y off-road.** Queda prohibido instalarlas en vehículos sedán o deportivos que no correspondan a esa categoría, por coherencia estética y de rendimiento.

**Servicios no permitidos.** Prohibido trabajar gratis y hacer reparaciones fuera de servicio o del taller, salvo excepciones o asistencia en carretera. El incumplimiento conlleva veto, strike o cierre.

**Restricciones de modificaciones.** Queda estrictamente prohibida la instalación de cualquier armamento o similar en vehículos.

**Facturas.** Todos los trabajos se cobran por factura. Está prohibido aceptar dinero en efectivo, salvo propinas voluntarias.

**Avisos en carretera.** Solo si queda otro mecánico en el taller.

**Tarifas.** Asistencia gubernamental (SASPA, LSPD, Sheriff, EMS, taxis), 150 $. Grúa, 200 $, más los precios adicionales del Excel.

### B. Ocio y alimentación

**Seguridad.** El personal de seguridad debe tener psicotécnico vigente.

**Control.** Registro obligatorio de las transacciones de venta.

**Combo gratuito.** Un combo 3x3 por día si se han hecho 30 minutos de servicio antes de consumirlo y se está activo y de servicio al consumir.

**Fiestas privadas.** Los empleados asisten y proporcionan comida. Los sobrantes regresan al local.

**Grupos independientes.** La contratación tiene coste obligatorio.

**Máximo combo individual.** 3x3 de comida y bebida. Alcohol sin límite.

**Facciones.** SASPA, LSPD, Sheriff y EMS compran combos 5x5, solo estando de servicio.

### Vestimenta por sector

**Mecánicos.** Cinturón de herramientas siempre puesto para cualquier reparación.

**Weazel News.** Ropa acorde al negocio o local.

**Tiendas y badulaques.** Prohibido llevar máscaras o cascos puestos mientras atiendes.

**Taxistas.** Prohibido ir con ropa que no sea acorde al rol.

**Ocio.** Ropa encajada con el local: elegante, moderna o nocturna según la temática.

El staff valorará el incumplimiento aplicando la lógica.

### Reparto y servicio

**Vehículos oficiales.** Los repartidores usan el vehículo de empresa, los taxistas el taxi oficial y los mecánicos la grúa del taller.

**Cobertura del local.** Mínimo un compañero en el establecimiento para atender a los clientes presenciales.

**Prioridad de atención.** El sistema de repartos es un extra y nunca sustituye el trato a los usuarios. La atención siempre tiene prioridad sobre las rutas automáticas.

## 9. Actividades ilegales y limitaciones

- Ningún miembro de banda es dueño de un negocio.
- Prohibido usar recursos del negocio para actos ilícitos.
- Usar vehículos robados para el comercio se considera exploit.
- Los dueños no forman parte oficial de ningún proyecto ilícito.
- Prohibido robar tablets de negocios.
- Prohibido robar en el local donde trabajas: productos, materiales o información.
- Prohibido usar recursos del trabajo para beneficiar a bandas.

**Secuestros.** Prohibido secuestrar civiles en servicio. Solo se permite con empleados de banda si son de banda, hay conocimiento de rol previo, existe rol previo justificado y está aprobado por administración. El secuestro requiere reporte con justificación de rol.

**Protección de negocios.** No se puede forzar el cierre de locales. Única excepción: cuando lo determine la policía.

## 10. Discord

- Mantener los canales actualizados es obligatorio.
- Todos con nombre IC en Discord.
- El uso indebido de los canales está sancionado.
- La sociedad se sube los domingos.
- Notificar las retiradas de dinero de la sociedad es obligatorio.
- Solo la directiva solicita rangos, pidiendo el rango superior deseado.
- Los dueños anuncian el Discord cada 24 horas en el apartado web de locales.
- Los Discord de negocios deben tener obligatoriamente rango de administración.

## 11. Multijob y multiempresa

- Tener más de un trabajo está permitido. El jefe del local puede despedir si no se cumplen los requisitos.
- El otro local queda sujeto al IDP del personaje.
- Los jefes de locales (dueños) no pueden tener un segundo trabajo.

## 12. Postulaciones

### A. Adquisición del local

**1. Obtención del negocio.** Requisitos: presentar un proyecto de negocio detallado en los periodos de postulación abiertos, completar el formulario disponible o presentar una propuesta nueva, y superar la selección administrativa.

**2. Guía para elaborar el proyecto.**

- **Información general:** nombre del negocio, ubicación en San Andreas y tipo de actividad.
- **Concepto y visión:** descripción del concepto, temática o estilo y aportación narrativa al servidor.
- **Productos y servicios:** servicios ofrecidos, productos especiales o exclusivos y política de precios aproximada.
- **Plantilla:** número de empleados inicial, cargos y funciones, horarios del negocio y del personal, y requisitos de contratación.
- **Operativa:** funcionamiento diario, eventos o actividades especiales y relación con la ciudadanía.
- **Material opcional:** bocetos, logos y referencias visuales.

### B. Pérdida del local

- Local abandonado o inactivo más allá del tiempo permitido.
- Acumulación de advertencias administrativas.
- Recibir un strike en el comercio durante los primeros 30 días desde la adjudicación.
- Las ausencias justificadas (salud, estudios, trabajo) deben notificarse previamente; un encargado autorizado asume la gestión.
- Fallecimiento del propietario (CK): el negocio se retira y la administración decide su reasignación o eliminación definitiva.
- Renuncia del propietario.
- Abandono del servidor o del negocio: se transfiere la propiedad al encargado, con aprobación administrativa, o se propone una postulación interna o pública.

### C. Sistema de productos

Los jefes de locales de venta de comida deben preparar un catálogo de productos con información precisa y estructura detallada.

Datos requeridos: nombre único, descripción, tipo (categoría del cupo del local) e imagen (enlace de fivemanage).

La información organizada evita retrasos en la validación. No se aceptan listas que excedan los límites.

## 13. Uso de la mesa DJ

Está estrictamente prohibido poner música con copyright. El incumplimiento conlleva la retirada del acceso a la mesa DJ.
`},{id:"banda-pdb",titulo:"Bandas y PDB",resumen:"Actos delictivos, armas, robos, puntos calientes y secuestros.",fuente:"https://origenls.gitbook.io/normativa-origenls/normativa-banda-y-pdb",md:`
## 1. Normas básicas

### 1.1. Actos delictivos

- Está totalmente prohibido iniciar un rol agresivo desde un vehículo. Se deberá realizar el rol una vez estemos fuera de este.
- Está prohibido usar los vehículos de trabajo para actos delictivos.
- Quedan totalmente prohibidos todos los actos delictivos y roles agresivos a falta de 30 minutos del reinicio y 15 minutos después de este.
- El tiempo máximo que puedes tener a una persona retenida será de 30 minutos. Una vez sobrepasado, deberás preguntar al secuestrado si quiere terminar el rol o continuarlo.
- NO se podrá robar ningún tipo de armamento policial (pistola, SMG, carabina, táser, etc.) en ningún momento. Excepción: en situaciones específicas de rol podrás coger las armas de la policía si tiene sentido hacerlo, para usarlas y luego tirarlas.
- Está prohibido obligar a una persona a sacar dinero del banco.
- Está prohibido vender droga a un NPC si ya le ha vendido un compañero.
- Está prohibido vender droga a NPC del barrio, y no podrán vender dentro de su barrio.
- No se podrá atracar a una persona mientras se encuentre en un menú de punto (tienda de ropa, cajero).
- NUNCA se podrá robar comida o bebida a una persona. Si se encuentra en maleteros u otros depósitos, sí podrá ser robada.
- No se podrán robar los materiales de los trabajadores NUNCA.
- Está prohibido iniciar roles agresivos durante los eventos propuestos por la administración o los locales, salvo que haya un rol previo con motivos de peso y sea aprobado previamente por la administración.
- Para cachear o robar a una persona muerta es necesario haber tenido un rol previo con ese jugador.
- Queda totalmente prohibido volver a una zona en la que hayas sido abatido hasta que se termine el rol.
- No se podrá secuestrar a un policía sin un motivo de peso justificado.
- NO está permitido robar o secuestrar a un trabajador en su zona de trabajo siempre que realice su trabajo de forma no conflictiva y con rol previo. Solo se podrá realizar un rol agresivo a un local si está aprobado por administración.
- Ningún jugador podrá efectuar un rol agresivo hacia un EMS si este se encuentra de servicio. Solo se permitirá con un rol previo de peso y con permiso de administración.
- No está permitido robar a jugadores que estén realizando trabajos no WL, como pesca o camiones, salvo que exista un rol previo que lo justifique.
- Está prohibido realizar roles agresivos en cualquier evento organizado en el servidor.

**Negociaciones en los atracos.** Si una de las dos partes decide romper negociaciones, deberá avisar; tras la rotura se deberán esperar 15 segundos antes de iniciar el tiroteo. Tras 30 minutos de persecución, si los ladrones no se han escapado ni han realizado su plan, la policía podrá intentar inutilizar los vehículos disparando a la carrocería o colocando bloqueos y pinchos estratégicamente.

**Roles agresivos.** Límite de participantes: en cualquier rol agresivo el número máximo por PDB será de 4 en el sur y 5 en el norte; por banda, 8 miembros en el sur y 10 en el norte. Si se inicia un rol agresivo contra otra banda y en la otra parte hay más de 4 personas, podrán participar todos en el momento.

Se considera rol agresivo cualquier situación que implique el uso de violencia o amenaza de violencia contra otros jugadores o bandas. Los roles agresivos deben tener una justificación coherente dentro del lore de la banda y del contexto del servidor.

**Uso del entorno.** A pesar de que los entornos se realizan de forma automática, es OBLIGATORIO mandar entorno en cualquier acción ilegal que realices. Deben ser claros e incluir vestimentas, vehículos o colores identificativos. Cualquier entorno no mandado o realizado después de la acción ilegal podrá ser sancionado.

En caso de que alguien ataque vuestro barrio podréis defenderlo entre todos, incluidos los camellos que estén dentro del barrio.

### 1.2. Uso de armas

- No se puede disparar agachado.
- Está prohibido utilizar la Q en roles agresivos.
- El uso de cualquier tipo de casco está prohibido en roles agresivos.
- Prohibido ir a tiroteos descalzo.

**1.2.1. Rol previo.** No se puede abrir fuego sin rol previo. Siempre debe haber un rol previo para realizar un rol agresivo con uso de armas de fuego o blancas, a excepción de las zonas habilitadas para ello.

**1.2.2. Principio de reacción.** El agresor, antes de abrir fuego o hacer uso de un arma blanca, deberá dar tiempo suficiente para que la víctima pueda atender su indicación y ejecutarla.

**1.2.3. Uso de armas en vehículos.** Se permite en los siguientes supuestos:

- Solo se podrá disparar a la carrocería o a las ruedas, NUNCA a matar.
- El conductor solo podrá disparar cuando su vehículo esté completamente parado. El copiloto podrá disparar con el vehículo en movimiento, siempre a la carrocería o a las ruedas.
- Prohibido iniciar un rol agresivo desde dentro del vehículo: para disparar a matar deberás estar fuera del mismo.

**1.2.4. Porte de armas.** El porte de armas de fuego en la calle está totalmente prohibido IC, y la policía podrá detener al sujeto si le ve un arma y pedirle la licencia.

## 2. Tipos de CK

Los tipos de CK están especificados en la normativa general.

## 3. Robos

### 3.1. Robos express

- Se consideran robos express: tiendas de tatuajes, casas, peluquerías y tiendas de ropa.
- Se pueden usar armas blancas.
- Los rehenes deberán ser NPCs secuestrados en la calle.
- Queda totalmente prohibido realizar bloqueos.
- En dichos robos no se podrá ir con coches de alta gama.

### 3.2. Personas en organización

- Las bandas del sur tendrán un límite de 15 oficiales; para actos delictivos solo podrán actuar 8 personas.
- Las bandas del norte tendrán un límite de 20 oficiales; para actos delictivos solo podrán actuar 10 personas.

### 3.3. Camellos

- Las organizaciones podrán tener un máximo de 5 camellos, que deberán estar incluidos en la tablet y en el Discord de ilegales.
- Los camellos tendrán que acogerse a la normativa de civiles. Si un camello va a un tiroteo o actúa con los miembros de la banda en rol agresivo y cae, será CK automático.
- Los camellos no podrán vestir con las bandanas oficiales de la banda.

## 4. Grafitis

- Está prohibido realizar grafitis que incluyan ideologías políticas, contenido sexual, esvásticas o cualquier otro tipo de contenido sensible.
- Está prohibido poner múltiples grafitis juntos en una sola zona, generando una sobrecarga para el servidor. Antes de hacerlo deberán consultar con su encargado.
- Está prohibido poner grafitis en zonas con rol de entorno (hospital, comisarías, estaciones de bomberos, etc.).

## 5. Puntos calientes

Se considera punto caliente toda zona señalizada en el mapa donde se realizan actividades ilícitas: procesado de droga, venta de armas, toma de suministros, etc.

### Entrada y permanencia

- **Zona de conflicto activo.** Al entrar en el perímetro aceptas que tu vida corre peligro. Se permite el uso de armas sin mediar palabra únicamente si hay una facción rival presente o alguien interfiriendo en la actividad.
- **Iniciación implícita.** Estar dentro del punto caliente se considera una iniciación de rol agresivo. No es necesario aviso previo por voz para disparar, aunque se recomienda para fomentar el rol.
- **Prohibición de campeo.** Está prohibido esperar fuera del perímetro para abatir a quienes salen del punto. El conflicto debe desarrollarse dentro de la zona delimitada.
- **Abandono del punto.** Una vez entras a disputarlo, si abandonas la zona tras recibir disparos no podrás volver a entrar, ni siquiera para ayudar o recoger heridos.
- **Persecuciones fuera de zona.** Queda prohibido salir del punto caliente para perseguir a otros jugadores. Si abandonas la zona, no podrás volver a entrar.
- **Prioridad del objetivo.** Siempre se debe priorizar la captura del punto caliente por encima de otras acciones.

### Vehículos y equipamiento

- **Vehículos.** No se permite el uso de vehículos blindados o de alta gama para cubrirse o atropellar dentro del punto. Tampoco se permite permanecer subido en vehículos dentro de la zona.
- **Armamento.** Solo se permite el armamento autorizado por la normativa general de facciones. El uso de explosivos está estrictamente prohibido, salvo autorización expresa en eventos administrativos.

### Policía (LSPD/BCSO)

- **Entrada de unidades.** La policía no puede patrullar puntos calientes de forma rutinaria. Solo podrá intervenir si recibe aviso de disparos, denuncia ciudadana o dispone de una investigación en curso.
- **Protocolo de asalto.** En caso de intervención se debe priorizar la preservación de la vida. El intercambio de disparos está permitido desde el primer momento, debido a la peligrosidad de la zona.

### NLR y retirada

- **Abatidos.** Si eres abatido en un punto caliente no podrás regresar a la zona hasta pasados 30 minutos reales, independientemente de si fuiste reanimado en el lugar o en el hospital.
- **Cierre de zona.** Una vez finalizado el tiempo, no se permitirá la entrada de nuevos jugadores para realizar PvP o lootear.
- **Looteo.** Está permitido lootear a jugadores abatidos siempre que la zona sea segura y se valore la vida. Los cuerpos deben ser cacheados en el mismo lugar donde cayeron; no se pueden trasladar a otra zona.
- **Combat logging.** Desconectarse durante un enfrentamiento en un punto caliente conllevará ban permanente.

### Prohibiciones estrictas

- **Zonas seguras cercanas.** Está prohibido huir de un punto caliente para refugiarse en una zona segura durante un tiroteo activo.
- **Uso de «skirts».** No se permite el uso de vestimenta que buguee animaciones o dificulte visualizar el hitbox del personaje.

## 6. Secuestros

Los secuestros no pueden durar más de 40 minutos, a no ser que la otra parte acepte estar más tiempo secuestrada vía MSG. Se podrá pedir un monto total de 10 000 $.

## 7. Secuestros en negocios

Siempre será necesario solicitar autorización previa a la administración para iniciar un rol de secuestro, aunque el conflicto haya sido iniciado por el trabajador.

### 7.1. Consideraciones generales

- Los negocios no deben utilizarse como zonas de inmunidad o refugio para evitar el rol.
- Estar de servicio en un negocio no otorga inmunidad frente a las consecuencias de un rol previo o de acciones iniciadas por el propio usuario.
- Cualquier usuario que inicie o provoque un conflicto mientras está de servicio deberá asumir las consecuencias dentro del rol.
- Si a una persona se le ha intentado secuestrar en varias ocasiones sin éxito fuera del local, transcurridas más de 24 horas quedará autorizado realizar el secuestro en el local si lo está utilizando para evitar el rol, siempre que no se afecte a los demás usuarios que estén desarrollando su rol en el lugar.
- Únicamente podrá secuestrarse a la persona que era el objetivo desde el inicio. Si un usuario ajeno interviene en dicho rol, tendrá que asumir las consecuencias.
- Está totalmente PROHIBIDO secuestrar en un evento.

### 7.2. Secuestro a miembros de bandas

Un usuario que pertenezca a una organización criminal y se encuentre trabajando en un negocio podrá ser secuestrado únicamente si se cumple alguna de estas condiciones:

- Existe un rol previo justificado entre las organizaciones implicadas.
- El usuario se refugia en el negocio para evitar continuar un rol agresivo iniciado previamente.
- El usuario provoca o inicia un conflicto con otra organización mientras se encuentra de servicio.

Los miembros de organizaciones criminales deben respetar la normativa del negocio mientras estén de servicio. Iniciar roles agresivos estando de servicio queda prohibido; tampoco se podrán iniciar roles agresivos sin sentido contra un negocio. Si un miembro de banda inicia un rol agresivo estando de servicio, la organización afectada quedará autorizada a secuestrarlo. No está permitido entrar de servicio con el objetivo de evitar un rol que ya se encuentra en curso.

### 7.3. Secuestro a civiles

Un civil que se encuentre trabajando en un negocio podrá ser secuestrado únicamente si existe una justificación previa dentro del rol, y deberá ser una situación con mucho peso. Se considerará justificado cuando:

- Exista un rol previo justificado contra el civil, pudiendo presentarse pruebas si la administración lo solicita.
- El civil inicie un conflicto o provoque a una organización criminal estando de servicio.
- El civil se refugie en un negocio tras haber participado en un rol agresivo contra una organización criminal.
- El civil provoque repetidamente a una organización criminal y utilice el negocio como refugio para evitar las consecuencias del rol.

### 7.4. Inicio de conflictos en negocios

Las organizaciones criminales tienen prohibido iniciar conflictos dentro de negocios sin una justificación previa en rol aprobada por administración. Los civiles, legales o ilegales, tienen prohibido iniciar roles agresivos mientras se encuentren de servicio en un negocio.

Si un civil inicia un conflicto estando de servicio podrá sufrir consecuencias dentro del rol, incluido el secuestro —siempre se deberá intentar solucionar el conflicto sin llegar a él—, y podrá recibir una sanción fuera de rol por iniciar rol agresivo en servicio.

La administración se reserva el derecho de revisar o autorizar cualquier situación que genere dudas o posibles abusos de esta normativa. Siempre deberán grabarse los roles agresivos en negocios por si se requieren dichas grabaciones.

## 8. Matrículas

- No se puede rolear que un vehículo no tiene matrícula visible, ya sea porque no se vea por tuneo o mediante /do.
- La única forma de encubrir tu matrícula es con el ítem de Matrícula Falsa.

## 9. Soporte y reportes

Deben tenerse grabados los roles agresivos para poder abrir un ticket de reporte. Sin pruebas no se aceptará el reporte, y está prohibido utilizar pruebas del stream de otras personas.
`},{id:"crews",titulo:"Crews",resumen:"Carreras, conducta en pista, actividad y taller ilegal.",fuente:"https://origenls.gitbook.io/normativa-origenls/normativa-crews",md:`
## 1. Respeto en la pista

**1.1.** Se exige respeto entre corredores: evitar golpes innecesarios y trazadas sin sentido.

## 2. Falta de respeto

**2.1.** Prohibido utilizar nombres troles, ofensivos o sensibles, tanto en la tablet como en las matrículas falsas.

## 3. Brake boosting

**3.1.** Se prohíbe frenar y acelerar de forma intencionada para ganar boost en baches o alcantarillas.

**3.2.** El abuso conlleva expulsión permanente del sistema de carreras.

## 4. Abuso de bumps

**4.1.** Prohibida la búsqueda intencional de bumps y el zigzagueo para incrementar la velocidad.

**4.2.** El abuso resulta en expulsión permanente del sistema de carreras.

## 5. Curb boosting

**5.1.** Totalmente prohibido el uso de bordillos para ganar velocidad mediante AD.

**5.2.** El abuso implica expulsión permanente del sistema de carreras.

## 6. En carreras

**6.1.** Las crews deberán llevar sus colores, vestimentas y accesorios.

**6.2.** Máximo 3 coches iguales por crew en una carrera.

**6.3.** Obligatorio enviar /entorno 5 minutos antes, indicando vehículos y ubicación.

## 7. Actividad

**7.1.** La inactividad del líder durante 15 días o más permite que el sublíder solicite la propiedad.

**7.2.** Si el 60 % carece de actividad durante 15 días, la administración puede disolver la crew.

## 8. Prohibiciones

**8.1.** Prohibido usar armas durante carreras activas, esperas o persecuciones.

**8.2.** Los vehículos deben ajustarse estrictamente a la categoría de la carrera.

**8.3.** No ejecutar el mismo circuito dos veces consecutivas.

**8.4.** Solo un nitro por carrera, instalado previamente.

**8.5.** Prohibidos los mods o shaders que eliminen elementos del juego.

**8.6.** Prohibido acceder a carreras en persecución policial activa.

**8.7.** Mínimo 8 personas para carreras privadas.

**8.8.** Máximo 3 carreras privadas consecutivas, para evitar el farmeo.

**8.9.** Prohibidas las palabras vetadas por Twitch en matrículas personalizadas.

## 9. UNDER (taller ilegal)

**9.1.** Solo las crews con 3 semanas o más de antigüedad pueden solicitar mecánico.

**9.2.** Prohibido utilizar menús de tuning; solo reparación mediante F7.

**9.3.** El incumplimiento resulta en pérdida automática de la crew.

**9.4.** Reparación permitida solo con carreras activas, entre eventos o al finalizar.

**9.5.** Cualquier piloto puede reparar, independientemente de su crew.
`},{id:"sams-ems",titulo:"SAMS (EMS)",resumen:"Conducta médica, avisos, grabaciones y sanidad privada.",fuente:"https://origenls.gitbook.io/normativa-origenls/normativa-sams-ems",md:`
## 1. Conducta hacia los jugadores

**1.1. Neutralidad.** El SAMS no apoyará a ningún bando; siempre se mostrará neutral en cualquier ocasión y tratará a cualquier herido con el mismo trato y profesionalidad.

**1.2. Comportamiento OOC.** No se tolerará ningún tipo de toxicidad ni mal comportamiento fuera de personaje. La profesionalidad debe mantenerse en todo momento.

**1.3. Ausencia en servicio.** Está prohibido quedarse ausente (AFK) durante el servicio más de 5 minutos.

## 2. Protocolo de actuación médica

**2.1. Valoración de la vida.** El médico siempre deberá proteger ante todo su vida y la del herido que esté tratando, priorizando la integridad propia como primer interviniente.

**2.2. Exclusividad de la facción.** Todo rol de índole médica deberá gestionarse obligatoriamente a través de la facción del SAMS.

**2.3. Medicina ilegal.** Actualmente no se practica ni se permite la medicina ilegal dentro del servidor.

## 3. Avisos médicos

**3.1. Orden de atención.** Los heridos se tratan por prioridad: personal del SAMS, empleados públicos (LSPD, etc.) y resto de jugadores.

**3.2. Ausencia durante un rol.** La SAMS puede ignorar avisos mal redactados o situaciones donde el jugador esté AFK.

**3.3. Coherencia de rol.** Los miembros de la SAMS podrán abstenerse de continuar roles que resulten incoherentes o carezcan de lógica en su continuidad narrativa.

**3.4. Evasión de rol.** Si un miembro de la SAMS está acudiendo o tratando a un jugador, está estrictamente prohibido pulsar E para reaparecer.

## 4. Grabaciones

**4.1. Revisión de grabaciones.** El personal solo podrá mostrar grabaciones a la SAPD, teniendo prohibido editar o eliminar cualquier archivo.

**4.2. Gestión de videovigilancia.** Solo la directiva tiene acceso a manipular las cámaras del hospital.

## 5. Sanidad privada y donaciones

**5.1. Cobro de servicios.** Está prohibido solicitar compensaciones económicas por servicios médicos fuera de las tasas establecidas previamente por la facción.

**5.2. Donaciones particulares.** Si un civil desea realizar una donación voluntaria y particular a un miembro de la facción como agradecimiento, este podrá aceptarla.
`},{id:"playmakers",titulo:"Playmakers",resumen:"Interpretación, cumplimiento del rol asignado y jerarquía.",fuente:"https://origenls.gitbook.io/normativa-origenls/normativa-playmakers",md:`
## 1. Rol y coherencia interpretativa

**1.1.** Todo playmaker debe interpretar su rol de manera coherente y constante.

**1.2.** Cuando se interpreta un animal está vedado emitir sonidos humanos, hablar o comunicarse de forma no acorde a la especie, y realizar acciones que no correspondan a un comportamiento animal realista.

**1.3.** El desconocimiento del rol asignado no exime de responsabilidad.

## 2. Cumplimiento del rol asignado

**2.1.** Una vez asignado un rol específico, el playmaker está obligado a cumplirlo hasta que finalice o un superior autorice su modificación o cancelación.

**2.2.** Abandonar, alterar o sabotear el rol sin autorización constituye falta grave.

**2.3.** El playmaker debe prepararse previamente para el rol asignado, considerando contexto, comportamiento y límites.

## 3. Jerarquía y respeto

**3.1.** La facción tiene cuatro niveles: playmaker en prácticas, playmaker oficial, playmaker coordinador y encargado de playmakers, cada uno con responsabilidades y facultades específicas.

## 4. Puntualidad y disponibilidad

**4.1.** Todos deben presentarse en tiempo y forma a los eventos y roles previamente confirmados.

**4.2.** Ante la imposibilidad de asistir, hay que avisar con antelación suficiente a un superior.

**4.3.** La impuntualidad reiterada puede derivar en sanciones o pérdida de confianza.

## 5. Profesionalismo en escena

**5.1.** Se exige actitud seria y profesional durante todo el rol.

**5.2.** Quedan prohibidas las actitudes que rompan la inmersión: trolear, conductas exageradas sin sentido y forzar situaciones irreales.

**5.3.** El playmaker debe actuar como herramienta de mejora, no como obstáculo.

## 6. Sanciones

**6.1.** El incumplimiento puede derivar en advertencia verbal, suspensión temporal de roles, expulsión del equipo o expulsión permanente del servidor.

**6.2.** La gravedad de la sanción queda a criterio del staff responsable.
`},{id:"streamods",titulo:"Streamers",resumen:"Requisitos, conducta en directo, sanciones y solicitud del rol.",fuente:"https://origenls.gitbook.io/normativa-origenls/normativa-streamods",md:`
## 1. Requisitos generales

1. Poseer el rol de whitelist aprobado dentro del servidor.
2. Prohibido tener roles +18 en stream; conlleva baneo.
3. No contar con sanciones graves en el historial disciplinario.
4. Mantener un rol coherente, respetuoso y de calidad conforme a los estándares del servidor.
5. Publicar obligatoriamente todo material audiovisual que incluya rol dentro del servidor.
6. Prohibido eliminar VODs del servidor. Ante problemas, comunicarlo al staff mediante ticket.
7. El título del stream debe incluir obligatoriamente el nombre «OrigenLS», sin espacios adicionales.
8. No realizar streams de otros servidores mientras se esté en directo de Origen.
9. Diferenciar claramente el rol IC del contenido OOC, evitando romper el rol durante la transmisión.

## 2. Beneficios del rol de streamer

1. Asignación de rol destacado en el servidor de Discord.
2. Promoción en los canales oficiales de Origen al iniciar transmisión.
3. Canal exclusivo para compartir clips.

## 3. Conducta en directo

1. Prohibida cualquier forma de toxicidad, directa o indirecta.
2. No desprestigiar personajes, jugadores o miembros del staff en las transmisiones.
3. Mantener actitud profesional, respetuosa y madura.
4. Prohibido realizar comentarios públicos sobre sanciones, conflictos o asuntos OOC.
5. Prohibido mostrar tickets o reportes en los streams.
6. Gestionar los inconvenientes exclusivamente mediante tickets, nunca en directo.
7. El streamer es responsable del comportamiento de su chat.
8. Prohibido burlarse de personajes, facciones o situaciones del rol.
9. Prohibido incentivar el metagaming mediante el chat o comentarios sugestivos.
10. Prohibido generar polémicas o emitir comentarios negativos en vivo.
11. Prohibido provocar a otros creadores o realizar quejas innecesarias.
12. Prohibido mostrar conversaciones privadas, sanciones o comunicaciones internas del staff.
13. Prohibido reincidir en conductas que afecten negativamente a la imagen del servidor.
14. Prohibido observar intencionadamente streams de jugadores activos para obtener ventaja.
15. Usar cuentas alternativas para espiar será sancionado.

## 4. Sanciones y advertencias

1. El rol de streamer no exime de recibir sanciones.
2. El rol de streamer puede revocarse sin previo aviso ante un incumplimiento normativo.
3. La toxicidad grave puede reportarse a plataformas externas como Twitch.
4. La manipulación, provocación o uso indebido del stream se considera falta grave.

## 5. Proceso de solicitud

1. Abrir un ticket en Discord solicitando el rol de streamer y completando la plantilla establecida.

## 6. Recomendaciones

1. Informar a la comunidad sobre las normas de comportamiento del chat.
2. Proponer ideas: eventos, dinámicas o iniciativas que aporten valor al servidor.
`},{id:"constitucion",titulo:"Constitución de San Andreas",resumen:"Principios, derechos, poderes del Estado y régimen electoral.",fuente:"https://origenls.gitbook.io/normativa-origenls/constitucion-estado-san-andreas",md:`
## Título I · Principios fundamentales

**Artículo 1. Naturaleza del Estado.** San Andreas es un Estado democrático, social y de derecho, dotado de autonomía plena para la gestión de sus asuntos internos.

**Artículo 2. Soberanía.** La soberanía reside exclusivamente en el pueblo, del cual emanan todos los poderes públicos.

**Artículo 3. Supremacía constitucional.** Esta Constitución prevalece sobre cualquier otra norma. Toda disposición contraria será nula.

**Artículo 4. Organización territorial.** El Estado se estructura en dos condados: Los Santos y Blaine. La ley podrá establecer subdivisiones administrativas adicionales.

**Artículo 5. Símbolos del Estado.** El Estado posee bandera y escudo propios, definidos por ley.

## Título II · Derechos, libertades y deberes

**Artículo 6. Derechos fundamentales.** Toda persona tiene derecho a la vida, la integridad física y moral, la libertad personal, la privacidad, la libertad de expresión y la igualdad ante la ley.

**Artículo 7. Derechos sociales.** El Estado garantizará el acceso a la educación, la salud, la vivienda digna y la protección social.

**Artículo 8. Libertades civiles.** Se reconoce la libertad de reunión, asociación, circulación y participación ciudadana.

**Artículo 9. Deberes cívicos.** Todo ciudadano deberá respetar la Constitución, colaborar con la justicia, participar en los procesos electorales y contribuir a la convivencia social.

## Título III · Organización del Estado

### Capítulo I · Poder ejecutivo

**Artículo 10. Composición.** El poder ejecutivo está integrado por el gobernador, el vicegobernador y los alcaldes de cada condado.

**Artículo 11. El gobernador.** Es la máxima autoridad del Estado, dirige la administración pública y garantiza el cumplimiento de la Constitución.

**Artículo 12. El vicegobernador.** Asiste al gobernador, participa en el proceso legislativo y lo sustituye en caso de ausencia.

**Artículo 13. Alcaldías.** Los alcaldes administran los asuntos locales y ejecutan las políticas estatales en su territorio, proponiendo leyes al Consejo Legislativo del Estado.

### Capítulo II · Poder legislativo

**Artículo 14. Naturaleza.** El poder legislativo se ejerce de manera conjunta por el gobernador y el vicegobernador, que conforman el Consejo Legislativo del Estado.

**Artículo 15. Funciones.** Corresponde al Consejo Legislativo aprobar leyes, modificar normas y supervisar la administración pública.

**Artículo 16. Participación ciudadana.** Los ciudadanos podrán presentar iniciativas legislativas mediante los mecanismos establecidos por ley.

### Capítulo III · Poder judicial

**Artículo 17. Independencia judicial.** El poder judicial actúa con plena autonomía respecto de los demás poderes.

**Artículo 18. Organización.** El sistema judicial está compuesto por jueces, fiscales y defensores públicos.

**Artículo 19. Funciones.** Corresponde al poder judicial garantizar los derechos fundamentales, resolver conflictos y controlar la legalidad de los actos administrativos.

## Título IV · Matrimonio y familia

**Artículo 20. Matrimonio civil.** El Estado reconoce el matrimonio civil como la unión legal entre dos personas.

**Artículo 21. Formalización.** El matrimonio será oficializado por un miembro del Gobierno.

**Artículo 22. Protección familiar.** El Estado promoverá la estabilidad familiar, la igualdad entre cónyuges y la protección de las familias.

## Título V · Seguridad y orden público

**Artículo 23. Fuerzas del orden.** El sistema policial está integrado por la SAPD, que integra la LSPD y la BCSO.

**Artículo 24. Competencias.** Cada cuerpo actuará en su jurisdicción bajo la coordinación del mando de la SAPD.

**Artículo 25. Uso de la fuerza.** El uso de la fuerza deberá ser proporcional, racional y sujeto a control.

## Título VI · Economía y hacienda

**Artículo 26. Sistema económico.** El Estado promoverá una economía mixta, competitiva y orientada al bienestar social.

**Artículo 27. Presupuesto estatal.** El gobernador presentará anualmente un presupuesto para su aprobación legislativa.

**Artículo 28. Fiscalidad.** Los tributos deberán ser equitativos y establecidos por ley.

## Título VII · Medio ambiente y desarrollo sostenible

**Artículo 29. Protección ambiental.** El Estado garantizará la conservación del medio ambiente y la protección de los recursos naturales.

**Artículo 30. Desarrollo sostenible.** Toda actividad económica deberá respetar criterios de sostenibilidad y equilibrio ecológico.

**Artículo 31. Áreas protegidas.** La ley podrá declarar zonas de especial protección ambiental.

## Título VIII · Cultura, educación y patrimonio

**Artículo 32. Cultura y artes.** El Estado promoverá el acceso a la cultura, el fomento de las artes y la preservación de la identidad cultural.

**Artículo 33. Patrimonio histórico.** El patrimonio histórico, artístico y arqueológico será protegido por ley.

**Artículo 34. Educación.** El Estado garantizará un sistema educativo público, accesible y de calidad.

## Título IX · Régimen electoral

**Artículo 35. Elecciones.** El gobernador, el vicegobernador y los alcaldes serán elegidos conjuntamente por sufragio universal directo.

**Artículo 36. Proceso electoral.** El voto será libre, secreto y supervisado por una autoridad electoral independiente.

## Título X · Disposiciones finales

**Artículo 37. Entrada en vigor.** La Constitución entrará en vigor tras su publicación oficial.

**Artículo 38. Reforma constitucional.** La Constitución podrá reformarse mediante el procedimiento especial establecido por ley.
`},{id:"codigo-penal",titulo:"Código penal",resumen:"Delitos, multas y penas de prisión por capítulos.",fuente:"https://origenls.gitbook.io/normativa-origenls/codigo-penal-del-estado-de-san-andreas",md:`
## Capítulo I · Seguridad vial

- **1.01** Conducir vehículo sin licencia — 1 250 $
- **1.02** Uso excesivo del claxon — 200 $
- **1.03** Giro indebido — 200 $
- **1.04** Circular en sentido contrario — 200 $
- **1.05** Mal estacionamiento — 300 $
- **1.06** Obstruir la circulación — 300 $
- **1.07** Ignorar señales de tráfico — 200 $
- **1.08** Saltarse un semáforo — 250 $
- **1.09** No ceder el paso a vehículos de emergencia — 550 $
- **1.10** Adelantamiento indebido — 250 $
- **1.11** Circular marcha atrás — 200 $
- **1.12** Conducción en malas condiciones — 250 $
- **1.13** Circular por zonas no habilitadas — 350 $
- **1.14** Circular con luces apagadas — 200 $
- **1.15** Motocicleta sin casco — 150 $
- **1.16** Conducción temeraria — 8 000 $ · 6 meses
- **1.17** Omitir indicaciones en regulación de tráfico — 300 $
- **1.18** Saltar un control de tráfico — 1 600 $ · 12 meses
- **1.19** Exceso de velocidad en vía urbana — 630 $ · 5 meses
- **1.20** Exceso de velocidad en carretera secundaria — 475 $ · 5 meses
- **1.21** Exceso de velocidad en autovía — 550 $ · 5 meses
- **1.22** Uso del teléfono móvil al volante — 250 $
- **1.23** No respetar el paso de peatones — 250 $
- **1.24** Conducir bajo los efectos del alcohol — 660 $ · 5 meses
- **1.25** Conducir bajo los efectos de estupefacientes — 850 $ · 7 meses
- **1.26** Abandono de vehículo en vía urbana — 750 $
- **1.27** Pilotar aeronave sin licencia — 15 000 $ · 20 meses
- **1.28** Pilotar aeronave en mal estado — 1 500 $ · 5 meses
- **1.29** No respetar la altitud mínima de vuelo — 2 500 $ · 10 meses
- **1.30** Estacionar aeronave en lugar no habilitado — 1 500 $ · 10 meses
- **1.31** Invadir espacios aéreos restringidos — 3 500 $ · 20 meses
- **1.32** Tráfico aéreo — 25 000 $ · 30 meses

## Capítulo II · Libertad, integridad física y conductas erróneas

- **2.01** Disturbios en vía pública — 900 $ · 5 meses
- **2.02** Agresión a un civil — 1 200 $ · 4 meses
- **2.03** Faltas de respeto a un civil — 500 $
- **2.04** Amenaza verbal a un civil — 400 $
- **2.05** Alteración del orden público — 750 $ · 5 meses
- **2.06** Allanamiento de morada — 2 500 $ · 10 meses
- **2.07** Delito de odio — 1 000 $ · 6 meses
- **2.08** Dañar mobiliario urbano — 350 $
- **2.09** Acoso psicológico — 1 400 $ · 8 meses
- **2.10** Suplantación de identidad — 3 000 $ · 10 meses
- **2.11** Circular con el rostro oculto — 450 $
- **2.12** Circular desnudo o semidesnudo — 300 $
- **2.13** Circular portando chaleco antibalas — 500 $
- **2.14** Participación en carreras ilegales — 900 $ · 6 meses
- **2.16** Prostitución — 850 $ · 8 meses
- **2.17** Explotación sexual — 2 500 $ · 13 meses
- **2.18** Agresión sexual — 1 500 $ · 10 meses
- **2.19** Abusos sexuales — 1 850 $ · 10 meses
- **2.20** Acoso sexual — 5 000 $ · 10 meses
- **2.21** Violación — 10 000 $ · 60 meses
- **2.22** Proxenetismo — 5 000 $ · 20 meses

## Capítulo III · Patrimonio y orden socioeconómico

- **3.01** Hurto — 600 $ · 5 meses
- **3.02** Robo con fuerza o intimidación — 1 000 $ · 6 meses
- **3.03** Cómplice de robo con fuerza — 850 $ · 5 meses
- **3.04** Robo de vehículo — 860 $ · 7 meses
- **3.05** Robo de vehículo de importación — 1 500 $ · 10 meses
- **3.06** Robo con fuerza en domicilio — 1 800 $ · 10 meses
- **3.07** Robo a negocio comercial — 2 000 $ · 10 meses
- **3.07.1** Intento de robo a negocio comercial — 800 $ · 5 meses
- **3.07.2** Cómplice de robo a negocio comercial — 700 $ · 5 meses
- **3.08** Robo a furgón blindado — 8 000 $ · 15 meses
- **3.08.1** Intento de robo a furgón blindado — 6 000 $ · 10 meses
- **3.08.2** Cómplice de robo a furgón blindado — 5 000 $ · 8 meses
- **3.09** Robo a joyería o galería de arte — 15 000 $ · 15 meses
- **3.09.1** Intento de robo a joyería o galería — 5 000 $ · 8 meses
- **3.09.2** Cómplice de robo a joyería o galería — 5 000 $ · 8 meses
- **3.10** Robo a Ammu-Nation — 15 000 $ · 15 meses
- **3.10.1** Intento de robo a Ammu-Nation — 5 000 $ · 8 meses
- **3.10.2** Cómplice de robo a Ammu-Nation — 5 000 $ · 8 meses
- **3.11** Robo a Life Invader — 18 000 $ · 15 meses
- **3.11.1** Intento de robo a Life Invader — 8 000 $ · 6 meses
- **3.11.2** Cómplice de robo a Life Invader — 8 000 $ · 6 meses
- **3.12** Asalto al yate — 22 000 $ · 20 meses
- **3.13** Robo a sucursal bancaria (Fleeca) — 20 000 $ · 30 meses
- **3.13.1** Intento de robo a Fleeca — 8 000 $ · 15 meses
- **3.13.2** Cómplice de robo a Fleeca — 10 000 $ · 15 meses
- **3.14** Robo al banco central — 50 000 $ · 40 meses
- **3.14.1** Intento de robo al banco central — 25 000 $ · 20 meses
- **3.14.2** Cómplice de robo al banco central — 30 000 $ · 20 meses
- **3.15** Asalto a establecimiento mayor del Estado — 70 000 $ · 45 meses
- **3.16** Asalto a laboratorios Humane — 13 000 $ · 10 meses
- **3.16.1** Intento de robo a laboratorios Humane — 8 000 $ · 5 meses
- **3.16.2** Cómplice de asalto a laboratorios Humane — 8 000 $ · 5 meses
- **3.17** Robo a casino — 22 500 $ · 15 meses
- **3.17.1** Intento de robo a casino — 10 000 $ · 5 meses
- **3.17.2** Cómplice de robo a casino — 12 000 $ · 15 meses

## Capítulo IV · Servicios estatales y autónomos

- **4.01** Estafa de local o servicio — 5 000 $ · 5 meses
- **4.02** Negar o borrar CCTV a la policía — 2 500 $ · 5 meses
- **4.03** Permitir la entrada de menores a locales — 10 000 $
- **4.04** Apropiación indebida — 6 000 $ · 15 meses
- **4.05** Posesión de objetos sin autorización — 3 000 $

## Capítulo V · Moneda, timbre y hacienda pública

- **5.01** Delito leve contra la hacienda pública — 1 000 $
- **5.02** Delito menos leve contra la hacienda pública — 3 300 $ · 7 meses
- **5.03** Delito grave contra la hacienda pública — 10 000 $ · 14 meses
- **5.04** Tráfico de divisas — 22 000 $ · 30 meses
- **5.05** Posesión de joyas — 2 500 $ · 10 meses
- **5.06** Venta de joyas — 5 000 $ · 20 meses

## Capítulo VI · Porte, tenencia y tráfico de armas u objetos ilegales

- **6.01** Exhibición de arma blanca legal — 700 $
- **6.02** Exhibición de arma blanca ilegal — 800 $
- **6.03** Tenencia de arma blanca ilegal — 1 200 $ · 6 meses
- **6.04** Exhibición de arma de fuego de calibre bajo — 3 000 $ · 10 meses
- **6.05** Exhibición de arma de fuego de calibre medio — 10 000 $ · 8 meses
- **6.06** Exhibición de arma de fuego de calibre alto — 15 000 $ · 8 meses
- **6.07** Tenencia ilegal de arma corta de fuego — 9 000 $ · 9 meses
- **6.08** Tenencia de arma de fuego de calibre bajo — 11 000 $ · 13 meses
- **6.09** Tenencia de arma de fuego de calibre medio — 16 000 $ · 15 meses
- **6.10** Tenencia de arma de fuego de calibre alto — 20 000 $ · 20 meses
- **6.11** Tráfico de armas — 30 000 $ · 25 meses
- **6.12** Posesión de herramientas de robo — 2 000 $ · 7 meses
- **6.13** Posesión de herramientas explosivas — 3 500 $ · 10 meses
- **6.14** Posesión de munición o accesorios ilegales — 100 $

## Capítulo VII · Salud pública

- **7.01** Tenencia de marihuana, hachís o crack — 260 $
- **7.02** Tenencia de metanfetamina, éxtasis o heroína — 350 $
- **7.03** Tenencia de cocaína o ayahuasca — 500 $
- **7.04** Venta menor de marihuana o hachís — 260 $ · 10 meses
- **7.05** Venta menor de metanfetamina o éxtasis — 350 $ · 10 meses
- **7.06** Venta menor de cocaína o ayahuasca — 500 $ · 10 meses
- **7.07** Venta mayor de estupefacientes — 12 000 $ · 20 meses
- **7.08** Tráfico de drogas — 20 000 $ · 25 meses
- **7.09** Consumo de estupefacientes en vía pública — 800 $

## Capítulo VIII · Integridad física ciudadana

- **8.01** Intento de secuestro de civil — 4 500 $ · 7 meses
- **8.02** Secuestro de civil — 9 000 $ · 9 meses
- **8.03** Retención ilegal — 1 500 $ · 5 meses
- **8.04** Quebrantamiento de condena — 1 000 $ · 10 meses
- **8.05** Inducción al suicidio — 10 000 $ · 15 meses
- **8.05.1** Cooperación necesaria al suicidio — 8 000 $ · 16 meses
- **8.05.2** Cooperación ejecutiva al suicidio — 12 000 $ · 18 meses
- **8.06** Intento de homicidio — 14 000 $ · 20 meses
- **8.06.1** Intento de homicidio a funcionario público — 16 000 $ · 22 meses
- **8.07** Homicidio imprudente — 15 000 $ · 25 meses
- **8.07.1** Homicidio imprudente a funcionario — 17 000 $ · 26 meses
- **8.08** Homicidio doloso — 17 000 $ · cadena perpetua
- **8.08.1** Homicidio doloso a funcionario — 20 000 $ · cadena perpetua
- **8.09** Asesinato — 25 000 $ · cadena perpetua
- **8.10** Omisión de socorro — 1 000 $ · 5 meses
- **8.11** Coacción — 3 500 $ · 10 meses
- **8.12** Negligencia médica con lesiones — 2 000 $
- **8.13** Negligencia médica con muerte — 8 000 $ · 10 meses
- **8.14** Vandalismo sobre propiedad privada — 950 $ · 5 meses

## Capítulo IX · Documentos, identificaciones y licencias

- **9.01** Falsificación de documento — 3 000 $ · 8 meses
- **9.02** Posesión de documentación no renovada — 1 000 $
- **9.03** Negativa de un agente a enseñar la placa — 1 000 $
- **9.04** Usurpación de funciones públicas — 4 000 $ · 15 meses
- **9.05** Intrusismo — 2 000 $ · 10 meses
- **9.06** Denuncia falsa o escasa — 1 000 $
- **9.07** Negativa de un civil a enseñar su identidad — 1 250 $
- **9.08** Ir indocumentado por la vía pública — 650 $

## Capítulo X · Administración pública

- **10.01** Prevaricación de funcionario público — 1 200 $ · 10 meses
- **10.02** Ingesta de drogas o alcohol en servicio — 1 200 $ · 8 meses
- **10.03** Omisión del deber de perseguir delitos — 3 000 $ · 10 meses
- **10.04** Omisión de socorro por funcionario público — 2 500 $ · 10 meses
- **10.05** Revelación de secretos — 2 500 $ · 10 meses
- **10.06** Allanamiento de domicilio — 3 500 $ · 10 meses

## Capítulo XI · Administración de justicia

- **11.01** Obstrucción a la justicia — 700 $ · 10 meses
- **11.02** Desacato a la autoridad — 1 000 $
- **11.03** Huida de la justicia — 1 600 $ · 7 meses
- **11.04** Cómplice de huida de la justicia — 1 400 $ · 5 meses
- **11.05** Agredir o amenazar a un funcionario público — 1 500 $ · 5 meses
- **11.06** Faltas de respeto a un funcionario — 750 $ · 5 meses
- **11.07** Robo a funcionario público — 4 000 $ · 15 meses
- **11.08** Violar un perímetro policial — 520 $
- **11.09** Intento de soborno a funcionario — 2 500 $
- **11.10** Soborno a funcionario público — 4 000 $ · 7 meses
- **11.11** Tomar o difamar grabaciones de un funcionario — 4 000 $ · 15 meses
- **11.12** Intento de secuestro de funcionario — 15 000 $ · 20 meses
- **11.13** Secuestro de funcionario público — 25 000 $ · 30 meses
- **11.14** Entrar en zonas de acceso policial — 1 200 $
- **11.15** Entrada no autorizada a instalaciones militares — 10 000 $ · 26 meses

## Capítulo XII · Recursos naturales y medio ambiente

- **12.01** Asesinato o caza de especies protegidas — 300 $
- **12.02** Contaminación del medio ambiente — 5 000 $ · 20 meses
- **12.03** Provocar un incendio — 1 000 $ · 10 meses

## Capítulo XIII · Animales

- **13.01** Maltrato animal — 1 250 $ · 7 meses
- **13.02** Maltrato animal con muerte — 2 500 $ · 15 meses
- **13.03** Circular sin documentación del animal — 600 $
- **13.04** Abandono animal — 1 000 $ · 5 meses
- **13.05** Posesión de perros peligrosos — 1 500 $ · 10 meses

## Capítulo XIV · Delitos contra el Estado

- **14.01** Falso reporte de bomba — 5 000 $ · 10 meses
- **14.02** Allanamiento de edificios o instalaciones públicas — 4 000 $
- **14.03** Uso indebido de la línea de emergencias — 1 000 $
- **14.04** Robo de elementos estatales — 8 000 $ · 12 meses
- **14.05** Robo de armamento estatal — 8 000 $ · 18 meses
- **14.06** Suplantación de identidad de miembro del Estado — 15 000 $ · 24 meses
- **14.07** Resistirse al arresto — 1 000 $ · 5 meses
- **14.08** Evadir el arresto — 4 000 $ · 10 meses
- **14.09** Soborno a miembro del Estado — 5 000 $ · 16 meses
- **14.10** Intento de soborno a miembro del Estado — 2 500 $ · 8 meses
- **14.11** Agresión a cargo público — 1 500 $ · 15 meses
- **14.12** Terrorismo — 150 000 $ · cadena perpetua

## Capítulo XV · Delitos del Estado

- **15.01** Resolución arbitraria — 10 000 $ · 30 meses
- **15.02** Negligencia en opción pública — 10 000 $ · 15 meses
- **15.03** Cómplice de negligencia en opción pública — 10 000 $ · 15 meses
- **15.04** Abandono de funciones públicas — 20 000 $ · 40 meses
- **15.05** Omisión de funciones públicas — 8 000 $ · 8 meses
- **15.06** Omisión de responsabilidad civil — 10 000 $ · 8 meses
- **15.07** Evasión de cargos criminales — 20 000 $ · 10 meses
- **15.08** Robo de documentos públicos — 7 500 $ · 12 meses
- **15.08** Revelación de secretos públicos — 25 000 $ · 18 meses
- **15.09** Daño por revelación de secretos — 20 meses
- **15.10** Corrupción — 40 000 $ · 40 meses
- **15.11** Coacción — 20 000 $ · 24 meses

## Capítulo XVI · Cadena perpetua

- **16.01** Cadena perpetua
`}];function ka(e){return String(e||"").replace(/\*\*(.+?)\*\*/g,"$1").replace(/`(.+?)`/g,"$1").trim()}function hc(e){const a=[];return String(e||"").split(`
`).forEach(o=>{const n=o.trim();if(!n)return;const r=n.match(/^#{2,4}\s+(.*)$/);if(r){a.push({sec:ka(r[1])});return}const i=n.match(/^\*\*(.+?)\*\*\s*(.*)$/);if(i){a.push({lead:ka(i[1]),body:ka(i[2])});return}const l=n.match(/^(\d+[.)])\s+(.*)$/);if(l){a.push({lead:l[1],body:ka(l[2])});return}const t=n.match(/^[-*]\s+(.*)$/);if(t){a.push({lead:"·",body:ka(t[1])});return}a.push({lead:"",body:ka(n)})}),a}const gc=fc.map(e=>({id:e.id,label:e.titulo,sub:e.resumen,head:"",blocks:hc(e.md)})),bc=[{id:"general",titulo:"NORMATIVA NACIÓN LS",resumen:"",fuente:"https://nacion-los-santos.gitbook.io/normativa-nacionls/normativa-nacion-ls",md:`\r
# NORMATIVA NACIÓN LS\r
\r
{% hint style="warning" %}\r
⚠️ El desconocimiento de la normativa no exime de su cumplimiento.\r
{% endhint %}\r
\r
## 1.  CONCEPTOS BÁSICOS\r
\r
1.1. :green\\_circle: In Character — IC\\\r
Todo lo que le sucede a nuestro personaje o a nuestro entorno de la ciudad cuando estamos dentro del juego.\\\r
\\\r
1.2. :red\\_circle: Out of Character — OOC\\\r
Todo lo que sucede o se habla fuera de nuestro personaje, tanto dentro como fuera del juego.\r
\r
{% hint style="info" %}\r
Por ejemplo:\\\r
• Todo lo que se hable en una llamada de Discord y no se escuche dentro del juego se considera OOC.\\\r
• Un reporte con un administrador también se considera OOC.\r
{% endhint %}\r
\r
1.3. :zap: PowerGaming — PG\\\r
El Power Gaming no está permitido.\r
\r
{% hint style="warning" %}\r
Se considera PG hacer cosas que en la vida real (IRL) no podrías hacer al no tener sentido, lógica o por ser imposibles de realizar.\\\r
También se considera PG forzar rol a un jugador sin darle la posibilidad de reaccionar tras una acción.\r
{% endhint %}\r
\r
{% hint style="info" %}\r
Ejemplos:\\\r
• :radio: Hablar por radio mientras estás esposado, herido o muerto.\\\r
• :herb: Meterse en los arbustos sin que se te vea para conseguir ventaja utilizando la vista en tercera persona.\\\r
• :red\\_car: No rolear golpes, vueltas de campana o cuando sales despedido de un vehículo.\\\r
• :wheel: Vehículos de 4 o más neumáticos: deberán pararse al tener 2 o más ruedas pinchadas. Con una rueda pinchada se deberá rolear descontrol y baja velocidad.\r
{% endhint %}\r
\r
1.4. :brain: MetaGaming — MG\\\r
El Metagaming no está permitido.\r
\r
{% hint style="warning" %}\r
Se considera MG: • Utilizar información obtenida fuera del servidor dentro del juego para obtener beneficio, intencionadamente o por error. • Reconocer a jugadores por la voz si van enmascarados.\r
\r
> :x: El MG está prohibido y conlleva sanción administrativa.\r
> {% endhint %}\r
\r
1.5. :rabbit: Bunny Jump — BJ\\\r
El BJ no está permitido. Se produce cuando el jugador comienza a dar saltos para desplazarse más rápidamente.\r
\r
1.6. :skull: Player Kill — PK\\\r
Ocurre cuando nuestro personaje queda en estado de inconsciencia y es reanimado por un EMS.\r
\r
{% hint style="info" %}\r
:arrow\\_right: Conlleva una pérdida de la memoria del rol anterior.\r
{% endhint %}\r
\r
1.7. :scales: Ajuste de cuentas\\\r
Venganza que toma una persona contra otra en respuesta a un daño recibido.\r
\r
{% hint style="warning" %}\r
Esta acción tiene que estar medida y meditada a la perfección.\r
\r
> :warning: NO debe confundirse con el concepto de RK.\r
> {% endhint %}\r
\r
1.8. :skull\\_crossbones: Character Kill — CK\\\r
Es cuando nuestro personaje muere de forma definitiva, incluyendo la pérdida de:\\\r
• :moneybag: Dinero\\\r
• :gun: Armas\\\r
• :identification\\_card: Identidad/nombre\r
\r
{% hint style="info" %}\r
Para poder seguir jugando se deberá crear un personaje nuevo con una historia y nombre distintos.\r
{% endhint %}\r
\r
1.9. :knife: Death Match — DM\\\r
El Death Match no está permitido y conlleva sanción.\r
\r
{% hint style="info" %}\r
Se considera DM:\\\r
• Agredir o matar a otros usuarios sin motivo aparente, previo o por puro aburrimiento.\r
{% endhint %}\r
\r
1.10. :arrows\\_counterclockwise: Revenge Kill — RK\\\r
El Revenge Kill no está permitido y conlleva sanción.\r
\r
{% hint style="info" %}\r
Se considera RK:\\\r
• Ignorar la pérdida de memoria producida por un PK y tomar venganza hacia la persona causante de nuestra situación.\r
{% endhint %}\r
\r
1.11. :red\\_car: Vehicle DeathMatch — VDM\\\r
El Vehicle DeathMatch no está permitido y conlleva sanción.\r
\r
{% hint style="info" %}\r
Se considera VDM:\\\r
• Provocar la inconsciencia a otro jugador usando un vehículo de forma intencionada.\r
\r
No se considerará VDM:\\\r
• Atropellar a un civil cuando intente parar el vehículo poniéndose delante estando en marcha.\r
{% endhint %}\r
\r
1.12. :oncoming\\_automobile: Bad Driving — BD\\\r
El BD no está permitido y conlleva sanción.\r
\r
{% hint style="info" %}\r
Hace referencia a la conducción inadecuada de un vehículo sin respetar la lógica en lo que respecta a la vida misma.\r
\r
Si os vais a escapar de las autoridades podéis conducir como locos por la adrenalina que acarrea la situación, pero en vuestra vida cotidiana y en el 90% del tiempo vais a ser conductores ejemplares que buscan no llamar la atención.\r
\r
Ejemplos:\\\r
• Pasar por la mitad de un estacionamiento público transitado.\\\r
• Atravesar una avenida de un costado a otro.\\\r
• Conducir por vía contraria.\r
{% endhint %}\r
\r
1.13. :city\\_dusk: Rol de entorno\\\r
La ciudad, como en la vida real, está llena de vida. Las calles están repletas de transeúntes, hay cámaras de videovigilancia, vecinos mirando por las ventanas y zonas privadas o restringidas a civiles.\r
\r
{% hint style="info" %}\r
Solo se podrá rolear que hay cámaras en aquellas zonas donde estén físicamente instaladas, excepto:\\\r
• Comisaría\\\r
• Sucursales\\\r
• Banco central\\\r
• Garaje\\\r
• Aeropuerto\r
\r
Siempre deberás actuar en consecuencia con el rol de entorno.\r
\r
Ejemplo:\\\r
• No se podría entrar en una base militar con libertad porque en la vida real habría muchos soldados armados.\r
{% endhint %}\r
\r
1.14. :performing\\_arts: Interpretación del personaje y de la situación\\\r
Crea una historia para tu personaje y actúa como si existiera en la vida real en cada situación.\r
\r
{% hint style="info" %}\r
• Respeta siempre la situación en la que se encuentra tu personaje.\\\r
• La evolución de tu PJ deberá ser coherente y progresiva.\\\r
• Los civiles NO podrán actuar como una banda o mafia, incluyendo ponerse de acuerdo para vestir colores específicos, salvo para eventos.\r
{% endhint %}\r
\r
1.15. :bug: Dupeo\\\r
Cualquier tipo de dupeo (duplicar) deberá ser reportado inmediatamente a un Administrador.\r
\r
{% hint style="warning" %}\r
De lo contrario podrás ser expulsado del servidor (baneado).\r
\r
Si eres conocedor de que alguien realiza una acción igual o similar también podrás ser expulsado de la comunidad.\r
{% endhint %}\r
\r
1.16. :writing\\_hand: Uso del /me\\\r
El /me se utiliza para expresar acciones dentro del juego que no se pueden ver visualmente porque no existe animación para ello.\r
\r
{% hint style="info" %}\r
Debe escribirse en tercera persona.\r
\r
Ejemplo: \`/me saca la libreta de su bolsillo\`\r
\r
Cuando se quiere realizar una acción hacia otra persona debemos tener en cuenta cómo respondería ésta. No se puede forzar a alguien a cumplir nuestra acción.\r
\r
Para ello se debe preguntar con el /do si la otra persona está de acuerdo en continuar el rol como nosotros deseamos.\r
{% endhint %}\r
\r
1.17. :speech\\_balloon: Uso del /do\\\r
El /do se utiliza para definir expresiones de nuestro personaje, descripciones propias, del entorno o situaciones ligadas al rol (golpes, heridas, etc.).\r
\r
{% hint style="warning" %}\r
• :x: El /do no puede expresar pensamientos ni sentimientos.\\\r
• :x: Mentir en el /do es sancionable por la administración.\\\r
• :x: Intentar moldear el entorno a nuestro favor es sancionable.\\\r
• :x: No se puede utilizar el /do en beneficio propio.\r
{% endhint %}\r
\r
1.18. :scales: FairPlay\\\r
Se deberá jugar con FairPlay, poniendo en primer lugar el gusto de jugar limpiamente y disfrutar del rol por encima de la ambición de victoria.\r
\r
{% hint style="info" %}\r
Se debe dar oportunidad al resto de jugadores y no actuar de forma ambiciosa y egoísta para conseguir la victoria.\\\r
Ejemplos de situaciones que NO respetan el FairPlay:\r
\r
:motorcycle: Persecución:\\\r
Durante una persecución entre una Akuma y un 4x4 de policía, el conductor de la Akuma se mete directamente en un callejón por el cual el 4x4 no podría entrar, sin dar oportunidad a la policía.\r
\r
:flag\\_black: Secuestro:\\\r
Una banda secuestra al jefe de la banda contraria y lo lleva directamente a su barrio sin dar oportunidad a la facción contraria de rescatarlo, dado que los barrios de bandas tienen rol de entorno y no se podría entrar.\r
{% endhint %}\r
\r
1.19. :zzz: AFK\\\r
Está prohibido quedarse AFK dentro de servicio.\r
\r
{% hint style="info" %}\r
Si necesitas un descanso rápido deberás quedarte sentado en la oficina o en tu zona de trabajo fuera de servicio.\r
{% endhint %}\r
\r
## 2. :closed\\_book: NORMAS GENERALES\r
\r
2.1. :heart: Valora tu vida\\\r
Tienes que valorar tu vida y la de tus compañeros o seres queridos como si de la vida real se tratase, buscando siempre la supervivencia de tu personaje por encima de todo.\r
\r
{% hint style="warning" %}\r
Debes actuar con sentido común y acorde a ello. Ignorar este hecho conlleva una sanción administrativa.\r
\r
Ejemplo:\\\r
Un jugador amenaza con matar a tu amigo/compañero mientras realiza la animación de rehén (/rehén).\r
\r
En la vida real debes priorizar la vida de tu amigo/compañero y levantar las manos, aunque seáis tres contra uno, porque en cualquier momento podría apretar el gatillo.\r
\r
Si te apuntan con un arma de fuego y vas desarmado o llevas un arma cuerpo a cuerpo estás obligado a valorar tu vida y acatar las órdenes de la persona que te está encañonando.\r
\r
No correr, atacar o huir.\r
\r
No hacerlo podría incurrir en un CK si la administración así lo aprueba.\r
{% endhint %}\r
\r
2.2. :door: Evadir rol\\\r
Evadir el rol no está permitido y conlleva sanción.\r
\r
{% hint style="info" %}\r
Se considera evasión de rol:\\\r
• Evitar rolear de forma intencionada con alguien.\\\r
• Quedarse AFK (Away From Keyboard).\\\r
• Desconectarse para evitar un rol.\r
{% endhint %}\r
\r
2.3. :keyboard: Uso de Binds & Emote Binds\\\r
Está totalmente prohibido el uso de Binds en roles agresivos.\r
\r
{% hint style="warning" %}\r
Todo lo que conlleve rolear con otra persona en un acto delictivo/agresivo se debe rolear de manera adecuada sin emplear Binds.\r
{% endhint %}\r
\r
2.4. :scissors: Cortar el rol\\\r
Cortar el rol no está permitido y conlleva sanción.\r
\r
{% hint style="warning" %}\r
Se considera cortar el rol: • Reportar en mitad de un rol. • Tratar por el chat de voz IC temas que son OOC durante el rol sin que este haya acabado. • No esperar a que un rol termine para poder hablar sobre lo sucedido con el propio jugador. • Utilizar de forma abusiva el chat /ooc durante el rol.\r
\r
> :warning: SIEMPRE debes esperar a que el rol termine para aclararlo en caso de no estar de acuerdo con cómo ha transcurrido.\r
> {% endhint %}\r
\r
2.5. :shield: Zonas seguras / Chill\r
\r
{% hint style="info" %}\r
Las zonas seguras del servidor son: • :police\\_officer: Cualquier comisaría debido al rol de entorno. • :person\\_lifting\\_weights: Cualquier gimnasio de la ciudad. • :tennis: Las canchas de tenis. • :boxing\\_glove: Zona de pulsos. • :hospital: El recinto de los hospitales de todo San Andreas.\r
{% endhint %}\r
\r
2.6. :handshake: Insultos y faltas de respeto\r
\r
{% hint style="warning" %}\r
Los insultos y faltas de respeto OOC no están permitidos y serán motivo de sanción administrativa.\r
\r
Los insultos y faltas de respeto IC están permitidos en los siguientes supuestos:\\\r
• Sentido común y uso moderado del lenguaje ofensivo.\\\r
• Si la situación y el rol lo permiten, sin insultar en exceso o de forma continuada.\r
\r
Los insultos y faltas de respeto IC reiterados y/o que no respeten el entorno podrán acarrear una sanción administrativa.\r
{% endhint %}\r
\r
{% hint style="danger" %}\r
\r
> \uFEFFProhibidos los insultos homófobos o racistas que pueden ser baneables en plataformas de streaming.\r
> {% endhint %}\r
\r
2.7. :computer: Uso de programas externos\r
\r
{% hint style="info" %}\r
Está prohibido el uso de todos los programas externos a FiveM que den una ventaja sobre otros jugadores, ya sean mods visuales o programas que mejoren el AIM.\r
{% endhint %}\r
\r
{% hint style="warning" %}\r
:white\\_check\\_mark: Mods permitidos: NVE y Redux para mejora visual. :white\\_check\\_mark: Programas para grabar y retransmitir streams: OBS, StreamLabs, etc.\r
\r
:x: No se permite el uso de multicuenta.\\\r
&#x20;:x: Están prohibidas las modificaciones de la carpeta Citizen que proporcionen ventajas.\\\r
&#x20;:x: Están prohibidas las miras externas.\r
{% endhint %}\r
\r
2.8. :round\\_pushpin: Chip localizador\r
\r
{% hint style="info" %}\r
La Policía es la única facción que lleva y puede rolear un chip localizador.\r
{% endhint %}\r
\r
2.9. :no\\_entry\\_sign: Rol ajeno\r
\r
{% hint style="warning" %}\r
Se considera rol ajeno:\\\r
• Sin estar previamente conectado en la ciudad, conectarte y unirte a un rol ya iniciado.\\\r
• Intervenir en un rol cerrado con la policía (por ejemplo: atracos).\r
{% endhint %}\r
\r
2.10. :loudspeaker: Publicidad de otros servidores y/o servicios (SPAM)\r
\r
{% hint style="danger" %}\r
Queda prohibido y será sancionado por la administración con la expulsión del servidor cualquier publicidad de otros servidores y/o servicios dentro del servidor, en Discord o por cualquier otro método que lo permita.\r
{% endhint %}\r
\r
2.11. :bug: Bugs y Fallos\r
\r
{% hint style="warning" %}\r
El conocimiento y uso de cualquier tipo de bug y/o fallo detectado en el servidor está prohibido y será sancionado por administración en los siguientes supuestos:\\\r
• Evadir el rol o escaparse de cualquier forma.\\\r
• Beneficio propio.\\\r
• Cualquier otra situación que genere una ventaja.\r
{% endhint %}\r
\r
2.12. :warning: Daños sensibles\r
\r
2.12.1. :no\\_entry\\_sign: Violaciones\r
\r
{% hint style="danger" %}\r
Las violaciones no están permitidas por norma general.\r
{% endhint %}\r
\r
2.12.2. :chains: Torturas, amputaciones y mutilaciones\r
\r
{% hint style="warning" %}\r
La tortura, amputación o mutilación de cualquier parte del cuerpo no está permitida por norma general.\r
\r
Solo se podrá realizar si dicho rol es pactado y aceptado por ambas partes.\r
{% endhint %}\r
\r
2.13. :speech\\_balloon: Uso del chat y comandos de texto\r
\r
2.13.1. \`/msg\`\r
\r
{% hint style="info" %}\r
Chat OOC para hablar con otro jugador de forma privada.\r
{% endhint %}\r
\r
2.13.2. \`/auxilio\` y \`/entorno\`\r
\r
{% hint style="info" %}\r
Son comandos para mandar alertas a EMS o Policía y NUNCA pueden ser falsos.\r
\r
Se deben rolear en tercera persona como si fuéramos un “sin mente” o NPC que esté especteando la situación.\r
{% endhint %}\r
\r
2.13.3. \`/dado\` y \`/dados\`\r
\r
{% hint style="info" %}\r
Los dados son un sistema de azar para resolver situaciones donde dos partes no se pongan de acuerdo o cualquier acción que se quiera dejar en manos de la suerte.\\\r
\\\r
:game\\_die: \`/dado\`\r
\r
Ofrece la posibilidad de que algo salga bien o mal. El azar juega 2 únicas posibilidades y está enfocado a un rol más individual.\r
\r
Ejemplo: \`/me rebusca en el bolsillo en busca de una moneda.\` \`/do ¿encontraría alguna moneda?\` \`/dado\`\r
\r
XXXX ha tentado a la suerte y le ha salido mal.\r
\r
El azar ha determinado que nuestro personaje no tendría ninguna moneda en su bolsillo.\r
\r
#### :game\\_die: \`/dados\`\r
\r
Ofrece lo mismo que /dado, pero permite añadir más posibilidades y está enfocado a roles donde participa más gente.\r
\r
Si se quiere dejar en manos del azar un rol con otra persona, ambas partes deben tirar dados (\`/dados\`) y la persona que saque el número más alto tendrá la razón.\r
\r
Ejemplo: \`/me le mete la mano en el bolsillo\` \`/do ¿se daría cuenta?\`\r
\r
XXXX ha lanzado dados y le ha salido un 5.\r
\r
Si la otra persona involucrada saca un número superior a 5 llevará la razón.\r
\r
En caso de sacar el mismo número se deberá repetir la tirada de dados.\r
{% endhint %}\r
\r
2.13.4. :microphone2: Chat de voz\r
\r
{% hint style="warning" %}\r
• JAMÁS se podrá hablar OOC en el chat de voz excepto si la administración lo permite.\\\r
• Está prohibido usar un simulador de voz, ya que ensucia la experiencia de los demás jugadores.\\\r
• Para simular una conversación por radio es obligatorio que se te escuche tanto dentro del juego como en el programa de voz (TeamSpeak) para Policía y EMS.\r
{% endhint %}\r
\r
2.14. :oncoming\\_automobile: Vehículos y casas de donación\r
\r
{% hint style="danger" %}\r
2.14.1.\\\r
Está prohibida la reventa tanto de coches de donación como de casas de donación.\r
{% endhint %}\r
\r
2.15. :red\\_car: Robo de vehículos\r
\r
{% hint style="info" %}\r
Se permite el robo de vehículo, siempre y cuando no se utilice de manera abusiva y enviando siempre el comando \`/forzar\`.\r
{% endhint %}\r
\r
2.16. :tractor: Uso de vehículos en trabajos de Ayuntamiento\r
\r
{% hint style="danger" %}\r
Está prohibido usar vehículos ajenos a la empresa en trabajos en los que se te asigna un vehículo para poder ejercer dicha labor.\r
{% endhint %}\r
\r
{% hint style="info" %}\r
Ejemplo:\\\r
No puedes usar una hidro-avioneta personal o robada para realizar el trabajo de buzo cuando el encargado de este trabajo te está asignando una barca.\r
{% endhint %}\r
\r
## 3.📕 **NORMATIVA ESPECÍFICA**\r
\r
3.1. :shirt: Vestimenta\r
\r
{% hint style="info" %}\r
• :identification\\_card: El ID (documento de identidad) es OBLIGATORIO llevarlo siempre encima y nunca puede ser falso.\\\r
• En él podremos observar el nombre del individuo.\\\r
• Se puede identificar a la gente por su ropa siempre y cuando sean casos muy evidentes.\r
{% endhint %}\r
\r
3.2. :fire: Zonas calientes\r
\r
{% hint style="info" %}\r
Las zonas calientes son: • Sedes de mafia. • Barrios de banda con rol de entorno. • Puntos de recogida de semillas de marihuana. • Médico ilegal.\r
\r
Si puedes ver la zona y los jugadores que están en ella se considera que estás dentro de un punto caliente.\r
\r
En los puntos calientes: • Se puede iniciar rol agresivo sin necesidad de rol previo o policía de servicio. • Todo jugador que muera en dichas zonas siempre llevará un PK y no podrá ser reanimado por un EMS. • Por lo tanto, no se puede usar \`/auxilio\`.\r
{% endhint %}\r
\r
3.3. :bust\\_in\\_silhouette: Slots de personajes\r
\r
{% hint style="danger" %}\r
No está permitido tener un personaje en banda/mafia y otro en la Policía.\r
{% endhint %}\r
\r
## 4. 🚑 TRABAJOS DE OPOSICIÓN, AYUNTAMIENTO Y LOCALES\r
\r
4.1. :ambulance: EMS\r
\r
4.1.1. :dizzy\\_face: Estado de inconsciencia\r
\r
{% hint style="info" %}\r
Un jugador en estado de inconsciencia no podrá hablar o comunicarse con terceros hasta que un EMS haya tratado las heridas adecuadamente.<br>\r
{% endhint %}\r
\r
4.1.2. :game\\_die: Dados con EMS\r
\r
{% hint style="warning" %}\r
:warning: IMPORTANTE: EL USO DE DADOS ES OBLIGATORIO PARA SER REANIMADO POR UN EMS.\r
\r
El \`/dados\` se usará para determinar la gravedad de las heridas.\r
\r
SIEMPRE será obligatorio para la persona que requiera asistencia médica y NO deberán estar de acuerdo las dos partes.\r
\r
Los dados se tiran cuando el EMS los solicite, normalmente cuando comprueban la gravedad en relación con las heridas.\r
\r
Por mucho que salga un 6, si la herida ha sido un rasguño o deshidratación, no se le va a aplicar el rol de una herida fatal, sino un rol acorde a lo que el /do señale.\r
{% endhint %}\r
\r
4.2. :police\\_car: Vehículos de EMS y Policía\r
\r
{% hint style="info" %}\r
El uso de vehículos de EMS y Policía por parte de cualquier jugador no está permitido como norma general.\r
\r
El uso de un vehículo de policía estará permitido: • Cuando no tengas opción de escapar usándolo como medio de huida.\r
\r
Debes tener en cuenta que el vehículo policial dispone de un localizador que indica su ubicación GPS.\r
\r
:arrow\\_right: Deberás utilizar el \`/entorno\` correspondiente.\r
{% endhint %}\r
\r
4.3. :telephone\\_receiver: Llamadas y mensajes a servicios públicos\r
\r
{% hint style="danger" %}\r
Las llamadas o mensajes de texto falsos a los servicios públicos (Policía, EMS, Mecánicos, Taxistas, etc.) quedan totalmente prohibidos y podrán ser sancionados.\r
\r
Todas las llamadas/mensajes de texto deben contener el motivo del aviso.\r
\r
Podrán ser ignorados aquellos que no contengan información o ésta sea insuficiente:\\\r
• :round\\_pushpin: Ubicación\\\r
• :pencil: Hechos\\\r
• :information\\_source: Información relevante\r
\r
Están prohibidos los mensajes sin sentido u ofensivos a los trabajos de oposición o locales por puro aburrimiento.\r
{% endhint %}\r
\r
## 5.📋 REPORTES\r
\r
5.1. Procedimiento para reportar un rol\r
\r
{% hint style="warning" %}\r
Ambas partes deberán llegar a un entendimiento utilizando los canales adecuados (\`/msg\` o Discord), NUNCA por el chat de voz IC.\r
\r
En caso de no llegar a un entendimiento, se utilizará \`/report\` especificando el motivo.\r
\r
Un administrador valorará objetivamente la situación y la resolverá de acuerdo con la normativa, aplicando las sanciones correspondientes cuando sea necesario.\r
\r
Queda prohibido y será motivo de sanción administrativa cualquier falta de respeto hacia la administración o el incumplimiento de las indicaciones que ésta pueda dar en un reporte o intervención.\r
{% endhint %}\r
\r
## 6.⚖️ SANCIONES\r
\r
6.1. Infracciones de normativa\r
\r
{% hint style="warning" %}\r
Las infracciones conllevan una penalización dependiendo de la gravedad de la misma (warn + jail/ban).\r
\r
> :red\\_circle: La acumulación de 5 WARN supone el baneo permanente de todos los servidores de Origen Network.\r
> {% endhint %}\r
\r
## 7.👮 COMUNICACIÓN CON EL STAFF\r
\r
7.1. Canales permitidos\r
\r
{% hint style="warning" %}\r
Para mantener comunicación con cualquier miembro del STAFF se deberá escribir a través de los Discord oficiales abriendo los respectivos tickets o mediante canales administrativos.\r
\r
Dentro del juego será mediante \`/report\`.\r
\r
> :x: Hablar a un STAFF por privado es motivo de sanción.\r
> {% endhint %}\r
\r
\r
---\r
`},{id:"comercios",titulo:"NORMATIVA COMERCIOS",resumen:"",fuente:"https://nacion-los-santos.gitbook.io/normativa-nacionls/normativa-comercios",md:`\r
# NORMATIVA COMERCIOS\r
\r
## NORMATIVA GENERAL<br>\r
\r
{% hint style="info" %}\r
\r
* Es obligatorio para todos los trabajadores estar en el Discord de ‘Locales NACIÓN’ y tener el rango correspondiente.\r
* Todos los trabajadores están obligados a entrar y salir de servicio cuando haya un reinicio o cuando se vaya a desconectar del juego.\r
* Todo negocio tiene que llevar un control de las horas que está abierto y cerrado en el Discord de ‘Locales NACIÓN’.\r
* El Gimnasio Sur, su aparcamiento y la zona delimitada en rojo, es considerado ‘Zona Chill’, no se pueden iniciar roles agresivos ni actos delictivos, siempre y cuando no haya un rol previo de peso que venga de fuera de la ‘Zona Chill’.\r
* No se podrá retirar dinero de la sociedad de los talleres y concesionarios sin autorización de los encargados de locales, excepto para abastecimiento de alimentos y materiales, comisiones o eventos.\r
* Queda totalmente prohibido usar vehículos de empresa para cometer actos delictivos.\r
* Los vehículos de empresa los podrán usar cualquier persona que trabaje en el negocio.\r
* Los locales tendrán que respetar los precios base, precios de convenio y precios máximos de la tabla de precios.\r
* Los locales no podrán traficar con materiales de trabajo.\r
  {% endhint %}\r
\r
## JEFES DE LOCAL\r
\r
{% hint style="info" %}\r
\r
* Los jefes de local podrán cometer actos delictivos, pero nunca estando de servicio.\r
* Los jefes de local deberán tener los datos de sus trabajadores apuntados: Nombre y Apellido IC, nº de teléfono IC y Discord.\r
* Los jefes de local deberán tener sus correspondientes canales actualizados: • Trabajadores: Fichas de trabajadores: Discord + Nombre y Apellido IC • Sociedad: Dinero de la sociedad y reparto de comisiones actualizado semanalmente. • Uniforme: Imágenes de los distintos uniformes del local. \\\r
  • Convenios: Convenios explicados con otros locales.\r
  {% endhint %}\r
\r
## ROBOS Y SECUESTROS\r
\r
{% hint style="warning" %}\r
\r
* No se permite robar o secuestrar a trabajadores dentro del local, ni cerca de las puertas, ni en el aparcamiento adjunto al local.\r
* Se puede robar a trabajadores mientras estén en rutas de abastecimiento y demás servicios fuera del local (convenios, repartos, venta ambulante...).\r
* Si hay un rol previo de peso que venga de fuera del local, un trabajador podrá ser secuestrado, aunque esté de servicio.\r
* Está prohibido robar materiales de trabajo bajo ningún concepto.\r
  {% endhint %}\r
\r
## MAFIAS / BANDAS\r
\r
{% hint style="warning" %}\r
\r
* Se podrá iniciar rol agresivo, secuestrar o robar a trabajadores de locales que sean miembros de mafia/banda y estén de servicio, siempre y cuando existan suficientes pruebas de que la facción atacante sepa que la persona pertenece a otra mafia/banda y que exista un rol previo.\r
* Todos los miembros de bandas y mafias podrán trabajar en todos los locales siempre y cuando cumplan la normativa, a excepción de Ammus y Concesionario.\r
* Todos los miembros de bandas y mafias podrán trabajar en trabajos de ayuntamiento.\r
* No se permite utilizar la información del trabajo para beneficio de la banda/mafia, si llegase a ocurrir se sancionará con un strike a la banda y para el local.\r
* No se pueden robar productos ni materiales de trabajos para abastecer a otro local o a la propia facción ilegal. Hacerlo conlleva una sanción grave.\r
* El uso de los servicios del local para sacar beneficio personal o para la propia facción ilegal conlleva una sanción grave.\r
  {% endhint %}\r
\r
## EMPLEADOS\r
\r
{% hint style="info" %}\r
\r
* Todos los locales podrán disponer de 2 jefes, 2 encargados y 9 empleados.\r
* Casino taxis y concesionario, podrán tener 2 jefes, 2 encargados y 20 empleados.\r
* Los empleados de cada local deberán llevar su correspondiente uniforme cuando estén de servicio.\r
* Si la administración descubre a una persona inactiva, podrá despedirla sin previo aviso.\r
* Los empleados que estén dentro de servicio no pueden cometer actos delictivos o iniciar roles agresivos.\r
  {% endhint %}\r
\r
## SEGURIDAD\r
\r
{% hint style="info" %}\r
\r
* Los negocios que requieran seguridad o vigilancia, podrán contratar en su plantilla a empleados de seguridad con la obligación de tener en regla los siguientes permisos: psicotécnico y licencia de armas. Debe estar con el correspondiente trabajo asignado IC.\r
* Los empleados de seguridad sólo pueden ejercer su puesto si hay otros compañeros de servicio en el negocio.\r
  {% endhint %}\r
\r
## AMMU-NATION\r
\r
{% hint style="warning" %}\r
\r
* Los jefes de Ammu deberán tener un control del inventario y de las ventas que realicen, pidiendo los correspondientes DNI y apuntándole.\r
* Será obligatorio tener un registro en el discord de la empresa con el DNI, licencia de armas y arma adquirida/s de cada cliente.\r
* Los encargados de locales deberán tener acceso al inventario, ventas y registro en todo momento.\r
* Se necesita licencia de armas para adquirir armas y chalecos, excepto para el bate.\r
* Límite de venta: solo se vende un arma de cada tipo por persona y semana, y 5 chalecos pesados y 5 chalecos medianos por persona y semana.\r
  {% endhint %}\r
\r
## HORARIO\r
\r
{% hint style="danger" %}\r
\r
* Todos los locales deberán abrir como mínimo 1 hora diaria.\r
  {% endhint %}\r
\r
## CONVENIOS CON LOCALES\r
\r
{% hint style="warning" %}\r
\r
* Badulaques y restaurantes: Los convenios con otros locales serán de máximo 100 de comida y 100 de bebida.\r
* Licorería: Los convenios con otros locales serán de máximo 100 botellas de alcohol.\r
* Gimnasios: Los convenios con otros locales serán de máximo 50 proteínas o 50 barritas energéticas. -Tiendas de Electrónica: Los convenios con otros locales serán máximo de 10 móviles y 10 radios. Los convenios con Badus serán máximo de 30 móviles y 30 radios.\r
* Ammus: Los convenios con otros locales será de un descuento máximo de un 20% en productos para jefes y encargados de locales.\r
* Es obligatorio respetar los precios de convenios de la tabla de productos.\r
* Queda totalmente prohibido realizar convenios exclusivos.\r
* Los convenios deben ser justos para las dos partes, no se pueden ofrecer cosas gratis o a precio base.\r
  {% endhint %}\r
\r
## LÍMITE DE VENTAS PARA CLIENTES\r
\r
{% hint style="warning" %}\r
\r
* Badulaques y restaurantes: La cantidad máxima por cliente será máximo 20 de comida y 20 de bebida.\r
* Licorería: La cantidad máxima por cliente será máximo 20 botellas de alcohol.\r
* Gimnasios: La cantidad máxima por cliente será máximo 10 proteínas o barritas energéticas y 1 tarjeta de gimnasio.\r
* Ammus: Un arma de cada tipo por persona y semana, y 5 chalecos pesados y 5 chalecos medianos por persona y semana.\r
  {% endhint %}\r
\r
## EVENTOS\r
\r
{% hint style="info" %}\r
\r
* Todos los locales de ocio deberán realizar un evento mínimo cada 15 días.\r
* Los demás locales que no sean de ocio podrán realizar eventos de forma opcional.\r
* Se deberá avisar con tiempo de los eventos en los correspondientes canales y dejar un mínimo de 2 días de diferencia, para no pisar otros eventos, si los hubiera en el mismo día.\r
  {% endhint %}\r
\r
## OWNERS (DONADORES)\r
\r
{% hint style="warning" %}\r
\r
* Si alguien deja un local por voluntad propia en menos de un mes de la adquisición del mismo, no podrá reclamar las coins usadas en ese local, hasta el siguiente wipe.\r
* Si alguien deja un local por voluntad propia después de un mes de la adquisición del mismo, tendrá que elegir entre la devolución de coins o quedarse con el dinero de la sociedad.\r
* Si se quiere cambiar de local, será mediante una donación nueva de 15 coins, con la que podrás trasladar el dinero de la sociedad (nunca los ítems), al nuevo local. Esta norma no se aplica a talleres y concesionarios.\r
* Si un local es retirado por la administración, las coins no serán devueltas hasta el siguiente wipe.\r
* Los locales son donaciones intransferibles, por lo que no se pueden alquilar, vender o transferir, ni pedir dinero IC y OCC para el uso de los mismos.\r
* Ningún OWNER puede tener más de 2 locales adquiridos.\r
  {% endhint %}\r
\r
## SANCIONES\r
\r
{% hint style="danger" %}\r
\r
* Si un negocio de ocio no planea un evento en mínimo 15 días se sancionará con un strike.\r
* Si se usa un servicio del local para uso personal, se sancionará a la persona y si pasa reiteradamente se sancionará con un strike al local.\r
* El negocio se puede llevar un strike si sus empleados no cumplen la normativa general de estar de servicio sin estar en su puesto de trabajo.\r
* Si un local no tiene los datos de sus empleados con sus correspondientes fichas podrá sancionar con un strike.\r
* Si un Ammu-Nation no registra correctamente las ventas con los correspondientes documentos, se sancionará con un strike.\r
* Se sancionará con un strike a los talleres donde los empleados se tuneen vehículos a sí mismos.\r
* Se sancionará con un strike al local que lleve 4 días seguidos sin actividad.\r
* En caso de tener strikes, la administración valorará si se retiran dichos strikes una vez haya pasado un mes y en función de la gravedad de los mismos.\r
* Si los encargados de locales observan inactividad injustificada por parte de un jefe de local, se procederá a retirarle su cargo del negocio sin previo aviso.\r
* Se procederá a retirar el negocio administrativamente a su Owner si el local acumula 5 strikes.\r
* Si un local permanece inactivo más de una semana sin justificación se retirará administrativamente.\r
* Si el Owner permanece inactivo más de 15 días en el servidor, se retirará el local automáticamente.\r
  {% endhint %}\r
\r
\r
---\r
`},{id:"bandas",titulo:"NORMATIVA BANDAS",resumen:"",fuente:"https://nacion-los-santos.gitbook.io/normativa-nacionls/normativa-bandas",md:`\r
# NORMATIVA BANDAS\r
\r
## 1. NORMAS BÁSICAS\r
\r
{% hint style="info" %}\r
\r
### 1.1. Actos delictivos\r
\r
* Los helicópteros y/o vehículos aéreos quedan totalmente prohibidos para usos delictivos.\r
* Prohibido robar a otros usuarios por las calles a no ser que estos mismos estén cometiendo un acto delictivo o se tenga un rol previo. El número máximo de civiles que pueden participar en conjunto en roles agresivos será de 2 personas.\r
* Se deberán respetar los caminos delimitados en cualquier rol que implique una persecución.\r
* Está totalmente prohibido iniciar un rol agresivo desde un vehículo. Se deberá realizar el rol una vez nos ubiquemos fuera de este.\r
* Está prohibido usar los vehículos de trabajo (ayuntamiento) para actos ilegales.\r
* Quedan totalmente prohibidos los actos delictivos como: Robo a establecimientos, coches de importación, furgón y de índole similar a falta de 30 minutos de los reinicios programados y 15 minutos después de los mismos (8:00 |14:00 | 20:00 | 02:00) Es decir, robos a civiles, venta de drogas secuestros pueden realizarse hasta los 15 minutos antes de la tormenta.\r
* Los secuestros pueden durar como máximo unos 30 minutos, aunque podrán alargarse si el rol lo exige.\r
* NO se podrá robar nada a la policía (comida, chalecos, armamento, munición...) en ningún momento (ni fuera ni dentro de servicio, ni en maleteros ni en la propia sede de la banda/mafia). Excepciones: En situaciones específicas de rol podrás coger las armas del policía si tiene sentido hacerlo (como, por ejemplo, falta de munición); luego, deberás deshacerte de ellas. Si cacheando un cuerpo se encuentra un arma reglamentaria, no será MG saber que esa persona pertenece al SAPD.\r
* Está prohibido obligar a una persona a sacar dinero del banco.\r
* No se podrá atracar a una persona mientras se encuentre en un menú de punto de tienda de ropa o cajero.\r
* NUNCA podremos robarle comida y/o bebida a una persona, si la comida/bebida se encuentra en maleteros y otros depósitos si podrá ser robada.\r
* No se podrá robar los materiales de los trabajadores siempre y cuando la persona esté trabajando en ese momento o en el punto de venta o procesado del material.\r
* NO está permitido robar o secuestrar a un trabajador en su zona de trabajo siempre que realice su trabajo de forma no conflictiva y con rol previo. Solamente se podrá realizar un rol agresivo (ataques robos o secuestros) a un trabajador si está en su trayecto de ida o vuelta.\r
* Queda terminantemente prohibido realizar roles agresivos (verbales o físicos) en eventos organizados por administración.\r
* Para cachear o robar a una persona muerta es necesario haber tenido un rol previo con el jugador.\r
* Está prohibido utilizar la Q en roles agresivos.\r
* Cuando se realice un acto delictivo tendrás que enviar un entorno con la mayor especificación posible del acto delictivo, del delincuente, del vehículo y de la dirección utilizada.\r
* Queda totalmente prohibido volver a una zona en la que hayas sido abatido hasta pasados 40 minutos.\r
* Con respecto a los secuestros, los rescates pueden ser desde 10k hasta 15k por civil, y de 15k a 20k por policía, siempre y cuando se colabore con el rol de negociación y esté presente el Fairplay.\r
* Ningún jugador podrá efectuar un rol agresivo hacia un EMS si éste se encuentra de servicio. Solo se permitirá con un rol previo de peso y con permiso de administración.\r
* Queda PROHIBIDO meterse en el agua en medio de una persecución.\r
  {% endhint %}\r
\r
{% hint style="info" %}\r
\r
### 1.2. Policía disponible\r
\r
No se pueden realizar actos delictivos si no hay 2 o más policía de servicio (excepto en las zonas calientes y reuniones de bandas/mafias).\r
\r
Para secuestrar a un policía deberán de ser mínimo 5 policías de servicio.\r
\r
Cuando se va a realizar un robo medio o superior se deberá usar el /polidispo. Acto seguido le describiremos el robo que vamos a realizar, una vez la policía haya dado el OK, se podrá realizar dicho robo.\r
{% endhint %}\r
\r
{% hint style="warning" %}\r
\r
#### 1.2.1. Drogas\r
\r
Para vender droga en el norte se deberá preguntar antes por /polidispo si hay policía disponible en el norte. En caso de que no haya policía disponible en el norte, la droga deberá venderse dentro de la ciudad.\r
\r
NO se podrá vender droga en el aeropuerto ni enfrente de comisarías por rol de entorno, tampoco en caminos secundarios o zonas alejadas de la ciudad de Los Santos o del pueblo de Sandy o Paleto.\r
\r
Se considera falta de fairplay vender droga a los NPC subido en tu propio vehículo y puede conllevar a sanciones graves.\r
\r
Está prohibido vender droga a un NPC al que ya le ha vendido un compañero.\r
\r
Será sancionada cualquier persona que vaya parando vehículos que estén transitando para venderles droga, únicamente se puede hacer con personas que están a pie.\r
\r
Solo se podrá cultivar marihuana en los territorios delimitados por el STAFF.\r
{% endhint %}\r
\r
{% hint style="warning" %}\r
\r
### 1.3. Uso de armas\r
\r
#### 1.3.1. Rol previo\r
\r
No se puede abrir fuego sin rol previo. Siempre debe de haber un rol previo de peso para realizar un rol agresivo con el uso de armas de fuego o blancas a excepción de las zonas calientes.\r
\r
#### 1.3.2. Principio de reacción\r
\r
El agresor, antes de abrir fuego o hacer uso de un arma blanca, deberá de dar el tiempo suficiente para que la víctima pueda hacer caso a su indicación o acatar su petición, es decir, dar tiempo a que la víctima pueda reaccionar a las indicaciones solicitadas y por consecuencia ejecutarlas.\r
\r
#### 1.3.3. Uso de armas en vehículos\r
\r
El uso de armas en vehículos se permite para los siguientes supuestos:\r
\r
* Solo se podrá disparar a la carrocería (NUNCA a matar).\r
* El conductor no podrá disparar en movimiento, solo podrá disparar estando parado. Sin embargo, el copiloto si podrá disparar tanto en movimiento como parado.\r
* Prohibido iniciar un rol agresivo desde encima de un vehículo.\r
* Para disparar a matar deberás estar FUERA del vehículo.\r
\r
#### 1.3.4. Porte de armas\r
\r
El porte de armas de fuego en la calle está totalmente prohibido IC y la policía podrá detener, aunque tenga la licencia de caza.\r
{% endhint %}\r
\r
## 2. TIPOS DE CK\r
\r
{% hint style="info" %}\r
\r
### 2.1. CK policial\r
\r
El CK Policial consiste en la condena a cadena perpetua de cualquier ciudadano siendo esto un CK que conlleva la pérdida del personaje e incluyendo todas sus pertenencias. Una vez en cadena perpetua se llamará a un administrador el cual procederá a mandarle a hacer una nueva identidad.\r
\r
#### 2.1.1. CK policial a civiles\r
\r
Se realizará un CK policial (cadena perpetua) a los ciudadanos que sean detenidos con un gran número de multas impagadas bajo los siguientes supuestos:\r
\r
* Si el detenido, en el momento de la detención, acumula más de 50.000$ en multas será condenado a cadena perpetua (CK policial).\r
* Si el detenido, en el momento de la detención, acumula menos de 50.000$ en multas y, una vez procesado y multado con las sanciones correspondientes, la cantidad supera los 50.000$, éste dispondrá de máximo 20 minutos para abonar el 50% de las multas impagadas para librarse de la cadena perpetua. Si no abona el 50% será condenado a cadena perpetua (CK policial).\r
\r
#### 2.1.2. CK policial a bandas/mafias\r
\r
Se realizará un CK policial (cadena perpetua) a los integrantes de grupos criminales que sean detenidos con un gran número de multas impagadas bajo los siguientes supuestos:\r
\r
* Si el detenido, en el momento de la detención, acumula más de 100.000$ en multas será condenado a cadena perpetua (CK policial)\r
* Si el detenido, en el momento de la detención, acumula menos de 100.000$ en multas y, una vez procesado y multado con las sanciones correspondientes, la cantidad supera los 100.000$, éste dispondrá de máximo 20 minutos para abonar el 50% de las multas impagadas para librarse de la cadena perpetua. Si no abona el 50% será condenado a cadena perpetua (CK policial).\r
\r
Los integrantes de estos grupos podrán iniciar un tiroteo contra la policía sin consecuencia de CK en los siguientes supuestos:\r
\r
* Persecución sin opción a escapar.\r
* Portar dinero negro o sustancias ilegales por valor superior a 100.000€, o llevar armas largas.\r
\r
### 2.2. CK de grupos criminales (banda y/o mafia)\r
\r
#### 2.2.1. CK a policía\r
\r
Un grupo criminal podrá realizar un CK a un miembro de la policía si se cumplen todas las condiciones siguientes:\r
\r
* Existen motivos de peso y probados que ponga en peligro la continuidad del grupo criminal\r
* Existe una investigación detrás que justifique el CK (se deben de aportar pruebas gráficas obtenidas IC demostrable).\r
\r
#### 2.2.2. CK a civiles e integrantes de otras bandas/mafias\r
\r
Un grupo criminal podrá realizar un CK a un civil si se cumplen todas las condiciones siguientes:\r
\r
* Existen motivos de peso que ponga en peligro la continuidad o los intereses del grupo criminal.\r
* Existe una investigación detrás que justifique el CK (se deben de aportar pruebas gráficas obtenidas IC demostrable).\r
  {% endhint %}\r
\r
## 3. ROBOS\r
\r
{% hint style="success" %}\r
\r
### 3.1. Robos pequeños\r
\r
Estos atracos están destinados tanto a civiles como a bandas/mafias. Se consideran robos pequeños tales como:\r
\r
* Badulaques, tiendas y licorerías.\r
* Robos de coches.\r
* Casas.\r
* Peluquerías.\r
* Tiendas de tatuaje.\r
\r
Las normas de estos atracos son:\r
\r
* Mínimo 2 policías y máximo 4.\r
* Los atracadores siempre tienen que ser 1 menos que la policía.\r
* No puede haber tiradores.\r
* Podrán usar armas blancas y pistolas de bajo calibre.\r
* El único rehén será el tendero NPC. Si hay jugadores en el establecimiento el atracador puede dejarlos dentro o mandarles fuera, pero en todo caso jamás podrán usarse para negociar. Todos los rehenes y el tendero contarán como una única demanda.\r
* Los civiles y camellos no oficiales NO podrán realizar más de 3 robos pequeños a la semana.\r
* Se podrá realizar el atraco sin preguntar policía disponible, tan solo es necesario mandar el debido entorno. Si el robo finaliza y la policía no ha llegado para negociar el atracador podrá abandonar el establecimiento con el botín. Si llega un policía se tendrá que negociar para poder salir del negocio.\r
* Queda totalmente prohibido realizar bloqueos.\r
\r
### 3.2. Robos para bandas y mafias\r
\r
* Es obligatorio enviar un entorno detallado de las personas que participan y de los vehículos en cada atraco que se realice.\r
\r
#### 3.2.1. Robos medios\r
\r
Se consideran robos medios tales como: Ammunation, Union y Joyería.\r
\r
#### 3.2.1.1. Ammunation\r
\r
* Mínimo 4 policías y máximo 6.\r
* Los atracadores siempre tienen que ser 1 menos que la policía.\r
* No puede haber tiradores.\r
* Se necesitará un arma de fuego obligatoriamente.\r
* Máximo 4 rehenes.\r
* Se permite realizar un único bloqueo.\r
\r
#### 3.2.1.2. Union\r
\r
* Mínimo 2 policías (no es necesario solicitar disponibilidad de policía).\r
* Los atracadores siempre tienen que ser 1 menos que la policía.\r
* Se deberán disfrazar de empleados los iniciantes del robo.\r
* Máximo 4 atracadores.\r
* Se podrá usar bajo y medio calibre (siempre armas de fuego).\r
* Máximo 2 rehenes.\r
* No se permite realizar bloqueos.\r
\r
#### 3.2.1.3. Joyería\r
\r
* Mínimo 4 policías y máximo 6.\r
* Los atracadores siempre tienen que ser 1 menos que la policía. Máximo 1 tirador por bando.\r
* Se podrán usar pistolas y armas de calibre medio.\r
* Máximo 4 rehenes.\r
* Se permitirá realizar como máximo un bloqueo.\r
* La negociación se realizará mediante una frecuencia de radio.\r
\r
#### 3.2.2. Robos grandes\r
\r
Se consideran robos grandes tales como:\r
\r
* Fleeca (sucursales)\r
* Yate presidencial\r
* Banco central\r
* Casino\r
* Robo a Humane\r
* Cayo Perico\r
\r
La negociación se realizará mediante una frecuencia de radio.\r
\r
#### 3.2.2.1. Fleeca (sucursales)\r
\r
* Mínimo 4 policías y máximo 8.\r
* Los atracadores siempre tienen que ser 1 menos que la policía. Puede haber 1 tirador.\r
* Se podrán usar pistolas y armas de calibre medio. Máximo 4 rehenes.\r
* Se permitirá realizar un único bloqueo.\r
\r
#### 3.2.2.2. Yate presidencial\r
\r
* Mínimo 8 policías y máximo 10.\r
* Los atracadores siempre tienen que ser 1 menos que la policía. Máximo 1 tirador por bando.\r
* Cualquier tipo de armamento en ambos bandos.\r
\r
#### 3.2.2.3. Banco Central\r
\r
* Mínimo 8 policías y máximo 10.\r
* Los atracadores siempre tienen que ser 1 menos que la policía. Máximo 1 tirador por bando.\r
* Cualquier tipo de armamento en ambos bandos.\r
\r
#### 3.2.2.4. Casino\r
\r
* Mínimo 8 policías y máximo 10.\r
* Los atracadores siempre tienen que ser 1 menos que la policía. Máximo 1 tirador por bando.\r
* Cualquier tipo de armamento en ambos bandos.\r
* No se permitirán realizar bloqueos.\r
\r
#### 3.2.2.5. Robo a Humane\r
\r
* Mínimo 8 policías y máximo 10.\r
* Los atracadores siempre tienen que ser 1 menos que la policía. Máximo 1 tirador por bando.\r
* Cualquier tipo de armamento en ambos bandos.\r
\r
#### 3.2.2.6. Robo a Cayo Perico\r
\r
* Se podrá realizar incluso sin policía (no es necesario tener policía activa). No se considera rol cerrado, por lo que puede intervenir otra banda/mafia.\r
* Se podrá usar bajo y medio calibre.\r
* No será necesario enviar entorno dentro de la isla.\r
\r
### 3.3. Negociaciones durante los atracos\r
\r
* Si un bando decide romper negociaciones deberá avisar a la otra persona. Se esperará un tiempo de 15 segundos antes de poder abrir fuego.\r
* NO se podrá añadir nadie al rol una vez comience el atraco. Si hay 4 policías y 3 atracadores en el rol estos serán los únicos que podrán participar en dicho rol.\r
* En robos pequeños y medios se realizará una negociación mediante dados cuando ambos bandos no puedan llegar a un acuerdo previo. Ambos negociadores deberán usar el /dados y la persona que saque el número más alto será el que gane la negociación.\r
* Si el atracador gana la negociación, el rehén deberá salir y la policía aceptará la condición.\r
\r
### 3.4. Personas en el exterior\r
\r
* En todos los atracos el bando de los atracadores SÍ podrán tener gente fuera para ayudar en la huida de estos, aunque SIEMPRE deberá haber un policía más que los delincuentes totales (en los cuales se incluyen los del exterior). Por ejemplo, en un atraco a joyería puede haber 4 policías, 1 atracador en el local y otros 2 en una lancha.\r
* Todos los delincuentes que estén fuera del local NO podrán tener roles agresivos contra la policía, exceptuando al tirador. Solo podrán ayudar con la huida o realizar bloqueos.\r
* En ningún caso se podrá incluir a civiles como terceros, ni para realizar el bloqueo ni con función de tirador.\r
\r
### Límites de atracos semanales por facción\r
\r
* Peluquerías/tatuajes: 10 a la semana entre los dos establecimientos.\r
* Badulaques: 10 a la semana.\r
* Coches de importación: 5 a la semana.\r
* Ammunation: 2 a la semana.\r
* Furgón blindado: 2 a la semana.\r
* Cayo Perico: 2 a la semana.\r
* Life: 2 a la semana.\r
* Unión/Bobcat: 2 a la semana.\r
* Robos ocultos: 2 a la semana.\r
* Joyería/Arte: 2 a la semana.\r
* Fleeca: 1 a la semana.\r
* Yate: 1 cada 2 semanas.\r
* Banco Central: 1 cada 2 semanas.\r
* Robo a Casino/Humane: 1 cada 3 semanas.\r
  {% endhint %}\r
\r
## 4. NIVELES DE BANDA\r
\r
{% hint style="info" %}\r
\r
### 4.1. Nivel 1\r
\r
* Máximo 6 integrantes.\r
* Podrán tener 2 camellos oficiales.\r
* Sin posibilidad de tener un rol de entorno favorable. (La sede siempre será rol de entorno favorable).\r
* Atracos disponibles hasta joyería.\r
\r
### 4.2. Nivel 2\r
\r
* Máximo 8 integrantes.\r
* Podrán tener 3 camellos oficiales.\r
* Posibilidad de tener rol de entorno favorable al comprar de viviendas del entorno valoradas en 100.000$ cada casa.\r
* Opción a comprar un almacén extra por 100.000$ (fuera del barrio)\r
* Atracos disponibles hasta banco central.\r
\r
### 4.3. Nivel 3\r
\r
* Máximo 10 integrantes.\r
* Podrán tener 3 camellos oficiales.\r
* Opción a comprar un almacén extra por 300.000$ (fuera del barrio).\r
* Disponibles todos los atracos.\r
  {% endhint %}\r
\r
## 5. NIVELES DE MAFIA\r
\r
{% hint style="warning" %}\r
\r
### 5.1. Nivel 1\r
\r
* Máximo 10 integrantes.\r
* Sin posibilidad de tener rol de entorno favorable. (La sede siempre será rol de entorno favorable)\r
* Atracos disponibles hasta joyería.\r
\r
### 5.2. Nivel 2\r
\r
* Máximo 13 integrantes.\r
* Posibilidad de tener rol de entorno favorable al comprar de viviendas del entorno valoradas en 100.000$ cada casa.\r
* Opción a comprar un almacén extra por 100.000$ (fuera de la sede)\r
* Atracos disponibles hasta banco central.\r
\r
### 5.3. Nivel 3\r
\r
* Máximo 16 integrantes.\r
* Opción a comprar un almacén extra por 300.000$ (fuera del barrio).\r
* Disponibles todos los atracos.\r
  {% endhint %}\r
\r
## 6. SANCIONES PARA BANDAS/MAFIAS\r
\r
{% hint style="danger" %}\r
\r
* Cuando una banda/mafia comete un fallo grave (ya sea uno o varios miembros) se le sanciona con un strike. En caso de acumular 3 strikes, se procederá a retirar la banda. En caso de que la administración vea que durante un periodo de tiempo determinado que las cosas se hacen bien, se podrá considerar la retirada de alguno de los strikes.\r
* La información de la banda y todos los apartados deberán estar debidamente actualizados. En el caso de faltar alguna información, la administración se guarda el derecho a sancionar con un strike y/o retirar dicha organización.\r
* Es totalmente obligatorio estar en el canal de voz (Discord de bandas/mafias) respectivo de cada organización mientras se esté dentro del servidor. En el caso de no estar en su respectivo canal se procederá a poner su respectiva sanción a dicha organización.\r
* Todos los integrantes de la organización tienen la obligación de grabar cuando estén cometiendo un acto delictivo. En el caso de detectarse en 3 ocasiones que no lo están haciendo, se impondrá un strike permanente.\r
* Es motivo de sanción el realizar o cometer actos delictivos junto con civiles.\r
* Para comunicarse con un encargado de bandas deberán escribir por el chat-admin correspondiente.\r
* La no valoración de vida será sancionada con strike directo a la banda/mafia.\r
* Entrar a otra facción sin esperar el tiempo mínimo será sancionable con un strike a la banda/mafia y 1 semana de ban a la persona que comete la infracción.\r
* Salirse del Discord de bandas/mafias sin solicitar que se le retire el rol será sancionado con 3 días de ban.\r
* Se considera falta de interpretación de personaje el abatir a una persona y luego llevarla al médico.\r
* No se pueden utilizar vehículos VIP ni exclusivos en actos delictivos.\r
  {% endhint %}\r
\r
## 7. NORMATIVA GENERAL BANDAS/MAFIAS\r
\r
{% hint style="warning" %}\r
\r
* Para entrar en la sede/barrio de otra organización se deberá de tener un motivo de peso suficientemente grande y demostrable a administración con pruebas IC.\r
* Todo acto IC que realice una banda/mafia en el rol de entorno de otra sin que haya entorno favorable no conllevará ninguna sanción; conlleva consecuencias IC que la tendrá que aplicar la propia banda/mafia dueña del rol. El entorno favorable se conseguirá para la banda/mafia a partir de nivel 2.\r
* El rol de entorno favorable beneficiará a la banda que lo posea pudiendo realizar, de forma automática, un CK a cualquier persona abatida en su zona de entorno favorable. Ese rol favorable también beneficiará a la banda de no avisar por /entorno o /forzar cuando se cometen actos delictivos en dicha zona, además de poder abrir fuego sin rol previo de peso en la misma.\r
* El interior de una sede SIEMPRE será entorno favorable para todas las bandas sin importar su nivel (de puertas para dentro, nunca la parte exterior)\r
* Los miembros de una banda/mafia podrán estar trabajando en negocios de ocio, alimentación, talleres y tienda de electrónica; siempre y cuando se respete el lore de dicha facción.\r
* Las bandas no podrán aliarse con otras bandas y las mafias tampoco, solo podrán realizarse pactos de no agresión. Las mafias, independientemente de los problemas que tengan, deberán facilitar material a las bandas.\r
* La policía, una banda o mafia podrán realizar CK a toda una organización si se tiene la información requerida: nombres, puestos que ocupan, negocio..., etc (siempre con la aprobación de administración).\r
* Cualquier tipo de comentario de toxicidad hacía otro usuario será sancionado con días de ban.\r
* Los reportes entre organizaciones ilegales deberán seguir un procedimiento. Se abrirá ticket-ilegal en el Discord de La Evolución rellenando la plantilla y pasando las pruebas pertinentes. Una vez seguido este paso, los encargados de Gestión de Bandas/Mafias atenderán el ticket en la mayor brevedad posible. El tiempo máximo que deberá pasar para abrir un reporte sobre un rol ocurrido será de 48 horas.\r
* No está permitido sacar información de los trabajadores o clientes de los negocios.\r
* Todas las reuniones, intercambios, pagos o cosas por el estilo se deberán hacer en una zona neutral, es decir, fuera de cualquier rol de entorno favorable (barrios, sedes..\r
* Si en una persecución entre dos facciones la facción que está siendo perseguida se mete en su barrio/sede, en ese mismo momento el RDE desaparece para dicha facción, es decir, pueden entrar y seguir el rol. Si la facción enemiga cae sería PK, no CK.\r
* Banda o mafia que meta en su organización a una persona sin haber esperado el tiempo límite para entrar será sancionada con un strike y la persona en cuestión con 1 semana de ban.\r
* Es obligatorio ir vestido acorde al lore de cada facción.\r
* En cualquier rol agresivo que se cometa, los colores de vuestro barrio tendrán que ser vistos de lejos. No podéis ir solamente con una gorra y pañuelo. Está totalmente prohibido quitarse prendas de ropa o zapatos.\r
* No se les podrá exigir a los civiles quitarse las prendas de algún color (a no ser que esa persona esté dando problemas al barrio).\r
* No se podrá exigir entre bandas/mafias quitarse los colores de su barrio por mucho que lo compartáis.\r
* El uso de coches de lore será obligatorio a no ser que vayáis a cometer algún acto delictivo.\r
* Para salir de una facción ilegal es obligatorio irse con un CK total, no están permitidos los PKT's.\r
* Para ser miembro oficial de una banda se debe de pasar primero por camello oficial. En el caso de las mafias, se entra directamente como miembro oficial.\r
* Tiempo mínimo de espera para entrar a uma banda/mafia (independientemente de si antes pertenecía a una organización o no):\r
* CK policial: 5 días para camello oficial y 10 para miembro.\r
* CK propio/ajeno: 2 días para camello oficial y 7 para miembro.\r
* A partir de ahora, queda prohibido utilizar el /rehen si estás CORRIENDO, Únicamente se podrá usar al ir PARADO o CAMINANDO si se coge al rehén de espaldas; si es por delante, el sujeto deberá estar DESARMADO.\r
* Queda totalmente prohibido que un miembro de una banda o mafia intente protegerse con la policía en cualquier tipo de rol.\r
* Cachear y robar a una persona que por rol está sin ropa será sancionado por PG.\r
* El jefe de una banda/mafia le podrá realizar un CK a un integrante cuando lo quiera fuera de la facción.\r
* Una mafia podrá realizarle un CK a un civil o a un miembro de otra banda/mafia cuando éste comprometa la seguridad o suplante la identidad de la mafia (este CK tiene que ser aprobado por Staff).\r
* Los miembros de una banda/mafia podrán solicitarle un CK al jefe de ésta si todos están de acuerdo y no es el donador (este CK tiene que ser aprobado por el Staff).\r
* Está permitido usar cualquier vehículo para estar de “chill” (sin cometer actos delictivos ni roleando como banda/mafia).\r
* Está totalmente prohibido pedir armas o dinero a cambio de la vida de una persona entre facciones ilegales.\r
* Los vehículos utilizados en actos delictivos deben representar el color de la facción de manera clara sin nacarado (a menos que la organización tenga dos colores y solo se pueda cambiar del vehículo únicamente un color).\r
* Se pueden utilizar vehículos de NPC para realizar atracos.\r
* En persecuciones entre facciones ilegales o legales, se permitirá pinchar ruedas después de que pase un tiempo considerable. (NORMATIVA FAIRPLAY)\r
* Para realizar un bloqueo deberá de pasar un tiempo mínimo considerable. normativa de fairplay. (NORMATIVA FAIRPLAY)\r
* El desarrollo de las relaciones con otros barrios debe ceñirse al lore de la banda, es decir, si existe una buena relación entre dos bandas, no se podrá, de la noche a la mañana, convertirse en una relación basada en roles agresivos.\r
* Las organizaciones ilegales deberán acatarse al lore definido, interpretación de personaje, acento, vestimentas... Cualquier banda/mafia que no siga dicho rol podrá ser retirada.\r
* La banda/mafia debe tener una actividad constante en el servidor.\r
  {% endhint %}\r
\r
## 8. ISLA DE CAYO PERICO\r
\r
{% hint style="info" %}\r
\r
Cayo Perico es una isla aparte que se encuentra a miles de kilómetros, no perteneciente al estado de San Andreas, por ende, tanto la SAMS como la SAPD no poseen la autoridad/jurisdicción de actuar y/o aplicar leyes en dicho lugar.\r
\r
* Toda la isla está considerada punto caliente (menos el aeropuerto y la zona de fiestas).\r
* NO es necesario tener policía disponible para cometer actos delictivos en toda la isla y está absolutamente prohibido utilizar los comandos /forzar o entorno.\r
* El agua/mar que se encuentra cerca de la isla está considerada como 'Aguas internacionales' formando parte del punto caliente de la isla.\r
\r
{% endhint %}\r
\r
## 9. GUERRA ENTRE ORGANIZACIONES\r
\r
{% hint style="warning" %}\r
\r
Se podrá declarar la guerra a otra banda con la que se tenga motivos y rol previo suficientes, además de la aprobación de administración.\r
\r
### Guerra entre bandas\r
\r
* Antes de una guerra, los líderes de ambas bandas se reunirán para determinar qué está en juego en esa guerra (armarios, territorios, CK, etc.) Ambos líderes pactarán las reglas de esa guerra de manera conjunta con la administración.\r
* En caso de no haber un acuerdo ganará la primera banda que consiga 20 bajas de la banda contraria.\r
* Las bandas deberán llevar los distintivos de su organización (colores, coches, máscara...)\r
* En la guerra sólo podrán participar miembros y camellos oficiales de la banda, así como la policía; nunca civiles, otras bandas, o la mafia a menos que sea aprobado por administración.\r
* Solo contarán las bajas a miembros/camellos oficiales y con fotos que demuestren sus muertes.\r
* Una banda podrá rendirse durante la guerra conllevando al CK total de la organización al completo.\r
\r
### Guerra entre mafias\r
\r
* Las reglas serán exactamente las mismas que en las guerras de bandas. Solo ambas mafias podrán participar en la guerra de mafias, además de la policía. Nunca podrán participar civiles u otras bandas a menos que sea aprobado por administración.\r
  {% endhint %}\r
\r
## 10. CAMELLOS\r
\r
{% hint style="warning" %}\r
\r
Un camello oficial es aquella persona que trabaja con la banda realizando pequeños actos delictivos como venta de droga o atracos y es el intermediario entre el civil y la banda.\r
\r
### 10.1. Normativa específica\r
\r
* Independientemente de la interpretación propia de cada civil, la banda se hará responsable de los “camellos” de dicha banda.\r
* Los camellos oficiales sí podrán colaborar con las actividades ilegales de una banda. Podrán colaborar en robos medios únicamente para realizar bloqueos, estando prohibido involucrarse en el robo directamente ni ocupando la posición de tirador. Nunca podrán colaborar en robos grandes. Un camello oficial podrá participar en los roles agresivos que inicie la banda para la que trabaja asumiendo las consecuencias que se le acarrea como civil (posible CK).\r
* La banda que no tenga camellos podrá contactar con civiles en busca de su primer camello haciéndole pruebas/misiones que no influyan en los intereses de la banda (robar badulaques, atracar a personas, recoger información básica sobre otras personas...).\r
* El camello/trabajador de una banda que de trabajo a un civil/vecino no podrá revelar que él mismo trabaja para dicha banda a ese civil/vecino. El camello/trabajador deberá encubrir a la banda ante cualquier persona.\r
* La banda tiene que dejar claro a un civil que forme parte de su territorio que no quiere problemas, por lo que, si un civil que vive en tu zona da problemas, tendrás que darle un toque de atención. Dicho esto, la banda se hará responsable de los comportamientos inapropiados de sus vecinos.\r
* La banda deberá castigar IC a dichos civiles si estos son conscientes de lo anterior. De no hacerlo, se podrá considerar que la banda incumple la normativa básica como falta de interpretación, forzar rol, MG y un largo etc (dependiendo del caso).\r
* Los camellos no oficiales/vecinos no pueden participar en ningún acto delictivo con la organización ni deben ser conscientes de cualquier situación que la involucre o la identifique como tal.\r
  {% endhint %}\r
\r
\r
---\r
`}],Hi={ambulance:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M10 10H6m8 8V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2m14 0h2a1 1 0 0 0 1-1v-3.28a1 1 0 0 0-.684-.948l-1.923-.641a1 1 0 0 1-.578-.502l-1.539-3.076A1 1 0 0 0 16.382 8H14M8 8v4m1 6h6"/><circle cx="17" cy="18" r="2"/><circle cx="7" cy="18" r="2"/></g>'},arrow_right:{tono:"acc",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14m-7-7l7 7l-7 7"/>'},arrows_counterclockwise:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M21 12a9 9 0 0 0-9-9a9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5m-5 4a9 9 0 0 0 9 9a9.75 9.75 0 0 0 6.74-2.74L21 16"/><path d="M16 16h5v5"/></g>'},boxing_glove:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M12.035 17.012a3 3 0 0 0-3-3l-.311-.002a.72.72 0 0 1-.505-1.229l1.195-1.195A2 2 0 0 1 10.828 11H12a2 2 0 0 0 0-4H9.243a3 3 0 0 0-2.122.879l-2.707 2.707A4.83 4.83 0 0 0 3 14a8 8 0 0 0 8 8h2a8 8 0 0 0 8-8V7a2 2 0 1 0-4 0v2a2 2 0 1 0 4 0"/><path d="M13.888 9.662A2 2 0 0 0 17 8V5a2 2 0 1 0-4 0M9 5a2 2 0 1 0-4 0v5m4-3V4a2 2 0 1 1 4 0v3.268"/></g>'},brain:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M12 18V5m3 8a4.17 4.17 0 0 1-3-4a4.17 4.17 0 0 1-3 4m8.598-6.5A3 3 0 1 0 12 5a3 3 0 1 0-5.598 1.5"/><path d="M17.997 5.125a4 4 0 0 1 2.526 5.77"/><path d="M18 18a4 4 0 0 0 2-7.464"/><path d="M19.967 17.483A4 4 0 1 1 12 18a4 4 0 1 1-7.967-.517"/><path d="M6 18a4 4 0 0 1-2-7.464"/><path d="M6.003 5.125a4 4 0 0 0-2.526 5.77"/></g>'},bug:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M12 20v-9m2-4a4 4 0 0 1 4 4v3a6 6 0 0 1-12 0v-3a4 4 0 0 1 4-4zm.12-3.12L16 2"/><path d="M21 21a4 4 0 0 0-3.81-4M21 5a4 4 0 0 1-3.55 3.97M22 13h-4M3 21a4 4 0 0 1 3.81-4M3 5a4 4 0 0 0 3.55 3.97M6 13H2M8 2l1.88 1.88M9 7.13V6a3 3 0 1 1 6 0v1.13"/></g>'},bust_in_silhouette:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></g>'},chains:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></g>'},city_dusk:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M10 12h4m-4-4h4m0 13v-3a2 2 0 0 0-4 0v3"/><path d="M6 10H4a2 2 0 0 0-2 2v7a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-2"/><path d="M6 21V5a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v16"/></g>'},clipboard:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><rect width="8" height="4" x="8" y="2" rx="1" ry="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2m4 7h4m-4 5h4m-8-5h.01M8 16h.01"/></g>'},closed_book:{tono:"acc",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H19a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1H6.5a1 1 0 0 1 0-5H20"/>'},computer:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><rect width="20" height="14" x="2" y="3" rx="2"/><path d="M8 21h8m-4-4v4"/></g>'},dizzy_face:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M16 16s-1.5-2-4-2s-4 2-4 2m1-7h.01M15 9h.01"/></g>'},door:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M10 21H2m8-18H7a2 2 0 0 0-2 2v16m9-9h.01"/><path d="M19 21V5a2 2 0 0 0-1.675-1.974l-6.163-1.013A1 1 0 0 0 10 3v18a1 1 0 0 0 1.124.992zm3 0h-3"/></g>'},fire:{tono:"acc",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3q1 4 4 6.5t3 5.5a1 1 0 0 1-14 0a5 5 0 0 1 1-3a1 1 0 0 0 5 0c0-2-1.5-3-1.5-5q0-2 2.5-4"/>'},flag_black:{tono:"acc",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 22V4a1 1 0 0 1 .4-.8A6 6 0 0 1 8 2c3 0 5 2 7.333 2q2 0 3.067-.8A1 1 0 0 1 20 4v10a1 1 0 0 1-.4.8A6 6 0 0 1 16 16c-3 0-5-2-8-2a6 6 0 0 0-4 1.528"/>'},game_die:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><rect width="12" height="12" x="2" y="10" rx="2" ry="2"/><path d="m17.92 14l3.5-3.5a2.24 2.24 0 0 0 0-3l-5-4.92a2.24 2.24 0 0 0-3 0L10 6M6 18h.01M10 14h.01M15 6h.01M18 9h.01"/></g>'},green_circle:{tono:"ok",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><circle cx="12" cy="12" r="1"/><circle cx="12" cy="12" r="10"/></g>'},gun:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M22 12h-4M6 12H2m10-6V2m0 20v-4"/></g>'},handshake:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="m11 17l2 2a1 1 0 1 0 3-3"/><path d="m14 14l2.5 2.5a1 1 0 1 0 3-3l-3.88-3.88a3 3 0 0 0-4.24 0l-.88.88a1 1 0 1 1-3-3l2.81-2.81a5.79 5.79 0 0 1 7.06-.87l.47.28a2 2 0 0 0 1.42.25L21 4"/><path d="m21 3l1 11h-2M3 3L2 14l6.5 6.5a1 1 0 1 0 3-3M3 4h8"/></g>'},heart:{tono:"acc",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2 9.5a5.5 5.5 0 0 1 9.591-3.676a.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5"/>'},herb:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M11 20a10 10 0 0 0 10-10a25.9 25.9 0 0 0-1.04-7.281a1 1 0 0 0-1.755-.325C15.833 5.5 13 5.5 9.8 6.1A7 7 0 0 0 11 20"/><path d="M2 21a5 5 0 0 1 2.911-4.544C7.613 15.212 8.351 15.24 11 13"/></g>'},hospital:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M12 7v4m2 10v-3a2 2 0 0 0-4 0v3m4-12h-4"/><path d="M18 11h2a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2v-9a2 2 0 0 1 2-2h2"/><path d="M18 21V5a2 2 0 0 0-2-2H8a2 2 0 0 0-2 2v16"/></g>'},identification_card:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M13 19a4 4 0 0 0-8 0m11-9h2m-2 4h2"/><circle cx="9" cy="12" r="3"/><rect width="20" height="14" x="2" y="5" rx="2"/></g>'},information_source:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4m0-4h.01"/></g>'},keyboard:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M10 8h.01M12 12h.01M14 8h.01M16 12h.01M18 8h.01M6 8h.01M7 16h10m-9-4h.01"/><rect width="20" height="16" x="2" y="4" rx="2"/></g>'},knife:{tono:"acc",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m11 19l-6-6m0 8l-2-2m5-3l-4 4m5.5-2.5L20.414 6.586A2 2 0 0 0 21 5.172V3h-2.172a2 2 0 0 0-1.414.586L6.5 14.5"/>'},loudspeaker:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M11 6a13 13 0 0 0 8.4-2.8A1 1 0 0 1 21 4v12a1 1 0 0 1-1.6.8A13 13 0 0 0 11 14H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2z"/><path d="M6 14a12 12 0 0 0 2.4 7.2a2 2 0 0 0 3.2-2.4A8 8 0 0 1 10 14M8 6v8"/></g>'},microphone2:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M12 19v3m7-12v2a7 7 0 0 1-14 0v-2"/><rect width="6" height="13" x="9" y="2" rx="3"/></g>'},moneybag:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M13.744 17.736a6 6 0 1 1-7.48-7.48M15 6h1v4"/><path d="m6.134 14.768l.866-.5l2 3.464"/><circle cx="16" cy="8" r="6"/></g>'},motorcycle:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><circle cx="18.5" cy="17.5" r="3.5"/><circle cx="5.5" cy="17.5" r="3.5"/><circle cx="15" cy="5" r="1"/><path d="M12 17.5V14l-3-3l4-3l2 3h2"/></g>'},no_entry_sign:{tono:"bad",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M4.929 4.929L19.07 19.071"/></g>'},oncoming_automobile:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="m21 8l-2 2l-1.5-3.7A2 2 0 0 0 15.646 5H8.4a2 2 0 0 0-1.903 1.257L5 10L3 8m4 6h.01M17 14h.01"/><rect width="18" height="8" x="3" y="10" rx="2"/><path d="M5 18v2m14-2v2"/></g>'},pencil:{tono:"acc",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497zM15 5l4 4"/>'},performing_arts:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M10 11h.01M14 6h.01M18 6h.01M6.5 13.1h.01M22 5c0 9-4 12-6 12s-6-3-6-12q0-3 6-3c6 0 6 1 6 3"/><path d="M17.4 9.9c-.8.8-2 .8-2.8 0m-4.5-2.8C9 7.2 7.7 7.7 6 8.6c-3.5 2-4.7 3.9-3.7 5.6c4.5 7.8 9.5 8.4 11.2 7.4c.9-.5 1.9-2.1 1.9-4.7"/><path d="M9.1 16.5c.3-1.1 1.4-1.7 2.4-1.4"/></g>'},person_lifting_weights:{tono:"acc",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.596 12.768a2 2 0 1 0 2.829-2.829l-1.768-1.767a2 2 0 0 0 2.828-2.829l-2.828-2.828a2 2 0 0 0-2.829 2.828l-1.767-1.768a2 2 0 1 0-2.829 2.829zM2.5 21.5l1.4-1.4M20.1 3.9l1.4-1.4M5.343 21.485a2 2 0 1 0 2.829-2.828l1.767 1.768a2 2 0 1 0 2.829-2.829l-6.364-6.364a2 2 0 1 0-2.829 2.829l1.768 1.767a2 2 0 0 0-2.828 2.829zM9.6 14.4l4.8-4.8"/>'},police_car:{tono:"acc",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 18v-6a5 5 0 1 1 10 0v6M5 21a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-1a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2zm16-9h1m-3.5-7.5L18 5M2 12h1m9-10v1M4.929 4.929l.707.707M12 12v6"/>'},police_officer:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="M6.376 18.91a6 6 0 0 1 11.249.003"/><circle cx="12" cy="11" r="4"/></g>'},rabbit:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M13 16a3 3 0 0 1 2.24 5M18 12h.01"/><path d="M18 21h-8a4 4 0 0 1-4-4a7 7 0 0 1 7-7h.2L9.6 6.4a1 1 0 1 1 2.8-2.8L15.8 7h.2c3.3 0 6 2.7 6 6v1a2 2 0 0 1-2 2h-1a3 3 0 0 0-3 3"/><path d="M20 8.54V4a2 2 0 1 0-4 0v3m-8.388 5.524a3 3 0 1 0-1.6 4.3"/></g>'},radio:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M16.247 7.761a6 6 0 0 1 0 8.478m2.828-11.306a10 10 0 0 1 0 14.134m-14.15 0a10 10 0 0 1 0-14.134m2.828 11.306a6 6 0 0 1 0-8.478"/><circle cx="12" cy="12" r="2"/></g>'},red_car:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"/><circle cx="7" cy="17" r="2"/><path d="M9 17h6"/><circle cx="17" cy="17" r="2"/></g>'},red_circle:{tono:"bad",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><circle cx="12" cy="12" r="1"/><circle cx="12" cy="12" r="10"/></g>'},round_pushpin:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/></g>'},scales:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M12 3v18m7-13l3 8a5 5 0 0 1-6 0zV7"/><path d="M3 7h1a17 17 0 0 0 8-2a17 17 0 0 0 8 2h1M5 8l3 8a5 5 0 0 1-6 0zV7m2 14h10"/></g>'},scissors:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><circle cx="6" cy="6" r="3"/><path d="M8.12 8.12L12 12m8-8L8.12 15.88"/><circle cx="6" cy="18" r="3"/><path d="M14.8 14.8L20 20"/></g>'},shield:{tono:"acc",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>'},shirt:{tono:"acc",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.38 3.46L16 2a4 4 0 0 1-8 0L3.62 3.46a2 2 0 0 0-1.34 2.23l.58 3.47a1 1 0 0 0 .99.84H6v10c0 1.1.9 2 2 2h8a2 2 0 0 0 2-2V10h2.15a1 1 0 0 0 .99-.84l.58-3.47a2 2 0 0 0-1.34-2.23"/>'},skull:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="m12.5 17l-.5-1l-.5 1z"/><path d="M15 22a1 1 0 0 0 1-1v-1a2 2 0 0 0 1.56-3.25a8 8 0 1 0-11.12 0A2 2 0 0 0 8 20v1a1 1 0 0 0 1 1z"/><circle cx="15" cy="12" r="1"/><circle cx="9" cy="12" r="1"/></g>'},skull_crossbones:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="m12.5 17l-.5-1l-.5 1z"/><path d="M15 22a1 1 0 0 0 1-1v-1a2 2 0 0 0 1.56-3.25a8 8 0 1 0-11.12 0A2 2 0 0 0 8 20v1a1 1 0 0 0 1 1z"/><circle cx="15" cy="12" r="1"/><circle cx="9" cy="12" r="1"/></g>'},speech_balloon:{tono:"acc",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.992 16.342a2 2 0 0 1 .094 1.167l-1.065 3.29a1 1 0 0 0 1.236 1.168l3.413-.998a2 2 0 0 1 1.099.092a10 10 0 1 0-4.777-4.719"/>'},telephone_receiver:{tono:"acc",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233a14 14 0 0 0 6.392 6.384"/>'},tennis:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M11 7a16 16 20 0 1 10.98 4.362M12 12a13 13 0 0 1-8.66 5m13.49-3.366a16 16 0 0 1-9.267 7.328"/><path d="M20.66 17A13 13 0 0 0 12 12a13 13 0 0 1 0-10M8.17 15.366a16 16 0 0 1-1.713-11.69"/><circle cx="12" cy="12" r="10"/></g>'},tractor:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="m10 11l11 .9a1 1 0 0 1 .8 1.1l-.665 4.158a1 1 0 0 1-.988.842H20m-4 0h-5"/><path d="M18 5a1 1 0 0 0-1 1v5.573M3 4h8.129a1 1 0 0 1 .99.863L13 11.246M4 11V4m3 11h.01M8 10.1V4"/><circle cx="18" cy="18" r="2"/><circle cx="7" cy="15" r="5"/></g>'},warning:{tono:"warn",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m21.73 18l-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3M12 9v4m0 4h.01"/>'},wheel:{tono:"acc",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="m4.93 4.93l4.24 4.24m5.66 0l4.24-4.24m-4.24 9.9l4.24 4.24m-9.9-4.24l-4.24 4.24"/><circle cx="12" cy="12" r="4"/></g>'},white_check_mark:{tono:"ok",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="m16 9l-5.5 5.5L8 12"/></g>'},writing_hand:{tono:"acc",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 21h8m.174-14.188a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/>'},x:{tono:"bad",svg:'<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="m15 9l-6 6m0-6l6 6"/></g>'},zap:{tono:"acc",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.914 4a1.5 1.5 0 0 0-2.474-1.561l-9 9A1.5 1.5 0 0 0 5.5 14h4.002a.5.5 0 0 1 .471.666L8.086 20a1.5 1.5 0 0 0 2.475 1.56l9-9A1.5 1.5 0 0 0 18.5 10h-3.997a.5.5 0 0 1-.472-.667z"/>'},zzz:{tono:"acc",svg:'<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.985 12.486a9 9 0 1 1-9.473-9.472c.405-.022.617.46.402.803a6 6 0 0 0 8.268 8.268c.344-.215.825-.004.803.401"/>'}},Uo="",vc={"⚠":"warning","📕":"closed_book","🚑":"ambulance","📋":"clipboard","⚖":"scales","👮":"police_officer"},Vi=e=>Uo+e+Uo;function Bn(e){return e.split(Uo).map((a,o)=>o%2?{i:Hi[a]}:{t:a}).filter(a=>a.i||a.t)}const Hn=e=>e.split(Uo).filter((a,o)=>o%2===0).join("").replace(/\s+/g," ").trim();function za(e){return String(e||"").replace(/\\_/g,"_").replace(/<br\s*\/?>/gi," ").replace(/&#x20;|&nbsp;/gi," ").replace(/\[([^\]]+)\]\((?:https?:\/\/|mailto:)[^)]+\)/g,"$1").replace(/\*\*(.+?)\*\*/g,"$1").replace(/__(.+?)__/g,"$1").replace(/\*(.+?)\*/g,"$1").replace(/`+/g,"").replace(/:([a-z0-9_+-]+):/gi,(a,o)=>Hi[o.toLowerCase()]?Vi(o.toLowerCase()):a).replace(/(⚠|📕|🚑|📋|⚖|👮)️?/gu,(a,o)=>Vi(vc[o])).replace(/[ \t]+/g," ").trim()}function yc(e){const a=[];return String(e||"").replace(/^>\s*For the complete documentation index,[^\r\n]*\r?\n/i,"").split(/^# Agent Instructions\s*$/mi)[0].split(/\r?\n/).forEach(n=>{const r=n.trim().replace(/^>\s?/,"").replace(/\\+$/,"").trim();if(!r||/^\{%.*%\}$/.test(r)||/^---+$/.test(r)||/^`{3}/.test(r)||/^#\s+/.test(r))return;const i=r.match(/^#{2,6}\s+(.*)$/);if(i){a.push({sec:za(i[1])});return}const l=r.match(/^\*\*(.+?)\*\*\s*(.*)$/);if(l){a.push({lead:za(l[1]),body:za(l[2])});return}const t=r.match(/^(\d+(?:\.\d+)*[.)]?)\s+(.*)$/);if(t){a.push({lead:t[1],body:za(t[2])});return}const s=r.match(/^[-*]\s+(.*)$/);if(s){a.push({lead:"·",body:za(s[1])});return}a.push({lead:"",body:za(r)})}),a.map(n=>n.sec!==void 0?{sec:Hn(n.sec),secParts:Bn(n.sec)}:{lead:Hn(n.lead),leadParts:Bn(n.lead),body:Hn(n.body),bodyParts:Bn(n.body)})}const xc=bc.map(e=>({id:e.id,label:e.titulo,sub:e.resumen,head:"",blocks:yc(e.md)})),T=e=>`<path d="${e}"></path>`,Ye=(e,a,o)=>`<circle cx="${e}" cy="${a}" r="${o}"></circle>`,U={check:[Ye(12,12,8.6),T("M8 12.4l2.9 2.9L16.4 9.7")],person:[Ye(12,8,3.5),T("M5.4 20c0-3.5 3-5.5 6.6-5.5s6.6 2 6.6 5.5")],bars:[T("M4.6 20V9.6"),T("M9.9 20V4.6"),T("M15.2 20V13"),T("M20.5 20V7.6")],people:[Ye(9.2,9,2.9),T("M3.6 19.2c0-3 2.5-5.4 5.6-5.4s5.6 2.4 5.6 5.4"),T("M16.2 6.3a2.9 2.9 0 0 1 0 5.4"),T("M17.8 14.2c2 .8 3.1 2.7 3.1 5")],link:[T("M10.4 13.6 13.6 10.4"),T("M9.2 15.2 7.6 16.8a3.3 3.3 0 0 1-4.6-4.6L5 10.2"),T("M14.8 8.8l1.6-1.6a3.3 3.3 0 0 1 4.6 4.6L19 13.8")],plus:[T("M12 5.5v13"),T("M5.5 12h13")],lock:[T("M5.5 10.5h13v9.5h-13z"),T("M8.5 10.5V7.8a3.5 3.5 0 0 1 7 0v2.7")],cal:[T("M4.5 6.5h15v13h-15z"),T("M4.5 11h15"),T("M8.5 3.5v3"),T("M15.5 3.5v3")],globe:[Ye(12,12,8.6),T("M3.4 12h17.2"),T("M12 3.4c2.6 2.4 2.6 14.2 0 17.2"),T("M12 3.4c-2.6 2.4-2.6 14.2 0 17.2")],duo:[Ye(9,9,2.9),T("M3.6 19c0-3 2.4-5.4 5.4-5.4s5.4 2.4 5.4 5.4"),T("M16 6.4a2.9 2.9 0 0 1 0 5.2"),T("M17.6 14.2c1.9.8 3 2.6 3 4.8")],sound:[T("M4 10v4h3l5 3.5V6.5L7 10z"),T("M15.5 9.6a3.6 3.6 0 0 1 0 4.8"),T("M18 7.4a7 7 0 0 1 0 9.2")],mute:[T("M4 10v4h3l5 3.5V6.5L7 10z"),T("M15.5 10l4.5 4"),T("M20 10l-4.5 4")],dollar:[T("M12 4.5v15"),T("M15.5 8.2c0-1.5-1.6-2.4-3.5-2.4s-3.5.9-3.5 2.4 1.6 2.2 3.5 2.6 3.5 1 3.5 2.7-1.6 2.6-3.5 2.6-3.5-1-3.5-2.6")],crown:[T("M4 18h16"),T("M4.5 16 3 7l5 4 4-6 4 6 5-4-1.5 9z")],clock:[Ye(12,12,8.4),T("M12 7.4V12l3.4 2.2")],job:[T("M3.5 8h17v11h-17z"),T("M9 8V5.8h6V8"),T("M3.5 12.6h17")],wifi:[T("M4 9.4a12 12 0 0 1 16 0"),T("M7 12.6a7.6 7.6 0 0 1 10 0"),T("M9.8 15.8a3.6 3.6 0 0 1 4.4 0"),Ye(12,19,1.1)],home:[T("M4 11 12 4.6 20 11"),T("M6 10.4V19.5h12V10.4")],garage:[T("M3.6 10.4 12 5l8.4 5.4V20H3.6z"),T("M7 20v-5.6h10V20"),T("M7 17h10")],spot:[Ye(12,12,8),Ye(12,12,2.4)]},wc=[{label:"Inicio",pad:"28px"},{label:"Normativa",pad:"28px"},{label:"Tienda",pad:"28px"}],Ui=[{id:"s1",name:"Alba Ferrer",line:"Nivel 23 · 128 h",zone:"Vinewood",state:"ok"},{id:"s2",name:"Dorian Vela",line:"Nivel 11 · 42 h",zone:"Grove Street",state:"ok"},{id:"s3",name:"Kira Osei",line:"Nivel 4 · 9 h",zone:"Sandy Shores",state:"ok"},{id:"s4",name:"Slot libre",line:"Crear personaje",zone:"",state:"free"},{id:"s5",name:"Bloqueado",line:"Nivel 30 o tienda",zone:"",state:"lock"}],Cc=["Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre"],Sc=new Date().getFullYear()-18,Ac=Array.from({length:82},(e,a)=>Sc-a),Mc={name:"OrigenTitle",components:{OgnImage:ac,MapaFicha:mc},props:{images:{type:Object,default:()=>({art:Ho.origen.art,poster:Ho.origen.poster})},player:{type:Object,default:()=>({name:"Orionev",id:"#0427",level:23})},slots:{type:Array,default:()=>Ui},rulesDoc:{type:Array,default:null},ping:{type:Number,default:42},volumeStart:{type:Number,default:60},ficha:{type:Object,default:()=>({})}},emits:["nav","slot","play","create","rule","search","volume","mute","field","genero"],setup(){return{imgMarca:Ti()}},data(){return{nav:0,rule:0,q:"",card:-1,nom:"",ape:"",edad:"",nac:"",gen:null,scale:1,vol:this.volumeStart,muted:!1,abierto:"",dia:0,mes:0,anio:0,buscaPais:""}},mounted(){this.fit(),this._r=()=>this.fit(),window.addEventListener("resize",this._r),this._destino={x:0,y:0},this._puesto={x:0,y:0},this._activo=typeof document.hasFocus=="function"?document.hasFocus():!0,this._foco=a=>{this._activo=a,a||(this._destino.x=0,this._destino.y=0)},this._onBlur=()=>this._foco(!1),this._onFocus=()=>this._foco(!0),this._onVis=()=>this._foco(!document.hidden),window.addEventListener("blur",this._onBlur),window.addEventListener("focus",this._onFocus),document.addEventListener("visibilitychange",this._onVis),this._m=a=>{this._activo&&(this._destino.x=(a.clientX/Math.max(1,window.innerWidth)*2-1)*7,this._destino.y=(a.clientY/Math.max(1,window.innerHeight)*2-1)*4.5)},window.addEventListener("mousemove",this._m,{passive:!0});const e=()=>{const a=this.$refs.arte;a&&(this._puesto.x+=(this._destino.x-this._puesto.x)*.08,this._puesto.y+=(this._destino.y-this._puesto.y)*.08,a.style.transform="scale(1.05) translate3d("+this._puesto.x.toFixed(2)+"px,"+this._puesto.y.toFixed(2)+"px,0)"),this._raf=requestAnimationFrame(e)};this._raf=requestAnimationFrame(e),window.ResizeObserver&&this.$refs.root&&(this._ro=new ResizeObserver(this._r),this._ro.observe(this.$refs.root))},beforeUnmount(){window.removeEventListener("resize",this._r),window.removeEventListener("mousemove",this._m),window.removeEventListener("blur",this._onBlur),window.removeEventListener("focus",this._onFocus),document.removeEventListener("visibilitychange",this._onVis),this._raf&&cancelAnimationFrame(this._raf),this._ro&&(this._ro.disconnect(),this._ro=null)},computed:{v(){return this.VALS()}},methods:{set(e){const a=typeof e=="function"?e(this.$data):e;Object.assign(this,a||{})},ico(e){return Array.isArray(e)?e.join(""):e||""},tonoIco(e){return{ok:"#4ade80",bad:"#f05252",warn:"#f5b93a"}[e]||"var(--ogn-acc-soft)"},abrirLista(e){this.set({abierto:this.abierto===e?"":e,buscaPais:""})},cerrarListas(){this.abierto&&this.set({abierto:""})},ponerFecha(e,a){const o={dia:this.dia,mes:this.mes,anio:this.anio};o[e]=a;const n=o.mes&&o.anio?new Date(o.anio,o.mes,0).getDate():31;o.dia>n&&(o.dia=n);const r=o.dia&&o.mes&&o.anio?String(o.dia).padStart(2,"0")+"/"+String(o.mes).padStart(2,"0")+"/"+o.anio:"";this.set({dia:o.dia,mes:o.mes,anio:o.anio,edad:r}),r&&this.$emit("field",{key:"edad",value:r})},ponerPais(e){this.set({nac:e,abierto:""}),this.$emit("field",{key:"nac",value:e})},fit(){const e=this.$refs.root;if(!e)return;const a=e.getBoundingClientRect(),o=a.width||window.innerWidth,n=a.height||window.innerHeight;this.scale=Math.min(o/1656,n/940)||1},volDown(e){const a=this.$refs.vol;if(!a)return;const o=r=>{const i=a.getBoundingClientRect(),l=Math.min(1,Math.max(0,(r.clientX-i.left)/Math.max(1,i.width))),t=Math.round(l*100);this.$emit("volume",t),this.set({vol:t,muted:!1})},n=()=>{window.removeEventListener("pointermove",o),window.removeEventListener("pointerup",n)};window.addEventListener("pointermove",o),window.addEventListener("pointerup",n),o(e)},VALS(){const e=this.$data,a=this.slots||Ui,o=this.rulesDoc||(Fn.value==="nacion"?xc:gc),n=e.card>=0&&a[e.card]||null,r=this.ficha||{},i=r.stats||{},l=!!(e.nom.trim()&&e.ape.trim()&&e.edad.trim()&&e.nac.trim()&&e.gen!==null);return{paper:this.imgMarca.paper,rotuloMapa:this.imgMarca.rotuloMapa,ubicacionMapa:r.ubicacion||"San Andreas",vitales:[{k:"Salud",v:r.vitales&&r.vitales.salud,color:"linear-gradient(90deg,#ff5c89 0%,#e0074f 100%)"},{k:"Comida",v:r.vitales&&r.vitales.comida,color:"linear-gradient(90deg,#ff5c89 0%,#e0074f 100%)"},{k:"Bebida",v:r.vitales&&r.vitales.bebida,color:"linear-gradient(90deg,#ff5c89 0%,#e0074f 100%)"}].map(t=>{const s=Math.max(0,Math.min(100,Math.round(Number(t.v)||0)));return{...t,v:s,ancho:s+"%"}}),createBg:this.imgMarca.createBg,lockBg:this.imgMarca.lockBg,scale:e.scale,nav:wc.map((t,s)=>{const u=s===e.nav;return{label:t.label,pad:t.pad,bg:u?"linear-gradient(100deg,#ff3b74 0%,#e0074f 100%)":"transparent",clip:u?"polygon(13px 0,100% 0,calc(100% - 13px) 100%,0 100%)":"none",fg:"#ffffff",go:()=>{this.set({nav:s}),this.$emit("nav",t.label)}}}),tagTop:["Los","Santos","Vive","Diferente"],tagMid:["Good","People","Better","Stories"],coins:[{mark:"RC",v:"1,000",ring:"inset 0 0 0 1.8px #f2c14b",markFg:"#f2c14b"},{mark:"O",v:"250",ring:"inset 0 0 0 1.8px #ff2d6a",markFg:"#ff2d6a"}],rows:[{k:"Whitelist",v:"Aprobada",icon:U.check,iconFg:"#146636",vFg:"#146636",ok:!0},{k:"Personajes",v:"3 / 6",icon:U.person,iconFg:"#4a4437",vFg:"#26221a"},{k:"Estadísticas",v:"128 h",icon:U.bars,iconFg:"#4a4437",vFg:"#26221a"},{k:"Jugadores online",v:"482 / 1024",icon:U.people,iconFg:"#4a4437",vFg:"#26221a"},{k:"Código de conexión",v:"play.origen.net",icon:U.link,iconFg:"#4a4437",vFg:"#26221a"}].map(t=>Object.assign({chapaBg:t.ok?"rgba(31,143,78,0.14)":"rgba(111,104,87,0.12)",chapaShadow:t.ok?"inset 0 0 0 1px rgba(20,102,54,0.4)":"inset 0 0 0 1px rgba(111,104,87,0.26)"},t)),cards:a.map((t,s)=>{const u=s===e.card,d=t.state==="free",m=t.state==="lock";return{name:t.name,line:"",slotId:"ogn-slot-"+t.id,hasRender:t.state==="ok",foto:t.foto||"",empty:d||m,emptyIcon:d?U.plus:U.lock,emptyBg:d?"rgba(255,45,106,0.07)":"rgba(255,255,255,0.03)",emptyFg:d?"#ff6b96":"#5f5a54",tag:m?"":d?"Vacío":t.zone,tagBg:u?"linear-gradient(160deg,#ff5c89 0%,#e0074f 100%)":"rgba(9,9,11,0.7)",tagShadow:u?"0 3px 0 #a80c3f":"inset 0 0 0 1px rgba(255,255,255,0.2)",tagFg:"#ffffff",nameFg:m?"#8f8a82":"#ffffff",lineFg:d?"#ff85a8":m?"#6f6a63":"#cfc8ba",flex:u?"1.3":"1",h:u?"156px":"142px",size:u?"23px":"19px",edge:u?"#ff2d6a":"rgba(255,255,255,0.2)",pad:u?"3px":"1px",go:()=>{const A=e.card===s?-1:s;this.set({card:A}),this.$emit("slot",{index:A,name:t.name,state:t.state,raw:t})}}}),isCreate:e.nav!==1&&n!==null&&n.state==="free",isLock:e.nav!==1&&n!==null&&n.state==="lock",noSel:e.card<0&&e.nav!==1,hasSel:e.card>=0&&e.nav!==1&&(n===null||n.state!=="free"&&n.state!=="lock"),prev:()=>{const t=(e.card-1+a.length)%a.length;this.set({card:t}),this.$emit("slot",{index:t,name:a[t].name,state:a[t].state,raw:a[t]})},next:()=>{const t=(e.card+1)%a.length;this.set({card:t}),this.$emit("slot",{index:t,name:a[t].name,state:a[t].state,raw:a[t]})},keys:[{k:"ENTER",label:"Seleccionar"},{k:"ESC",label:"Volver"},{k:"TAB",label:"Opciones"}].map((t,s)=>({k:t.k,label:t.label,rule:s<2?"inset -1px 0 0 rgba(255,255,255,0.2)":"none"})),volRef:this.volRef,volDown:this.volDown,volPct:(e.muted?0:e.vol)+"%",track:e.muted?"Silenciada":"Origen Radio",muteIcon:e.muted?U.mute:U.sound,muteBg:e.muted?"rgba(255,255,255,0.08)":"linear-gradient(160deg,#ff5c89 0%,#e0074f 100%)",muteShadow:e.muted?"inset 0 0 0 1px rgba(255,255,255,0.22)":"0 3px 0 #a80c3f",muteFg:e.muted?"#8f8a82":"#ffffff",toggleMute:()=>{this.$emit("mute",!e.muted),this.set(t=>({muted:!t.muted}))},isRules:e.nav===1,ruleTitle:(o[e.rule]||o[0]).label,ruleSub:(o[e.rule]||o[0]).sub,ruleHead:(o[e.rule]||o[0]).head,ruleBlocks:(o[e.rule]||o[0]).blocks.filter(t=>{const s=e.q.trim().toLowerCase();return s?((t.sec||"")+" "+(t.lead||"")+" "+(t.body||"")).toLowerCase().indexOf(s)>=0:!0}),ruleFoot:"Origen Network · vigente",ruleEmpty:(o[e.rule]||o[0]).blocks.length===0,ruleQ:e.q,onRuleQ:t=>this.set({q:t.target.value}),rules:o.map((t,s)=>{const u=s===e.rule;return{label:t.label,bg:u?"linear-gradient(160deg,#ff5c89 0%,#e0074f 100%)":"transparent",shadow:u?"0 3px 0 #a80c3f":"inset 0 0 0 1px var(--hoja-borde-28)",fg:u?"#ffffff":"var(--hoja-suave)",delay:s*22+"ms",go:()=>{this.$emit("rule",t.name||s),this.set({rule:s,q:""})}}}),pjName:r.name||(a[e.card]||{}).name||"",pjId:r.id||"#2847",pjLvl:r.level!=null?String(r.level):"18",pjXp:r.xp||"3.420 / 5.000 XP",pjXpPct:r.xpPct||"68%",pjMoney:[{v:r.money&&r.money[0]||"$ 245.750",icon:U.dollar,bg:"linear-gradient(160deg,#ff5c89 0%,#e0074f 100%)",ring:"0 3px 0 #a80c3f",markFg:"#ffffff"},{v:r.money&&r.money[1]||"2.350",icon:U.crown,bg:"transparent",ring:"inset 0 0 0 1.8px #e0074f",markFg:"var(--hoja-acento)"}],pjStats:[{k:"Whitelist",v:i.whitelist||"Aprobada",sub:"",icon:U.check,fg:"var(--hoja-ok)",rule:"inset -1px 0 0 var(--hoja-linea-18)"},{k:"Personajes",v:i.personajes||"3 / 6",sub:"",icon:U.people,fg:"var(--hoja-tinta)",rule:"inset -1px 0 0 var(--hoja-linea-18)"},{k:"Tiempo en la ciudad",v:i.tiempo||"128 h",sub:"",icon:U.clock,fg:"var(--hoja-tinta)",rule:"none"},{k:"Trabajo",v:i.trabajo||"Mecánico",sub:i.trabajoSub!=null?i.trabajoSub:"Pillbox Motors",icon:U.job,fg:"var(--hoja-tinta)",rule:"inset -1px 0 0 var(--hoja-linea-18)"},{k:"Facción",v:i.faccion||"Los Santos Vagos",sub:i.faccionSub!=null?i.faccionSub:"Miembro",icon:U.people,fg:"var(--hoja-tinta)",rule:"inset -1px 0 0 var(--hoja-linea-18)"},{k:"Última conexión",v:i.ultima||"Hace 2 horas",sub:i.ultimaSub!=null?i.ultimaSub:"En línea",icon:U.wifi,fg:"var(--hoja-tinta)",rule:"none"}],pins:[{x:"50%",y:"52%",icon:U.crown,bg:"linear-gradient(160deg,#ff5c89 0%,#e0074f 100%)",glow:"0 0 0 6px rgba(224,7,79,0.2),0 3px 0 #a80c3f"},{x:"31%",y:"26%",icon:U.home,bg:"linear-gradient(160deg,#ff5c89 0%,#e0074f 100%)",glow:"0 3px 0 #a80c3f"},{x:"72%",y:"42%",icon:U.home,bg:"linear-gradient(160deg,#ff5c89 0%,#e0074f 100%)",glow:"0 3px 0 #a80c3f"},{x:"23%",y:"48%",icon:U.garage,bg:"linear-gradient(160deg,#ff5c89 0%,#e0074f 100%)",glow:"0 3px 0 #a80c3f"},{x:"64%",y:"70%",icon:U.job,bg:"linear-gradient(160deg,#ff5c89 0%,#e0074f 100%)",glow:"0 3px 0 #a80c3f"}],legend:[{label:"Tu ubicación",icon:U.crown,bg:"linear-gradient(160deg,#ff5c89 0%,#e0074f 100%)",ring:"0 2px 0 #a80c3f",fg:"#ffffff"},{label:"Propiedad",icon:U.home,bg:"transparent",ring:"inset 0 0 0 1.6px #e0074f",fg:"#c00a46"},{label:"Garaje",icon:U.garage,bg:"transparent",ring:"inset 0 0 0 1.6px #e0074f",fg:"#c00a46"},{label:"Trabajo",icon:U.job,bg:"transparent",ring:"inset 0 0 0 1.6px #e0074f",fg:"#c00a46"},{label:"Facción",icon:U.people,bg:"transparent",ring:"inset 0 0 0 1.6px #e0074f",fg:"#c00a46"},{label:"Punto de interés",icon:U.spot,bg:"transparent",ring:"inset 0 0 0 1.6px rgba(111,104,87,0.5)",fg:"#6f6857"}],form:[{label:"Nombre",ph:"Ingresa tu nombre…",icon:U.person,key:"nom",tipo:"texto"},{label:"Apellidos",ph:"Ingresa tus apellidos…",icon:U.duo,key:"ape",tipo:"texto"},{label:"Fecha de nacimiento",ph:"Elige tu fecha de nacimiento…",icon:U.cal,key:"edad",tipo:"fecha",arrow:!0},{label:"Nacionalidad",ph:"Selecciona tu nacionalidad…",icon:U.globe,key:"nac",tipo:"lista",arrow:!0}].map(t=>({label:t.label,ph:t.ph,icon:t.icon,arrow:!!t.arrow,tipo:t.tipo,value:e[t.key],abierto:e.abierto===t.tipo,abrir:()=>this.abrirLista(t.tipo),set:s=>{this.set({[t.key]:s.target.value}),this.$emit("field",{key:t.key,value:s.target.value})}})),sexo:{icon:U.person,opciones:[{label:"Hombre",v:0},{label:"Mujer",v:1}].map(t=>({label:t.label,puesto:e.gen===t.v,elegir:()=>{e.gen!==t.v&&(this.set({gen:t.v}),this.$emit("genero",t.v))}}))},fechaCols:[{k:"dia",titulo:"Día",opciones:Array.from({length:31},(t,s)=>({v:s+1,t:String(s+1).padStart(2,"0")})),puesto:e.dia},{k:"mes",titulo:"Mes",opciones:Cc.map((t,s)=>({v:s+1,t})),puesto:e.mes},{k:"anio",titulo:"Año",opciones:Ac.map(t=>({v:t,t:String(t)})),puesto:e.anio}].map(t=>({...t,elegir:s=>this.ponerFecha(t.k,s)})),buscaPais:e.buscaPais,buscarPais:t=>this.set({buscaPais:t.target.value}),paises:(()=>{const t=Bi(e.buscaPais||"").trim();return(t?Fi.filter(u=>Bi(u).includes(t)):Fi).map(u=>({nombre:u,puesto:u===e.nac,elegir:()=>this.ponerPais(u)}))})(),cerrarListas:()=>this.cerrarListas(),hayLista:!!e.abierto,createOk:l,deselect:()=>this.set({card:-1}),playLabel:n&&n.state==="free"?"Crear":"Jugar",play:()=>{n&&n.state==="free"?this.$emit("create",{slot:e.card,nombre:e.nom,apellidos:e.ape,edad:e.edad,nacionalidad:e.nac,genero:e.gen}):n&&this.$emit("play",{slot:e.card,name:n.name})}}}}},_c={ref:"root",class:"ogn-root"},Lc={ref:"arte",style:{position:"absolute",left:"0",top:"0",right:"0",bottom:"0",transform:"scale(1.05)","will-change":"transform"}},kc={style:{position:"absolute",left:"300px",top:"45px",width:"926px","z-index":"30",display:"flex","justify-content":"center","pointer-events":"none"}},zc={style:{"pointer-events":"auto",height:"42px",transform:"skewX(-9deg)",display:"flex","align-items":"stretch","border-radius":"9px",overflow:"hidden",background:"#0c0c0e","box-shadow":"inset 0 0 0 1px rgba(255,255,255,0.1),0 5px 0 rgba(0,0,0,0.85),0 14px 26px rgba(0,0,0,0.55)"}},Ec={style:{flex:"none",display:"flex","align-items":"center",padding:"0 13px 0 15px","box-shadow":"inset -1px 0 0 rgba(255,255,255,0.12)"}},jc={viewBox:"0 0 24 24",width:"17",height:"17",fill:"none",stroke:"rgba(255,255,255,0.6)","stroke-width":"2.6","stroke-linecap":"round","stroke-linejoin":"round",style:{transform:"skewX(9deg)"},"aria-hidden":"true"},qc=["onClick"],Pc={style:{flex:"none",display:"flex","align-items":"center",padding:"0 15px 0 13px","box-shadow":"inset 1px 0 0 rgba(255,255,255,0.12)"}},Nc={viewBox:"0 0 24 24",width:"17",height:"17",fill:"none",stroke:"rgba(255,255,255,0.6)","stroke-width":"2.6","stroke-linecap":"round","stroke-linejoin":"round",style:{transform:"skewX(9deg)"},"aria-hidden":"true"},Ic={class:"ogn-hoja",style:{position:"absolute",right:"-40px",top:"0",bottom:"0",width:"618px","clip-path":"polygon(148px 0,100% 0,100% 100%,0 100%)","pointer-events":"none"}},Oc={key:0,class:"ogn-cartel",style:{position:"absolute",right:"-40px",top:"0",bottom:"0",width:"618px","clip-path":"polygon(151px 0,100% 0,100% 100%,3px 100%)",overflow:"hidden","pointer-events":"none",animation:"rulesIn 420ms cubic-bezier(0.16,0.9,0.28,1) both"}},Tc={style:{position:"absolute",right:"-40px",top:"0",bottom:"0",width:"618px","clip-path":"polygon(151px 0,100% 0,100% 100%,3px 100%)",overflow:"hidden","pointer-events":"none",animation:"rulesIn 420ms cubic-bezier(0.16,0.9,0.28,1) both"}},$c={style:{position:"absolute",left:"1204px",right:"34px",top:"432px","z-index":"20",display:"flex","flex-direction":"column",gap:"9px",animation:"rulesIn 460ms cubic-bezier(0.16,0.9,0.28,1) 60ms both"}},Rc=["onClick"],Dc={style:{flex:"none",width:"26px",height:"26px",display:"flex","align-items":"center","justify-content":"center",color:"#e0074f"}},Fc=["innerHTML"],Bc={style:{flex:"1","min-width":"0"}},Hc={style:{"font-family":"'Barlow Condensed',sans-serif","font-weight":"700","font-size":"11px","letter-spacing":"0.2em",color:"#26221a","text-transform":"uppercase"}},Vc=["value","onInput","placeholder"],Uc={key:0,style:{position:"absolute",left:"0",right:"0",top:"calc(100% + 7px)",display:"flex",gap:"8px",padding:"10px","border-radius":"11px",background:"#fffdf7","box-shadow":"inset 0 0 0 1px rgba(111,104,87,0.3),0 16px 30px rgba(80,70,50,0.25)"}},Kc={style:{"font-family":"'Barlow Condensed',sans-serif","font-weight":"700","font-size":"10px","letter-spacing":"0.22em",color:"#8a8270","text-transform":"uppercase",padding:"0 6px 6px"}},Gc={style:{"max-height":"186px","overflow-y":"auto"}},Xc=["onClick"],Wc={key:1,style:{position:"absolute",left:"0",right:"0",top:"calc(100% + 7px)",padding:"10px","border-radius":"11px",background:"#fffdf7","box-shadow":"inset 0 0 0 1px rgba(111,104,87,0.3),0 16px 30px rgba(80,70,50,0.25)"}},Jc={style:{display:"flex","align-items":"center",gap:"8px","border-radius":"7px",background:"rgba(38,34,26,0.05)","box-shadow":"inset 0 0 0 1px rgba(111,104,87,0.2)",padding:"6px 10px","margin-bottom":"8px"}},Qc=["value"],Zc={style:{"max-height":"170px","overflow-y":"auto"}},Yc=["onClick"],ed={key:0,style:{padding:"10px 9px","font-family":"'Barlow',sans-serif","font-size":"13px",color:"#9a9382"}},ad={style:{position:"relative","z-index":"1",display:"flex","align-items":"center",gap:"12px","border-radius":"9px",background:"rgba(255,255,255,0.62)","box-shadow":"inset 0 0 0 1px rgba(111,104,87,0.26),0 4px 0 rgba(120,110,88,0.14)",padding:"9px 13px"}},od={style:{flex:"none",width:"26px",height:"26px",display:"flex","align-items":"center","justify-content":"center",color:"#e0074f"}},nd=["innerHTML"],rd={style:{flex:"1","min-width":"0",display:"flex",gap:"8px","justify-content":"flex-end","padding-right":"4px"}},id=["onClick"],td={style:{display:"block",transform:"skewX(10deg)","font-family":"'Barlow Condensed',sans-serif","font-style":"italic","font-weight":"800","font-size":"16px","letter-spacing":"0.06em","text-transform":"uppercase"}},sd={key:3,class:"ogn-cartel",style:{position:"absolute",right:"-40px",top:"0",bottom:"0",width:"618px","clip-path":"polygon(151px 0,100% 0,100% 100%,3px 100%)",overflow:"hidden"}},ld={style:{position:"absolute",left:"1372px",right:"30px",top:"332px",display:"flex","flex-direction":"column",gap:"12px",animation:"rulesIn 440ms cubic-bezier(0.16,0.9,0.28,1) 40ms both"}},cd={style:{flex:"none",width:"58px","font-family":"'Barlow Condensed',sans-serif","font-weight":"700","font-size":"10px","letter-spacing":"0.2em",color:"var(--hoja-t3)","text-transform":"uppercase"}},dd={style:{flex:"1","min-width":"0",height:"7px",transform:"skewX(-9deg)","border-radius":"3px",background:"var(--hoja-pista)","box-shadow":"inset 0 0 0 1px var(--hoja-linea-16)",overflow:"hidden"}},ud={style:{position:"absolute",left:"1081px",right:"-40px",top:"430px",bottom:"0",overflow:"hidden","clip-path":"polygon(80px 0,100% 0,100% 100%,0 100%)",animation:"rulesIn 400ms cubic-bezier(0.16,0.9,0.28,1) both"}},pd={style:{position:"absolute",left:"100px",right:"110px",bottom:"120px","z-index":"801"}},md={style:{display:"flex","align-items":"center",gap:"7px"}},fd={class:"ogn-mapa-calle__texto",style:{flex:"1","min-width":"0","font-family":"'Barlow Condensed',sans-serif","font-weight":"700","font-size":"13px","letter-spacing":"0.1em","text-transform":"uppercase",overflow:"hidden","text-overflow":"ellipsis","white-space":"nowrap"}},hd={style:{position:"absolute",left:"1096px",right:"30px",top:"32px",bottom:"118px",display:"flex","flex-direction":"column",gap:"11px",animation:"rulesIn 400ms cubic-bezier(0.16,0.9,0.28,1) both"}},gd={style:{flex:"none","margin-left":"140px",display:"flex","align-items":"center",gap:"14px"}},bd={style:{flex:"none",width:"86px",height:"100px",transform:"skewX(-9deg)","border-radius":"9px",overflow:"hidden",background:"linear-gradient(160deg,#ff5c89 0%,#e0074f 100%)","box-shadow":"0 5px 0 #a80c3f"}},vd={style:{width:"100%",height:"100%",transform:"skewX(9deg) scale(1.2)"}},yd={style:{flex:"1","min-width":"0"}},xd={style:{"font-family":"'Barlow Condensed',sans-serif","font-style":"italic","font-weight":"800","font-size":"33px","line-height":"0.92",color:"var(--hoja-tinta)","text-transform":"uppercase",overflow:"hidden","text-overflow":"ellipsis","white-space":"nowrap"}},wd={style:{"font-family":"'Barlow Condensed',sans-serif","font-weight":"700","font-size":"12px","letter-spacing":"0.16em",color:"var(--hoja-t2)","text-transform":"uppercase","margin-top":"6px"}},Cd={style:{color:"var(--hoja-acento)"}},Sd={style:{flex:"none",display:"flex","flex-direction":"column",gap:"7px"}},Ad=["innerHTML"],Md={style:{"font-family":"'Barlow Condensed',sans-serif","font-weight":"700","font-size":"17px","letter-spacing":"0.04em",color:"var(--hoja-tinta)","white-space":"nowrap"}},_d={style:{flex:"none","margin-left":"128px",display:"flex","align-items":"center",gap:"11px"}},Ld={style:{flex:"none","font-family":"'Barlow Condensed',sans-serif","font-style":"italic","font-weight":"800","font-size":"21px","line-height":"1",color:"var(--hoja-tinta)","text-transform":"uppercase"}},kd={style:{flex:"1","min-width":"0",height:"11px",transform:"skewX(-9deg)","border-radius":"4px",background:"var(--hoja-pista)","box-shadow":"inset 0 0 0 1px var(--hoja-linea-16)",overflow:"hidden"}},zd={style:{flex:"none","font-family":"'Barlow Condensed',sans-serif","font-weight":"700","font-size":"12px","letter-spacing":"0.08em",color:"var(--hoja-t2)","white-space":"nowrap"}},Ed={style:{flex:"none","margin-left":"116px",display:"grid","grid-template-columns":"repeat(3,minmax(0,1fr))",gap:"0","border-radius":"10px",background:"var(--hoja-fondo)","box-shadow":"inset 0 0 0 1px var(--hoja-linea-18)",padding:"10px 0"}},jd={style:{flex:"none",color:"var(--hoja-acento)"}},qd=["innerHTML"],Pd={style:{flex:"1","min-width":"0"}},Nd={style:{"font-family":"'Barlow Condensed',sans-serif","font-weight":"700","font-size":"9.5px","letter-spacing":"0.18em",color:"var(--hoja-t3)","text-transform":"uppercase",overflow:"hidden","text-overflow":"ellipsis","white-space":"nowrap"}},Id={key:0,style:{"font-family":"'Barlow',sans-serif","font-size":"10.5px","line-height":"1.25",color:"var(--hoja-t3)",overflow:"hidden","text-overflow":"ellipsis","white-space":"nowrap"}},Od={style:{flex:"none",margin:"0 20px 6px 84px"}},Td=["src"],$d={style:{position:"absolute",left:"40px",right:"590px",top:"700px",height:"156px",display:"flex","align-items":"center",gap:"16px"}},Rd={style:{flex:"1","min-width":"0",display:"flex","align-items":"center",gap:"10px"}},Dd=["onClick"],Fd={style:{position:"relative",width:"100%",height:"100%","border-radius":"9px",overflow:"hidden",background:"#0c0c0e"}},Bd=["src"],Hd={key:1,style:{position:"absolute",left:"0",right:"0",top:"0",bottom:"0",background:"linear-gradient(180deg,rgba(255,255,255,0.05) 0%,rgba(255,255,255,0.02) 100%)",display:"flex","align-items":"center","justify-content":"center",color:"rgba(255,255,255,0.14)"}},Vd={style:{transform:"skewX(5deg)",width:"34px",height:"34px","border-radius":"50%","box-shadow":"inset 0 0 0 2px currentColor",display:"flex","align-items":"center","justify-content":"center"}},Ud=["innerHTML"],Kd={style:{transform:"skewX(5deg)",position:"absolute",left:"13px",right:"13px",bottom:"9px","pointer-events":"none"}},Gd={style:{transform:"skewX(16deg)","font-family":"'Barlow Condensed',sans-serif","font-style":"italic","font-weight":"800","font-size":"42px","line-height":"1",color:"#ffffff","text-transform":"uppercase","letter-spacing":"0.02em"}},Xd={viewBox:"0 0 24 24",width:"37",height:"37",fill:"none",stroke:"#ffffff","stroke-width":"2.4","stroke-linecap":"round","stroke-linejoin":"round",style:{transform:"skewX(16deg)"},"aria-hidden":"true"},Wd={key:6,style:{position:"absolute",left:"1096px",right:"30px",top:"96px",bottom:"118px",display:"flex","flex-direction":"column",gap:"11px",animation:"rulesIn 420ms cubic-bezier(0.16,0.9,0.28,1) both"}},Jd={style:{flex:"none","margin-left":"142px",display:"flex","align-items":"center",gap:"9px",transform:"skewX(-9deg)","border-radius":"8px",background:"var(--hoja-caja)","box-shadow":"inset 0 0 0 1px var(--hoja-borde-26)",padding:"8px 12px"}},Qd={viewBox:"0 0 24 24",width:"14",height:"14",fill:"none","stroke-width":"1.8","stroke-linecap":"round",style:{stroke:"var(--hoja-t3)",transform:"skewX(9deg)"},"aria-hidden":"true"},Zd=["value"],Yd={style:{flex:"none","margin-left":"134px",display:"flex","flex-wrap":"wrap","align-content":"flex-start",gap:"5px"}},eu=["onClick"],au={style:{flex:"1","min-height":"0","margin-left":"112px",overflow:"auto",display:"flex","flex-direction":"column",gap:"11px","padding-right":"4px"}},ou={style:{flex:"none"}},nu={style:{"font-family":"'Barlow Condensed',sans-serif","font-style":"italic","font-weight":"800","font-size":"24px","line-height":"1",color:"var(--hoja-tinta)","text-transform":"uppercase"}},ru={style:{"font-size":"13.5px","line-height":"1.45",color:"var(--hoja-t2)","margin-top":"4px","text-wrap":"pretty"}},iu={key:0,style:{flex:"none",display:"flex","align-items":"center",gap:"10px"}},tu={style:{flex:"none","font-family":"'Barlow Condensed',sans-serif","font-weight":"700","font-size":"11.5px","letter-spacing":"0.2em",color:"var(--hoja-acento)","text-transform":"uppercase"}},su={key:0,style:{flex:"none",display:"flex","align-items":"center",gap:"10px","margin-top":"6px"}},lu={style:{flex:"none","font-family":"'Barlow Condensed',sans-serif","font-weight":"700","font-size":"11.5px","letter-spacing":"0.2em",color:"var(--hoja-acento)","text-transform":"uppercase"}},cu=["innerHTML"],du={key:1,style:{flex:"none","font-size":"14px","line-height":"1.5",color:"var(--hoja-texto)","text-wrap":"pretty"}},uu={style:{"font-weight":"600",color:"var(--hoja-tinta)"}},pu=["innerHTML"],mu=["innerHTML"],fu={key:1,style:{flex:"none","border-radius":"9px","box-shadow":"inset 3px 0 0 #ff2d6a",background:"var(--hoja-fondo)",padding:"11px 13px","font-size":"13.5px","line-height":"1.5",color:"var(--hoja-suave)","text-wrap":"pretty"}},hu={style:{flex:"none","margin-left":"34px",display:"flex","align-items":"center",gap:"9px"}},gu={style:{flex:"none","font-family":"'Barlow Condensed',sans-serif","font-weight":"700","font-size":"10px","letter-spacing":"0.2em",color:"var(--hoja-t3)","text-transform":"uppercase"}};function bu(e,a,o,n,r,i){const l=Dr("OgnImage"),t=Dr("MapaFicha");return M(),_("div",_c,[h("div",{class:"ogn-stage",style:X(`transform:scale(${i.v.scale})`)},[h("div",Lc,[pe(l,{"src-key":"art",images:o.images,label:"Arte principal"},null,8,["images"])],512),a[32]||(a[32]=yi('<div style="position:absolute;left:-60px;right:-60px;top:-20px;height:140px;background:linear-gradient(180deg,rgba(9,9,11,0.42) 0%,rgba(9,9,11,0.12) 60%,rgba(9,9,11,0) 100%);pointer-events:none;" data-v-f47496e6></div><div style="position:absolute;left:-60px;right:-60px;bottom:-20px;height:350px;background:linear-gradient(180deg,rgba(9,9,11,0) 0%,rgba(9,9,11,0.55) 38%,rgba(9,9,11,0.94) 72%,#08080a 100%);pointer-events:none;" data-v-f47496e6></div><div style="position:absolute;right:-60px;top:-20px;bottom:-20px;width:530px;background:linear-gradient(270deg,rgba(9,9,11,0.9) 0%,rgba(9,9,11,0.5) 45%,rgba(9,9,11,0) 100%);pointer-events:none;" data-v-f47496e6></div><div style="position:absolute;left:-60px;top:-20px;right:-60px;bottom:-20px;box-shadow:inset 0 0 90px 10px rgba(8,8,10,0.4);pointer-events:none;" data-v-f47496e6></div><div style="position:absolute;left:14px;top:682px;width:1046px;height:2px;transform:skewX(-9deg);background:linear-gradient(90deg,rgba(255,45,106,0.15) 0%,rgba(255,45,106,0.85) 14%,rgba(255,45,106,0.35) 68%,rgba(255,255,255,0) 100%);pointer-events:none;" data-v-f47496e6></div><div style="position:absolute;left:14px;top:874px;width:1046px;height:2px;transform:skewX(-9deg);background:linear-gradient(90deg,rgba(255,255,255,0.06) 0%,rgba(255,255,255,0.34) 14%,rgba(255,255,255,0.12) 68%,rgba(255,255,255,0) 100%);pointer-events:none;" data-v-f47496e6></div>',6)),h("div",kc,[h("div",zc,[h("div",Ec,[(M(),_("svg",jc,[...a[8]||(a[8]=[h("path",{d:"M14.5 5 8 12l6.5 7"},null,-1)])]))]),(M(!0),_(H,null,be(i.v.nav,(s,u)=>(M(),_("div",{key:u,onClick:s.go,style:X(`cursor:pointer;flex:none;display:flex;align-items:center;justify-content:center;padding:0 ${s.pad};background:${s.bg};clip-path:${s.clip}`)},[h("div",{style:X(`transform:skewX(9deg);font-family:'Barlow Condensed',sans-serif;font-style:italic;font-weight:800;font-size:19px;letter-spacing:0.08em;color:${s.fg};text-transform:uppercase;white-space:nowrap`)},V(s.label),5)],12,qc))),128)),h("div",Pc,[(M(),_("svg",Nc,[...a[9]||(a[9]=[h("path",{d:"M9.5 5 16 12l-6.5 7"},null,-1)])]))])])]),h("div",Ic,[h("div",{class:"ogn-hoja__papel",style:X(`position:absolute;left:0;right:0;top:0;bottom:0;clip-path:polygon(148px 0,100% 0,100% 100%,0 100%);background-image:url(${i.v.paper});background-size:auto 100%;background-position:left top;background-repeat:no-repeat`)},null,4),a[10]||(a[10]=h("div",{class:"ogn-hoja__velo",style:{position:"absolute",left:"0",right:"0",top:"0",bottom:"0","clip-path":"polygon(148px 0,100% 0,100% 100%,0 100%)",background:"linear-gradient(180deg,rgba(255,253,247,0.34) 0%,rgba(255,253,247,0.12) 45%,rgba(255,253,247,0.3) 100%)"}},null,-1))]),i.v.isLock?(M(),_("div",Oc,[pe(l,{src:i.v.lockBg,label:"Slot bloqueado"},null,8,["src"])])):oe("",!0),i.v.isCreate?(M(),_(H,{key:1},[h("div",Tc,[h("div",{style:X(`position:absolute;left:0;right:0;top:0;bottom:0;background-color:#fffdf7;background-image:url(${i.v.createBg});background-size:cover;background-position:left center;background-repeat:no-repeat`)},null,4)]),i.v.hayLista?(M(),_("div",{key:0,onClick:a[0]||(a[0]=(...s)=>i.v.cerrarListas&&i.v.cerrarListas(...s)),style:{position:"absolute",left:"0",right:"0",top:"0",bottom:"0","z-index":"15",cursor:"default"}})):oe("",!0),h("div",$c,[(M(!0),_(H,null,be(i.v.form,(s,u)=>(M(),_("div",{key:u,style:X(`position:relative;z-index:${s.abierto?6:1}`)},[h("div",{onClick:d=>s.tipo==="texto"?null:s.abrir(),style:X(`display:flex;align-items:center;gap:12px;border-radius:9px;background:rgba(255,255,255,0.62);box-shadow:inset 0 0 0 1px ${s.abierto?"#e0074f":"rgba(111,104,87,0.26)"},0 4px 0 rgba(120,110,88,0.14);padding:9px 13px;${s.tipo==="texto"?"":"cursor:pointer"}`)},[h("div",Dc,[(M(),_("svg",{viewBox:"0 0 24 24",width:"19",height:"19",fill:"none",stroke:"currentColor","stroke-width":"1.8","stroke-linecap":"round","stroke-linejoin":"round","aria-hidden":"true",innerHTML:i.ico(s.icon)},null,8,Fc))]),h("div",Bc,[h("div",Hc,V(s.label),1),s.tipo==="texto"?(M(),_("input",{key:0,type:"text",value:s.value,onInput:s.set,placeholder:s.ph,style:{width:"100%",border:"0",outline:"none",background:"transparent","font-family":"'Barlow',sans-serif","font-style":"italic","font-size":"15px",color:"#3b352a","margin-top":"1px"}},null,40,Vc)):(M(),_("div",{key:1,style:X(`font-family:'Barlow',sans-serif;font-style:italic;font-size:15px;margin-top:1px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;color:${s.value?"#3b352a":"#9a9382"}`)},V(s.value||s.ph),5))]),s.arrow?(M(),_("div",{key:0,style:X(`flex:none;color:#8a8270;transition:transform 180ms ease;transform:rotate(${s.abierto?"180deg":"0deg"})`)},[...a[11]||(a[11]=[h("svg",{viewBox:"0 0 24 24",width:"17",height:"17",fill:"none",stroke:"currentColor","stroke-width":"2","stroke-linecap":"round","stroke-linejoin":"round","aria-hidden":"true"},[h("path",{d:"M6 9.5 12 15.5 18 9.5"})],-1)])],4)):oe("",!0)],12,Rc),s.tipo==="fecha"&&s.abierto?(M(),_("div",Uc,[(M(!0),_(H,null,be(i.v.fechaCols,(d,m)=>(M(),_("div",{key:m,style:{flex:"1","min-width":"0"}},[h("div",Kc,V(d.titulo),1),h("div",Gc,[(M(!0),_(H,null,be(d.opciones,(A,E)=>(M(),_("div",{key:E,onClick:Dn(g=>d.elegir(A.v),["stop"]),style:X(`cursor:pointer;border-radius:6px;padding:5px 8px;font-family:'Barlow',sans-serif;font-size:13.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;${d.puesto===A.v?"background:linear-gradient(100deg,#ff3b74 0%,#e0074f 100%);color:#fff;font-weight:600":"color:#4a4437"}`)},V(A.t),13,Xc))),128))])]))),128))])):oe("",!0),s.tipo==="lista"&&s.abierto?(M(),_("div",Wc,[h("div",Jc,[a[12]||(a[12]=h("svg",{viewBox:"0 0 24 24",width:"15",height:"15",fill:"none",stroke:"#8a8270","stroke-width":"2","stroke-linecap":"round","stroke-linejoin":"round","aria-hidden":"true"},[h("circle",{cx:"11",cy:"11",r:"6.4"}),h("path",{d:"m20 20-4.2-4.2"})],-1)),h("input",{type:"text",value:i.v.buscaPais,onInput:a[1]||(a[1]=(...d)=>i.v.buscarPais&&i.v.buscarPais(...d)),onClick:a[2]||(a[2]=Dn(()=>{},["stop"])),placeholder:"Buscar país…",style:{width:"100%",border:"0",outline:"none",background:"transparent","font-family":"'Barlow',sans-serif","font-size":"13.5px",color:"#3b352a"}},null,40,Qc)]),h("div",Zc,[(M(!0),_(H,null,be(i.v.paises,(d,m)=>(M(),_("div",{key:m,onClick:Dn(A=>d.elegir(),["stop"]),style:X(`cursor:pointer;border-radius:6px;padding:6px 9px;font-family:'Barlow',sans-serif;font-size:13.5px;${d.puesto?"background:linear-gradient(100deg,#ff3b74 0%,#e0074f 100%);color:#fff;font-weight:600":"color:#4a4437"}`)},V(d.nombre),13,Yc))),128)),i.v.paises.length?oe("",!0):(M(),_("div",ed,"Sin resultados"))])])):oe("",!0)],4))),128)),h("div",ad,[h("div",od,[(M(),_("svg",{viewBox:"0 0 24 24",width:"19",height:"19",fill:"none",stroke:"currentColor","stroke-width":"1.8","stroke-linecap":"round","stroke-linejoin":"round","aria-hidden":"true",innerHTML:i.ico(i.v.sexo.icon)},null,8,nd))]),a[13]||(a[13]=h("div",{style:{flex:"none","font-family":"'Barlow Condensed',sans-serif","font-weight":"700","font-size":"11px","letter-spacing":"0.2em",color:"#26221a","text-transform":"uppercase"}},"Sexo",-1)),h("div",rd,[(M(!0),_(H,null,be(i.v.sexo.opciones,(s,u)=>(M(),_("button",{key:u,type:"button",onClick:d=>s.elegir(),style:X(`flex:1;max-width:132px;border:0;border-radius:7px;padding:7px 10px;cursor:pointer;transform:skewX(-10deg);transition:background 160ms ease,box-shadow 160ms ease,color 160ms ease;${s.puesto?"background:linear-gradient(160deg,#ff5c89 0%,#e0074f 100%);box-shadow:0 3px 0 #a80c3f;color:#fff":"background:rgba(255,255,255,0.85);box-shadow:inset 0 0 0 1px rgba(111,104,87,0.26),0 3px 0 rgba(120,110,88,0.18);color:#4a4437"}`)},[h("span",td,V(s.label),1)],12,id))),128))])])])],64)):oe("",!0),i.v.hasSel?(M(),_("div",{key:2,onClick:a[3]||(a[3]=(...s)=>i.v.deselect&&i.v.deselect(...s)),style:{position:"absolute",left:"0",right:"0",top:"0",bottom:"0",cursor:"default"}})):oe("",!0),i.v.noSel?(M(),_("div",sd,[pe(l,{"src-key":"poster",images:o.images,label:"Cartel de bienvenida"},null,8,["images"])])):oe("",!0),i.v.hasSel?(M(),_(H,{key:4},[h("div",ld,[(M(!0),_(H,null,be(i.v.vitales,(s,u)=>(M(),_("div",{key:u,style:{display:"flex","align-items":"center",gap:"10px"}},[h("div",cd,V(s.k),1),h("div",dd,[h("div",{style:X(`height:7px;width:${s.ancho};border-radius:2px;background:${s.color}`)},null,4)])]))),128))]),h("div",ud,[pe(t,{coords:o.ficha.coords,puntos:o.ficha.puntos||[]},null,8,["coords","puntos"]),a[15]||(a[15]=h("div",{class:"ogn-mapa-fundido ogn-mapa-fundido--arriba"},null,-1)),a[16]||(a[16]=h("div",{class:"ogn-mapa-fundido ogn-mapa-fundido--abajo"},null,-1)),h("div",pd,[h("div",md,[a[14]||(a[14]=h("div",{class:"ogn-mapa-calle__pin",style:{flex:"none"}},[h("svg",{viewBox:"0 0 24 24",width:"14",height:"14",fill:"none",stroke:"currentColor","stroke-width":"2","stroke-linecap":"round","stroke-linejoin":"round","aria-hidden":"true"},[h("path",{d:"M12 21s6.5-6.1 6.5-10.4A6.5 6.5 0 0 0 5.5 10.6C5.5 14.9 12 21 12 21z"}),h("circle",{cx:"12",cy:"10.4",r:"2.3"})])],-1)),h("div",fd,V(i.v.ubicacionMapa),1)])])]),h("div",hd,[a[18]||(a[18]=h("div",{style:{flex:"none","margin-left":"150px",height:"1px",background:"var(--hoja-linea-22)"}},null,-1)),h("div",gd,[h("div",bd,[h("div",vd,[pe(l,{"src-key":"portrait",images:o.images,label:"Retrato"},null,8,["images"])])]),h("div",yd,[h("div",xd,V(i.v.pjName),1),h("div",wd,[a[17]||(a[17]=La("ID ",-1)),h("span",Cd,V(i.v.pjId),1)])]),h("div",Sd,[(M(!0),_(H,null,be(i.v.pjMoney,(s,u)=>(M(),_("div",{key:u,style:{display:"flex","align-items":"center",gap:"8px"}},[h("div",{style:X(`flex:none;width:24px;height:24px;border-radius:50%;background:${s.bg};box-shadow:${s.ring};display:flex;align-items:center;justify-content:center;color:${s.markFg}`)},[(M(),_("svg",{viewBox:"0 0 24 24",width:"13",height:"13",fill:"none",stroke:"currentColor","stroke-width":"2","stroke-linecap":"round","stroke-linejoin":"round","aria-hidden":"true",innerHTML:i.ico(s.icon)},null,8,Ad))],4),h("div",Md,V(s.v),1)]))),128))])]),h("div",_d,[h("div",Ld,"Nv. "+V(i.v.pjLvl),1),h("div",kd,[h("div",{style:X(`height:11px;width:${i.v.pjXpPct};border-radius:3px;background:linear-gradient(90deg,#ff5c89 0%,#e0074f 100%)`)},null,4)]),h("div",zd,V(i.v.pjXp),1)]),h("div",Ed,[(M(!0),_(H,null,be(i.v.pjStats,(s,u)=>(M(),_("div",{key:u,style:X(`display:flex;align-items:center;gap:9px;padding:6px 11px;box-shadow:${s.rule}`)},[h("div",jd,[(M(),_("svg",{viewBox:"0 0 24 24",width:"17",height:"17",fill:"none",stroke:"currentColor","stroke-width":"1.8","stroke-linecap":"round","stroke-linejoin":"round","aria-hidden":"true",innerHTML:i.ico(s.icon)},null,8,qd))]),h("div",Pd,[h("div",Nd,V(s.k),1),h("div",{style:X(`font-family:'Barlow Condensed',sans-serif;font-weight:700;font-size:14px;letter-spacing:0.04em;line-height:1.2;color:${s.fg};overflow:hidden;text-overflow:ellipsis;white-space:nowrap`)},V(s.v),5),s.sub?(M(),_("div",Id,V(s.sub),1)):oe("",!0)])],4))),128))]),h("div",Od,[h("img",{src:i.v.rotuloMapa,alt:"",style:{display:"block",width:"172px",height:"auto"}},null,8,Td)])])],64)):oe("",!0),h("div",$d,[h("div",{onClick:a[4]||(a[4]=(...s)=>i.v.prev&&i.v.prev(...s)),style:{flex:"none",width:"30px",height:"44px",display:"flex","align-items":"center","justify-content":"center",color:"#ffffff",cursor:"pointer"}},[...a[19]||(a[19]=[h("svg",{viewBox:"0 0 24 24",width:"28",height:"28",fill:"none",stroke:"currentColor","stroke-width":"2","stroke-linecap":"round","stroke-linejoin":"round","aria-hidden":"true"},[h("path",{d:"M15.5 4 7.5 12l8 8"})],-1)])]),h("div",Rd,[(M(!0),_(H,null,be(i.v.cards,(s,u)=>(M(),_("div",{key:u,onClick:s.go,style:X(`cursor:pointer;flex:${s.flex};min-width:0;position:relative;height:${s.h};transform:skewX(-5deg);border-radius:11px;overflow:hidden;background:${s.edge};padding:${s.pad};box-shadow:0 5px 0 rgba(0,0,0,0.85)`)},[h("div",Fd,[s.hasRender?(M(),_(H,{key:0},[s.foto?(M(),_(H,{key:0},[h("img",{src:s.foto,alt:"",style:{position:"absolute",left:"0",right:"0",top:"0",bottom:"0",margin:"auto",height:"100%",width:"auto","aspect-ratio":"1/1","object-fit":"cover",transform:"skewX(5deg)","-webkit-mask-image":"linear-gradient(90deg,transparent 0,#000 14%,#000 86%,transparent 100%)","mask-image":"linear-gradient(90deg,transparent 0,#000 14%,#000 86%,transparent 100%)"}},null,8,Bd),a[20]||(a[20]=h("div",{style:{position:"absolute",left:"0",right:"0",top:"0",bottom:"0",background:"linear-gradient(180deg,rgba(9,9,11,0) 0%,rgba(9,9,11,0.1) 60%,rgba(9,9,11,0.35) 100%)","pointer-events":"none"}},null,-1))],64)):(M(),_("div",Hd,[...a[21]||(a[21]=[h("svg",{viewBox:"0 0 24 24",width:"46",height:"46",fill:"none",stroke:"currentColor","stroke-width":"1.5","stroke-linecap":"round","stroke-linejoin":"round","aria-hidden":"true"},[h("circle",{cx:"12",cy:"8",r:"3.6"}),h("path",{d:"M5 20c0-3.6 3.1-5.6 7-5.6s7 2 7 5.6"})],-1)])]))],64)):oe("",!0),s.empty?(M(),_("div",{key:1,style:X(`position:absolute;left:0;right:0;top:0;bottom:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:9px;background:${s.emptyBg};color:${s.emptyFg}`)},[h("div",Vd,[(M(),_("svg",{viewBox:"0 0 24 24",width:"17",height:"17",fill:"none",stroke:"currentColor","stroke-width":"2","stroke-linecap":"round","stroke-linejoin":"round","aria-hidden":"true",innerHTML:i.ico(s.emptyIcon)},null,8,Ud))])],4)):oe("",!0)]),a[22]||(a[22]=h("div",{style:{position:"absolute",left:"0",right:"0",bottom:"0",top:"38%",background:"linear-gradient(180deg,rgba(9,9,11,0) 0%,rgba(9,9,11,0.55) 38%,rgba(9,9,11,0.95) 100%)","pointer-events":"none"}},null,-1)),h("div",Kd,[h("div",{style:X(`font-family:'Barlow Condensed',sans-serif;font-style:italic;font-weight:800;font-size:${s.size};line-height:1;color:${s.nameFg};text-transform:uppercase;text-shadow:0 3px 0 rgba(0,0,0,0.5);overflow:hidden;text-overflow:ellipsis;white-space:nowrap`)},V(s.name),5),s.line?(M(),_("div",{key:0,style:X(`font-family:'Barlow Condensed',sans-serif;font-weight:700;font-size:10.5px;letter-spacing:0.14em;color:${s.lineFg};text-transform:uppercase;margin-top:3px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap`)},V(s.line),5)):oe("",!0)]),s.tag?(M(),_("div",{key:0,style:X(`transform:skewX(5deg);position:absolute;left:11px;top:10px;display:flex;align-items:center;gap:6px;border-radius:6px;background:${s.tagBg};box-shadow:${s.tagShadow};padding:3px 8px;pointer-events:none`)},[h("div",{style:X(`font-family:'Barlow Condensed',sans-serif;font-weight:700;font-size:9.5px;letter-spacing:0.18em;line-height:1.25;color:${s.tagFg};text-transform:uppercase;white-space:nowrap`)},V(s.tag),5)],4)):oe("",!0)],12,Dd))),128))]),h("div",{onClick:a[5]||(a[5]=(...s)=>i.v.next&&i.v.next(...s)),style:{flex:"none",width:"30px",height:"44px",display:"flex","align-items":"center","justify-content":"center",color:"#ffffff",cursor:"pointer"}},[...a[23]||(a[23]=[h("svg",{viewBox:"0 0 24 24",width:"28",height:"28",fill:"none",stroke:"currentColor","stroke-width":"2","stroke-linecap":"round","stroke-linejoin":"round","aria-hidden":"true"},[h("path",{d:"M8.5 4 16.5 12l-8 8"})],-1)])])]),a[33]||(a[33]=yi('<div style="position:absolute;left:45px;right:614px;bottom:26px;display:flex;align-items:center;gap:14px;" data-v-f47496e6><div style="flex:none;display:flex;align-items:center;gap:9px;color:rgba(255,255,255,0.82);" data-v-f47496e6><svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" data-v-f47496e6><rect x="7.2" y="2.8" width="9.6" height="18.4" rx="4.8" data-v-f47496e6></rect><path d="M12 6.6v3.2" data-v-f47496e6></path></svg><div style="font-family:&#39;Barlow&#39;,sans-serif;font-weight:500;font-size:13px;letter-spacing:0.2em;text-transform:uppercase;white-space:nowrap;" data-v-f47496e6>Click para seleccionar</div></div></div><div style="position:absolute;left:1086px;bottom:22px;width:186px;transform:rotate(-4deg);pointer-events:none;" data-v-f47496e6></div>',2)),i.v.isLock?oe("",!0):(M(),_("div",{key:5,onClick:a[6]||(a[6]=(...s)=>i.v.play&&i.v.play(...s)),style:{cursor:"pointer",position:"absolute",right:"0px",bottom:"30px",width:"392px",height:"80px",transform:"skewX(-16deg) translateX(22px)","border-radius":"14px 0 0 14px",overflow:"hidden",background:"linear-gradient(100deg,#ff3b74 0%,#e0074f 100%)","box-shadow":"0 6px 0 #a80c3f,0 16px 26px rgba(0,0,0,0.45)",display:"flex","align-items":"center","justify-content":"center",gap:"16px","padding-right":"20px",top:"867px"}},[h("div",Gd,V(i.v.playLabel),1),(M(),_("svg",Xd,[...a[24]||(a[24]=[h("path",{d:"M3.5 12h16"},null,-1),h("path",{d:"M13 5.5 19.5 12 13 18.5"},null,-1)])]))])),i.v.isRules?(M(),_("div",Wd,[a[30]||(a[30]=h("div",{style:{flex:"none","margin-left":"146px"}},[h("div",{style:{"font-family":"'Barlow Condensed',sans-serif","font-weight":"700","font-size":"10.5px","letter-spacing":"0.28em",color:"var(--hoja-acento)","text-transform":"uppercase"}},"Documento vinculante"),h("div",{style:{"font-family":"'Barlow Condensed',sans-serif","font-style":"italic","font-weight":"800","font-size":"33px","line-height":"0.95",color:"var(--hoja-tinta)","text-transform":"uppercase","margin-top":"2px"}},"Normativa")],-1)),h("div",Jd,[(M(),_("svg",Qd,[...a[25]||(a[25]=[h("circle",{cx:"11",cy:"11",r:"6.5"},null,-1),h("path",{d:"M16 16l4 4"},null,-1)])])),h("input",{class:"ogn-rule-search",type:"text",value:i.v.ruleQ,onInput:a[7]||(a[7]=(...s)=>i.v.onRuleQ&&i.v.onRuleQ(...s)),placeholder:"Buscar en la normativa",style:{transform:"skewX(9deg)",flex:"1","min-width":"0",border:"0",outline:"none",background:"transparent","font-family":"'Barlow Condensed',sans-serif","font-weight":"700","font-size":"13px","letter-spacing":"0.1em",color:"var(--hoja-tinta)","text-transform":"uppercase"}},null,40,Zd)]),h("div",Yd,[(M(!0),_(H,null,be(i.v.rules,(s,u)=>(M(),_("div",{key:u,onClick:s.go,style:X(`cursor:pointer;flex:none;max-width:100%;transform:skewX(-9deg);border-radius:6px;background:${s.bg};box-shadow:${s.shadow};padding:6px 9px;animation:ruleChip 340ms cubic-bezier(0.16,0.9,0.28,1) both;animation-delay:${s.delay}`)},[h("div",{style:X(`transform:skewX(9deg);font-family:'Barlow Condensed',sans-serif;font-weight:700;font-size:10.5px;letter-spacing:0.12em;line-height:1.2;color:${s.fg};text-transform:uppercase;white-space:nowrap`)},V(s.label),5)],12,eu))),128))]),a[31]||(a[31]=h("div",{style:{flex:"none","margin-left":"112px",height:"1px",background:"var(--hoja-linea-22)"}},null,-1)),h("div",au,[h("div",ou,[h("div",nu,V(i.v.ruleTitle),1),h("div",ru,V(i.v.ruleSub),1)]),i.v.ruleHead?(M(),_("div",iu,[h("div",tu,V(i.v.ruleHead),1),a[26]||(a[26]=h("div",{style:{flex:"1",height:"2px",background:"linear-gradient(90deg,rgba(224,7,79,0.5),rgba(111,104,87,0))"}},null,-1))])):oe("",!0),(M(!0),_(H,null,be(i.v.ruleBlocks,(s,u)=>(M(),_(H,{key:u},[s.sec!==void 0?(M(),_("div",su,[h("div",lu,[(M(!0),_(H,null,be(s.secParts||[{t:s.sec}],(d,m)=>(M(),_(H,{key:m},[d.i?(M(),_("svg",{key:0,class:"ogn-rule-ico",viewBox:"0 0 24 24","aria-hidden":"true",style:X(`color:${i.tonoIco(d.i.tono)}`),innerHTML:d.i.svg},null,12,cu)):(M(),_(H,{key:1},[La(V(d.t),1)],64))],64))),128))]),a[27]||(a[27]=h("div",{style:{flex:"1",height:"2px",background:"linear-gradient(90deg,rgba(224,7,79,0.5),rgba(111,104,87,0))"}},null,-1))])):(M(),_("div",du,[h("span",uu,[(M(!0),_(H,null,be(s.leadParts||[{t:s.lead}],(d,m)=>(M(),_(H,{key:m},[d.i?(M(),_("svg",{key:0,class:"ogn-rule-ico",viewBox:"0 0 24 24","aria-hidden":"true",style:X(`color:${i.tonoIco(d.i.tono)}`),innerHTML:d.i.svg},null,12,pu)):(M(),_(H,{key:1},[La(V(d.t),1)],64))],64))),128))]),a[28]||(a[28]=La()),(M(!0),_(H,null,be(s.bodyParts||[{t:s.body}],(d,m)=>(M(),_(H,{key:m},[d.i?(M(),_("svg",{key:0,class:"ogn-rule-ico",viewBox:"0 0 24 24","aria-hidden":"true",style:X(`color:${i.tonoIco(d.i.tono)}`),innerHTML:d.i.svg},null,12,mu)):(M(),_(H,{key:1},[La(V(d.t),1)],64))],64))),128))]))],64))),128)),i.v.ruleEmpty?(M(),_("div",fu,"Este apartado está listo para el texto del documento. Pásame el contenido y lo vuelco con el mismo formato.")):oe("",!0)]),h("div",hu,[a[29]||(a[29]=h("div",{style:{flex:"1",height:"2px",background:"linear-gradient(90deg,rgba(224,7,79,0.45),rgba(111,104,87,0))"}},null,-1)),h("div",gu,V(i.v.ruleFoot),1)])])):oe("",!0)],4)],512)}const vu=Vo(Mc,[["render",bu],["__scopeId","data-v-f47496e6"]]),yu="origen_titlemenu";let Ko="";function le(e,a={}){return new Promise(o=>{const n=new XMLHttpRequest;n.open("POST",`https://${yu}/${e}`,!0),n.setRequestHeader("Content-Type","application/json; charset=UTF-8"),n.onload=()=>{if(n.status<200||n.status>=300)return Ko=`${e}: HTTP ${n.status}`,console.error("[origen_titlemenu] "+Ko),o(null);const r=n.responseText;if(!r)return o(null);try{o(JSON.parse(r))}catch{o(r)}},n.onerror=()=>{Ko=`${e}: sin conexion con el recurso`,console.error("[origen_titlemenu] "+Ko),o(null)},n.send(JSON.stringify(a))})}function Ki(e,a={},o=15e3,n=!1){const r=le("TriggerCallback",{...a,name:e}),i=new Promise(l=>setTimeout(()=>{n||console.error("[origen_titlemenu] Sin respuesta de "+e+" tras "+o+" ms"),l(null)},o));return Promise.race([r,i])}function ga(e,a){const o=n=>{n.data?.action===e&&a(n.data)};Va(()=>window.addEventListener("message",o)),qo(()=>window.removeEventListener("message",o))}function xu(e){window.invokeNative?window.invokeNative("openUrl",e):window.open(e,"_blank")}const ao=se([]),oo=se(5),Ea=se(null),Go=se(null),Xo=se([]),Gi=se(null),Xi=se(!0),ea=se(!1),Wi=se(!1),no=se(null),ja=wo({nombre:"",apellido:"",nacimiento:"",nacionalidad:"",genero:null});function Ji(){ja.nombre="",ja.apellido="",ja.nacimiento="",ja.nacionalidad="",ja.genero=null}const la=se(!1),qa=se(!1);let ro=null;function wu(){return la.value?Promise.resolve(!0):new Promise(e=>{ro=e})}async function Vn(e=420){qa.value||(qa.value=!0,await le("HudFadeOut",{time:e}))}async function Wo(e=300){if(qa.value){if(la.value){qa.value=!1;return}qa.value=!1,await le("HudFadeIn",{time:e})}}const Cu=e=>e==null?"—":"$ "+Number(e).toLocaleString("es-ES").replace(/,/g," ");function Su(e){const a=e.lastLoggedOutUnix?e.lastLoggedOutUnix*1e3:Number(e.last_logged_out);if(!a||Number.isNaN(a))return"Nunca";const o=new Date(a);return Number.isNaN(o.getTime())?"Nunca":o.toLocaleDateString("es-ES",{day:"2-digit",month:"short",year:"numeric"})+" · "+o.toLocaleTimeString("es-ES",{hour:"2-digit",minute:"2-digit"})}function Au(e){if(!e)return"—";const a=/^(\d{4})-(\d{2})-(\d{2})/.exec(String(e));if(a)return`${a[3]}/${a[2]}/${a[1]}`;const o=new Date(e);return Number.isNaN(o.getTime())?String(e):o.toLocaleDateString("es-ES",{day:"2-digit",month:"2-digit",year:"numeric"})}function Mu(e){const a=Number(e)||0;if(a<60)return a+" min";const o=Math.floor(a/60),n=a%60;return n?`${o} h ${n} min`:`${o} h`}const Jo=(e,a)=>Math.max(0,Math.min(100,Math.round((Number(e)||0)/a*100)));function Qi(){const e=sa(()=>{const g=Math.max(oo.value,ao.value.length,1);return Array.from({length:Math.max(g,5)},(b,j)=>{const q=j+1,w=ao.value.find(N=>N.cid===q),$=String(q).padStart(2,"0");return w?{n:$,cid:q,citizenid:w.citizenid,nombre:[w.firstname,w.lastname].filter(Boolean).join(" ")||"Sin nombre",estado:"libre",cumple:Au(w.birthdate),ocupacion:w.job||"Desempleado",nacionalidad:w.nationality||"—",banco:Cu(w.bank),ult:Su(w),tiempo:Mu(w.playtime),minutos:Number(w.playtime)||0,racha:(Number(w.login_streak)||0)+(Number(w.login_streak)===1?" día":" días"),ubicacion:w.ubicacion||"—",nivel:Number(w.nivel)||1,xpNivel:Number(w.xpNivel)||0,xpFalta:Number(w.xpFalta)||0,retrato:w.retrato||"",coords:w.position&&w.position.x!=null?{x:w.position.x,y:w.position.y}:null,salud:Jo(w.health??200,200),hambre:Jo(w.hunger??100,100),sed:Jo(w.thirst??100,100),estres:Jo(w.stress??0,100)}:{n:$,cid:q,nombre:q<=oo.value?"Slot vacío":"Slot bloqueado",estado:q<=oo.value?"vacio":"bloqueado"}})});function a(){la.value=!0,ro&&(ro(!0),ro=null)}function o(){la.value=!1,qa.value=!1,ea.value=!1,ro=null,Ji()}function n(g,b){const j=ao.value.find(q=>q.citizenid===g);j&&(j.retrato=b)}function r(g){ao.value=g.characters||[],oo.value=g.slots||1,Xi.value=ao.value.length===0,Wi.value=!0}async function i(){await le("HudFadeOut",{time:380}),await le("StartCinematicCam",{blend:0}),await le("HudFadeIn",{time:380})}async function l(){Ea.value=null,await le("UnselectCharacter",{}),await le("StopCinematicCam",{})}async function t(g){if(!g||g.estado==="bloqueado")return;if(Ea.value=g.cid,g.estado!=="libre"){await le("StartCharacterCreation",{});return}const b=12,j=250;for(let q=0;q<b;q++){if(Ea.value!==g.cid||await le("SelectCharacter",{citizenid:g.citizenid}))return;await new Promise(w=>setTimeout(w,j))}console.error("[origen_titlemenu] El ped de "+g.citizenid+" no ha llegado a montarse")}function s(g){no.value=g}async function u(g){if(ea.value)return!1;ea.value=!0;try{const b=await Ki("origen_titlemenu:server:CreateCharacter",{charinfo:g,cid:Ea.value}),j=typeof b=="string"?b:b?.citizenid;return j?(Go.value=j,await le("StartCharacterCreation",{}),!0):!1}finally{ea.value=!1}}async function d(g,{directo:b=!1}={}){Go.value=g;const j=await le("GetSpawns",{citizenid:g}),q=j?.spawns||[];if(b){const w=q.find($=>$.type==="lastplace")||q[0];if(w)return await E(w),!1}return Xo.value=q.filter(w=>w.type!=="lastplace"),j?.skipSpawnSelection&&Xo.value.length?(await E(Xo.value[0]),!1):(await le("StartSpawnCamera",{}),await Wo(),!0)}async function m(g){if(!g||ea.value)return!1;await Vn();const b=await d(g.citizenid,{directo:!0});return!b&&!la.value&&(console.error("[origen_titlemenu] No se ha podido entrar; se vuelve al menu"),await Wo()),b}async function A(g){Gi.value=g,await le("SelectSpawn",{x:parseFloat(g.coordX),y:parseFloat(g.coordY)})}async function E(g){if(!g||ea.value||la.value)return!1;if(await Vn(),no.value){if(!await u(no.value))return await Wo(),!1;no.value=null}ea.value=!0;try{const b=e.value.find($=>$.cid===Ea.value),j=wu(),q=Ki("origen_titlemenu:server:SpawnPlayer",{citizenid:Go.value,type:g.type,id:g.name||g.id,apartmentType:g.apartmentType,firstname:b?.nombre?.split(" ")[0],lastname:b?.nombre?.split(" ").slice(1).join(" ")},2e4,!0),w=await Promise.race([j,q]);return w||console.error("[origen_titlemenu] Ni el servidor ha contestado ni el juego ha avisado del spawn"),w&&(la.value=!0),!!w}finally{ea.value=!1}}return{lista:e,slotsTotales:oo,slotElegido:Ea,citizenidActual:Go,spawns:Xo,spawnElegido:Gi,primeraVez:Xi,ocupado:ea,listoSetup:Wi,fichaPendiente:no,entrado:la,borrador:ja,reiniciarBorrador:Ji,recibirSetup:r,marcarEntrado:a,reiniciar:o,abrirSeleccion:i,cerrarSeleccion:l,mirarSlot:t,ponerRetrato:n,guardarFicha:s,crearPersonaje:u,cargarSpawns:d,entrarConExistente:m,ponerTelon:Vn,quitarTelon:Wo,mirarSpawn:A,confirmarSpawn:E}}const _u={class:"mapa"},Lu={key:0,class:"mapa__sin"},ku="https://cfx-nui-origen_map/html/teselas/styleAtlas/{z}/{x}/{y}.jpg",zu=117.3,Eu=172.8,ju=.02072,qu=Vo({__name:"MapaSpawns",props:{puntos:{type:Array,default:()=>[]},elegido:{type:Object,default:null}},emits:["elegir"],setup(e,{emit:a}){const o=e,n=a,r=se(null),i=se(!0);let l=null,t=[];function s(g){return g.extend({},g.CRS.Simple,{projection:g.Projection.LonLat,scale:b=>Math.pow(2,b),zoom:b=>Math.log(b)/Math.LN2,distance:(b,j)=>Math.hypot(j.lng-b.lng,j.lat-b.lat),transformation:new g.Transformation(ju,zu,-.0205,Eu),infinite:!0})}function u(g,b){return g.divIcon({className:"",iconSize:[22,22],iconAnchor:[11,11],html:`<span class="mapa__pin${b?" is-on":""}"><span class="mapa__pinNucleo"></span></span>`})}function d(){const g=window.L;if(!E||l||!r.value||!r.value.isConnected)return;if(!g){Di().then(q=>{q?(d(),l&&l.invalidateSize()):i.value=!1});return}i.value=!0,l=g.map(r.value,{crs:s(g),minZoom:1.5,maxZoom:5,zoom:2,center:[1700,300],zoomControl:!1,attributionControl:!1,boxZoom:!1,preferCanvas:!0,noWrap:!0,maxBoundsViscosity:1}),g.tileLayer(ku,{minZoom:0,maxZoom:5,noWrap:!0}).addTo(l);const b=l.unproject([0,8592],l.getMaxZoom()),j=l.unproject([8192,0],l.getMaxZoom());l.setMaxBounds(g.latLngBounds(b,j)),m()}function m(){const g=window.L;if(!l||!g)return;t.forEach(j=>l.removeLayer(j)),t=[];const b=[];o.puntos.forEach(j=>{const q=parseFloat(j.coordX),w=parseFloat(j.coordY);if(Number.isNaN(q)||Number.isNaN(w))return;const $=o.elegido===j,N=g.marker([w,q],{icon:u(g,$),zIndexOffset:$?1e3:0}).addTo(l).bindTooltip(j.label||j.name||"Punto",{direction:"top",offset:[0,-12]}).on("click",()=>n("elegir",j));t.push(N),b.push([w,q])}),b.length===1?l.setView(b[0],4):b.length>1&&l.fitBounds(g.latLngBounds(b),{padding:[30,30],maxZoom:4})}ta(()=>o.puntos,()=>Sn(m),{deep:!0}),ta(()=>o.elegido,g=>{if(m(),l&&g){const b=parseFloat(g.coordX),j=parseFloat(g.coordY);!Number.isNaN(b)&&!Number.isNaN(j)&&l.panTo([j,b])}});let A=null,E=!0;return Va(()=>{Sn(()=>{A=setTimeout(()=>{!E||!r.value||!r.value.isConnected||(d(),l&&l.invalidateSize())},120)})}),kn(()=>{if(E=!1,clearTimeout(A),l){try{l.remove()}catch{}l=null}t=[]}),(g,b)=>(M(),_("div",_u,[h("div",{ref_key:"lienzo",ref:r,class:"mapa__lienzo"},null,512),i.value?oe("",!0):(M(),_("p",Lu,"Mapa no disponible"))]))}},[["__scopeId","data-v-45c1c660"]]),Pu={class:"ogn-spawn"},Nu={class:"ogn-spawn__caja"},Iu={key:1,class:"ogn-spawn__vacio"},Ou=["onClick"],Tu={class:"punto__nombre"},$u={class:"punto__tipo"},Ru=["disabled"],Du=Vo({__name:"SelectorSpawn",setup(e){const{spawns:a,spawnElegido:o,ocupado:n,mirarSpawn:r,confirmarSpawn:i}=Qi(),l={apartment:"Tu apartamento",first_apartment:"Nuevo hogar",qb_spawn:"Punto de la ciudad",esx_spawn:"Punto de la ciudad",custom_place:"Punto de la ciudad",spawn:"Punto de la ciudad"};return(t,s)=>(M(),_("div",Pu,[h("section",Nu,[s[1]||(s[1]=h("h2",{class:"ogn-spawn__tit"},"Dónde despiertas",-1)),ge(a).length?(M(),gi(qu,{key:0,puntos:ge(a),elegido:ge(o),onElegir:ge(r)},null,8,["puntos","elegido","onElegir"])):oe("",!0),ge(a).length?oe("",!0):(M(),_("p",Iu," No hay puntos disponibles todavía. ")),(M(!0),_(H,null,be(ge(a),(u,d)=>(M(),_("button",{key:u.id||u.name||d,type:"button",class:ho(["punto",{"is-on":ge(o)===u}]),onClick:m=>ge(r)(u)},[h("span",Tu,V(u.label||u.name||"Punto "+(d+1)),1),h("span",$u,V(l[u.type]||"Punto de la ciudad"),1)],10,Ou))),128)),h("button",{type:"button",class:"ogn-spawn__ok",disabled:!ge(o)||ge(n),onClick:s[0]||(s[0]=u=>ge(i)(ge(o)))},V(ge(n)?"Entrando…":ge(o)?"Despertar aquí":"Elige un punto"),9,Ru)])]))}},[["__scopeId","data-v-dcf7bfd3"]]),Fu={lado:512,alto:.92,centroX:.5,centroY:.5};function Bu(e){return new Promise((a,o)=>{const n=new Image;n.onload=()=>a(n),n.onerror=()=>o(new Error("no se pudo leer la captura")),n.src=e})}function Hu(e){const o=e.getContext("2d",{willReadFrequently:!0}).getImageData(0,0,e.width,e.height).data;let n=0,r=0;for(let i=0;i<o.length;i+=4*16)n+=(o[i]+o[i+1]+o[i+2])/3,r++;return r?n/r:0}const Vu=28;function Uu(e){const o=Math.max(1,Math.round((e.naturalHeight||e.height)*384/(e.naturalWidth||e.width))),n=document.createElement("canvas");n.width=384,n.height=o;const r=n.getContext("2d",{willReadFrequently:!0});r.drawImage(e,0,0,384,o);const i=r.getImageData(0,0,384,o).data,l=(q,w)=>{const $=(w*384+q)*4;return(i[$]+i[$+1]+i[$+2])/3};let t=0,s=0;const u=Math.max(1,Math.round(o*.06)),d=Math.max(1,Math.round(384*.06));for(let q=0;q<u;q++){for(let w=0;w<d;w++)t+=l(w,q),s++;for(let w=384-d;w<384;w++)t+=l(w,q),s++}const m=Math.max((s?t/s:0)+Vu,45),A=(q,w)=>l(q,w)>m;let E=-1;for(let q=0;q<o&&E<0;q++){let w=0;for(let $=0;$<384;$++)A($,q)&&w++;w>=4&&(E=q)}if(E<0)return null;const g=Math.min(o-1,E+Math.round(o*.22));let b=0,j=0;for(let q=E;q<=g;q++)for(let w=0;w<384;w++)A(w,q)&&(b+=w,j++);return j?{cx:b/j/384,arriba:E/o}:null}function Ku(e,a,o){const n={...Fu,...a||{}},r=e.naturalWidth||e.width,i=e.naturalHeight||e.height,l=Math.max(1,Math.min(Math.round(i*n.alto),r,i)),t=o?o.cx*r:r*n.centroX,s=o?o.arriba*i-l*(n.aire!=null?n.aire:.14)+l/2:i*n.centroY,u=Math.max(0,Math.min(Math.round(t-l/2),r-l)),d=Math.max(0,Math.min(Math.round(s-l/2),i-l)),m=document.createElement("canvas");m.width=n.lado,m.height=n.lado;const A=m.getContext("2d");return A.imageSmoothingEnabled=!0,A.imageSmoothingQuality="high",A.drawImage(e,u,d,l,l,0,0,n.lado,n.lado),m}function Gu(e){ga("procesarRetrato",async a=>{if(!(!a||!a.image||!a.citizenid))try{const o=await Bu(a.image),n=Ku(o,a.salida,Uu(o)),r=Hu(n);if(console.log("[origen_titlemenu] Retrato de "+a.citizenid+": brillo "+r.toFixed(1)),r<(a.salida&&a.salida.umbralNegro||20)){console.warn("[origen_titlemenu] Retrato en negro (brillo "+r.toFixed(1)+"), se reintenta"),await le("RetratoListo",{citizenid:a.citizenid,negro:!0});return}await le("RetratoListo",{citizenid:a.citizenid,image:n.toDataURL("image/png")})}catch(o){console.error("[origen_titlemenu] Retrato: "+o.message),await le("RetratoListo",{citizenid:a.citizenid,image:""})}}),ga("retratoEscondeMenu",a=>{document.body.style.visibility=a&&a.valor?"hidden":""}),ga("retratoListo",a=>{a&&a.citizenid&&a.url&&e&&e(a.citizenid,a.url)})}const Xu=location.pathname.includes("/landing/")?"../sounds/":"./sounds/",Wu={hover:"over.wav",click:"click.wav",swipe:"slide.wav",unlock:"unlock.wav",glitch:"glitch.wav",aviso:"aviso.wav"},Ju={hover:.32,click:.4,swipe:.45,unlock:.9,glitch:.35,aviso:.5},Zi=4,Un={},Qo={};function Yi(){if(!Object.keys(Un).length)for(const[e,a]of Object.entries(Wu))Un[e]=Array.from({length:Zi},()=>{const o=new Audio(Xu+a);return o.volume=Ju[e]??.4,o.preload="auto",o}),Qo[e]=0}let et=0;function ba(e){const a=performance.now();if(e==="click"){if(a-et<80)return}else et=a;Yi();const o=Un[e];if(!o)return;const n=o[Qo[e]];Qo[e]=(Qo[e]+1)%Zi;try{n.currentTime=0;const r=n.play();r&&r.catch&&r.catch(()=>{})}catch{}}const Qu=["button","a[href]",'[role="button"]',"[data-snd]",".card",".cell--hold",".cell--action",".punto",".ogn-nav__item",".wordmark",".rules__item"].join(",");function Kn(e){const a=e.target;if(!a||typeof a.closest!="function")return null;const o=a.closest(Qu);return!o||o.getAttribute("data-snd")==="no"||o.disabled||o.getAttribute("aria-disabled")==="true"||o.classList.contains("card--off")?null:o}function Zu(){Yi();let e=null;function a(r){const i=Kn(r);!i||i===e||(e=i,ba("hover"))}function o(r){const i=Kn(r);i&&i===e&&!i.contains(r.relatedTarget)&&(e=null)}function n(r){const i=Kn(r);i&&ba(i.getAttribute("data-snd")||"click")}return document.addEventListener("pointerover",a),document.addEventListener("pointerout",o),document.addEventListener("click",n),()=>{document.removeEventListener("pointerover",a),document.removeEventListener("pointerout",o),document.removeEventListener("click",n)}}const Yu={key:0,class:"stage"},ep={key:0,class:"capa-spawn"},ap="https://origennetwork.com/store-ogn";Il({__name:"App",setup(e){const a=Ti(),o=Qi(),n=o.lista;ga("setup",S=>o.recibirSetup(S)),ga("entrado",()=>o.marcarEntrado());const r=se(-1),i=se(!1),l=se(42),t=se([]);async function s(){const S=await le("PuntosMapa",{});Array.isArray(S)&&S.length&&(t.value=S)}Gu((S,B)=>o.ponerRetrato(S,B)),ga("updateServerInfo",S=>{typeof S.ping=="number"&&(l.value=S.ping)});const u=sa(()=>({art:a.value.art,poster:a.value.poster,portrait:m.value&&m.value.retrato||""})),d=sa(()=>n.value.map(S=>S.estado==="bloqueado"?{id:"s"+S.cid,name:"Bloqueado",line:"Slot bloqueado",zone:"",state:"lock"}:S.estado==="vacio"?{id:"s"+S.cid,name:"Slot libre",line:"Crear personaje",zone:"",state:"free"}:{id:"s"+S.cid,name:S.nombre,line:[S.ocupacion,S.tiempo].filter(Boolean).join(" · "),zone:S.ubicacion&&S.ubicacion!=="—"?S.ubicacion:"Los Santos",state:"ok",foto:S.retrato||""})),m=sa(()=>n.value[r.value]||null),A=sa(()=>{const S=m.value;if(!S||S.estado!=="libre")return{};const B=n.value.filter(va=>va.estado==="libre").length,ie=S.xpFalta||0,Be=S.xpNivel||0,aa=ie>0?Math.max(0,Math.min(100,Math.round(Be/ie*100))):100;return{name:S.nombre,level:S.nivel,xp:ie>0?Be.toLocaleString("es-ES")+" / "+ie.toLocaleString("es-ES")+" XP":"Nivel máximo",xpPct:aa+"%",id:S.citizenid?"#"+String(S.citizenid).slice(-4).toUpperCase():void 0,money:[S.banco,void 0],stats:{personajes:B+" / "+o.slotsTotales.value,tiempo:S.tiempo,trabajo:S.ocupacion,trabajoSub:S.nacionalidad&&S.nacionalidad!=="—"?S.nacionalidad:"",ultima:S.ult,ultimaSub:S.ubicacion&&S.ubicacion!=="—"?S.ubicacion:""},coords:S.coords||null,puntos:t.value,ubicacion:S.ubicacion&&S.ubicacion!=="—"?S.ubicacion:"San Andreas",vitales:{salud:S.salud,comida:S.hambre,bebida:S.sed}}});async function E(S){const B=S&&typeof S.index=="number"?S.index:-1;if(r.value=B,B<0)return;const ie=n.value[B];if(!(!ie||ie.estado==="bloqueado")){if(ba("swipe"),s(),ie.estado==="vacio"){o.reiniciarBorrador(),await o.mirarSlot(ie),j.value===1&&le("SetModel",{model:q[1]});return}o.mirarSlot(ie)}}async function g(){const S=m.value;if(!S||S.estado!=="libre")return;ba("unlock");const B=await o.entrarConExistente(S);i.value=!!B}async function b(S){const B=m.value;if(!B||B.estado!=="vacio")return;const ie={firstname:(S.nombre||"").trim(),lastname:(S.apellidos||"").trim(),birthdate:(S.edad||"").trim(),nationality:(S.nacionalidad||"").trim(),gender:S.genero===1?1:0};if(!ie.firstname||!ie.lastname||S.genero!==0&&S.genero!==1)return;ba("unlock"),o.guardarFicha(ie),await o.ponerTelon();const Be=await o.cargarSpawns(null);i.value=!!Be,Be||await o.quitarTelon()}const j=se(null),q=["mp_m_freemode_01","mp_f_freemode_01"];function w(S){S!==0&&S!==1||(j.value=S,ba("swipe"),le("SetModel",{model:q[S]}))}function $(S){ba("swipe"),String(S).toLowerCase()==="tienda"&&xu(ap)}function N(S){if(S.key==="F2"&&m.value&&m.value.estado==="libre"){S.preventDefault(),le("AjustarCamara");return}S.key==="Escape"&&r.value>=0&&(r.value=-1)}ta(()=>o.entrado.value,S=>{if(S){try{const B=window.parent.document.getElementsByName("origen_loadingasset")[0];B&&B.contentWindow&&B.contentWindow.postMessage({action:"stopMusic"},"*")}catch(B){console.error("[origen_titlemenu] No he podido parar la musica: "+B.message)}try{const B=window.parent.document.getElementById("music-frame");B&&B.contentWindow&&B.contentWindow.postMessage({type:"stopMusic"},"*")}catch{}try{window.player&&window.player.stopVideo&&window.player.stopVideo()}catch{}document.querySelectorAll("iframe").forEach(B=>B.remove()),document.querySelectorAll("audio, video").forEach(B=>{try{B.pause(),B.removeAttribute("src"),B.load()}catch{}}),document.body.style.display="none"}}),ga("logout",()=>{o.reiniciar(),r.value=-1,i.value=!1,document.body.style.display=""});let re;return Va(()=>{s(),window.addEventListener("keydown",N),re=Zu()}),qo(()=>{window.removeEventListener("keydown",N),re&&re()}),(S,B)=>ge(o).entrado.value?oe("",!0):(M(),_("div",Yu,[as(pe(vu,{images:u.value,slots:d.value,ficha:A.value,ping:l.value,onSlot:E,onPlay:g,onCreate:b,onGenero:w,onNav:$},null,8,["images","slots","ficha","ping"]),[[ml,!i.value]]),i.value?(M(),_("div",ep,[pe(Du)])):oe("",!0)]))}}).mount("#app")})();
