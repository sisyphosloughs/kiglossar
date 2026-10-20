import { defineConfig } from "blume";
import { filesystem, obsidian } from "blume/sources";
export default defineConfig({
  title: "KI-Glossar",
  description: "Documentation powered by Blume.",
  deployment: {
    site: "https://kiglossar.schreibauf.de",
  },
  i18n: {
    defaultLocale: "de",
    locales: [
      { code: "de", label: "Deutsch" },
    ],
  },
  feedback: false,
  content: {
    sources: [
      filesystem({ root: "docs" }),
      obsidian({
        //prefix: "glossar",
        vault: "/Users/bbruecker/Notizen/IT/KI/_KI-Glossar",
        // Vault folder names to skip at any depth, on top of dot-folders
        exclude: ["Templates", "Daily"],
      }),
    ],
  },
});