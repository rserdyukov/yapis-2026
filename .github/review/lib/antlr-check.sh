#!/usr/bin/env bash
# Фактическая проверка грамматики ANTLR студента: сборка .g4 и прогон
# примеров через сгенерированный парсер — то же, что делает lab.antlr.org,
# только без картинки дерева разбора.
#
# ЗАЧЕМ. До этого check.sh для ЛР2 лишь считал строки и regex-правила в .g4.
# Модель при этом писала «грамматика полностью покрывает функционал», хотя
# грамматика не разбирала ни один из собственных примеров студента (реальный
# случай: yapis-2026-321702-rublevskaya#2 — все три примера падали на первой
# же строке). Сборка и прогон занимают ~2 с и дают модели факты вместо догадок.
#
# КАК РАБОТАЕТ
#   1. Находит все *.g4 (кроме каталогов сборки). Комбинированные грамматики
#      (`grammar X;`) собираются по одной; пара `lexer grammar A;` +
#      `parser grammar B;` из одного каталога — вместе. Имена A и B могут
#      быть любыми: ANTLR этого не требует.
#   2. Выбирает таргет и генерирует код во временный каталог. По умолчанию
#      Java: рантайм есть в образе, а сама грамматика от таргета не зависит.
#      Если в .g4 есть код под конкретный язык (@header/@members,
#      options { language = ... }) или options { superClass = X; }, грамматика
#      собирается в таргете студента:
#        - C# — `using ...;`, IToken и т.п. в @members или superClass из
#          X.cs / пакета Dentlr (yapis-2026-321702-burak#6: INDENT/DEDENT
#          в @members на C#, раньше прогон пропускался);
#        - Python — import/def/self. в @members или superClass из X.py;
#        - Java — superClass из X.java рядом с грамматикой
#          (yapis-2026-321702-cheretun#6: RelangLexerBase.java лежал в
#          работе, а прогон пропускался из-за одного слова superClass).
#      Базовый класс X ищется в работе по имени файла и компилируется вместе
#      со сгенерированным кодом. Другие языки (JavaScript, Go, ...), базовый
#      класс, которого нет в работе, и отсутствие рантайма в окружении —
#      честный пропуск с пометкой «ПРОПУЩЕН»: это ограничение проверки, а не
#      ошибка студента.
#   3. Компилирует (javac / dotnet build / импорт модулей Python), стартовое
#      правило — ПЕРВОЕ правило парсера в файле (так же поступает
#      lab.antlr.org, когда правило не указано).
#   4. Прогоняет каждый пример из examples/ через собственный драйвер
#      (YapisParseDriver ниже). Раньше использовался org.antlr.v4.gui.TestRig,
#      но он принимает одно базовое имя X и ищет классы XLexer/XParser —
#      пара lang_lexer + lang_parser для него «не согласована», хотя для
#      ANTLR совершенно законна (yapis-2026-321701-perminova#7: модель
#      выдала это студенту как существенное замечание). Драйвер получает
#      имена классов лексера и парсера явно; для C# и Python — такие же
#      драйверы на этих языках. Корректные примеры (без префикса error-)
#      должны разбираться без сообщений «line N:M ...»; error-примеры
#      (если есть) — с ними.
#
# Результат печатается в stdout и попадает в промпт как ДАННЫЕ.
#
# Использование:
#   run_antlr_checks <work_dir> [timeout_seconds] [max_examples]
#
# Возвращает 0, если все грамматики собрались и все корректные примеры
# разобрались; 1 — иначе. Отсутствие Java/ANTLR в окружении — не вина
# студента: печатается предупреждение, возвращается 0.
#
# Переменные окружения:
#   ANTLR_JAR         путь к antlr-4.x-complete.jar (в образе задан
#                     Dockerfile; локально ищется в типовых местах).
#   ANTLR_NUGET_FEED  каталог с .nupkg (Antlr4.Runtime.Standard, Dentlr) для
#                     сборки C#-таргета без сети. В образе задан Dockerfile;
#                     если не задан — dotnet берёт пакеты из своих источников
#                     по умолчанию (локально у студента есть сеть).

ANTLR_CHECK_MAX_EXAMPLES_DEFAULT=6
ANTLR_CHECK_TIMEOUT_DEFAULT=60
# Сколько строк вывода парсера показывать на один пример.
ANTLR_CHECK_MAX_OUTPUT_LINES=8

# --- Поиск инструментов ----------------------------------------------------

_antlr_find_jar() {
  if [ -n "${ANTLR_JAR:-}" ] && [ -f "${ANTLR_JAR}" ]; then
    echo "${ANTLR_JAR}"; return 0
  fi
  local c
  for c in /opt/antlr/antlr-*-complete.jar \
           /usr/local/lib/antlr-*-complete.jar \
           /opt/homebrew/Cellar/antlr/*/antlr-*-complete.jar \
           /usr/share/java/antlr4-*complete.jar \
           "${HOME}"/.m2/repository/org/antlr/antlr4/*/antlr4-*-complete.jar; do
    if [ -f "${c}" ]; then echo "${c}"; return 0; fi
  done
  return 1
}

# --- Разбор заголовка грамматики -------------------------------------------

# Печатает тип грамматики: combined | lexer | parser | unknown.
_antlr_grammar_kind() {
  local f="$1" head
  head="$(grep -vE '^\s*(//|\*|/\*)' "${f}" | grep -m1 -E '^\s*(lexer\s+grammar|parser\s+grammar|grammar)\s+[A-Za-z_][A-Za-z0-9_]*\s*;' || true)"
  case "${head}" in
    *"lexer grammar"*)  echo lexer ;;
    *"parser grammar"*) echo parser ;;
    *grammar*)          echo combined ;;
    *)                  echo unknown ;;
  esac
}

# Имя грамматики из заголовка.
_antlr_grammar_name() {
  grep -vE '^\s*(//|\*|/\*)' "$1" \
    | grep -m1 -oE '(lexer\s+|parser\s+)?grammar\s+[A-Za-z_][A-Za-z0-9_]*' \
    | awk '{ print $NF }'
}

# Первое правило парсера: строка, начинающаяся со строчной буквы и
# продолжающаяся `:` (возможно, через перевод строки). Комментарии и
# `fragment`/лексерные правила (с заглавной) не подходят.
_antlr_first_parser_rule() {
  local f="$1"
  # Убираем блочные и строчные комментарии (perl: BSD sed на macOS не знает
  # \+ и не работает с многострочными шаблонами), затем ищем первое
  # `<начало строки>имя<пробелы/переводы>:`. Строчные буквы в начале —
  # признак правила парсера (лексерные — с заглавной); `options`, `import`,
  # `tokens`, `channels`, `mode` и `fragment` исключаем явно.
  perl -0777 -pe 's{/\*.*?\*/}{}gs; s{//[^\n]*}{}g' "${f}" \
    | grep -oE '^[[:space:]]*[a-z][A-Za-z0-9_]*[[:space:]]*(:|$)' \
    | grep -oE '[a-z][A-Za-z0-9_]*' \
    | grep -vE '^(options|import|tokens|channels|mode|fragment|grammar|lexer|parser|returns|locals|throws|catch|finally)$' \
    | head -n 1
}

# Базовый класс из options { superClass = X; }, если задан. Печатает X.
# Такой класс живёт вне .g4 (код студента или библиотека вроде Dentlr для
# C#): его исходник ищет _antlr_find_super_source, по его языку выбирается
# таргет.
_antlr_super_class() {
  local sc
  sc="$(perl -0777 -ne 's{/\*.*?\*/}{}gs; s{//[^\n]*}{}g; print "$1\n" if /\bsuperClass\s*=\s*([A-Za-z_][\w.]*)/' "$1")"
  [ -n "${sc}" ] || return 1
  echo "${sc}"
}

# Имя словаря токенов из options { tokenVocab = X; } — по нему парсер
# связывается со своим лексером, если их в каталоге несколько.
_antlr_token_vocab() {
  perl -0777 -ne 's{/\*.*?\*/}{}gs; s{//[^\n]*}{}g; print "$1\n" if /\btokenVocab\s*=\s*([A-Za-z_]\w*)/' "$1"
}

# --- Определение таргета ----------------------------------------------------

# Каталоги, которые при поиске файлов работы не смотрим.
_ANTLR_FIND_EXCLUDES=(-not -path '*/target/*' -not -path '*/build/*' -not -path '*/.venv/*'
  -not -path '*/node_modules/*' -not -path '*/.antlr/*' -not -path '*/.git/*'
  -not -path '*/bin/*' -not -path '*/obj/*' -not -path '*/.deps/*')

# Явный таргет из options { language = X; } первого файла, где он задан.
_antlr_language_option() {
  perl -0777 -ne 's{/\*.*?\*/}{}gs; s{//[^\n]*}{}g; if (/\blanguage\s*=\s*([A-Za-z_]\w*)/) { print "$1\n"; exit }' "$@" | head -n 1
}

# Тело блоков @header/@members/@lexer::members/... всех файлов: по нему
# угадывается язык встроенного кода. Действия внутри правил не смотрим —
# если они на чужом языке, это покажет компиляция.
_antlr_action_text() {
  perl -0777 -ne '
    while (/@(?:lexer::|parser::)?(?:header|members|init|after)\s*\{/g) {
      my ($start, $depth, $i) = (pos, 1, pos);
      while ($i < length && $depth > 0) {
        my $c = substr($_, $i, 1);
        $depth++ if $c eq "{";
        $depth-- if $c eq "}";
        $i++;
      }
      print substr($_, $start, $i - $start - 1), "\n";
      pos = $i;
    }' "$@"
}

# Язык кода в блоках действий: csharp | python | javascript | java (по
# умолчанию: и пустые блоки, и Java-код). Признаки подобраны так, чтобы не
# пересекаться с Java: в Java нет `using X;`, IToken, readonly, override как
# ключевого слова, self. и import без `;`.
_antlr_action_language() {
  local text
  text="$(_antlr_action_text "$@")"
  if printf '%s\n' "${text}" | grep -qE '^\s*using\s+[A-Za-z][A-Za-z0-9_.]*\s*;|\bIToken\b|\breadonly\b|\bpublic\s+override\b|\bbase\.NextToken\b|\bConsole\.Write'; then
    echo csharp
  elif printf '%s\n' "${text}" | grep -qE '^\s*import\s+[A-Za-z_][A-Za-z0-9_.]*(\s+as\s+\w+)?\s*$|^\s*from\s+[A-Za-z_.][A-Za-z0-9_.]*\s+import\b|^\s*def\s+\w+\s*\(|\bself\.'; then
    echo python
  elif printf '%s\n' "${text}" | grep -qE '\bconst\s+\w+\s*=|\blet\s+\w+\s*=|\brequire\(|\bfunction\s+\w+\s*\('; then
    echo javascript
  else
    echo java
  fi
}

# Исходник базового класса X (последний сегмент имени) с расширением ext:
# сначала рядом с грамматикой, затем по всей работе.
_antlr_find_super_source() {
  local work="$1" gdir="$2" cls="${3##*.}" ext="$4" f
  if [ -f "${gdir}/${cls}.${ext}" ]; then
    echo "${gdir}/${cls}.${ext}"; return 0
  fi
  f="$(find "${work}" -type f -name "${cls}.${ext}" "${_ANTLR_FIND_EXCLUDES[@]}" 2>/dev/null | sort | head -n 1)"
  [ -n "${f}" ] || return 1
  echo "${f}"
}

# Человекочитаемое имя таргета.
_antlr_target_title() {
  case "$1" in
    java) echo Java ;; csharp) echo 'C#' ;; python) echo Python ;; *) echo "$1" ;;
  esac
}

# Печатает сообщение о пропуске прогона из-за ограничения проверки.
_antlr_skip_note() {
  echo "    Прогон примеров ПРОПУЩЕН — это ограничение автоматической проверки, а НЕ ошибка студента."
  echo "    Грамматику нужно проверить по тексту."
}

# --- Драйверы разбора --------------------------------------------------------

# Драйвер разбора: как TestRig без -tree, но классы лексера и парсера
# передаются явно, а не выводятся из общего базового имени.
#   java YapisParseDriver <LexerClass> <ParserClass> <rule> <file>
# Ошибки лексера и парсера печатает стандартный ConsoleErrorListener в том
# же формате `line N:M message`, что и TestRig. Код выхода 0 и при
# синтаксических ошибках — их считает вызывающий по строкам вывода.
_antlr_write_driver() {
  cat > "$1/YapisParseDriver.java" <<'JAVA'
import java.lang.reflect.InvocationTargetException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Paths;
import org.antlr.v4.runtime.*;

public class YapisParseDriver {
    public static void main(String[] args) throws Exception {
        CharStream input = CharStreams.fromPath(Paths.get(args[3]), StandardCharsets.UTF_8);
        Lexer lexer = (Lexer) Class.forName(args[0]).getConstructor(CharStream.class).newInstance(input);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        Parser parser = (Parser) Class.forName(args[1]).getConstructor(TokenStream.class).newInstance(tokens);
        try {
            parser.getClass().getMethod(args[2]).invoke(parser);
        } catch (InvocationTargetException e) {
            throw (e.getCause() instanceof Exception) ? (Exception) e.getCause() : e;
        }
    }
}
JAVA
}

# Тот же драйвер для C#: классы ищутся по имени в сборке (у сгенерированных
# классов может быть namespace из @namespace). Проект собирается без сети из
# локального фида ANTLR_NUGET_FEED, если он задан.
#   $1 — каталог, $2 — "1", если нужен пакет Dentlr.
_antlr_write_csharp_driver() {
  local dir="$1" dentlr="$2" dentlr_ref="" major
  [ "${dentlr}" = "1" ] && dentlr_ref='<PackageReference Include="Dentlr" Version="2.0.0" />'
  # TargetFramework — по установленному SDK: в образе 10, на раннере GitHub
  # и у студента может быть 8 или 9 (Dentlr 2.0.0 требует net8.0+).
  major="$(dotnet --version 2>/dev/null | cut -d. -f1)"
  case "${major}" in ''|*[!0-9]*) major=10 ;; esac
  cat > "${dir}/YapisParseDriver.cs" <<'CS'
using System;
using System.Linq;
using System.Reflection;
using Antlr4.Runtime;

public static class YapisParseDriver
{
    public static int Main(string[] args)
    {
        var asm = typeof(YapisParseDriver).Assembly;
        Type Find(string n) => asm.GetTypes().First(t => t.Name == n || t.FullName == n);
        var input = CharStreams.fromPath(args[3]);
        var lexer = (Lexer)Activator.CreateInstance(Find(args[0]), input);
        var tokens = new CommonTokenStream(lexer);
        var parser = (Parser)Activator.CreateInstance(Find(args[1]), (ITokenStream)tokens);
        try
        {
            parser.GetType().GetMethod(args[2], Type.EmptyTypes).Invoke(parser, null);
        }
        catch (TargetInvocationException e)
        {
            // Только тип, сообщение и первый кадр: полный стек рантайма
            // вытеснил бы из отчёта строки `line N:M`.
            var inner = e.InnerException ?? e;
            Console.Error.WriteLine(inner.GetType().FullName + ": " + inner.Message);
            var frame = (inner.StackTrace ?? "").Split('\n').FirstOrDefault(l => !l.Contains(" Antlr4.Runtime."));
            if (!string.IsNullOrWhiteSpace(frame)) Console.Error.WriteLine(frame.TrimEnd());
            return 1;
        }
        return 0;
    }
}
CS
  cat > "${dir}/YapisParseDriver.csproj" <<CSPROJ
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net${major}.0</TargetFramework>
    <Nullable>disable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
    <NoWarn>\$(NoWarn);CS3021;CS0108;CS8981;CS0618</NoWarn>
    <AssemblyName>YapisParseDriver</AssemblyName>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Antlr4.Runtime.Standard" Version="4.13.1" />
    ${dentlr_ref}
  </ItemGroup>
</Project>
CSPROJ
  if [ -n "${ANTLR_NUGET_FEED:-}" ]; then
    cat > "${dir}/NuGet.config" <<NUGET
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="yapis-antlr" value="${ANTLR_NUGET_FEED}" />
  </packageSources>
</configuration>
NUGET
  fi
}

_antlr_write_python_driver() {
  cat > "$1/YapisParseDriver.py" <<'PY'
import importlib
import sys

from antlr4 import CommonTokenStream, FileStream


def load(name):
    return getattr(importlib.import_module(name), name)


lexer = load(sys.argv[1])(FileStream(sys.argv[4], encoding="utf-8"))
parser = load(sys.argv[2])(CommonTokenStream(lexer))
try:
    getattr(parser, sys.argv[3])()
except Exception as e:  # исключение из кода лексера/парсера студента
    print(f"{type(e).__name__}: {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# --- Прогон одного примера --------------------------------------------------

# Печатает отчёт по примеру, возвращает 0 при ожидаемом поведении.
_antlr_run_example() {
  local classdir="$1" jar="$2" target="$3" lexer_class="$4" parser_class="$5" rule="$6" example="$7" expect="$8" timeout_s="$9" rel="${10}"
  local out rc errors

  case "${target}" in
    csharp)
      out="$(cd "${classdir}" && timeout "${timeout_s}" \
        dotnet out/YapisParseDriver.dll "${lexer_class}" "${parser_class}" "${rule}" "${example}" 2>&1)" ;;
    python)
      out="$(cd "${classdir}" && timeout "${timeout_s}" \
        python3 YapisParseDriver.py "${lexer_class}" "${parser_class}" "${rule}" "${example}" 2>&1)" ;;
    *)
      out="$(cd "${classdir}" && timeout "${timeout_s}" \
        java -cp "${jar}:." YapisParseDriver "${lexer_class}" "${parser_class}" "${rule}" "${example}" 2>&1)" ;;
  esac
  rc=$?

  # Ошибки печатаются в формате `line N:M message`; процесс при
  # синтаксических ошибках всё равно завершается кодом 0, поэтому считаем
  # именно строки с ошибками.
  errors="$(printf '%s\n' "${out}" | grep -cE '^line [0-9]+:[0-9]+ ' || true)"

  echo "--- ${rel}"
  if [ "${rc}" -eq 124 ]; then
    echo "    РЕЗУЛЬТАТ: таймаут ${timeout_s}с — разбор не завершился (возможна левая рекурсия без базы или бесконечный цикл в лексере)."
    return 1
  fi

  if [ -n "${out}" ]; then
    printf '%s\n' "${out}" | head -n "${ANTLR_CHECK_MAX_OUTPUT_LINES}" | cut -c1-300 | sed 's/^/    /'
    if [ "$(printf '%s\n' "${out}" | wc -l)" -gt "${ANTLR_CHECK_MAX_OUTPUT_LINES}" ]; then
      echo "    (вывод обрезан)"
    fi
  fi

  if [ "${expect}" = "ok" ]; then
    if [ "${errors}" -eq 0 ] && [ "${rc}" -eq 0 ]; then
      echo "    РЕЗУЛЬТАТ: разобран без ошибок, как и ожидается."
      return 0
    fi
    if [ "${errors}" -eq 0 ]; then
      echo "    РЕЗУЛЬТАТ: разбор прерван исключением (код ${rc}) — корректный пример НЕ разбирается грамматикой."
    else
      echo "    РЕЗУЛЬТАТ: ${errors} сообщений об ошибках — корректный пример НЕ разбирается грамматикой."
    fi
    return 1
  fi

  # expect = error. Исключение из кода лексера (например, «Inconsistent
  # indentation») — тоже обнаруженная ошибка.
  if [ "${errors}" -gt 0 ] || [ "${rc}" -ne 0 ]; then
    echo "    РЕЗУЛЬТАТ: ${errors} сообщений об ошибках (код ${rc}) — ошибка обнаружена, как и ожидается."
    return 0
  fi
  echo "    РЕЗУЛЬТАТ: разобран БЕЗ ошибок — пример с ошибкой грамматика принимает как корректный."
  return 1
}

# --- Сборка одной грамматики ------------------------------------------------

# Аргументы: <jar> <outdir> <work_dir> <файлы .g4...>
# Печатает отчёт; в stdout последней строкой —
# "OK <target> <LexerClass> <ParserClass> <rule>" либо "FAIL" / "SKIP <причина>".
_antlr_build() {
  local jar="$1" outdir="$2" work="$3"; shift 3
  local files=("$@") f out rc
  local parser_name="" rule="" kind name

  # Имена классов. Для `grammar X;` ANTLR генерирует XLexer и XParser; для
  # раздельных `lexer grammar A;` и `parser grammar B;` — классы A и B,
  # и имена могут быть любыми. Лексер для парсера выбирается по tokenVocab,
  # а если он не указан — единственный лексер каталога.
  local lexer_class="" parser_class="" vocab="" lexer_names=()
  for f in "${files[@]}"; do
    kind="$(_antlr_grammar_kind "${f}")"
    name="$(_antlr_grammar_name "${f}")"
    case "${kind}" in
      combined) parser_name="${name}"; parser_class="${name}Parser"; lexer_class="${name}Lexer"
                rule="$(_antlr_first_parser_rule "${f}")" ;;
      parser)   parser_name="${name}"; parser_class="${name}"; vocab="$(_antlr_token_vocab "${f}")"
                rule="$(_antlr_first_parser_rule "${f}")" ;;
      lexer)    lexer_names+=("${name}") ;;
    esac
  done
  if [ -z "${lexer_class}" ] && [ "${#lexer_names[@]}" -gt 0 ]; then
    local ln
    for ln in "${lexer_names[@]}"; do
      [ "${ln}" = "${vocab}" ] && lexer_class="${ln}"
    done
    if [ -z "${lexer_class}" ] && [ "${#lexer_names[@]}" -eq 1 ]; then
      lexer_class="${lexer_names[0]}"
    fi
    if [ -z "${lexer_class}" ]; then
      echo "    В каталоге несколько lexer grammar (${lexer_names[*]}), а parser grammar ${parser_name} не указывает"
      echo "    свой лексер через options { tokenVocab = ...; }. Какой лексер использовать, определить нельзя —"
      echo "    прогон примеров пропущен. Это ограничение проверки; tokenVocab в парсере решит вопрос."
      echo "SKIP ambiguous-lexer"
      return 0
    fi
  fi

  if [ -z "${parser_name}" ]; then
    echo "    Не найдено правил парсера (только lexer grammar?) — прогон примеров невозможен."
    echo "SKIP no-parser"
    return 0
  fi
  if [ -z "${rule}" ]; then
    echo "    Не удалось определить стартовое правило (первое правило парсера) — прогон примеров невозможен."
    echo "FAIL"
    return 1
  fi

  # Таргет: явный options { language = ... } > язык кода в @header/@members >
  # язык исходника базового класса > Java. "strong" — таргет задан явно или
  # кодом, и базовый класс обязан быть на том же языке.
  local target="" strong=0 lang_opt reason=""
  lang_opt="$(_antlr_language_option "${files[@]}")"
  case "${lang_opt}" in
    "")       ;;
    CSharp*)  target=csharp ;;
    Python*)  target=python ;;
    Java)     target=java ;;
    *)        target="${lang_opt}" ;;
  esac
  if [ -n "${target}" ]; then
    strong=1; reason="options { language = ${lang_opt}; }"
  else
    target="$(_antlr_action_language "${files[@]}")"
    if [ "${target}" != "java" ]; then
      strong=1; reason="код в @header/@members"
    fi
  fi

  local super_sources=() need_dentlr=0 sc src ext cand
  for f in "${files[@]}"; do
    sc="$(_antlr_super_class "${f}")" || continue
    case "${sc}" in
      Dentlr.*|DentlrLexer)
        # Dentlr — NuGet-пакет с базовым лексером для отступов, только C#.
        if [ "${strong}" -eq 1 ] && [ "${target}" != "csharp" ]; then
          echo "    $(basename "${f}"): superClass = ${sc} (пакет Dentlr для C#), но таргет по ${reason} — $(_antlr_target_title "${target}")."
          _antlr_skip_note
          echo "SKIP super-class-mismatch"
          return 0
        fi
        target=csharp; strong=1; need_dentlr=1
        [ -n "${reason}" ] || reason="superClass = ${sc}"
        continue ;;
    esac
    src=""
    if [ "${strong}" -eq 1 ]; then
      case "${target}" in java) ext=java ;; csharp) ext=cs ;; python) ext=py ;; *) ext="" ;; esac
      [ -n "${ext}" ] && src="$(_antlr_find_super_source "${work}" "$(dirname "${f}")" "${sc}" "${ext}")"
    else
      for cand in java:java cs:csharp py:python; do
        if src="$(_antlr_find_super_source "${work}" "$(dirname "${f}")" "${sc}" "${cand%%:*}")"; then
          target="${cand##*:}"; strong=1; reason="superClass = ${sc} (${src#"${work}"/})"
          break
        fi
      done
    fi
    if [ -z "${src}" ]; then
      echo "    $(basename "${f}"): options { superClass = ${sc}; } — исходник базового класса ${sc##*.} в работе не найден"
      echo "    (искали ${sc##*.}.java, ${sc##*.}.cs, ${sc##*.}.py рядом с грамматикой и во всей работе; Dentlr для C# поддерживается)."
      _antlr_skip_note
      echo "SKIP super-class-missing"
      return 0
    fi
    echo "    $(basename "${f}"): базовый класс ${sc} — ${src#"${work}"/}"
    super_sources+=("${src}")
  done

  case "${target}" in
    java|csharp|python) ;;
    *)
      echo "    Встроенный код или options { language } для таргета ${target} (${reason:-не определено})."
      echo "    Автоматическая проверка собирает грамматики в Java, C# и Python; для ${target} рантайма в образе нет."
      _antlr_skip_note
      echo "    Рекомендация (не существенное замечание): код лучше выносить из .g4 в отдельные классы."
      echo "SKIP foreign-actions"
      return 0 ;;
  esac

  local title
  title="$(_antlr_target_title "${target}")"
  if [ "${target}" = "csharp" ] && ! command -v dotnet >/dev/null 2>&1; then
    echo "    Таргет C# (${reason}), но dotnet в окружении не найден — сборка не выполнена (ограничение окружения, не работы)."
    _antlr_skip_note
    echo "SKIP no-dotnet"
    return 0
  fi
  if [ "${target}" = "python" ] && ! python3 -c 'import antlr4' >/dev/null 2>&1; then
    echo "    Таргет Python (${reason}), но python3 с пакетом antlr4-python3-runtime в окружении не найден —"
    echo "    сборка не выполнена (ограничение окружения, не работы)."
    _antlr_skip_note
    echo "SKIP no-python-runtime"
    return 0
  fi
  [ "${target}" = "java" ] || echo "    Таргет: ${title} (${reason})."

  mkdir -p "${outdir}"
  # -Xexact-output-dir: класть файлы прямо в outdir, а не воспроизводить путь.
  # Файлы копируем в outdir: ANTLR ищет tokenVocab рядом с грамматикой.
  cp "${files[@]}" "${outdir}/"
  local basenames=() b lang_flag=()
  for f in "${files[@]}"; do basenames+=("$(basename "${f}")"); done
  case "${target}" in
    csharp) lang_flag=(-Dlanguage=CSharp) ;;
    python) lang_flag=(-Dlanguage=Python3) ;;
    java)   lang_flag=(-Dlanguage=Java) ;;
  esac

  out="$(cd "${outdir}" && timeout 120 java -jar "${jar}" "${lang_flag[@]}" -o . -Xexact-output-dir -no-listener -no-visitor "${basenames[@]}" 2>&1)"
  rc=$?
  if [ -n "${out}" ]; then
    echo "    Вывод antlr4:"
    printf '%s\n' "${out}" | head -n 20 | cut -c1-300 | sed 's/^/      /'
  fi
  if [ "${rc}" -ne 0 ]; then
    echo "    РЕЗУЛЬТАТ: antlr4 завершился с кодом ${rc} — грамматика НЕ собирается."
    echo "FAIL"
    return 1
  fi
  # Предупреждения ANTLR (warning(…)) не ломают сборку, но это замечания.
  if printf '%s\n' "${out}" | grep -qE '^(warning|error)\('; then
    echo "    ЗАМЕЧАНИЕ: antlr4 выдал предупреждения — см. выше."
  fi
  for b in "${basenames[@]}"; do
    rm -f "${outdir:?}/${b}"
  done

  for src in ${super_sources[@]+"${super_sources[@]}"}; do
    cp "${src}" "${outdir}/"
  done

  local tool
  case "${target}" in
    java)
      tool=javac
      _antlr_write_driver "${outdir}"
      # -d .: базовый класс студента может лежать в пакете.
      out="$(cd "${outdir}" && timeout 120 javac -encoding UTF-8 -d . -cp "${jar}" ./*.java 2>&1)" ;;
    csharp)
      tool="dotnet build"
      _antlr_write_csharp_driver "${outdir}" "${need_dentlr}"
      # Без фида пакеты берутся из источников dotnet по умолчанию (локальный
      # запуск с сетью); с фидом — изолированный кэш внутри outdir.
      # Сервер сборки и node reuse отключены: иначе после сборки остаются
      # фоновые процессы, и контейнер/timeout ждут их.
      out="$(cd "${outdir}" \
        && if [ -n "${ANTLR_NUGET_FEED:-}" ]; then export NUGET_PACKAGES="${outdir}-nuget"; fi \
        && DOTNET_NOLOGO=1 DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
           timeout 180 dotnet build YapisParseDriver.csproj -nologo -v q -nodeReuse:false \
             -p:UseSharedCompilation=false -o out 2>&1)" ;;
    python)
      tool=python3
      _antlr_write_python_driver "${outdir}"
      out="$(cd "${outdir}" && timeout 60 python3 -c 'import importlib, sys
for m in sys.argv[1:]:
    importlib.import_module(m)' "${lexer_class}" "${parser_class}" 2>&1)" ;;
  esac
  rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "    Вывод ${tool}:"
    printf '%s\n' "${out}" | grep -vE '^\s*$' | grep -E 'error|Error|rror:|^\s' | head -n 15 | cut -c1-300 | sed 's/^/      /'
    echo "    РЕЗУЛЬТАТ: сгенерированный код (${title}) не компилируется (код ${rc})."
    if [ "${target}" = "java" ] && [ "${strong}" -eq 0 ] && [ "${#super_sources[@]}" -eq 0 ]; then
      echo "    Обычно это встроенный в .g4 код под другой язык, который проверка не распознала."
    else
      echo "    Если ошибка в коде из самого .g4 (@header/@members) или в базовом классе — это замечание к работе;"
      echo "    если не найден тип из другой части работы (класс вне каталога грамматики) — ограничение проверки."
    fi
    echo "    Прогон примеров ПРОПУЩЕН."
    echo "SKIP compile-failed"
    return 0
  fi

  echo "    Сборка (${title}): успешно. Лексер: ${lexer_class}, парсер: ${parser_class}, стартовое правило: ${rule}"
  echo "OK ${target} ${lexer_class} ${parser_class} ${rule}"
  return 0
}

# --- Главная функция -------------------------------------------------------

run_antlr_checks() {
  local work_dir="${1:?work_dir is required}"
  local timeout_s="${2:-${ANTLR_CHECK_TIMEOUT_DEFAULT}}"
  local max_examples="${3:-${ANTLR_CHECK_MAX_EXAMPLES_DEFAULT}}"

  # Прогон идёт из временного каталога с .class-файлами, поэтому пути к
  # примерам и грамматикам должны быть абсолютными (check.sh получает '.').
  if [ -d "${work_dir}" ]; then
    work_dir="$(cd "${work_dir}" && pwd)"
  fi

  local jar
  if ! command -v java >/dev/null 2>&1; then
    echo "Java не найдена — сборка грамматики и прогон примеров не выполнены (ограничение окружения, не работы)."
    return 0
  fi
  if ! jar="$(_antlr_find_jar)"; then
    echo "antlr-*-complete.jar не найден — сборка грамматики и прогон примеров не выполнены (ограничение окружения, не работы)."
    return 0
  fi

  local grammars=() line
  while IFS= read -r line; do
    [ -n "${line}" ] && grammars+=("${line}")
  done < <(find "${work_dir}" -name '*.g4' \
      -not -path '*/target/*' -not -path '*/build/*' -not -path '*/.venv/*' \
      -not -path '*/node_modules/*' -not -path '*/.antlr/*' -not -path '*/.git/*' 2>/dev/null | sort)

  if [ "${#grammars[@]}" -eq 0 ]; then
    echo "Файлы грамматики (*.g4) не найдены — сборка не выполнена."
    return 1
  fi

  local examples_dir="" candidate
  for candidate in examples example samples; do
    if [ -d "${work_dir}/${candidate}" ]; then examples_dir="${work_dir}/${candidate}"; break; fi
  done

  local ok_examples=() err_examples=()
  if [ -n "${examples_dir}" ]; then
    while IFS= read -r line; do
      [ -n "${line}" ] && err_examples+=("${line}")
    done < <(find "${examples_dir}" -type f -iname 'error-*' 2>/dev/null | sort | head -n "${max_examples}")
    while IFS= read -r line; do
      [ -n "${line}" ] && ok_examples+=("${line}")
    done < <(find "${examples_dir}" -type f -not -iname 'error-*' -not -iname '*.md' -not -iname '.*' 2>/dev/null | sort | head -n "${max_examples}")
  fi

  echo "ANTLR: $(java -jar "${jar}" 2>&1 | head -n 1 | grep -oE 'Version [0-9.]+' || echo 'версия неизвестна'). Стартовое правило — первое правило парсера в файле (как в lab.antlr.org без указания правила)."
  echo

  # Группировка: комбинированные — по одной; lexer+parser из одного каталога — вместе.
  # Простая схема: для каждого каталога с .g4 собираем все parser/combined
  # грамматики, к parser-грамматике добавляем все lexer-грамматики того же каталога.
  local tmp_root
  tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/antlr-check.XXXXXX")"
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp_root}'" RETURN

  local failed=0 built=0 skipped=0 target g kind dir lexers=() group=() name outdir status lexer_class parser rule example rel n=0

  for g in "${grammars[@]}"; do
    kind="$(_antlr_grammar_kind "${g}")"
    [ "${kind}" = "lexer" ] && lexers+=("${g}")
  done

  for g in "${grammars[@]}"; do
    kind="$(_antlr_grammar_kind "${g}")"
    name="$(_antlr_grammar_name "${g}")"
    rel="${g#"${work_dir}"/}"
    case "${kind}" in
      lexer)
        # Отдельный лексер: собирается в паре со своим парсером, здесь пропускаем.
        continue ;;
      unknown)
        echo "== ${rel} =="
        echo "    Не распознан заголовок grammar/lexer grammar/parser grammar — файл пропущен."
        echo
        failed=$((failed + 1))
        continue ;;
    esac

    group=("${g}")
    if [ "${kind}" = "parser" ]; then
      dir="$(dirname "${g}")"
      local lx
      # ${lexers[@]+…}: пустой массив под set -u в bash 3.2 (macOS) — unbound variable.
      for lx in ${lexers[@]+"${lexers[@]}"}; do
        [ "$(dirname "${lx}")" = "${dir}" ] && group+=("${lx}")
      done
      if [ "${#group[@]}" -eq 1 ]; then
        echo "== ${rel} (${name}) =="
        echo "    parser grammar без lexer grammar в том же каталоге — сборка невозможна."
        echo
        failed=$((failed + 1))
        continue
      fi
    fi

    n=$((n + 1))
    outdir="${tmp_root}/g${n}"
    echo "== ${rel} (${name}) =="
    status="$(_antlr_build "${jar}" "${outdir}" "${work_dir}" "${group[@]}")"
    printf '%s\n' "${status}" | sed '$d'
    status="$(printf '%s\n' "${status}" | tail -n 1)"

    case "${status}" in
      FAIL*) failed=$((failed + 1)); echo; continue ;;
      SKIP*) skipped=$((skipped + 1)); echo; continue ;;
      OK*)   built=$((built + 1)) ;;
    esac
    target="$(printf '%s' "${status}" | awk '{ print $2 }')"
    lexer_class="$(printf '%s' "${status}" | awk '{ print $3 }')"
    parser="$(printf '%s' "${status}" | awk '{ print $4 }')"
    rule="$(printf '%s' "${status}" | awk '{ print $5 }')"

    if [ -z "${examples_dir}" ]; then
      echo "    Директория с примерами не найдена — прогон пропущен."
      echo
      continue
    fi

    if [ "${#ok_examples[@]}" -gt 0 ]; then
      echo "  -- Корректные примеры (ожидается разбор без ошибок) --"
      for example in "${ok_examples[@]}"; do
        _antlr_run_example "${outdir}" "${jar}" "${target}" "${lexer_class}" "${parser}" "${rule}" "${example}" ok "${timeout_s}" "${example#"${work_dir}"/}" \
          || failed=$((failed + 1))
      done
    else
      echo "  Корректных примеров не найдено."
    fi
    if [ "${#err_examples[@]}" -gt 0 ]; then
      echo "  -- Примеры с ошибками (ожидаются сообщения об ошибках) --"
      for example in "${err_examples[@]}"; do
        _antlr_run_example "${outdir}" "${jar}" "${target}" "${lexer_class}" "${parser}" "${rule}" "${example}" error "${timeout_s}" "${example#"${work_dir}"/}" \
          || failed=$((failed + 1))
      done
    fi
    echo
  done

  if [ "${failed}" -gt 0 ]; then
    echo "Итог: собрано грамматик — ${built}, расхождений с ожидаемым поведением — ${failed}."
    return 1
  fi
  if [ "${built}" -eq 0 ]; then
    echo "Итог: прогон примеров НЕ ВЫПОЛНЕН ни для одной грамматики (причины выше). Если причина — ограничение"
    echo "проверки (ПРОПУЩЕН), это не замечание к работе, но и подтверждения, что примеры разбираются, НЕТ:"
    echo "грамматику и примеры нужно проверить по тексту."
    return 0
  fi
  if [ "${skipped}" -gt 0 ]; then
    echo "Итог: собрано грамматик — ${built}, их примеры разобраны ожидаемо; ещё ${skipped} грамматик(и) не собраны (ПРОПУЩЕН, см. выше)."
    return 0
  fi
  echo "Итог: собрано грамматик — ${built}, все проверенные примеры разобраны ожидаемо."
  return 0
}
