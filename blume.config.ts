import { defineConfig } from "blume";
import { filesystem, obsidian } from "blume/sources";
export default defineConfig({
  title: "KI-Glossar",
  description: "Begriffe rund um KI, kurz erklärt.",
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
  footer: {
    copyright: `${new Date().getFullYear()} Benjamin Brücker`,
    links: [
      { label: "Über dieses Glossar", href: "/ueber" },
      { label: "Impressum", href: "/impressum" },
      { label: "Datenschutz", href: "/datenschutz" },
    ],
  },
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