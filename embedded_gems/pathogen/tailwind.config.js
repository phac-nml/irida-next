const colors = require("tailwindcss/colors");

const globalColors = {
  brand: colors.emerald,
  neutral: colors.slate,
  danger: colors.rose,
  success: colors.green,
  warning: colors.amber,
};

/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: "class",
  content: [
    "./app/components/**/*.erb",
    "./app/components/**/*.html",
    "./app/components/**/*.rb",
    "./app/lib/**/*.rb",
  ],
  theme: {
    extend: {
      colors: globalColors,
      backgroundColor: {
        // Light mode
        "brand-primary": globalColors.brand[600],
        "brand-primary-hover": globalColors.brand[500],
        "brand-secondary": globalColors.brand[100],
        "brand-secondary-hover": globalColors.brand[200],
        "neutral-primary": globalColors.neutral[100],
        "neutral-primary-hover": globalColors.neutral[200],
        "neutral-secondary": globalColors.neutral[50],
        "danger-primary": globalColors.danger[600],
        "danger-primary-hover": globalColors.danger[800],
        "danger-secondary": globalColors.danger[100],
        "danger-secondary-hover": globalColors.danger[200],
        // Dark mode
        "dark:brand-primary": globalColors.brand[500],
        "dark:brand-primary-hover": globalColors.brand[400],
        "dark:brand-secondary": globalColors.brand[900],
        "dark:brand-secondary-hover": globalColors.brand[800],
        "dark:neutral-primary": globalColors.neutral[800],
        "dark:neutral-primary-hover": globalColors.neutral[700],
        "dark:neutral-secondary": globalColors.neutral[900],
        "dark:danger-primary": globalColors.danger[500],
        "dark:danger-primary-hover": globalColors.danger[400],
        "dark:danger-secondary": globalColors.danger[900],
        "dark:danger-secondary-hover": globalColors.danger[800],
      },
      borderColor: {
        // Light mode
        "brand-primary": globalColors.brand[400],
        "neutral-primary": globalColors.neutral[300],
        "danger-primary": globalColors.danger[400],
        "danger-secondary": globalColors.danger[300],
        // Dark mode
        "dark:brand-primary": globalColors.brand[300],
        "dark:neutral-primary": globalColors.brand[200],
        "dark:danger-primary": globalColors.danger[300],
        "dark:danger-secondary": globalColors.danger[200],
      },
      textColor: {
        // Light mode
        "brand-onprimary": colors.white,
        "brand-onsecondary": globalColors.brand[800],
        "neutral-primary": globalColors.neutral[800],
        "neutral-secondary": globalColors.neutral[500],
        "neutral-emphasis": globalColors.neutral[900],
        "danger-onprimary": globalColors.danger[800],
        "danger-onprimary-hover": globalColors.neutral[50],
        "danger-onsecondary": globalColors.danger[800],
        // Dark mode
        "dark:brand-onprimary": colors.white,
        "dark:brand-onsecondary": globalColors.brand[200],
        "dark:neutral-primary": globalColors.neutral[200],
        "dark:neutral-secondary": globalColors.neutral[400],
        "dark:neutral-emphasis": globalColors.neutral[100],
        "dark:danger-onprimary": colors.white,
        "dark:danger-onsecondary": globalColors.danger[200],
      },
    },
  },
  plugins: [],
};
