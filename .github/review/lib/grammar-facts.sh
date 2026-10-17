#!/usr/bin/env bash
# Факты о грамматике для промпта: стартовое правило целиком.
#
# ЗАЧЕМ. Модель по коду анализатора придумывала программы, которые
# грамматика не разбирает: «тело функции видит глобальную, объявленную
# ниже» при program: globalVarDecl* funcDecl* mainBlock (rumyantseva#10),
# «повтор функции после кода — синтаксическая ошибка» при funcDecl* statement*
# (romanov#9). Порядок конструкций задаёт стартовое правило, и его дешевле
# показать модели готовым, чем надеяться, что она откроет .g4.
#
# Использование: source grammar-facts.sh; print_grammar_facts <work_dir>
# Печатает отчёт, всегда возвращает 0.

# Стартовое правило парсера и его тело до «;» (комментарии и действия {…}
# убраны, пробелы схлопнуты). Печатает «имя: тело». Стартовым считаем
# первое правило с EOF: первое по тексту часто вспомогательное (nl: NEWLINE+,
# germanenko#8); без EOF — первое правило парсера.
_gf_start_rule() {
  perl -0777 -ne '
    # Один проход: литерал в кавычках прячем (в нём «//», «;», «{» — не
    # синтаксис грамматики), комментарий удаляем.
    my @lit;
    s{(\x27(?:[^\x27\\\n]|\\.)*\x27)|/\*.*?\*/|//[^\n]*}{defined $1 ? do { push @lit, $1; "\x00" . $#lit . "\x00" } : ""}gse;
    1 while s/\{[^{}]*\}//g;
    s/^\s*(lexer|parser)?\s*grammar\s+\w+\s*;//m;
    s/^\s*(options|tokens|channels)\s*;//mg;
    s/^\s*@\w+(::\w+)?//mg;
    s/^\s*(import)\s+[^;]*;//mg;
    my (@order, %body);
    while (/^[ \t]*(?:fragment\s+)?([A-Za-z_]\w*)\s*(?:returns\s*\[[^\]]*\]\s*)?(?:locals\s*\[[^\]]*\]\s*)?:(.*?);/msg) {
      my ($n, $b) = ($1, $2);
      next unless $n =~ /^[a-z]/;
      $b =~ s/\s+/ /g; $b =~ s/^ | $//g;
      $b =~ s{\x00(\d+)\x00}{$lit[$1]}ge;
      push @order, $n unless exists $body{$n};
      $body{$n} = $b;
    }
    exit unless @order;
    my ($start) = grep { $body{$_} =~ /\bEOF\b/ } @order;
    $start //= $order[0];
    print "$start: $body{$start}\n";
    # Правила, на которые стартовое ссылается напрямую, — если короткие:
    # «program: topLevelItem* EOF» без topLevelItem порядка не показывает.
    my (%seen, $k);
    for my $r ($body{$start} =~ /\b([a-z]\w*)\b/g) {
      next if $seen{$r}++ || $r eq $start || !exists $body{$r} || length($body{$r}) > 200;
      print "$r: $body{$r}\n";
      last if ++$k >= 4;
    }' "$1" 2>/dev/null
}

print_grammar_facts() {
  local work="${1:?work_dir}" g kind rule shown=0
  work="$(cd "${work}" && pwd)"
  while IFS= read -r g; do
    [ -n "${g}" ] || continue
    kind="$(grep -vE '^\s*(//|\*|/\*)' "${g}" | grep -m1 -oE '^\s*(lexer\s+|parser\s+)?grammar' | awk '{print $1}')"
    [ "${kind}" = "lexer" ] && continue
    rule="$(_gf_start_rule "${g}")"
    [ -n "${rule}" ] || continue
    [ "${shown}" -eq 0 ] && echo "Стартовое правило задаёт порядок конструкций программы. Пример для замечания должен разбираться этим правилом; программа, которую оно не допускает, даёт синтаксическую ошибку, а не семантическую."
    shown=$((shown + 1))
    echo "  ${g#"${work}"/}:"
    printf '%s\n' "${rule}" | cut -c1-400 | sed 's/^/    /'
  done < <(find "${work}" -name '*.g4' -not -path '*/.git/*' -not -path '*/.deps/*' \
             -not -path '*/target/*' -not -path '*/build/*' -not -path '*/node_modules/*' \
             -not -path '*/.antlr/*' -not -path '*/.venv/*' 2>/dev/null | sort | head -n 5)
  [ "${shown}" -eq 0 ] && echo "Грамматика .g4 не найдена или в ней нет правил парсера — стартовое правило не определено."
  return 0
}
