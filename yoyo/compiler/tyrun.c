/*
 * tyrun.c — Linux 原生 .ty 运行/编译（yoyo.exe 不可用时的替代）
 *
 * gcc -O2 -o build/tyrun yoyo/compiler/tyrun.c
 * ./build/tyrun build/flow_signal_demo.ty
 * ./build/tyrun -o build/flow_signal_demo build/flow_signal_demo.ty
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>

#define NSTATE 256
#define MAXH 512
#define MAXINS 8192
#define MAXTOK 8

typedef enum {
    OP_SET, OP_LABEL, OP_CALL, OP_COPY, OP_CMP, OP_INC,
    OP_ADDV, OP_SUBV, OP_JMP, OP_JE, OP_JNE, OP_JL, OP_JG,
    OP_JB, OP_JAE, OP_JA, OP_RET
} OpKind;

typedef struct { OpKind k; int a, b; char lbl[64]; } Ins;
typedef struct { char name[64]; Ins ins[MAXINS]; int n; } Handler;

static uint64_t state[NSTATE];
static Handler hs[MAXH];
static int nh;
static int cmpf;

static char *trim(char *s) {
    while (*s && isspace((unsigned char)*s)) s++;
    if (!*s) return s;
    char *e = s + strlen(s) - 1;
    while (e > s && isspace((unsigned char)*e)) *e-- = 0;
    return s;
}

static Handler *hget(const char *name) {
    for (int i = 0; i < nh; i++)
        if (!strcasecmp(hs[i].name, name)) return &hs[i];
    Handler *h = &hs[nh++];
    memset(h, 0, sizeof(*h));
    strncpy(h->name, name, sizeof(h->name) - 1);
    return h;
}

static void hpush(Handler *h, Ins in) {
    if (h && h->n < MAXINS) h->ins[h->n++] = in;
}

static int parse_hex(const char *s, int *out) {
    char *end;
    long v = strtol(s, &end, 16);
    if (end == s) return 0;
    *out = (int)v;
    return 1;
}

static void parse_line(char *line, Handler **cur) {
    char *p = trim(line);
    if (!*p || *p == ';') return;
    char *sc = strchr(p, ';');
    if (sc) *sc = 0, p = trim(p);
    if (!*p) return;

    char *tok[MAXTOK];
    int nt = 0;
    for (char *t = strtok(p, " \t"); t && nt < MAXTOK; t = strtok(NULL, " \t"))
        tok[nt++] = t;
    if (!nt) return;

    int op;
    if (!parse_hex(tok[0], &op)) return;

    if (op == 0x40) {
        *cur = hget(tok[1]);
        return;
    }

    Ins in = {0};
    if (op == 0x30 && nt >= 3) {
        parse_hex(tok[1], &in.a); parse_hex(tok[2], &in.b);
        in.k = OP_SET;
    } else if (op == 0x41 && nt >= 2) {
        in.k = OP_CALL;
        strncpy(in.lbl, tok[1], sizeof(in.lbl) - 1);
    } else if (op == 0x60 && nt >= 3) {
        parse_hex(tok[1], &in.a); parse_hex(tok[2], &in.b);
        in.k = OP_COPY;
    } else if (op == 0x65 && nt >= 3) {
        parse_hex(tok[1], &in.a); parse_hex(tok[2], &in.b);
        in.k = OP_CMP;
    } else if (op == 0x66 && nt >= 2) {
        parse_hex(tok[1], &in.a);
        in.k = OP_INC;
    } else if (op == 0x68 && nt >= 3) {
        parse_hex(tok[1], &in.a); parse_hex(tok[2], &in.b);
        in.k = OP_ADDV;
    } else if (op == 0x69 && nt >= 3) {
        parse_hex(tok[1], &in.a); parse_hex(tok[2], &in.b);
        in.k = OP_SUBV;
    } else if (op == 0x70 && nt >= 2) {
        in.k = OP_JMP; strncpy(in.lbl, tok[1], sizeof(in.lbl) - 1);
    } else if (op == 0x71 && nt >= 2) {
        in.k = OP_JE; strncpy(in.lbl, tok[1], sizeof(in.lbl) - 1);
    } else if (op == 0x72 && nt >= 2) {
        in.k = OP_JNE; strncpy(in.lbl, tok[1], sizeof(in.lbl) - 1);
    } else if (op == 0x82 && nt >= 2) {
        in.k = OP_JL; strncpy(in.lbl, tok[1], sizeof(in.lbl) - 1);
    } else if (op == 0x83 && nt >= 2) {
        in.k = OP_JG; strncpy(in.lbl, tok[1], sizeof(in.lbl) - 1);
    } else if (op == 0x77 && nt >= 2) {
        in.k = OP_JB; strncpy(in.lbl, tok[1], sizeof(in.lbl) - 1);
    } else if (op == 0x78 && nt >= 2) {
        in.k = OP_JAE; strncpy(in.lbl, tok[1], sizeof(in.lbl) - 1);
    } else if (op == 0x7A && nt >= 2) {
        in.k = OP_JA; strncpy(in.lbl, tok[1], sizeof(in.lbl) - 1);
    } else if (op == 0xFF) {
        in.k = OP_RET;
    } else return;

    /* 顶层 30/41 进 init；handler 内 FF 后 *cur 清空 */
    Handler *dst = *cur ? *cur : hget("init");
    hpush(dst, in);
    if (in.k == OP_RET) *cur = NULL;
}

static void parse_file(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) { perror(path); exit(1); }
    char line[512];
    Handler *cur = NULL;
    while (fgets(line, sizeof line, f)) parse_line(line, &cur);
    fclose(f);
}

static int run_at(Handler *h, int ip);

static int jump_cond(Ins *in) {
    switch (in->k) {
    case OP_JE: return cmpf == 0;
    case OP_JNE: return cmpf != 0;
    case OP_JL: return cmpf < 0;
    case OP_JG: return cmpf > 0;
    case OP_JB: return cmpf < 0;
    case OP_JAE: return cmpf >= 0;
    case OP_JA: return cmpf > 0;
    case OP_JMP: return 1;
    default: return 0;
    }
}

static int run_handler(Handler *h) {
    return run_at(h, 0);
}

static int run_at(Handler *h, int ip) {
    if (!h) return 1;
    while (ip < h->n) {
        Ins *in = &h->ins[ip++];
        switch (in->k) {
        case OP_SET: state[in->a] = (uint64_t)in->b; break;
        case OP_COPY: state[in->a] = state[in->b]; break;
        case OP_CMP:
            if (state[in->a] < state[in->b]) cmpf = -1;
            else if (state[in->a] > state[in->b]) cmpf = 1;
            else cmpf = 0;
            break;
        case OP_INC: state[in->a]++; break;
        case OP_ADDV: state[in->a] += state[in->b]; break;
        case OP_SUBV: state[in->a] -= state[in->b]; break;
        case OP_CALL: {
            Handler *c = hget(in->lbl);
            if (run_handler(c)) return 1;
            break;
        }
        case OP_JMP: case OP_JE: case OP_JNE: case OP_JL: case OP_JG:
        case OP_JB: case OP_JAE: case OP_JA:
            if (jump_cond(in)) return run_handler(hget(in->lbl));
            break;
        case OP_RET: return 0;
        default: break;
        }
    }
    return 0;
}

static int emit_elf(const char *outpath) {
    FILE *cf = fopen("/tmp/tywrap.c", "w");
    if (!cf) return 1;
    fprintf(cf, "#include <stdio.h>\n#include <stdint.h>\n");
    fprintf(cf, "int main(void){\n");
    fprintf(cf, "  uint64_t s22=%lluU, s50=%lluU;\n",
            (unsigned long long)state[0x22], (unsigned long long)state[0x32]);
    fprintf(cf, "  printf(\"signal=%%llu (0卖 1持 2买)\\n\", (unsigned long long)s22);\n");
    fprintf(cf, "  printf(\"active_buy=%%llu pct\\n\", (unsigned long long)s50);\n");
    fprintf(cf, "  return 0;\n}\n");
    fclose(cf);
    char cmd[512];
    snprintf(cmd, sizeof cmd, "gcc -O2 -o '%s' /tmp/tywrap.c", outpath);
    return system(cmd);
}

int main(int argc, char **argv) {
    const char *out = NULL, *src = NULL;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-o") && i + 1 < argc) out = argv[++i];
        else src = argv[i];
    }
    if (!src) {
        fprintf(stderr, "usage: tyrun [-o out] program.ty\n");
        return 1;
    }
    parse_file(src);
    Handler *boot = hget("init");
    if (boot->n == 0) boot = hget("main");
    if (boot->n == 0) {
        /* orphan top-level 41 XX / FF in demo files */
        FILE *f = fopen(src, "r");
        char line[512];
        Handler *b = hget("_boot");
        while (fgets(line, sizeof line, f)) {
            char *p = trim(line);
            char *sc = strchr(p, ';'); if (sc) *sc = 0;
            char *tok[MAXTOK]; int nt = 0;
            for (char *t = strtok(p, " \t"); t && nt < MAXTOK; t = strtok(NULL, " \t")) tok[nt++] = t;
            if (!nt) continue;
            int op; if (!parse_hex(tok[0], &op)) continue;
            if (op == 0x41 && nt >= 2) {
                Ins in = {OP_CALL, 0, 0, {0}};
                strncpy(in.lbl, tok[1], sizeof in.lbl - 1);
                hpush(b, in);
            } else if (op == 0xFF) hpush(b, (Ins){OP_RET,0,0,{0}});
        }
        fclose(f);
        if (b->n) boot = b;
    }
    if (run_handler(boot)) return 1;
    if (out) {
        if (emit_elf(out)) return 1;
        printf("OK %s\n", out);
    }
    printf("signal=%llu (0卖 1持 2买)\n", (unsigned long long)state[0x22]);
    printf("active_buy=%llu\n", (unsigned long long)state[0x32]);
    return 0;
}
