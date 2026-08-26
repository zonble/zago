export type Locale = "en" | "zh-TW";

interface LocaleRule {
  pattern: RegExp;
  locale: Locale;
}

const URL_LOCALE_RULES: readonly LocaleRule[] = [
  { pattern: /^(zh|tw|hant)/i, locale: "zh-TW" },
  { pattern: /^en/i, locale: "en" },
];

const BROWSER_LOCALE_RULES: readonly LocaleRule[] = [
  { pattern: /^zh(-|_)?(tw|hk|mo|hant)|^zh$/i, locale: "zh-TW" },
  { pattern: /^en/i, locale: "en" },
];

function matchLocale(input: string, rules: readonly LocaleRule[]): Locale | undefined {
  return rules.find((rule) => rule.pattern.test(input.trim()))?.locale;
}

export function detectLanguage(): Locale {
  const langParam = new URLSearchParams(window.location.search).get("lang");
  if (langParam) {
    return matchLocale(langParam, URL_LOCALE_RULES) ?? "en";
  }

  const navLanguages = navigator.languages?.length ? navigator.languages : [navigator.language || ""];
  for (const lang of navLanguages) {
    const matched = matchLocale(lang, BROWSER_LOCALE_RULES);
    if (matched) return matched;
  }

  return "en";
}

import { en } from "./locales/en";
import { zhTW } from "./locales/zh-TW";

export const translations = {
  en,
  "zh-TW": zhTW,
};

export function applyI18n(lang: Locale) {
  const t = translations[lang];
  document.documentElement.lang = lang === "zh-TW" ? "zh-TW" : "en";
  document.title = t.pageTitle;

  const metaDesc = document.querySelector('meta[name="description"]');
  if (metaDesc) metaDesc.setAttribute("content", t.pageDescription);

  const metaOgTitle = document.querySelector('meta[property="og:title"]');
  if (metaOgTitle) metaOgTitle.setAttribute("content", t.pageTitle);

  const metaTwitterTitle = document.querySelector('meta[name="twitter:title"]');
  if (metaTwitterTitle) metaTwitterTitle.setAttribute("content", t.pageTitle);

  // Translate all [data-i18n] elements
  const elements = document.querySelectorAll<HTMLElement>("[data-i18n]");
  elements.forEach((el) => {
    const key = el.dataset.i18n as keyof typeof t;
    if (key && typeof t[key] === "string") {
      const val = t[key] as string;
      if (el.dataset.i18nHtml === "true") {
        el.innerHTML = val;
      } else {
        el.textContent = val;
      }
    }
  });

  // Translate all [data-i18n-title] elements
  const titleElements = document.querySelectorAll<HTMLElement>("[data-i18n-title]");
  titleElements.forEach((el) => {
    const key = el.dataset.i18nTitle as keyof typeof t;
    if (key && typeof t[key] === "string") {
      el.title = t[key] as string;
    }
  });
}
