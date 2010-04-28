#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Perl 5.6.1 ? */
#ifndef utf8n_to_uvuni
#define utf8n_to_uvuni  utf8_to_uv
#endif /* utf8n_to_uvuni */

/* if utf8n_to_uvuni() sets retlen to 0 (?) */
#define ErrRetlenIsZero "panic (Unicode::Collate): zero-length character"

static const UV max_div_16 = UV_MAX / 16;

/* Supported Levels */
#define MinLevel	(1)
#define MaxLevel	(4)

/* Shifted weight at 4th level */
#define Shift4Wt	(0xFFFF)

#define VCE_Length	(9)

#define Hangul_SBase	(0xAC00)
#define Hangul_SIni	(0xAC00)
#define Hangul_SFin	(0xD7A3)
#define Hangul_NCount	(588)
#define Hangul_TCount	(28)
#define Hangul_LBase	(0x1100)
#define Hangul_LIni	(0x1100)
#define Hangul_LFin	(0x1159)
#define Hangul_LFill	(0x115F)
#define Hangul_VBase	(0x1161)
#define Hangul_VIni	(0x1160)
#define Hangul_VFin	(0x11A2)
#define Hangul_TBase	(0x11A7)
#define Hangul_TIni	(0x11A8)
#define Hangul_TFin	(0x11F9)

#define CJK_UidIni	(0x4E00)
#define CJK_UidFin	(0x9FA5)
#define CJK_UidF41	(0x9FBB)
#define CJK_ExtAIni	(0x3400)
#define CJK_ExtAFin	(0x4DB5)
#define CJK_ExtBIni	(0x20000)
#define CJK_ExtBFin	(0x2A6D6)

MODULE = Unicode::Collate	PACKAGE = Unicode::Collate

PROTOTYPES: DISABLE

void
_getHexArray (src)
    SV* src
  PREINIT:
    char *s, *e;
    STRLEN byte;
    UV value;
    bool overflowed = FALSE;
    const char *hexdigit;
  PPCODE:
    s = SvPV(src,byte);
    for (e = s + byte; s < e;) {
	hexdigit = strchr((char *) PL_hexdigit, *s++);
        if (! hexdigit)
	    continue;
	value = (hexdigit - PL_hexdigit) & 0xF;
	while (*s) {
	    hexdigit = strchr((char *) PL_hexdigit, *s++);
	    if (! hexdigit)
		break;
	    if (overflowed)
		continue;
	    if (value > max_div_16) {
		overflowed = TRUE;
		continue;
	    }
	    value = (value << 4) | ((hexdigit - PL_hexdigit) & 0xF);
	}
	XPUSHs(sv_2mortal(newSVuv(overflowed ? UV_MAX : value)));
    }


SV*
_isIllegal (sv)
    SV* sv
  PREINIT:
    UV uv;
  CODE:
    if (!sv || !SvIOK(sv))
	XSRETURN_YES;
    uv = SvUVX(sv);
    RETVAL = boolSV(
	   0x10FFFF < uv		   /* out of range */
	|| ((uv & 0xFFFE) == 0xFFFE)       /* ??FFF[EF] (cf. utf8.c) */
	|| (0xD800 <= uv && uv <= 0xDFFF)  /* unpaired surrogates */
	|| (0xFDD0 <= uv && uv <= 0xFDEF)  /* other non-characters */
    );
OUTPUT:
    RETVAL


void
_decompHangul (code)
    UV code
  PREINIT:
    UV sindex, lindex, vindex, tindex;
  PPCODE:
    /* code *must* be in Hangul syllable.
     * Check it before you enter here. */
    sindex =  code - Hangul_SBase;
    lindex =  sindex / Hangul_NCount;
    vindex = (sindex % Hangul_NCount) / Hangul_TCount;
    tindex =  sindex % Hangul_TCount;

    XPUSHs(sv_2mortal(newSVuv(lindex + Hangul_LBase)));
    XPUSHs(sv_2mortal(newSVuv(vindex + Hangul_VBase)));
    if (tindex)
	XPUSHs(sv_2mortal(newSVuv(tindex + Hangul_TBase)));


SV*
getHST (code)
    UV code
  PREINIT:
    char * hangtype;
    STRLEN typelen;
  CODE:
    if (Hangul_LIni <= code && code <= Hangul_LFin || code == Hangul_LFill) {
	hangtype = "L"; typelen = 1;
    }
    else if (Hangul_VIni <= code && code <= Hangul_VFin) {
	hangtype = "V"; typelen = 1;
    }
    else if (Hangul_TIni <= code && code <= Hangul_TFin) {
	hangtype = "T"; typelen = 1;
    }
    else if (Hangul_SIni <= code && code <= Hangul_SFin) {
	if ((code - Hangul_SBase) % Hangul_TCount) {
	    hangtype = "LVT"; typelen = 3;
	} else {
	    hangtype = "LV"; typelen = 2;
	}
    }
    else {
	hangtype = ""; typelen = 0;
    }
    RETVAL = newSVpvn(hangtype, typelen);
OUTPUT:
    RETVAL


void
_derivCE_9 (code)
    UV code
  ALIAS:
    _derivCE_14 = 1
  PREINIT:
    UV base, aaaa, bbbb;
    U8 a[VCE_Length + 1] = "\x00\xFF\xFF\x00\x20\x00\x02\xFF\xFF";
    U8 b[VCE_Length + 1] = "\x00\xFF\xFF\x00\x00\x00\x00\xFF\xFF";
  PPCODE:
    base = (CJK_UidIni <= code && (ix ? (code <= CJK_UidF41)
				      : (code <= CJK_UidFin)))
	    ? 0xFB40 : /* CJK */
	   (CJK_ExtAIni <= code && code <= CJK_ExtAFin ||
	    CJK_ExtBIni <= code && code <= CJK_ExtBFin)
	    ? 0xFB80   /* CJK ext. */
	    : 0xFBC0;  /* others */
    aaaa =  base + (code >> 15);
    bbbb = (code & 0x7FFF) | 0x8000;
    a[1] = (U8)(aaaa >> 8);
    a[2] = (U8)(aaaa & 0xFF);
    b[1] = (U8)(bbbb >> 8);
    b[2] = (U8)(bbbb & 0xFF);
    a[7] = b[7] = (U8)(code >> 8);
    a[8] = b[8] = (U8)(code & 0xFF);
    XPUSHs(sv_2mortal(newSVpvn((char *) a, VCE_Length)));
    XPUSHs(sv_2mortal(newSVpvn((char *) b, VCE_Length)));


void
_derivCE_8 (code)
    UV code
  PREINIT:
    UV aaaa, bbbb;
    U8 a[VCE_Length + 1] = "\x00\xFF\xFF\x00\x02\x00\x01\xFF\xFF";
    U8 b[VCE_Length + 1] = "\x00\xFF\xFF\x00\x00\x00\x00\xFF\xFF";
  PPCODE:
    aaaa =  0xFF80 + (code >> 15);
    bbbb = (code & 0x7FFF) | 0x8000;
    a[1] = (U8)(aaaa >> 8);
    a[2] = (U8)(aaaa & 0xFF);
    b[1] = (U8)(bbbb >> 8);
    b[2] = (U8)(bbbb & 0xFF);
    a[7] = b[7] = (U8)(code >> 8);
    a[8] = b[8] = (U8)(code & 0xFF);
    XPUSHs(sv_2mortal(newSVpvn((char *) a, VCE_Length)));
    XPUSHs(sv_2mortal(newSVpvn((char *) b, VCE_Length)));


void
_uideoCE_8 (code)
    UV code
  PREINIT:
    U8 uice[VCE_Length + 1] = "\x00\xFF\xFF\x00\x20\x00\x02\xFF\xFF";
  PPCODE:
    uice[1] = uice[7] = (U8)(code >> 8);
    uice[2] = uice[8] = (U8)(code & 0xFF);
    XPUSHs(sv_2mortal(newSVpvn((char *) uice, VCE_Length)));


SV*
_isUIdeo (code, uca_vers)
    UV code;
    IV uca_vers;
  CODE:
    RETVAL = boolSV(
	(CJK_UidIni <= code &&
	    (uca_vers >= 14 ? (code <= CJK_UidF41) : (code <= CJK_UidFin)))
		||
	(CJK_ExtAIni <= code && code <= CJK_ExtAFin)
		||
	(CJK_ExtBIni <= code && code <= CJK_ExtBFin)
    );
OUTPUT:
    RETVAL


SV*
mk_SortKey (self, buf)
    SV* self;
    SV* buf;
  PREINIT:
    SV *dst, **svp;
    STRLEN dlen, vlen;
    U8 *d, *p, *e, *v, *s[MaxLevel], *eachlevel[MaxLevel];
    AV *bufAV;
    HV *selfHV;
    UV back_flag;
    I32 i, buf_len;
    IV  lv, level, uca_vers;
    bool upper_lower, kata_hira, v2i, last_is_var;
  CODE:
    if (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV)
	selfHV = (HV*)SvRV(self);
    else
	croak("$self is not a HASHREF.");

    svp = hv_fetch(selfHV, "level", 5, FALSE);
    level = svp ? SvIV(*svp) : MaxLevel;

    if (SvROK(buf) && SvTYPE(SvRV(buf)) == SVt_PVAV)
	bufAV = (AV*)SvRV(buf);
    else
	croak("XSUB, not an ARRAYREF.");

    buf_len = av_len(bufAV);

    if (buf_len < 0) { /* empty: -1 */
	dlen = 2 * (MaxLevel - 1);
	dst = newSV(dlen);
	(void)SvPOK_only(dst);
	d = SvPVX(dst);
	while (dlen--)
	    *d++ = '\0';
    }
    else {
	for (lv = 0; lv < level; lv++) {
	    New(0, eachlevel[lv], 2 * (1 + buf_len) + 1, U8);
	    s[lv] = eachlevel[lv];
	}

	svp = hv_fetch(selfHV, "upper_before_lower", 18, FALSE);
	upper_lower = svp ? SvTRUE(*svp) : FALSE;
	svp = hv_fetch(selfHV, "katakana_before_hiragana", 24, FALSE);
	kata_hira = svp ? SvTRUE(*svp) : FALSE;
	svp = hv_fetch(selfHV, "UCA_Version", 11, FALSE);
	uca_vers = SvIV(*svp);
	svp = hv_fetch(selfHV, "variable", 8, FALSE);
	v2i = uca_vers >= 9 && svp /* (vers >= 9) and not (non-ignorable) */
	    ? !(SvCUR(*svp) == 13 && memEQ(SvPVX(*svp), "non-ignorable", 13))
	    : FALSE;

	last_is_var = FALSE;
	for (i = 0; i <= buf_len; i++) {
	    svp = av_fetch(bufAV, i, FALSE);

	    if (svp && SvPOK(*svp))
		v = SvPV(*svp, vlen);
	    else
		croak("not a vwt.");

	    if (vlen < VCE_Length) /* ignore short VCE (unexpected) */
		continue;

	    /* "Ignorable (L1, L2) after Variable" since track. v. 9 */
	    if (v2i) {
		if (*v)
		    last_is_var = TRUE;
		else if (v[1] || v[2]) /* non zero primary weight */
		    last_is_var = FALSE;
		else if (last_is_var) /* zero primary weight; skipped */
		    continue;
	    }

	    if (v[5] == 0) { /* tert wt < 256 */
		if (upper_lower) {
		    if (0x8 <= v[6] && v[6] <= 0xC) /* lower */
			v[6] -= 6;
		    else if (0x2 <= v[6] && v[6] <= 0x6) /* upper */
			v[6] += 6;
		    else if (v[6] == 0x1C) /* square upper */
			v[6]++;
		    else if (v[6] == 0x1D) /* square lower */
			v[6]--;
		}
		if (kata_hira) {
		    if (0x0F <= v[6] && v[6] <= 0x13) /* katakana */
			v[6] -= 2;
		    else if (0xD <= v[6] && v[6] <= 0xE) /* hiragana */
			v[6] += 5;
		}
	    }

	    for (lv = 0; lv < level; lv++) {
		if (v[2 * lv + 1] || v[2 * lv + 2]) {
		    *s[lv]++ = v[2 * lv + 1];
		    *s[lv]++ = v[2 * lv + 2];
		}
	    }
	}

	dlen = 2 * (MaxLevel - 1);
	for (lv = 0; lv < level; lv++)
	    dlen += s[lv] - eachlevel[lv];

	dst = newSV(dlen);
	(void)SvPOK_only(dst);
	d = SvPVX(dst);

	svp = hv_fetch(selfHV, "backwardsFlag", 13, FALSE);
	back_flag = svp ? SvUV(*svp) : (UV)0;

	for (lv = 0; lv < level; lv++) {
	    if (back_flag & (1 << (lv + 1))) {
		p = s[lv];
		e = eachlevel[lv];
		for ( ; e < p; p -= 2) {
		    *d++ = p[-2];
		    *d++ = p[-1];
		}
	    }
	    else {
		p = eachlevel[lv];
		e = s[lv];
		while (p < e)
		    *d++ = *p++;
	    }
	    if (lv + 1 < MaxLevel) { /* lv + 1 == real level */
		*d++ = '\0';
		*d++ = '\0';
	    }
	}

	for (lv = level; lv < MaxLevel; lv++) {
	    if (lv + 1 < MaxLevel) { /* lv + 1 == real level */
		*d++ = '\0';
		*d++ = '\0';
	    }
	}

	for (lv = 0; lv < level; lv++) {
	    Safefree(eachlevel[lv]);
	}
    }
    *d = '\0';
    SvCUR_set(dst, d - (U8*)SvPVX(dst));
    RETVAL = dst;
OUTPUT:
    RETVAL


SV*
_varCE (vbl, vce)
    SV* vbl
    SV* vce
  PREINIT:
    SV *dst;
    U8 *a, *v, *d;
    STRLEN alen, vlen;
  CODE:
    a = (U8*)SvPV(vbl, alen);
    v = (U8*)SvPV(vce, vlen);

    dst = newSV(vlen);
    d = (U8*)SvPVX(dst);
    (void)SvPOK_only(dst);
    Copy(v, d, vlen, U8);
    SvCUR_set(dst, vlen);
    d[vlen] = '\0';

    /* variable: checked only the first char and the length,
       trusting checkCollator() and %VariableOK in Perl ... */

    if (vlen < VCE_Length /* ignore short VCE (unexpected) */
	||
	*a == 'n') /* 'non-ignorable' */
	1;
    else if (*v) {
	if (*a == 's') { /* shifted or shift-trimmed */
	    d[7] = d[1]; /* wt level 1 to 4 */
	    d[8] = d[2];
	}
	d[1] = d[2] = d[3] = d[4] = d[5] = d[6] = '\0';
    }
    else if (*a == 'b') /* blanked */
	1;
    else if (*a == 's') { /* shifted or shift-trimmed */
	if (alen == 7 && (d[1] + d[2] + d[3] + d[4] + d[5] + d[6])) {
	    d[7] = (U8)(Shift4Wt >> 8);
	    d[8] = (U8)(Shift4Wt & 0xFF);
	}
	else {
	    d[7] = d[8] = 0;
	}
    }
    else
	croak("unknown variable value '%s'", a);
    RETVAL = dst;
OUTPUT:
    RETVAL



SV*
visualizeSortKey (self, key)
    SV * self
    SV * key
  PREINIT:
    HV *selfHV;
    SV **svp, *dst;
    U8 *s, *e, *d;
    STRLEN klen, dlen;
    UV uv;
    IV uca_vers;
    static char *upperhex = "0123456789ABCDEF";
  CODE:
    if (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV)
	selfHV = (HV*)SvRV(self);
    else
	croak("$self is not a HASHREF.");

    svp = hv_fetch(selfHV, "UCA_Version", 11, FALSE);
    if (!svp)
	croak("Panic: no $self->{UCA_Version} in visualizeSortKey");
    uca_vers = SvIV(*svp);

    s = (U8*)SvPV(key, klen);

   /* slightly *longer* than the need, but I'm afraid of miscounting;
      exactly: (klen / 2) * 5 + MaxLevel * 2 - 1 (excluding '\0')
         = (klen / 2) * 5 - 1  # FFFF (16bit) and ' ' between 16bit units
         + (MaxLevel - 1) * 2  # ' ' and '|' for level boundaries
         + 2                   # '[' and ']'
   */
    dlen = (klen / 2) * 5 + MaxLevel * 2 + 2;
    dst = newSV(dlen);
    (void)SvPOK_only(dst);
    d = (U8*)SvPVX(dst);

    *d++ = '[';
    for (e = s + klen; s < e; s += 2) {
	uv = (U16)(*s << 8 | s[1]);
	if (uv) {
	    if ((d[-1] != '[') && ((9 <= uca_vers) || (d[-1] != '|')))
		*d++ = ' ';
	    *d++ = upperhex[ (s[0] >> 4) & 0xF ];
	    *d++ = upperhex[  s[0]       & 0xF ];
	    *d++ = upperhex[ (s[1] >> 4) & 0xF ];
	    *d++ = upperhex[  s[1]       & 0xF ];
	}
	else {
	    if ((9 <= uca_vers) && (d[-1] != '['))
		*d++ = ' ';
	    *d++ = '|';
	}
    }
    *d++ = ']';
    *d   = '\0';
    SvCUR_set(dst, d - (U8*)SvPVX(dst));
    RETVAL = dst;
OUTPUT:
    RETVAL



void
unpack_U (src)
    SV* src
  PREINIT:
    STRLEN srclen, retlen;
    U8 *s, *p, *e;
    UV uv;
  PPCODE:
    s = (U8*)SvPV(src,srclen);
    if (!SvUTF8(src)) {
	SV* tmpsv = sv_mortalcopy(src);
	if (!SvPOK(tmpsv))
	    (void)sv_pvn_force(tmpsv,&srclen);
	sv_utf8_upgrade(tmpsv);
	s = (U8*)SvPV(tmpsv,srclen);
    }
    e = s + srclen;

    for (p = s; p < e; p += retlen) {
	uv = utf8n_to_uvuni(p, e - p, &retlen, UTF8_ALLOW_ANY);
	if (!retlen)
	    croak(ErrRetlenIsZero);
	XPUSHs(sv_2mortal(newSVuv(uv)));
    }

