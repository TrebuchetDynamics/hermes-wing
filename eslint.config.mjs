export default [
  {
    files: ["**/*.mjs"],
    ignores: [
      "build/**",
      "node_modules/**",
      "hermes-agent/**",
      "hermes-desktop/**",
    ],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: {
        Buffer: "readonly",
        TextDecoder: "readonly",
        URL: "readonly",
        console: "readonly",
        fetch: "readonly",
        process: "readonly",
        setTimeout: "readonly",
      },
    },
    rules: {
      "no-undef": "error",
      "no-unused-vars": ["warn", { args: "none" }],
    },
  },
  {
    files: ["playwright/**/*.mjs"],
    languageOptions: {
      globals: {
        document: "readonly",
        Event: "readonly",
        HTMLMediaElement: "readonly",
        location: "readonly",
        MouseEvent: "readonly",
        navigator: "readonly",
        PointerEvent: "readonly",
        queueMicrotask: "readonly",
        setTimeout: "readonly",
        window: "readonly",
      },
    },
  },
];
