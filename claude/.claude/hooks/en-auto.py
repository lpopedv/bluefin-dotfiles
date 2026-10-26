#!/usr/bin/env python3
"""UserPromptSubmit hook: when a prompt is written in English, tell Claude to run the /en skill.

Disable temporarily with:  touch ~/.claude/english/auto-off   (re-enable: rm it)
"""
import json
import re
import sys
from pathlib import Path

BASE = Path.home() / ".claude" / "english"

# Words that are clearly one language or the other (ambiguous ones like a/no/me/do/as/so are left out).
EN = set("""
the is are was were be been being i i'm i've i'd you you're it it's this that these those what how why
which who when where can could would should will won't have has had to of and with for in on at from
about my your our we they he she please want need make fix run use add check create show change remove
update now not don't doesn't didn't can't just all any some there here if then but also again still
know think see look let let's help tell give get got going go try work works working everything
something nothing because before after into out up only more less than very really thanks thank
""".split())
PT = set("""
o os um uma uns umas de da do das dos que não nao é e eu você voce vc vcs pra pro para por com como
isso esse essa isto está esta tá ta estou mas mais meu minha meus minhas seu sua ele ela eles elas
faz fazer faça pode posso quero queria preciso também tambem já ja aqui aí ai na nas nos em se
quando onde porque porquê qual quais sim tem ter ser vai vamos agora então entao só roda rodar
ver veja olha olhe erro mostra mostre favor obrigado valeu tudo nada algum alguma ainda depois antes sobre até
""".split())
ACCENTS = re.compile(r"[ãõçáéíóúâêôà]", re.I)


def prose(text):
    text = re.sub(r"<pasted_content[^>]*>.*?</pasted_content[^>]*>", " ", text, flags=re.S)
    text = re.sub(r"```.*?```", " ", text, flags=re.S)
    text = re.sub(r"`[^`]*`", " ", text)
    text = re.sub(r"https?://\S+|\S*/\S+|\S+\.\w{1,4}\b", " ", text)
    lines = []
    for line in text.splitlines():
        letters = sum(c.isalpha() or c.isspace() for c in line)
        if line.strip() and letters / len(line) > 0.8:
            lines.append(line)
    return " ".join(lines)


def is_english(prompt):
    stripped = prompt.lstrip()
    if not stripped or stripped[0] in "/!#":
        return False
    text = prose(prompt)
    words = re.findall(r"[a-zA-ZÀ-ÿ']+", text.lower())
    if len(words) < 3:
        return False
    en = sum(w in EN for w in words)
    pt = sum(w in PT for w in words) + len(ACCENTS.findall(text))
    return en >= 2 and pt < 2 and en > 2 * pt


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return
    if (BASE / "auto-off").exists():
        return
    if not is_english(data.get("prompt", "")):
        return

    context = (
        "ENGLISH PRACTICE: the user wrote this message in English. Their standing setup is that every "
        "English message is practice. Before doing anything else, invoke the Skill tool with "
        "skill=\"en\" and args = the user's message verbatim, then follow that skill (English check, "
        "log, then do the real task). Exception: if an /en-interview mock interview is in progress in "
        "this conversation, don't invoke it, because the interview flow already corrects and logs the answer."
    )

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": context,
        }
    }))


if __name__ == "__main__":
    main()
