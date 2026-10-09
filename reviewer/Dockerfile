# Образ для изолированного запуска compile.sh студента (reviewer/lib/run-check.sh).
#
# Контейнер запускается БЕЗ СЕТИ, поэтому всё, что нужно для сборки
# студенческих работ, должно быть внутри образа: скачать зависимости во время
# проверки студент не сможет. Состав подобран по фактическим работам прошлого
# года (yapis-2025): Python — 10 работ, Java — 7, C# — 2, TypeScript — 1.
#
# Образ собирается и публикуется в GHCR раз в неделю
# (reviewer/workflow/build-check-image.yml), а не при каждом ревью.
#
# Если студенту нужен другой toolchain — он пишет об этом преподавателю,
# и пакет добавляется сюда. Это осознанное ограничение: единый образ
# гарантирует, что "у меня на машине работает" проверяется одинаково у всех.

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    ANTLR_JAR=/opt/antlr/antlr-4.13.2-complete.jar \
    M2_HOME=/opt/maven \
    PATH=/opt/maven/bin:/usr/share/dotnet:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash coreutils findutils grep sed gawk diffutils file \
      ca-certificates curl unzip zip make \
      python3 python3-pip python3-venv \
      openjdk-21-jdk-headless \
      nodejs npm \
      dotnet-sdk-10.0 dotnet-runtime-8.0 \
      llvm clang \
    && rm -rf /var/lib/apt/lists/*

# .NET: SDK 10 (LTS, поддержка до 11.2028) из noble-updates. Это линейка
# SDK 1xx (10.0.1xx): Ubuntu собирает SDK из исходников и 2xx–4xx не
# выпускает. rollForward в global.json разрешает только версии ВЫШЕ
# указанной, поэтому работа с "version": "10.0.401" здесь не соберётся ни
# при каком rollForward (проверено: latestPatch/latestFeature/latestMajor —
# "A compatible .NET SDK was not found"). Студенту нужно удалить
# global.json или указать "version": "10.0.100", "rollForward": "latestFeature".
#
# Runtime 8.0 — на переходный период, для работ с TargetFramework=net8.0:
# SDK 10 их собирает, но запустить собранную .dll без runtime 8.0 нельзя.
# Поддержка .NET 8 заканчивается 10.11.2026 — тогда runtime можно убрать.

# ANTLR — основной инструмент курса (ЛР2-ЛР5). Кладём и jar, и обёртки
# antlr4/grun, и Python/JS-рантаймы: без сети студент их не поставит.
RUN mkdir -p /opt/antlr \
    && curl -fsSL -o "${ANTLR_JAR}" https://www.antlr.org/download/antlr-4.13.2-complete.jar \
    && printf '#!/bin/sh\nexec java -jar %s "$@"\n' "${ANTLR_JAR}" > /usr/local/bin/antlr4 \
    && printf '#!/bin/sh\nexec java -cp %s:"$CLASSPATH" org.antlr.v4.gui.TestRig "$@"\n' "${ANTLR_JAR}" > /usr/local/bin/grun \
    && chmod +x /usr/local/bin/antlr4 /usr/local/bin/grun

# Офлайн-фид NuGet для сборки C#-грамматик ЛР2 (.github/review/lib/antlr-check.sh):
# грамматика с кодом на C# в @members или с superClass = Dentlr.DentlrLexer
# собирается в C#-таргете, а сети во время проверки нет. Antlr4.Runtime.Standard
# 4.13.1 — последняя версия рантайма в NuGet (совместима с инструментом 4.13.2);
# Dentlr — базовый лексер INDENT/DEDENT, который встречается в работах на C#.
ENV ANTLR_NUGET_FEED=/opt/antlr/nuget
RUN mkdir -p "${ANTLR_NUGET_FEED}" \
    && curl -fsSL -o "${ANTLR_NUGET_FEED}/antlr4.runtime.standard.4.13.1.nupkg" \
         https://api.nuget.org/v3-flatcontainer/antlr4.runtime.standard/4.13.1/antlr4.runtime.standard.4.13.1.nupkg \
    && curl -fsSL -o "${ANTLR_NUGET_FEED}/dentlr.2.0.0.nupkg" \
         https://api.nuget.org/v3-flatcontainer/dentlr/2.0.0/dentlr.2.0.0.nupkg

# JAVA_HOME — через symlink, а не захардкоженный путь с архитектурой:
# на раннере образ amd64, а локально у преподавателя на Apple Silicon —
# arm64, и mvn с неверным JAVA_HOME отказывался стартовать.
RUN ln -s "$(dirname "$(dirname "$(readlink -f "$(which java)")")")" /opt/java
ENV JAVA_HOME=/opt/java

# Maven ставим тарболом: пакет из apt тянет лишний JDK 17 в образ.
#
# Берём с archive.apache.org, а НЕ с dlcdn.apache.org: зеркало dlcdn хранит
# только актуальные версии и удаляет старые — сборка образа падала с 404,
# когда 3.9.9 оттуда убрали. В архиве версии остаются навсегда.
ARG MAVEN_VERSION=3.9.16
RUN curl -fsSL "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
      | tar -xz -C /opt \
    && mv "/opt/apache-maven-${MAVEN_VERSION}" /opt/maven

# Python-рантаймы ANTLR и типовые зависимости студенческих работ.
RUN pip3 install --break-system-packages --no-cache-dir \
      antlr4-tools antlr4-python3-runtime==4.13.2 pytest

# Java-рантайм ANTLR в CLASSPATH по умолчанию — чтобы javac находил его без
# настройки со стороны студента.
ENV CLASSPATH=".:${ANTLR_JAR}"

# Непривилегированный пользователь: контейнер запускается с --user 1000:1000.
# В ubuntu:24.04 uid 1000 уже занят пользователем ubuntu — используем его.
RUN mkdir -p /work /review && chown -R 1000:1000 /work

WORKDIR /work
USER 1000:1000
