const colors = require("tailwindcss/colors");

/*
Colors naming convention: [light|dark]-[role]-[primary|secondary]-[interaction]
e.g. hover:bg-dark-brand-primary-hover

Use the semantic colours first, then override with global colours
e.g. bg-light-brand-primary instead of bg-bg-brand-600
*/

const globalColors = {
  brand: colors.teal,
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
    "./previews/**/*.html.erb",
    "./app/lib/**/*.rb",
    "./docs/**/*.html.erb",
  ],
  theme: {
    extend: {
      colors: globalColors,
      backgroundColor: {
        // Light mode
        "light-default": globalColors.neutral[50],
        "light-brand-primary": globalColors.brand[600],
        "light-brand-primary-hover": globalColors.brand[700],
        "light-brand-secondary": globalColors.brand[500],
        "light-neutral-primary": globalColors.neutral[200],
        "light-neutral-primary-hover": globalColors.neutral[300],
        "light-neutral-secondary": globalColors.neutral[100],
        "light-danger-primary": globalColors.danger[600],
        "light-danger-primary-hover": globalColors.danger[700],
        "light-danger-secondary": globalColors.danger[400],

        // Dark mode
        "dark-default": globalColors.neutral[900],
        "dark-brand-primary": globalColors.brand[700],
        "dark-brand-primary-hover": globalColors.brand[800],
        "dark-brand-secondary": globalColors.brand[600],
        "dark-neutral-primary": globalColors.neutral[600],
        "dark-neutral-primary-hover": globalColors.neutral[700],
        "dark-neutral-secondary": globalColors.neutral[500],
        "dark-danger-primary": globalColors.danger[700],
        "dark-danger-primary-hover": globalColors.danger[800],
        "dark-danger-secondary": globalColors.danger[500],
      },
      borderColor: {
        // Light mode
        "light-brand-primary": globalColors.brand[600],
        "light-neutral-primary": globalColors.neutral[400],
        "light-danger-primary": globalColors.danger[400],

        // Dark mode
        "dark-brand-primary": globalColors.brand[800],
        "dark-neutral-primary": globalColors.neutral[600],
        "dark-danger-primary": globalColors.danger[500],
      },
      textColor: {
        // Light mode
        "light-default": globalColors.neutral[900],
        "light-onbrand-primary": colors.neutral[100],
        "light-onbrand-secondary": globalColors.neutral[900],
        "light-onneutral-primary": globalColors.neutral[700],
        "light-ondanger-primary": colors.neutral[100],

        // ------------------------------------------------------
        "light-brand-onprimary": colors.neutral[50],
        "light-brand-onneutral": globalColors.brand[600],
        "light-danger-onprimary": colors.neutral[50],
        "light-danger-onprimary-hover": globalColors.neutral[50],
        "light-neutral-onprimary": globalColors.neutral[800],
        "light-neutral-onneutral": globalColors.neutral[900],

        // Dark mode
        "dark-default": globalColors.neutral[400],
        "dark-onbrand-primary": colors.neutral[100],
        "dark-onbrand-secondary": globalColors.neutral[800],
        "dark-onneutral-primary": globalColors.neutral[200],
        "dark-ondanger-primary": colors.neutral[100],
        // ------------------------------------------------------
        "dark-brand-onprimary": colors.neutral[100],
        "dark-brand-onneutral": globalColors.brand[500],
        "dark-danger-onprimary": colors.neutral[100],
        "dark-danger-onprimary-hover": globalColors.neutral[900],
        "dark-neutral-onprimary": globalColors.neutral[200],
        "dark-neutral-onneutral": globalColors.neutral[900],
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
