const colors = require("tailwindcss/colors");

/*
Colors naming convention: [light|dark]-[role]-[primary|secondary]-[interaction]
e.g. hover:bg-dark-brand-primary-hover
*/

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
        "light-brand-primary": globalColors.brand[600],
        "light-brand-primary-hover": globalColors.brand[500],
        "light-brand-secondary": globalColors.brand[100],
        "light-brand-secondary-hover": globalColors.brand[200],
        "light-neutral-primary": globalColors.neutral[100],
        "light-neutral-primary-hover": globalColors.neutral[200],
        "light-neutral-secondary": globalColors.neutral[50],
        "light-danger-primary": globalColors.danger[600],
        "light-danger-primary-hover": globalColors.danger[800],
        "light-danger-secondary": globalColors.danger[100],
        "light-danger-secondary-hover": globalColors.danger[200],

        // Dark mode
        "dark-brand-primary": globalColors.brand[700],
        "dark-brand-primary-hover": globalColors.brand[800],
        "dark-brand-secondary": globalColors.brand[900],
        "dark-brand-secondary-hover": globalColors.brand[800],
        "dark-neutral-primary": globalColors.neutral[800],
        "dark-neutral-primary-hover": globalColors.neutral[700],
        "dark-neutral-secondary": globalColors.neutral[900],
        "dark-danger-primary": globalColors.danger[600],
        "dark-danger-primary-hover": globalColors.danger[700],
        "dark-danger-secondary": globalColors.danger[900],
        "dark-danger-secondary-hover": globalColors.danger[800],
      },
      borderColor: {
        // Light mode
        "light-brand-primary": globalColors.brand[600],
        "light-neutral-primary": globalColors.neutral[400],
        "light-danger-primary": globalColors.danger[400],
        "light-danger-secondary": globalColors.danger[300],

        // Dark mode
        "dark-brand-primary": globalColors.brand[500],
        "dark-neutral-primary": globalColors.neutral[600],
        "dark-danger-primary": globalColors.danger[500],
        "dark-danger-secondary": globalColors.danger[600],
      },
      textColor: {
        // Light mode
        "light-brand-onprimary": colors.white,
        "light-brand-onsecondary": globalColors.brand[800],
        "light-brand-onneutral": globalColors.brand[600],
        "light-danger-onprimary": colors.white,
        "light-danger-onprimary-hover": globalColors.neutral[50],
        "light-danger-onsecondary": globalColors.danger[800],
        "light-neutral-onprimary": globalColors.neutral[800],
        "light-neutral-onsecondary": globalColors.neutral[800],
        "light-neutral-onneutral": globalColors.neutral[900],

        // Dark mode
        "dark-brand-onprimary": colors.white,
        "dark-brand-onsecondary": globalColors.brand[200],
        "dark-brand-onneutral": globalColors.brand[500],
        "dark-danger-onprimary": colors.white,
        "dark-danger-onprimary-hover": globalColors.neutral[900],
        "dark-danger-onsecondary": globalColors.danger[200],
        "dark-neutral-onprimary": globalColors.neutral[200],
        "dark-neutral-onsecondary": globalColors.neutral[200],
      },
      ringColor: {
        // Light mode
        "light-brand-primary": globalColors.brand[100],
        "light-neutral-primary": globalColors.neutral[100],
        "light-danger-primary": globalColors.danger[100],

        // Dark mode
        "dark-brand-primary": globalColors.brand[800],
        "dark-neutral-primary": globalColors.neutral[600],
        "dark-danger-primary": globalColors.danger[600],
      },
    },
  },
  plugins: [],
};
