// Точка входа бандла: всё, что нужно странице самопроверки, из одной копии
// @codemirror/state (несколько копий ломают редактор).
export { EditorState, StateField, StateEffect, RangeSetBuilder, Transaction } from "@codemirror/state";
export { EditorView, Decoration, WidgetType, keymap, lineNumbers, highlightActiveLine,
         highlightActiveLineGutter, drawSelection, placeholder } from "@codemirror/view";
export { defaultKeymap, history, historyKeymap, indentWithTab } from "@codemirror/commands";
export { StreamLanguage, HighlightStyle, syntaxHighlighting, bracketMatching } from "@codemirror/language";
export { setDiagnostics, lintGutter, lintKeymap } from "@codemirror/lint";
export { autocompletion, completionKeymap, closeBrackets } from "@codemirror/autocomplete";
export { tags } from "@lezer/highlight";
